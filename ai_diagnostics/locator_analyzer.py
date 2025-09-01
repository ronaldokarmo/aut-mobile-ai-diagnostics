import json
import re
from collections import defaultdict
from difflib import SequenceMatcher
from pathlib import Path
from datetime import datetime
from appium import webdriver
from appium.options.android import UiAutomator2Options

# ========================
# Configurações e paths
# ========================
CAPS_FILE = Path("resources/capabilities.json")
REPO_FILE = Path("locators/locator_repository.json")
LOG_FILE = Path("logs/locator_failures.json")
REPORT_FILE = Path("logs/locator_report.html")
PAGE_SOURCE_FILE = Path("logs/page_source.xml")
SIMILARITY_THRESHOLD = 0.75

# ========================
# Funções utilitárias
# ========================
def load_json(path):
    """Carrega JSON normal, JSON Lines ou corrige aspas simples."""
    if not path.exists():
        return []
    with open(path, "r", encoding="utf-8") as f:
        content = f.read().strip()
        if not content:
            return []
        try:
            # Primeiro tenta carregar como JSON válido
            return json.loads(content)
        except json.JSONDecodeError:
            items = []
            for line in content.splitlines():
                line = line.strip()
                if not line or line in ["[", "]"]:
                    continue
                # Corrige aspas simples para aspas duplas
                fixed_line = line.replace("'", '"')
                try:
                    items.append(json.loads(fixed_line))
                except json.JSONDecodeError as e:
                    print(f"⚠ Linha ignorada por erro de JSON: {line} ({e})")
            return items

def save_json(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)

def normaliza_strategy_name(strategy):
    if not strategy:
        return ""
    s = str(strategy).strip().lower()
    aliases = {
        "accessibility_id": "accessibility_id",
        "accessibilityid": "accessibility_id",
        "content-desc": "accessibility_id",
        "id": "id",
        "resource-id": "id",
        "text": "text",
        "xpath": "xpath",
        "uiautomator": "android uiautomator",
        "android uiautomator": "android uiautomator",
        "androiduiautomator": "android uiautomator",
        "class": "class",
    }
    return aliases.get(s, s)


# ========================
# Mapeamento de locators
# ========================
# ========================
# Mapeamento de locators
# ========================
def find_locator_key_in_repo(repo: dict, locator_value: str):
    """Procura no repositório a chave correspondente a um locator."""
    if locator_value in repo:
        return locator_value

    strat, val = (None, locator_value)
    if "=" in locator_value:
        try:
            strat, val = locator_value.split("=", 1)
            strat = normaliza_strategy_name(strat)
        except ValueError:
            strat, val = None, locator_value

    for key, alternatives in repo.items():
        for alt in alternatives:
            a_strat = normaliza_strategy_name(alt.get("strategy"))
            a_val = alt.get("value")
            if not a_val:
                continue
            if strat and a_strat and strat == a_strat and val == a_val:
                return key
            if val == a_val:
                return key
            if locator_value == f"{a_strat}={a_val}":
                return key
    return None

# ========================
# Extração de candidatos
# ========================
def extract_candidates(page_source: str):
    """Extrai todos os resource-id do page source."""
    ids = set(re.findall(r'resource-id="([^"]+)"', page_source or ""))
    return sorted(ids)

# ========================
# Similaridade
# ========================
def find_similar_locators(page_source: str, failed_value: str):
    """Encontra locators semelhantes ao que falhou, com base no page source."""
    candidates = extract_candidates(page_source)
    if not candidates:
        return []
    similar = []
    base = str(failed_value or "")
    for cand in candidates:
        ratio = SequenceMatcher(None, base, cand).ratio()
        if ratio >= SIMILARITY_THRESHOLD:
            similar.append((cand, ratio))
    return sorted(similar, key=lambda x: x[1], reverse=True)

# ========================
# Sugestões e Atualizações
# ========================
def suggest_and_update(default_page_source=""):
    repo_before = load_json(REPO_FILE)
    logs = load_json(LOG_FILE)
    grouped_failures = defaultdict(int)
    suggestions_display = {}
    updated = False

    # Cópia profunda do repositório para edição
    repo = json.loads(json.dumps(repo_before))

    for entry in logs:
        locator_value = entry.get("locator")
        ps_file = entry.get("page_source_file")

        # Escolhe o page source correto
        if ps_file and Path(ps_file).exists():
            page_source = Path(ps_file).read_text(encoding="utf-8")
            print(f"📄 Usando page source específico: {ps_file}")
        else:
            page_source = default_page_source
            print("📄 Usando page source padrão")

        # Mapeia locator para chave no repositório
        key = find_locator_key_in_repo(repo, locator_value)
        grouped_failures[key or locator_value] += 1

        # Se o locator já está no repositório
        if key:
            base_value = repo[key][0]["value"] if repo[key] else locator_value
            similar = find_similar_locators(page_source, base_value)
            if similar:
                existentes = {(alt.get("strategy"), alt.get("value")) for alt in repo[key]}
                novos = []
                for cand, score in similar:
                    if ("id", cand) not in existentes:
                        repo[key].append({"strategy": "id", "value": cand, "success_count": 0})
                        novos.append((cand, score))
                if novos:
                    suggestions_display[key] = novos
                    updated = True
        else:
            # Locator não mapeado no repositório
            failed_val = locator_value.split("=", 1)[1] if "=" in locator_value else locator_value
            similar = find_similar_locators(page_source, failed_val)
            if similar:
                suggestions_display[locator_value] = similar

    # Salva alterações no repositório, se houver
    if updated:
        save_json(REPO_FILE, repo)
        print("✅ Repositório atualizado com novas sugestões.")
    else:
        print("ℹ Nenhuma alteração aplicada ao repositório.")

    # Gera o relatório HTML
    generate_html_report(grouped_failures, suggestions_display, repo_before, repo)

# ========================
# Geração de Relatório
# ========================
def generate_html_report(failures, suggestions_display, before_repo, after_repo):
    changed_rows = [
        (k, before_repo.get(k, []), after_repo.get(k, []))
        for k in set(after_repo) | set(before_repo)
        if before_repo.get(k, []) != after_repo.get(k, [])
    ]
    labels, values = list(failures.keys()), list(failures.values())

    html = f"""
    <html>
    <head>
        <meta charset='utf-8'>
        <title>Locator Analysis Report</title>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
        <script src="https://cdn.datatables.net/1.13.6/js/jquery.dataTables.min.js"></script>
        <script src="https://cdn.datatables.net/buttons/2.4.1/js/dataTables.buttons.min.js"></script>
        <script src="https://cdn.datatables.net/buttons/2.4.1/js/buttons.html5.min.js"></script>
        <link rel="stylesheet" href="https://cdn.datatables.net/1.13.6/css/jquery.dataTables.min.css">
        <link rel="stylesheet" href="https://cdn.datatables.net/buttons/2.4.1/css/buttons.dataTables.min.css">
        <style>
            body {{ font-family: Arial, sans-serif; margin:0; padding:0; }}
            header {{
                background-color: #1f3b57;
                color: white;
                padding: 10px 20px;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }}
            header h1 {{ margin: 0; font-size: 20px; }}
            header .actions button {{
                margin-left: 10px;
                padding: 6px 12px;
                border: none;
                border-radius: 4px;
                cursor: pointer;
            }}
            .container {{ padding: 20px; }}
            .flex-row {{ display: flex; gap: 20px; flex-wrap: wrap; }}
            .flex-col {{ flex: 1; background: #fff; padding: 16px; border-radius: 8px; box-shadow: 0 0 5px rgba(0,0,0,0.1); min-width: 300px; }}
            h2 {{ margin-top: 0; }}
            .empty-msg {{ font-style: italic; color: #888; }}
            body.dark-mode {{ background: #1e1e1e; color: #ddd; }}
            body.dark-mode header {{ background-color: #111; }}
            body.dark-mode .flex-col {{ background: #2a2a2a; }}
        </style>
    </head>
    <body>
        <header>
            <h1>Locator Analysis Report</h1>
            <div class="actions">
                <button id="exportBtn">Exportar</button>
                <button id="themeToggle">🌙 Modo Escuro</button>
            </div>
        </header>
        <div class="container">
            <div class="flex-row">
                <div class="flex-col">
                    <h2>Top Failing Locators</h2>
                    <canvas id="failChart" height="200"></canvas>
                </div>
                <div class="flex-col">
                    <h2>Suggested Locators</h2>
    """
    if suggestions_display:
        html += "<table id='suggestionsTable' class='display'><thead><tr><th>Locator</th><th>Suggestion</th><th>Similarity</th></tr></thead><tbody>"
        for key, sims in suggestions_display.items():
            for cand, score in sims:
                html += f"<tr><td>{key}</td><td>{cand}</td><td>{score*100:.0f}%</td></tr>"
        html += "</tbody></table>"
    else:
        html += "<p class='empty-msg'>Nenhuma sugestão encontrada nesta execução.</p>"
    html += """
                </div>
            </div>
            <div class="flex-col" style="margin-top:20px;">
                <h2>Repository Updates</h2>
    """
    if changed_rows:
        html += "<table id='changesTable' class='display'><thead><tr><th>Locator</th><th>Antes</th><th>Depois</th></tr></thead><tbody>"
        for key, before, after in changed_rows:
            html += f"<tr><td>{key}</td><td>{json.dumps(before, ensure_ascii=False)}</td><td>{json.dumps(after, ensure_ascii=False)}</td></tr>"
        html += "</tbody></table>"
    else:
        html += "<p class='empty-msg'>Nenhuma alteração detectada no repositório.</p>"

    html += f"""
            </div>
        </div>
        <script>
            const body = document.body;
            const toggleBtn = document.getElementById('themeToggle');
            if (localStorage.getItem('theme') === 'dark') {{
                body.classList.add('dark-mode');
                toggleBtn.textContent = '☀️ Modo Claro';
            }}
            toggleBtn.addEventListener('click', () => {{
                body.classList.toggle('dark-mode');
                localStorage.setItem('theme', body.classList.contains('dark-mode') ? 'dark' : 'light');
                toggleBtn.textContent = body.classList.contains('dark-mode') ? '☀️ Modo Claro' : '🌙 Modo Escuro';
            }});

            new Chart(document.getElementById('failChart').getContext('2d'), {{
                type: 'bar',
                data: {{
                    labels: {json.dumps(labels, ensure_ascii=False)},
                    datasets: [{{ label: 'Falhas', data: {json.dumps(values)}, backgroundColor: 'rgba(54, 162, 235, 0.6)' }}]
                }},
                options: {{ responsive: true, plugins: {{ legend: {{ display: false }} }} }}
            }});

            $(function() {{
                $('#suggestionsTable').DataTable({{ dom: 'Bfrtip', buttons: ['copyHtml5','csvHtml5','excelHtml5'] }});
                $('#changesTable').DataTable();
                $('#exportBtn').on('click', function() {{
                    $('.buttons-csv').click();
                }});
            }});
        </script>
    </body>
    </html>
    """

    REPORT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(REPORT_FILE, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"\n📄 Relatório HTML gerado em: {REPORT_FILE}")


if __name__ == "__main__":
    # Captura um page_source padrão para fallback
    if PAGE_SOURCE_FILE.exists():
        default_ps = PAGE_SOURCE_FILE.read_text(encoding="utf-8")
    else:
        default_ps = ""
    suggest_and_update(default_ps)
    print("🔍 Análise concluída.")
