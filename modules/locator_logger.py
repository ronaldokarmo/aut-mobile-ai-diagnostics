import json
from datetime import datetime
import os

# Caminhos dos arquivos de dados
FAILURE_LOG_PATH = os.path.join("logs", "locator_failures.json")
REPOSITORY_PATH = os.path.join("locators", "locator_repository.json")

def log_failure(test_name, locator, error_message):
    """Registra falha de locator em arquivo JSON."""
    log_entry = {
        "timestamp": datetime.now().isoformat(),
        "test_name": test_name,
        "locator": locator,
        "error": error_message
    }

    if os.path.exists(FAILURE_LOG_PATH):
        with open(FAILURE_LOG_PATH, "r+", encoding="utf-8") as file:
            try:
                data = json.load(file)
            except json.JSONDecodeError:
                data = []
            data.append(log_entry)
            file.seek(0)
            json.dump(data, file, indent=4, ensure_ascii=False)
    else:
        with open(FAILURE_LOG_PATH, "w", encoding="utf-8") as file:
            json.dump([log_entry], file, indent=4, ensure_ascii=False)

def get_best_locator(locator_key):
    """Retorna o melhor locator alternativo baseado no repositório."""
    try:
        with open(REPOSITORY_PATH, "r", encoding="utf-8") as file:
            locators = json.load(file)
        alternatives = locators.get(locator_key, [])
        for alt in alternatives:
            return f"{alt['strategy']}={alt['value']}"
    except Exception as e:
        print(f"Erro ao buscar locator: {e}")
    return locator_key  # fallback

def log_success(locator_key):
    """Registra sucesso de uso de locator (para evolução futura)."""
    try:
        with open(REPOSITORY_PATH, "r+", encoding="utf-8") as file:
            locators = json.load(file)
            alternatives = locators.get(locator_key, [])
            for alt in alternatives:
                alt["success_count"] = alt.get("success_count", 0) + 1
            locators[locator_key] = alternatives
            file.seek(0)
            json.dump(locators, file, indent=4, ensure_ascii=False)
    except Exception as e:
        print(f"Erro ao registrar sucesso: {e}")
