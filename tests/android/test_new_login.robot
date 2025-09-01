*** Settings ***
Documentation    Test Case for login functionality
Library    AppiumLibrary
Library    Collections
Library    String

Test Setup     Abrir App
Test Teardown  Fechar App

*** Variables ***
${REMOTE_URL}   http://127.0.0.1:4723
${PLATFORM}     Android
${DEVICE}       moto_g54_5G
${UDID}         ZF524DL8QB
${APP_PACKAGE}  com.itau
# ${APP_ACTIVITY}    br.com.itau.feature.client.hub.main.view.activity.ClientHubActivity
${dontStopAppOnReset}    true
${forceAppLaunch}    true
${AGENCIA}      1500
${CONTA}        592363
${SENHA}        12300001
${wait}        30
${STEP_COUNTER}    1

*** Keywords ***
Abrir App
    Open Application    ${REMOTE_URL}    platformName=${PLATFORM}    automationName=UiAutomator2
    ...    deviceName=${DEVICE}    udid=${UDID}    appPackage=${APP_PACKAGE}
    ...    noReset=true    autoGrantPermissions=true

Fechar App
    Close Application

Obter Mapeamento Teclado Virtual
    [Documentation]    Lê os números nos botões do teclado virtual e cria um mapeamento.
    Wait Until Element Is Visible    id=com.itau:id/btn1    timeout=${wait}
    ${button_mapping}=    Create Dictionary
    @{button_ids}=    Create List    com.itau:id/btn0    com.itau:id/btn1    com.itau:id/btn2    com.itau:id/btn3    com.itau:id/btn4    com.itau:id/btn5    com.itau:id/btn6    com.itau:id/btn7    com.itau:id/btn8    com.itau:id/btn9

    FOR    ${button_id}    IN    @{button_ids}
        ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible    id=${button_id}    timeout=5s
        IF    ${status} == ${TRUE}
            ${button_text}=    Get Text    id=${button_id}
            Log    Button ID: ${button_id}, Button Text: ${button_text}
            ${digits}=    String.Split String    ${button_text}    ou
            FOR    ${digit}    IN    @{digits}
                ${digit}=    Strip String    ${digit}
                Set To Dictionary    ${button_mapping}    ${digit}    ${button_id}
            END
        ELSE
            Log    Button ID: ${button_id} not visible. Skipping.    level=WARN
        END
    END
    RETURN    ${button_mapping}

Digitar Senha No Teclado Virtual
    [Arguments]    ${senha}
    [Documentation]    Digita a senha fornecida usando o teclado virtual.
    ${button_mapping}=    Obter Mapeamento Teclado Virtual
    @{senha_digits}=    Split String To Characters    ${senha}
    FOR    ${digit}    IN    @{senha_digits}
        ${button_id}=    Get From Dictionary    ${button_mapping}    ${digit}
        Click Element    ${button_id}
    END

Capture Page Screenshot Steps
    [Arguments]    ${evento}
    ${STEP_COUNTER}=    Evaluate    ${STEP_COUNTER} + 1
    ${formatted_step_counter}=    Evaluate    f'{${STEP_COUNTER}:02d}'
    ${filename}=    Set Variable    results/steps/step_${formatted_step_counter}_${evento}.png
    Capture Page Screenshot    ${filename}

*** Test Cases ***
Scenario: Login por Agência e Conta :: Login com Sucesso
    [Tags]    smoke    login_positivo
    # launchApp: clearState: true, permissions: all allow
    Log    Iniciando o teste de login por agência e conta
    Wait Until Element Is Visible    id=segregate_image_logo    ${wait}
    Log    Elemento de logo visível
    Wait Until Element Is Visible    id=segregate_config_selector_button    ${wait}
    Click Element    id=segregate_config_selector_button
    Capture Page Screenshot Steps    home_screen_app_varejo
    Log    Clicou no botão de Seleção de Ambiente

    Wait Until Page Contains    Homologação AWS    ${wait}
    Click Element    xpath=//android.widget.TextView[@text="Homologação AWS"]
    # Capture Page Screenshot Steps    selecao_de_ambiente
    Log    Clicou na opção de Homologação AWS

    Wait Until Element Is Visible    id=segregate_access_button    ${wait}
    Click Element    id=segregate_access_button
    Log    Clicou no botão de Acesso
    
    Wait Until Element Is Visible    id=fbl_change_credentials    ${wait}
    ${is_on_agency_account_screen}=    Run Keyword And Return Status    Wait Until Page Contains    Entre com agência e conta    timeout=5s

    Run Keyword If    not ${is_on_agency_account_screen}    Click Element    xpath=//android.widget.TextView[@text="Entrar com agência"]
    Run Keyword If    not ${is_on_agency_account_screen}    Log    Clicou no botão de Entrar com Agência
    Run Keyword If    ${is_on_agency_account_screen}    Log    Já está na tela de login por agência e conta. Não clicou no botão.

    Wait Until Element Is Visible    id=com.itau:id/primary_button
    Element Should Be Disabled       id=com.itau:id/primary_button
    Capture Page Screenshot Steps    btn_continuar_desabilitado
    Log      *** Keywords ***

    Wait Until Element Is Visible    xpath=//android.widget.EditText[@resource-id="com.itau:id/editText" and @text="agência"]    ${wait}
    Click Element    xpath=//android.widget.EditText[@resource-id="com.itau:id/editText" and @text="agência"]
    Input Text       xpath=//android.widget.EditText[@resource-id="com.itau:id/editText" and @text="agência"]    ${AGENCIA}

    Log    Preencheu o campo Agência

    Wait Until Element Is Visible    xpath=//android.widget.EditText[@resource-id="com.itau:id/editText" and @text="conta"]    ${wait}
    Click Element    xpath=//android.widget.EditText[@resource-id="com.itau:id/editText" and @text="conta"]
    Input Text    xpath=//android.widget.EditText[@resource-id="com.itau:id/editText" and @text="conta"]    ${CONTA}
    Log    Preencheu o campo Conta

    Wait Until Element Is Visible    id=com.itau:id/primary_button    ${wait}
    Element Should Be Enabled        id=com.itau:id/primary_button
    Capture Page Screenshot Steps    btn_continuar_habilitado
    Click Element    id=com.itau:id/primary_button
    Log    Clicou no botão Continuar

    Wait Until Element Is Visible    id=login_password_field    ${wait}
    Log    Verificou que a tela de senha foi exibida

    Wait Until Element Is Visible    id=com.itau:id/ids_fbl_primaryButton    ${wait}
    Element Should Be Disabled    id=com.itau:id/ids_fbl_primaryButton
    Log    Verificou que o botão de Acesso à Conta foi exibido

    Digitar Senha No Teclado Virtual    ${SENHA}
    Log    Digitou a senha

    Wait Until Element Is Visible    id=com.itau:id/ids_fbl_primaryButton    ${wait}
    Element Should Be Enabled    id=com.itau:id/ids_fbl_primaryButton
    Click Element    id=com.itau:id/ids_fbl_primaryButton
    Capture Page Screenshot Steps    senha_informada_sucesso
    Log    Clicou no botão de Acesso à Conta


Scenario: Login por Agência e Conta :: Login Interrompido por Instabilidade
    [Tags]    regressao    login_negativo
    # launchApp: clearState: true, permissions: all allow
    Log    Iniciando o teste de login por agência e conta
    Wait Until Element Is Visible    id=segregate_image_logo    ${wait}
    Log    Elemento de logo visível
    Wait Until Element Is Visible    id=segregate_config_selector_button    ${wait}
    Click Element    id=segregate_config_selector_button
    Capture Page Screenshot Steps    home_screen_app_varejo
    Log    Clicou no botão de Seleção de Ambiente

    Wait Until Page Contains    Homologação AWS    ${wait}
    Click Element    xpath=//android.widget.TextView[@text="Homologação AWS"]
    # Capture Page Screenshot Steps    selecao_de_ambiente
    Log    Clicou na opção de Homologação AWS

    Wait Until Element Is Visible    id=segregate_access_button    ${wait}
    Click Element    id=segregate_access_button
    Log    Clicou no botão de Acesso
    
    Wait Until Element Is Visible    id=fbl_change_credentials    ${wait}
    ${is_on_agency_account_screen}=    Run Keyword And Return Status    Wait Until Page Contains    Entre com agência e conta    timeout=5s

    Run Keyword If    not ${is_on_agency_account_screen}    Click Element    xpath=//android.widget.TextView[@text="Entrar com agência"]
    Run Keyword If    not ${is_on_agency_account_screen}    Log    Clicou no botão de Entrar com Agência
    Run Keyword If    ${is_on_agency_account_screen}    Log    Já está na tela de login por agência e conta. Não clicou no botão.

    Wait Until Element Is Visible    id=com.itau:id/primary_button
    Element Should Be Disabled       id=com.itau:id/primary_button
    Capture Page Screenshot Steps    btn_continuar_desabilitado
    Log      *** Keywords ***

    Wait Until Element Is Visible    xpath=//android.widget.EditText[@resource-id="com.itau:id/editText" and @text="agência"]    ${wait}
    Click Element    xpath=//android.widget.EditText[@resource-id="com.itau:id/editText" and @text="agência"]
    Input Text       xpath=//android.widget.EditText[@resource-id="com.itau:id/editText" and @text="agência"]    ${AGENCIA}
    Log    Preencheu o campo Agência

    Wait Until Element Is Visible    xpath=//android.widget.EditText[@resource-id="com.itau:id/editText" and @text="conta"]    ${wait}
    Click Element    xpath=//android.widget.EditText[@resource-id="com.itau:id/editText" and @text="conta"]
    Input Text    xpath=//android.widget.EditText[@resource-id="com.itau:id/editText" and @text="conta"]    ${CONTA}
    Log    Preencheu o campo Conta

    Wait Until Element Is Visible    id=com.itau:id/primary_button    ${wait}
    Element Should Be Enabled        id=com.itau:id/primary_button
    Capture Page Screenshot Steps    btn_continuar_habilitado
    Click Element    id=com.itau:id/primary_button
    Log    Clicou no botão Continuar

    Wait Until Element Is Visible    xpath=//*[contains(@text, 'Estamos com instabilidades. Tente entrar novamente')]    ${wait}
    Element Should Be Enabled        xpath=//*[contains(@text, 'Estamos com instabilidades. Tente entrar novamente')]
    Capture Page Screenshot Steps    msg_instabilidade
    Log    Verificou a mensagem de instabilidade

