*** Settings ***
Documentation       Testes de Login com análise automática de locators.

Library             AppiumLibrary
Library             Collections
Library             String
Library             Process

Resource            ../resources/keywords.robot
Resource            ../resources/app_itau.robot

Test Setup          Abrir Meu App
Test Teardown       Fechar Meu App


*** Variables ***
${AGENCIA}          1500
${CONTA}            592363
${CPF}              15350399144
${SENHA}            12300001

*** Keywords ***
Dado que eu esteja na tela de login
    Aguardar Elemento Visível Inteligente    app_itau_logo
    Selecionar Ambiente Se Necessario    Homologação AWS
    Aguardar Elemento Visível Inteligente    app_itau_button_acesso
    Clicar Elemento Inteligente    app_itau_button_acesso

Efetuar login com agencia e conta
    [Arguments]    ${AGENCIA}    ${CONTA}
    Selecionar Metodo de Login    app_itau_select_metodo_login    Entre com agência e conta
    Verificar Estado de Elemento Inteligente    login_button_continuar    disabled
    Preencher Texto Inteligente    login_field_agencia    ${AGENCIA}
    Preencher Texto Inteligente    login_field_conta    ${CONTA}
    Verificar Estado de Elemento Inteligente    login_button_continuar    enabled
    Clicar Elemento Inteligente    login_button_continuar

Efetuar login com CPF
    [Arguments]    ${CPF}
    Selecionar Metodo de Login    app_itau_select_metodo_login    Entre com seu CPF
    Verificar Estado de Elemento Inteligente    login_button_continuar    disabled
    Preencher Texto Inteligente    login_field_cpf    ${CPF}
    Verificar Estado de Elemento Inteligente    login_button_continuar    enabled
    Clicar Elemento Inteligente    login_button_continuar

Digitar a senha virtual
    [Arguments]    ${SENHA}
    Aguardar Elemento Visível Inteligente    login_display_password
    Verificar Estado de Elemento Inteligente    login_button_continuar    disabled
    Digitar Senha Inteligente Virtual    ${SENHA}
    Verificar Estado de Elemento Inteligente    login_button_continuar    enabled
    Clicar Elemento Inteligente    login_button_continuar

Digitar a senha
    [Arguments]    ${SENHA}
    Aguardar Elemento Visível Inteligente    login_display_password
    Verificar Estado de Elemento Inteligente    login_button_continuar    disabled
    Digitar Senha Inteligente    login_password_field_keyword_number    ${SENHA}
    Verificar Estado de Elemento Inteligente    login_button_continuar    enabled
    Clicar Elemento Inteligente    login_button_continuar

E o login seja efetuado com sucesso
    Verificar Tela Principal Após Login

E a tela de instabilidade seja exibida
    Aguardar Elemento Visível Inteligente    login_display_perdemos_conexao
    Verificar Estado de Elemento Inteligente    login_button_tentar_novamente    enabled
    Clicar Elemento Inteligente    login_button_tentar_novamente
    Simular Instabilidade de Rede
    Aguardar Elemento Visível Inteligente    login_display_estamos_instabilidade

*** Test Cases ***
Scenario: Login por Agência e Conta com Sucesso
    [Documentation]    Teste de login com sucesso utilizando agência e conta.
    [Tags]    login_com_agconta

    Dado que eu esteja na tela de login
    Efetuar login com agencia e conta    ${AGENCIA}    ${CONTA}
    Digitar a senha virtual    ${SENHA}
    E o login seja efetuado com sucesso

Scenario: Login por CPF com Sucesso
    [Documentation]    Teste de login com sucesso utilizando CPF.
    [Tags]    login_com_cpf

    Dado que eu esteja na tela de login
    Efetuar login com CPF    ${CPF}
    Digitar a senha    ${SENHA}
    E o login seja efetuado com sucesso

Scenario: Login por Agência e Conta com Instabilidade
    [Documentation]    Teste de login com instabilidade utilizando agência e conta.
    [Tags]    login_instabilidade

    Dado que eu esteja na tela de login
    Efetuar login com agencia e conta    ${AGENCIA}    ${CONTA}
    E a tela de instabilidade seja exibida

Scenario: Login por CPF com Instabilidade
    [Documentation]    Teste de login com instabilidade utilizando CPF.
    [Tags]    login_instabilidade

    Dado que eu esteja na tela de login
    Efetuar login com CPF    ${CPF}
    Digitar a senha    ${SENHA}
    E a tela de instabilidade seja exibida

