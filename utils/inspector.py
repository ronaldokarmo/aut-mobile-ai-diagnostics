"""
Módulo de diagnóstico para verificar a conexão e o estado de um aplicativo em um dispositivo Android via ADB.

Este script executa uma série de comandos ADB para:
- Listar dispositivos conectados.
- Verificar se um pacote de aplicativo específico está instalado.
- Tentar iniciar a atividade principal do aplicativo.
- Verificar os logs em busca de erros recentes.
"""
import subprocess

def run_cmd(cmd):
    """Executa um comando no shell e retorna a saída padrão (stdout).

    Args:
        cmd (str): O comando a ser executado.

    Returns:
        str: A saída do comando (stdout), sem espaços em branco no início ou fim.
    """
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=False)
    return result.stdout.strip()


# --- Diagnósticos ---
PACKAGE_NAME = "com.itau"
ACTIVITY_NAME = "br.com.itau.pf.modules.features.appUse.appStart.splash.view.SplashActivity"

print("🔍 Verificando dispositivo conectado via ADB...")
devices = run_cmd("adb devices")
print(devices)

print("\n📦 Verificando se o pacote está instalado...")
PACKAGE_CHECK_CMD = f"adb shell pm list packages | grep {PACKAGE_NAME}"
package_check = run_cmd(PACKAGE_CHECK_CMD)
print(package_check or f"❌ Pacote {PACKAGE_NAME} não encontrado")

print("\n🚀 Tentando iniciar a activity principal...")
LAUNCH_CMD = f"adb shell am start -n {PACKAGE_NAME}/{ACTIVITY_NAME}"
launch_result = run_cmd(LAUNCH_CMD)
print(launch_result)

print("\n📄 Verificando logs recentes do logcat...")
LOGCAT_PATTERNS = "'error\\|exception\\|crash'"
LOGCAT_CMD = f"adb logcat -d | grep -i {LOGCAT_PATTERNS}"
logcat = run_cmd(LOGCAT_CMD)
print(logcat or "✅ Nenhum erro crítico encontrado")

print("\n✅ Diagnóstico concluído.")
