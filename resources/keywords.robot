*** Settings ***
Documentation    Keywords for login functionality
Library          AppiumLibrary
Library          JSONLibrary
Library          OperatingSystem
Library          Collections
Library          String
Library          Process

*** Variables ***
${CAPS_FILE}       ${CURDIR}/capabilities.json
${REMOTE_URL}      http://127.0.0.1:4723
${wait-large}      15s
${wait-small}      5s
${STEP_COUNTER}    0


*** Keywords ***
Open my App
    [Documentation]    Abre o aplicativo.
    ${caps}=    Load JSON From File    ${CAPS_FILE}
    Open Application    ${REMOTE_URL}    &{caps}
    Log    Iniciando o testes automatizados

Close my App
    [Documentation]    Fecha o aplicativo.
    Close Application
    Log    Finalizando o testes automatizados

Registrar Falha com Page Source
    [Arguments]    ${locator}
    ${timestamp}=    Get Time    epoch
    ${ps_file}=    Set Variable    logs/page_source_${timestamp}.xml
    Sleep    1s
    ${source}=    Get Source
    Create File    ${ps_file}    ${source}

    # Load existing failures, append new one, and dump back to file
    ${failures_file}=    Set Variable    logs/locator_failures.json
    ${new_failure_entry}=    Create Dictionary    locator=${locator}    page_source_file=${ps_file}

    ${file_exists}=    Run Keyword And Return Status    OperatingSystem.File Should Exist    ${failures_file}

    IF    ${file_exists}
        ${existing_failures}=    Load JSON From File    ${failures_file}
        Append To List    ${existing_failures}    ${new_failure_entry}
        Dump Json To File    ${failures_file}    ${existing_failures}
    ELSE
        Dump Json To File    ${failures_file}    [${new_failure_entry}]
    END

    Log    Falha registrada para locator: ${locator} com page source salvo em ${ps_file}


Get Virtual Keyboard Mapping Intelligence
    [Documentation]    Lê os números nos botões do teclado virtual e cria um mapeamento.
    Wait Until Element Is Visible    id=com.itau:id/btn1    timeout=${wait-large}
    ${button_mapping}=    Create Dictionary
    @{button_ids}=    Create List    com.itau:id/btn0    com.itau:id/btn1    com.itau:id/btn2    com.itau:id/btn3    com.itau:id/btn4    com.itau:id/btn5    com.itau:id/btn6    com.itau:id/btn7    com.itau:id/btn8    com.itau:id/btn9

    FOR    ${button_id}    IN    @{button_ids}
        ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible    id=${button_id}    timeout=${wait-small}
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

Enter Smart Password Intelligence
    [Documentation]    Digita a senha usando o teclado virtual.
    [Arguments]    ${senha}    ${evento}=None
    ${button_mapping}=    Get Virtual Keyboard Mapping Intelligence
    @{senha_digits}=    Split String To Characters    ${senha}
    FOR    ${digit}    IN    @{senha_digits}
        ${button_id}=    Get From Dictionary    ${button_mapping}    ${digit}
        ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${button_id}")    modules.locator_logger
        ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${wait-small}
        Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${locator}", "Botão do dígito ${digit} não visível")    modules.locator_logger
        Run Keyword If    ${status}    Click Element    ${locator}
        Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("${button_id}")    modules.locator_logger
        Run Keyword If    ${status}    Log    Digitou ${digit} com botão ${locator}
    END
    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}

Capture Page Screenshot Steps
    [Documentation]
    [Arguments]    ${evento}
    ${STEP_COUNTER}=    Evaluate    ${STEP_COUNTER} + 1
    ${formatted_step_counter}=    Evaluate    f'{${STEP_COUNTER}:02d}'
    ${filename}=    Set Variable    results/steps/step_${formatted_step_counter}_${evento}.png
    Capture Page Screenshot    ${filename}

Click Element Intelligence
    [Documentation]    Clica em um elemento.
    [Arguments]    ${locator_key}    ${evento}=None
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${wait-small}
    Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${locator}", "Elemento não visível")    modules.locator_logger
    Run Keyword If    ${status}    Element Should Be Enabled    ${locator}
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${status}    Click Element    ${locator}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If    ${status}    Log    Clicou no elemento: ${locator_key}

Input Text Intelligence
    [Documentation]    Preenche um campo de texto.
    [Arguments]    ${locator_key}    ${texto}    ${evento}=None
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${wait-small}
    Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${locator}", "Campo não visível")    modules.locator_logger
    Run Keyword If    ${status}    Click Element    ${locator}
    Run Keyword If    ${status}    Input Text    ${locator}    ${texto}
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If    ${status}    Log    Preencheu o campo: ${locator_key} com valor: ${texto}

Wait Until Element Is Visible Intelligence
    [Documentation]    Espera que um elemento seja visível.
    [Arguments]    ${locator_key}    ${evento}=None
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${wait-small}
    Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${locator}", "Elemento não visível")    modules.locator_logger
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If    ${status}    Log    Elemento visível: ${locator_key}

Verificar Texto na Tela Inteligente
    [Documentation]    Verifica se um texto específico está presente na tela.
    [Arguments]    ${texto_esperado}    ${evento}=None
    ${status}=     Run Keyword And Return Status    Wait Until Page Contains    ${texto_esperado}    timeout=${wait-large}
    Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "texto=${texto_esperado}", "Texto não encontrado na tela")    modules.locator_logger
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("texto=${texto_esperado}")    modules.locator_logger
    Run Keyword If    ${status}    Log    Texto encontrado na tela: ${texto_esperado}

Verificar Estado de Elemento Inteligente
    [Documentation]    Verifica o estado de um elemento (habilitado/desabilitado).
    [Arguments]    ${locator_key}    ${estado_esperado}=enabled    ${evento}=None
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${wait-large}
    Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${locator}", "Elemento não visível para verificação de estado")    modules.locator_logger
    Run Keyword If    ${status}    Run Keyword If    '${estado_esperado}' == 'enabled'    Element Should Be Enabled    ${locator}
    Run Keyword If    ${status}    Run Keyword If    '${estado_esperado}' == 'disabled'    Element Should Be Disabled    ${locator}
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If    ${status}    Log    Estado verificado: ${estado_esperado} para ${locator_key}

Selecionar Item de Lista Inteligente
    [Documentation]    Seleciona um item da lista.
    [Arguments]    ${texto_item}    ${evento}=None
    ${xpath}=    Set Variable    xpath=//android.widget.TextView[@text="${texto_item}"]
    ${status}=   Run Keyword And Return Status    Wait Until Element Is Visible    ${xpath}    timeout=${wait-large}
    Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${xpath}", "Item de lista '${texto_item}' não visível")    modules.locator_logger
    Run Keyword If    ${status}    Click Element    ${xpath}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("texto=${texto_item}")    modules.locator_logger
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${status}    Log    Selecionou item da lista: ${texto_item}

Rolar Até Elemento Inteligente
    [Documentation]    Rolar até um elemento.
    [Arguments]    ${locator_key}    ${evento}=None
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${wait-small}
    Run Keyword If    not ${status}    Scroll To Element    ${locator}
    ${status_final}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${wait-large}
    Run Keyword If    not ${status_final}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${locator}", "Elemento não visível após rolagem")    modules.locator_logger
    Run Keyword If    ${status_final}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${status_final}    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If    ${status_final}    Log    Rolou até o elemento: ${locator_key}

Verificar Mensagem de Erro Inteligente
    [Documentation]    Verifica se uma mensagem de erro está visível.
    [Arguments]    ${mensagem_esperada}    ${evento}=None
    ${xpath}=    Set Variable    xpath=//*[contains(@text, "${mensagem_esperada}")]
    ${status}=   Run Keyword And Return Status    Wait Until Element Is Visible    ${xpath}    timeout=${wait-large}
    Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${xpath}", "Mensagem de erro '${mensagem_esperada}' não visível")    modules.locator_logger
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("mensagem=${mensagem_esperada}")    modules.locator_logger
    Run Keyword If    ${status}    Log    Mensagem de erro visível: ${mensagem_esperada}

Validar Tela com Múltiplos Elementos Inteligente
    [Documentation]    Valida se todos os elementos da tela estão visíveis.
    [Arguments]    @{locator_keys}    ${evento}=None
    ${todos_visiveis}=    Set Variable    ${TRUE}
    FOR    ${locator_key}    IN    @{locator_keys}
        ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
        ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${wait-large}
        Run Keyword If    not ${status}    Set Variable    ${todos_visiveis}    ${FALSE}
        Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${locator}", "Elemento da tela não visível")    modules.locator_logger
        Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
        Run Keyword If    ${status}    Log    Elemento visível: ${locator_key}
    END
    Run Keyword If    ${todos_visiveis}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${todos_visiveis}    Log    Todos os elementos da tela estão visíveis
    Run Keyword If    not ${todos_visiveis}    Fail    Um ou mais elementos da tela não estão visíveis

Validar Ausência de Elemento Inteligente
    [Documentation]    Valida se um elemento não está presente na tela.
    [Arguments]    ${locator_key}    ${evento}=None
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Not Visible    ${locator}    timeout=${wait-large}
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${status}    Log    Elemento ausente como esperado: ${locator_key}
    Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${locator}", "Elemento ainda visível, mas deveria estar ausente")

Verificar Elemento ou Executar Alternativa Inteligente
    [Documentation]    Verifica se um elemento está visível ou executa uma alternativa.
    [Arguments]    ${locator_key}    ${keyword_alternativo}    @{args}
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${wait-large}
    Run Keyword If    ${status}    Log    Elemento visível: ${locator_key}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${locator}", "Elemento não visível, executando alternativa")    modules.locator_logger
    Run Keyword If    not ${status}    Run Keyword    ${keyword_alternativo}    @{args}

Validar Tempo de Carregamento de Tela Inteligente
    [Documentation]    Valida o tempo de carregamento de uma tela.
    [Arguments]    ${locator_key}    ${limite_segundos}=5    ${evento}=None
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${inicio}=     Get Time    epoch
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${wait-large}
    ${fim}=        Get Time    epoch
    ${duracao}=    Evaluate    ${fim} - ${inicio}
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If    ${status}    Log    Tela carregada em ${duracao} segundos: ${locator_key}
    Run Keyword If    ${duracao} > ${limite_segundos}    Log    ⚠️ Tempo de carregamento acima do limite: ${duracao}s > ${limite_segundos}s    level=WARN
    Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${locator}", "Tela não carregada dentro do tempo")    modules.locator_logger
    Run Keyword If    not ${status}    Fail    Tela não carregada: ${locator_key}

Validar Estado Visual de Elemento Inteligente
    [Documentation]    Valida o estado visual de um elemento.
    [Arguments]    ${locator_key}    ${atributo}    ${valor_esperado}    ${evento}=None
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${wait-large}
    Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${locator}", "Elemento não visível para validação visual")    modules.locator_logger
    Run Keyword If    ${status}    ${valor_atual}=    Get Element Attribute    ${locator}    ${atributo}
    Run Keyword If    ${status}    Should Be Equal    ${valor_atual}    ${valor_esperado}
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If    ${status}    Log    Estado visual validado: ${atributo} = ${valor_esperado}

Validar Conteúdo Dinâmico Inteligente
    [Documentation]    Valida o conteúdo dinâmico de um elemento.
    [Arguments]    ${locator_key}    ${conteudo_esperado}    ${evento}=None
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${wait-large}
    Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${locator}", "Elemento não visível para validação de conteúdo")    modules.locator_logger
    Run Keyword If    ${status}    ${conteudo_atual}=    Get Text    ${locator}
    Run Keyword If    ${status}    Should Be Equal    ${conteudo_atual}    ${conteudo_esperado}
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If    ${status}    Log    Conteúdo validado: ${conteudo_atual}

Validar Item em Lista Inteligente
    [Documentation]    Valida se um item específico está presente na lista.
    [Arguments]    ${texto_item}    ${evento}=None
    ${xpath}=    Set Variable    xpath=//android.widget.TextView[contains(@text, "${texto_item}")]
    ${status}=   Run Keyword And Return Status    Wait Until Element Is Visible    ${xpath}    timeout=${wait-large}
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("item_lista=${texto_item}")    modules.locator_logger
    Run Keyword If    ${status}    Log    Item encontrado na lista: ${texto_item}
    Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${xpath}", "Item '${texto_item}' não encontrado na lista")    modules.locator_logger
    Run Keyword If    not ${status}    Fail    Item não encontrado na lista: ${texto_item}

Validar Notificação Inteligente
    [Arguments]    ${mensagem_esperada}    ${evento}=None
    ${xpath}=    Set Variable    xpath=//android.widget.Toast[contains(@text, "${mensagem_esperada}")]
    ${status}=   Run Keyword And Return Status    Wait Until Element Is Visible    ${xpath}    timeout=${wait-large}
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("notificacao=${mensagem_esperada}")    modules.locator_logger
    Run Keyword If    ${status}    Log    Notificação exibida: ${mensagem_esperada}
    Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${xpath}", "Notificação '${mensagem_esperada}' não exibida")    modules.locator_logger
    Run Keyword If    not ${status}    Fail    Notificação não exibida: ${mensagem_esperada}

Validar Comportamento Após Rotação Inteligente
    [Documentation]
    [Arguments]    ${locator_key}    ${orientacao}    ${evento}=None
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    Rotate Screen    ${orientacao}
    Sleep    2s
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${wait-large}
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot Steps    ${evento}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If    ${status}    Log    Elemento visível após rotação (${orientacao}): ${locator_key}
    Run Keyword If    not ${status}    Evaluate    modules.locator_logger.log_failure("Login por Agência", "${locator}", "Elemento não visível após rotação (${orientacao})")    modules.locator_logger
    Run Keyword If    not ${status}    Fail    Elemento não visível após rotação: ${locator_key}

Página Contém Pelo Menos Um Elemento
    [Documentation]    Verifica se pelo menos um dos locators fornecidos está visível na página.
    [Arguments]    @{locator_keys}
    FOR    ${locator_key}    IN    @{locator_keys}
        ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible Intelligence    ${locator_key}
        IF    ${status}    RETURN
    END
    Fail    Nenhum dos elementos esperados foi encontrado: @{locator_keys}

Aguardar Pela Home Tratando Popups
    [Documentation]    Espera a home do app aparecer, tratando pop-ups intermediários.
    [Arguments]    ${timeout}=${wait-large}    ${interval}=${wait-small}
    Wait Until Keyword Succeeds    ${timeout}    ${interval}
    ...    Verificar Tela Home Ou Tratar Popups

Verificar Tela Home Ou Tratar Popups
    [Documentation]    Keyword interna: Passa se a home estiver visível, ou tenta tratar pop-ups. Falha se nenhum estado conhecido for encontrado.
    ${is_home}=    Run Keyword And Return Status    Página Contém Pelo Menos Um Elemento    button_perfil_bancario    tilte_home_bancario
    IF    ${is_home}
        Log    Tela principal (Home) alcançada.
        RETURN  # Sucesso, encerra o loop.
    END

    # Se não está na home, tenta tratar os pop-ups conhecidos
    ${popup_tratado}=    Tratar Pop-up de Biometria
    # Para adicionar um novo pop-up, crie uma keyword "Tratar Pop-up de X" e chame aqui:
    # ${outro_popup}=    Tratar Pop-up de Localizacao
    # ${popup_tratado}=    Evaluate    ${popup_tratado} or ${outro_popup}
    
    # Se um pop-up foi tratado, a keyword passa para o Wait Until... não falhar.
    # Na próxima iteração, o estado da tela será reavaliado.
    Run Keyword If    ${popup_tratado}    Log    Um pop-up foi tratado. Verificando a tela novamente.
    
    # Se não estamos na home E nenhum pop-up foi encontrado/tratado, a keyword deve falhar para forçar uma nova tentativa.
    Run Keyword Unless    ${popup_tratado}    Fail    Tela Home ou pop-ups conhecidos não encontrados. Tentando novamente.

Tratar Pop-up de Biometria
    [Documentation]    Verifica se o pop-up de biometria está visível e o fecha. Retorna ${TRUE} se o pop-up foi tratado.
    ${fido_visible}=    Elemento Está Visível    main_display_habilitar_fido
    IF    ${fido_visible}
        Log    Pop-up de biometria detectado. Clicando em 'Não habilitar'.
        Click Element Intelligence    main_button_nao_habilitar_fido
        Sleep    2s  # Pausa para a UI atualizar após fechar o pop-up.
    END
    RETURN    ${fido_visible}

Get Text Inteligente
    [Documentation]    Obtém o texto de um elemento de forma inteligente.
    [Arguments]    ${locator_key}
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${wait-large}
    IF    not ${status}
        Evaluate    modules.locator_logger.log_failure("Obter Texto", "${locator}", "Elemento não visível para obter texto")    modules.locator_logger
        Fail    Elemento não visível para obter texto: ${locator_key}
    END
    Registrar Falha com Page Source    ${locator}
    ${text}=    Get Text    ${locator}
    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Log    Texto obtido do elemento ${locator_key}: ${text}
    RETURN    ${text}

Selecionar Ambiente Se Necessario
    [Documentation]    Seleciona um ambiente na tela de segregação, apenas se já não estiver selecionado.
    [Arguments]    ${nome_ambiente}    ${evento_clique}=None    ${evento_selecao}=None
    Wait Until Element Is Visible Intelligence    app_itau_select_ambiente
    ${texto_atual}=    Get Text Inteligente    app_itau_select_ambiente
    
    # Remove espaços em branco do início e do fim para uma comparação mais robusta
    ${texto_atual_stripped}=    Strip String    ${texto_atual}
    
    IF    "$texto_atual_stripped" == "$nome_ambiente"
        Log    Ambiente '${nome_ambiente}' já está selecionado. Nenhuma ação necessária.
    ELSE
        Log    Ambiente atual é '${texto_atual_stripped}'. Alterando para '${nome_ambiente}'.
        Click Element Intelligence    app_itau_select_ambiente    ${evento_clique}
        Selecionar Item de Lista Inteligente    ${nome_ambiente}    ${evento_selecao}
        Log    Ambiente '${nome_ambiente}' selecionado.
    END

Elemento Está Visível
    [Documentation]    Verifica se um elemento está visível, retornando um status booleano. Não falha o teste.
    [Arguments]    ${locator_key}    ${timeout}=${wait-small}
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${timeout}
    RETURN    ${status}

Selecionar Metodo de Login
    [Documentation]    Seleciona o método de login desejado (por CPF ou Agência/Conta), se necessário.
    [Arguments]    ${locator_key}    ${nome_metodo}
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${wait-large}
    IF    not ${status}
        Evaluate    modules.locator_logger.log_failure("Obter Texto", "${locator}", "Elemento não visível para obter texto")    modules.locator_logger
        Fail    Elemento não visível para obter texto: ${locator_key}
    END
    ${text}=    Get Text    ${locator}
    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Log    TEXTO: Texto obtido do elemento ${locator_key}: ${text}
    RETURN    ${text}
    ${metodo_desejado}=    Strip String    ${text}

    # Mapeia o método de login para o botão de alternância e texto alternativo
    IF    "$metodo_desejado" == "Entre com agência e conta"
        ${locator_botao_alternar}=    Set Variable    login_button_entrar_com_cpf
        ${texto_alternativo}=    Set Variable    Entre com seu CPF
    ELSE IF    "$metodo_desejado" == "Entre com seu CPF"
        ${locator_botao_alternar}=    Set Variable    login_button_entrar_com_agencia
        ${texto_alternativo}=    Set Variable    Entre com agência e conta
    ELSE
        Fail    Método de login desconhecido: ${metodo_desejado}.
    END

    # O locator do título é o mesmo para ambas as telas, usamos um deles como referência
    ${locator_titulo}=    Set Variable    login_entre_com_agencia

    # Pega o texto do título da tela atual
    Wait Until Element Is Visible Intelligence    ${locator_titulo}
    ${texto_atual_titulo}=    Get Text Inteligente    ${locator_titulo}

    # Compara o texto atual com o desejado e age de acordo
    IF    "$texto_atual_titulo" == "$metodo_desejado"
        Log    Já está na tela de login '${metodo_desejado}'. Nenhuma ação necessária.
        RETURN
    ELSE IF    "$texto_atual_titulo" == "$texto_alternativo"
        Log    Tela alternativa '${texto_alternativo}' encontrada. Trocando para '${metodo_desejado}'.
        Click Element Intelligence    ${locator_botao_alternar}
        Wait Until Page Contains    ${metodo_desejado}    timeout=${wait-large}
        Log    Troca para '${metodo_desejado}' realizada com sucesso.
    ELSE
        Fail    Não foi possível identificar a tela de login. Título encontrado: '${texto_atual_titulo}'.
    END

Simular Instabilidade de Rede
    [Documentation]    Simula uma queda temporária de internet no device Android usando Appium.
    ...                Requer que a sessão Appium esteja aberta.
    Log    🔌 Simulando instabilidade de rede...
    # 0 = Sem rede, 1 = Modo avião, 2 = Somente Wi-Fi, 4 = Somente Dados, 6 = Wi-Fi + Dados
    Set Network Connection    0
    Sleep    5s
    Log    🌐 Restaurando conexão Wi-Fi...
    Set Network Connection    2
    Sleep    2s
    Log    🌐 Conexão restaurada.

Simular Rede Lenta
    [Documentation]    Simula uma rede lenta no device Android usando Appium.
    ...                Requer que a sessão Appium esteja aberta.
    Log    🌐 Simulando rede lenta...
    Set Network Connection    4
    Sleep    5s
    Log    🔌 Restaurando conexão normal...
    Set Network Connection    2
    Sleep    5s
    Log    🌐 Conexão restaurada.

Simular Modo Avião
    [Documentation]    Ativa o modo avião no device Android usando Appium.
    ...                Requer que a sessão Appium esteja aberta.
    Log    ✈️ Ativando modo avião...
    Set Network Connection    1
    Sleep    5s
    Log    🔌 Desativando modo avião...
    Set Network Connection    2
    Sleep    5s
    Log    🌐 Conexão restaurada.

Simular Queda de App
    [Documentation]    Simula uma queda do app fechando-o e reabrindo.
    ...                Requer que a sessão Appium esteja aberta.
    Log    💥 Simulando queda do app...
    Close Application
    Sleep    3s
    Log    🔄 Reabrindo o app...
    ${caps}=    Load JSON From File    ${CAPS_FILE}
    Open Application    ${REMOTE_URL}    &{caps}
    Sleep    5s
    Log    ✅ App reaberto com sucesso.

Simular Rede de Dados
    [Documentation]    Simula uma rede de dados no device Android usando Appium.
    ...                Requer que a sessão Appium esteja aberta.
    Log    📶 Simulando rede de dados...
    Set Network Connection    4
    Sleep    5s
    Log    🔌 Restaurando conexão normal...
    Set Network Connection    2
    Sleep    5s
    Log    🌐 Conexão restaurada.
