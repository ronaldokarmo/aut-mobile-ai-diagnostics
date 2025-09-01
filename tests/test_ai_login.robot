*** Settings ***
Documentation    Testes de Login com análise automática de locators
Library           AppiumLibrary
Library           Collections
Library           String
Library           Process
Resource          ../resources/keywords.robot
Suite Teardown    Executar Analisador de Locators
Test Setup        Open my App
Test Teardown     Close my App

*** Keywords ***
Executar Analisador de Locators
    Log    Iniciando análise automática de locators...
    Run Process    python    ai_diagnostics/locator_analyzer.py
    Log    Relatório gerado em logs/locator_report.html

*** Variables ***
${AGENCIA}      1500
${CONTA}        592363
${CPF}          12345678909
${SENHA}        12300001


*** Test Cases ***
Scenario: Login por Agência e Conta :: com Sucesso
    [Documentation]    Teste de login com sucesso utilizando agência e conta.
    [Tags]    smoke    login_com_agencia_e_conta

    Wait Until Element Is Visible Intelligence    app_itau_logo
    Registrar Falha com Page Source    app_itau_logo
    Log    Elemento de logo visível

    Selecionar Ambiente Se Necessario    Homologação AWS
    Log    Ambiente selecionado se necessário

    Wait Until Element Is Visible Intelligence    app_itau_button_acesso
    Click Element Intelligence    app_itau_button_acesso
    Log    Clicou no botão de Acesso

    Selecionar Metodo de Login    app_itau_select_metodo_login    Entre com agência e conta
    Verificar Estado de Elemento Inteligente    login_button_continuar    disabled
    Log    Método de login selecionado

    Input Text Intelligence    login_field_agencia    ${AGENCIA}
    Input Text Intelligence    login_field_conta     ${CONTA}
    Log    Preencheu agência e conta
    
    Verificar Estado de Elemento Inteligente    login_button_continuar    enabled
    Click Element Intelligence    login_button_continuar
    Log    Clicou no botão de Continuar

    Wait Until Element Is Visible Intelligence    login_password_field
    Registrar Falha com Page Source    login_password_field
    Log    Navegou para a tela de senha

    Verificar Estado de Elemento Inteligente    login_button_continuar    disabled
    Enter Smart Password Intelligence    ${SENHA}
    Log    Digitou a senha

    Verificar Estado de Elemento Inteligente    login_button_continuar    enabled
    Click Element Intelligence    login_button_continuar
    Log    Clicou no botão de Continuar

    Aguardar Pela Home Tratando Popups
    Registrar Falha com Page Source    main_button_perfil_bancario
    Log    Aguardando pela tela inicial

Scenario: Login por CPF :: com Sucesso
    [Documentation]    Teste de login com sucesso utilizando CPF.
    [Tags]    smoke    login_com_cpf

    Wait Until Element Is Visible Intelligence    app_itau_logo
    Registrar Falha com Page Source    main_button_perfil_bancario
    Log    Elemento de logo visível

    Selecionar Ambiente Se Necessario    app_itau_select_ambiente    Homologação AWS
    Log    Ambiente selecionado se necessário

    Wait Until Element Is Visible Intelligence    login_button_acesso
    Registrar Falha com Page Source    login_button_acesso
    Click Element Intelligence    login_button_acesso
    Log    Clicou no botão de Acesso

    Selecionar Metodo de Login    app_itau_select_metodo_login    Entre com seu CPF
    Verificar Estado de Elemento Inteligente    login_button_continuar    disabled
    Log    Método de login selecionado

    Input Text Intelligence    login_field_cpf    ${CPF}
    Log    Preencheu CPF

    Verificar Estado de Elemento Inteligente    login_button_continuar    enabled
    Click Element Intelligence    login_button_continuar
    Log    Clicou no botão de Continuar

    Wait Until Element Is Visible Intelligence    login_password_field
    Log    Navegou para a tela de senha

    Verificar Estado de Elemento Inteligente    login_button_continuar    disabled
    Enter Smart Password Intelligence    ${SENHA}
    Log    Digitou a senha

    Verificar Estado de Elemento Inteligente    login_button_continuar    enabled
    Click Element Intelligence    login_button_continuar
    Log    Clicou no botão de Continuar

    Aguardar Pela Home Tratando Popups
    Registrar Falha com Page Source    main_button_perfil_bancario
    Log    Aguardando pela tela inicial

Scenario: Login por Agência e Conta :: com Interrompido por Instabilidade
    [Documentation]    Teste de login com instabilidade utilizando agência e conta.
    [Tags]    regressao    login_negativo

    Wait Until Element Is Visible Intelligence    app_itau_logo
    Registrar Falha com Page Source    app_itau_logo
    Log    Elemento de logo visível

    Selecionar Ambiente Se Necessario    Homologação AWS
    Log    Ambiente selecionado se necessário

    Wait Until Element Is Visible Intelligence    app_itau_button_acesso
    Click Element Intelligence    app_itau_button_acesso
    Log    Clicou no botão de Acesso

    Selecionar Metodo de Login    app_itau_select_metodo_login    Entre com agência e conta
    Verificar Estado de Elemento Inteligente    login_button_continuar    disabled
    Log    Método de login selecionado

    Input Text Intelligence    login_field_agencia    ${AGENCIA}
    Input Text Intelligence    login_field_conta     ${CONTA}
    Log    Preencheu agência e conta
    
    Verificar Estado de Elemento Inteligente    login_button_continuar    enabled
    Click Element Intelligence    login_button_continuar
    Log    Clicou no botão de Continuar

    Validar Tela com Múltiplos Elementos Inteligente    login_display_instabilidades
    Log    Verificou mensagem de instabilidade
