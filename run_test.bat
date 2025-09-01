@echo off
setlocal

REM Define o diretório de testes
set TEST_DIR=tests\android

REM Ativa o ambiente virtual
call .\.venv\Scripts\activate

REM Verifica se a ativação foi bem-sucedida
if %errorlevel% neq 0 (
    echo Falha ao ativar o ambiente virtual. Verifique o caminho.
    exit /b 1
)

echo ✅ Ambiente virtual ativado.

echo 🚀 Executando testes do Robot Framework em %TEST_DIR%...

REM Executa o Robot Framework
robot --outputdir results --name "Android Tests" %TEST_DIR%

REM Captura o código de saída do Robot
set ROBOT_EXIT_CODE=%errorlevel%

REM Desativa o ambiente virtual
call .\.venv\Scripts\deactivate

echo ✅ Testes finalizados.

REM Sai com o código de erro do Robot
exit /b %ROBOT_EXIT_CODE%