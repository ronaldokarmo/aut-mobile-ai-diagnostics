*** Settings ***
Documentation       Keywords personalizados para automação do app Itaú.

Library             AppiumLibrary
Library             JSONLibrary
Library             OperatingSystem
Library             Collections
Library             String
Library             Process
Library             DateTime

*** Variables ***
${CAPS_FILE}        ${CURDIR}/capabilities.json
${REMOTE_URL}       http://127.0.0.1:4723
${WAIT_LARGE}       30s
${WAIT_SMALL}       8s


*** Keywords ***
Abrir Meu App
    [Documentation]    Abre o aplicativo, maximiza a janela e define as esperas implícitas.
    ${caps}    Load JSON From File    ${CAPS_FILE}
    Open Application    ${REMOTE_URL}    &{caps}
    Log    Iniciando o testes automatizados    level=INFO

Fechar Meu App
    [Documentation]    Fecha o aplicativo.
    Close Application
    Log    Finalizando o testes automatizados    level=INFO

Registrar Falha de Locator Padronizada
    [Documentation]    Registra uma falha de locator em um arquivo JSON e retorna status.
    [Arguments]    ${test_name}    ${locator}    ${error_message}
    ${timestamp}=    Get Time    epoch
    ${ps_file}=    Set Variable    logs/page_source_${timestamp}.xml
    ${source}=    Get Source
    Create File    ${ps_file}    ${source}
    ${timestamp_iso}=    Convert Date    ${timestamp}    result_format=%Y-%m-%dT%H:%M:%S
    ${entry}=    Create Dictionary
    ...    timestamp=${timestamp_iso}
    ...    test_name=${test_name}
    ...    locator=${locator}
    ...    error=${error_message}
    ...    page_source_file=${ps_file}

    ${failures}=    Create List
    ${file_exists}=    Run Keyword And Return Status    File Should Exist    logs/locator_failures.json
    IF    ${file_exists}
        ${content}=    Get File    logs/locator_failures.json
        IF    $content != ''
            ${status_and_json}=    Run Keyword And Ignore Error    Load JSON From File    logs/locator_failures.json
            IF    '${status_and_json[0]}' == 'PASS'
                ${failures}=    Set Variable    ${status_and_json[1]}
            END
        END
    END

    Append To List    ${failures}    ${entry}
    ${json_str}=    Evaluate    json.dumps(${failures}, ensure_ascii=False, indent=4)    json
    Create File    logs/locator_failures.json    ${json_str}
    Log    Falha registrada: ${error_message} | Teste: ${test_name} | Locator: ${locator} | PageSource: ${ps_file}    level=WARN
    RETURN    ${FALSE}

Mapeamento Inteligente do Teclado Virtual
    [Documentation]    Lê os números nos botões do teclado virtual e cria um mapeamento.
    Wait Until Element Is Visible    id=com.itau:id/btn1    timeout=${WAIT_LARGE}
    ${button_mapping}=    Create Dictionary
    @{button_ids}=    Create List    com.itau:id/btn0    com.itau:id/btn1    com.itau:id/btn2    com.itau:id/btn3    com.itau:id/btn4    com.itau:id/btn5    com.itau:id/btn6    com.itau:id/btn7    com.itau:id/btn8    com.itau:id/btn9

    FOR    ${button_id}    IN    @{button_ids}
    ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible    id=${button_id}    timeout=${WAIT_SMALL}
    IF    ${status} == ${TRUE}
        ${button_text}=    Get Text    id=${button_id}
        Log    Button ID: ${button_id}, Button Text: ${button_text} level=INFO
        ${digits}=    String.Split String    ${button_text} ou
        FOR    ${digit}    IN    @{digits}
            ${digit}=    Strip String    ${digit}
            Set To Dictionary    ${button_mapping}    ${digit}    ${button_id}
        END
        ELSE
            Log    Button ID: ${button_id} não visível. Pulando.    level=INFO
        END
    END
    RETURN    ${button_mapping}

Digitar Senha Inteligente Virtual
    [Documentation]    Digita a senha usando o teclado virtual, retorna status geral.
    [Arguments]    ${senha}    ${evento}=None
    ${button_mapping}=    Mapeamento Inteligente do Teclado Virtual
    @{senha_digits}=    Split String To Characters    ${senha}
    ${sucesso}=    Set Variable    ${TRUE}
    FOR    ${digit}    IN    @{senha_digits}
        ${button_id}=    Get From Dictionary    ${button_mapping}    ${digit}
        ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${button_id}")    modules.locator_logger
        ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${WAIT_SMALL}
        IF    not ${status}
            Registrar Falha de Locator Padronizada    Digitar Senha Inteligente Virtual    ${locator}    Botão do dígito ${digit} não visível
            Set Variable    ${sucesso}    ${FALSE}
        ELSE
            Click Element    ${locator}
            Evaluate    modules.locator_logger.log_success("${button_id}")    modules.locator_logger
            Log    Digitou ${digit} com botão ${locator}    level=INFO
        END
    END
    Run Keyword If    ${evento} Capture Page Screenshot    ${evento}
    RETURN    ${sucesso}

Digitar Senha Inteligente
    [Documentation]    Digita a senha em campo único, retorna status.
    [Arguments]    ${locator_key}    ${texto}    ${evento}=None
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${WAIT_SMALL}
    IF    not ${status}
        Registrar Falha de Locator Padronizada    Digitar Senha Inteligente    ${locator}    Campo não visível
        RETURN    ${FALSE}
    END
    Click Element    ${locator}
    Input Text    ${locator}    ${texto}
    Run Keyword If    ${evento}    Capture Page Screenshot    ${evento}
    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Log    Preencheu o campo: ${locator_key} com valor: ${texto}    level=INFO
    RETURN    ${TRUE}

Clicar Elemento Inteligente
    [Documentation]     Clica em um elemento, retorna status.
    [Arguments]     ${locator_key}     ${evento}=None
    ${locator}=     Evaluate     modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status     Wait Until Element Is Visible     ${locator}     timeout=${WAIT_SMALL}
    IF     not ${status}
        Registrar Falha de Locator Padronizada     Clicar Elemento Inteligente     ${locator}     Elemento não visível
        RETURN     ${FALSE}
    END
    Element Should Be Enabled     ${locator}
    Run Keyword If     ${evento}     Capture Page Screenshot     ${evento}
    Click Element     ${locator}
    Evaluate     modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Log     Clicou no elemento:${locator_key}     level=INFO
    RETURN     ${TRUE}

Preencher Texto Inteligente
    [Documentation]     Preenche um campo de texto de forma robusta e registra sucesso ou falha.
    [Arguments]     ${locator_key}     ${texto}     ${evento}=None
    ${locator}=     Evaluate     modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status     Wait Until Element Is Visible    ${locator}     timeout=${WAIT_SMALL}
    IF  not ${status}
        Registrar Falha de Locator Padronizada     Preencher Texto Inteligente     ${locator}     Campo não visível
        RETURN     ${FALSE}
    END
    Click Element     ${locator}
    Input Text     ${locator}     ${texto}
    Run Keyword If     ${evento}     Capture Page Screenshot     ${evento}
    Evaluate     modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Log     Preencheu o campo: ${locator_key} com valor: ${texto}    level=INFO
    RETURN     ${TRUE}

Aguardar Elemento Visível Inteligente
    [Documentation]     Espera que um elemento seja visível e retorna status booleano.
    [Arguments]     ${locator_key}     ${evento}=None
    ${locator}=     Evaluate     modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${WAIT_LARGE}
    IF     not ${status}
        Registrar Falha de Locator Padronizada     Aguardar Elemento Visível Inteligente     ${locator}     Elemento não visível
        RETURN     ${FALSE}
    END
    Run Keyword If     ${evento}     Capture Page Screenshot     ${evento}
    Evaluate     modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Log     Elemento visível: ${locator_key}     level=INFO
    RETURN     ${TRUE}

Verificar Texto na Tela Inteligente
    [Documentation]     Verifica se um texto específico está presente na tela, retorna status.
    [Arguments]     ${texto_esperado}     ${evento}=None
    ${status}=     Run Keyword And Return Status     Wait Until Page Contains ${texto_esperado}     timeout=${WAIT_LARGE}
    IF     not ${status}
        Registrar Falha de Locator Padronizada     Verificar Texto na Tela Inteligente    texto=${texto_esperado}     Texto não encontrado na tela
        RETURN     ${FALSE}
    END
    Run Keyword If     ${evento}     Capture Page Screenshot ${evento}
    Evaluate     modules.locator_logger.log_success("texto=${texto_esperado}")    modules.locator_logger
    Log     Texto encontrado na tela: ${texto_esperado}     level=INFO
    RETURN     ${TRUE}

Verificar Estado de Elemento Inteligente
    [Documentation]     Verifica o estado de um elemento (habilitado/desabilitado).
    [Arguments]     ${locator_key}     ${estado_esperado}=enabled     ${evento}=None
    ${locator}=     Evaluate     modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status     Wait Until Element Is Visible     ${locator}     timeout=${WAIT_LARGE}
    IF     not ${status}
        Registrar Falha de Locator Padronizada     Verificar Estado de Elemento Inteligente     ${locator}     Elemento não visível para verificação de estado
    END
    Run Keyword If     ${status}     Run Keyword If     '${estado_esperado}' == 'enabled'    Element Should Be Enabled     ${locator}
    Run Keyword If     ${status}     Run Keyword If     '${estado_esperado}' == 'disabled'    Element Should Be Disabled     ${locator}
    Run Keyword If     ${status}     Run Keyword If     ${evento}     Capture Page Screenshot     ${evento}
    Run Keyword If     ${status}     Evaluate     modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If     ${status}     Log    Estado verificado: ${estado_esperado} para ${locator_key}     level=INFO

Selecionar Item de Lista Inteligente
    [Documentation]     Seleciona um item da lista.
    [Arguments]     ${texto_item}     ${evento}=None
    ${xpath}=     Set Variable     xpath=//android.widget.TextView[@text="${texto_item}"]
    ${status}=     Run Keyword And Return Status     Wait Until Element Is Visible     ${xpath}     timeout=${WAIT_LARGE}
    IF     not ${status}
        Registrar Falha de Locator Padronizada     Selecionar Item de Lista Inteligente     ${xpath}    Item de lista '${texto_item}' não visível
    END
    Run Keyword If     ${status}     Click Element     ${xpath}
    Run Keyword If     ${status}     Evaluate     modules.locator_logger.log_success("texto=${texto_item}")    modules.locator_logger
    Run Keyword If     ${status}     Run Keyword If     ${evento}     Capture Page Screenshot     ${evento}
    Run Keyword If     ${status}     Log     Selecionou item da lista: ${texto_item} level=INFO

Rolar Até Elemento Inteligente
    [Documentation]     Rolar até um elemento.
    [Arguments]     ${locator_key}     ${evento}=None
    ${locator}=     Evaluate     modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status     Wait Until Element Is Visible     ${locator}     timeout=${WAIT_SMALL}
    Run Keyword If     not ${status}    Scroll Element Into View     ${locator}
    ${status_final}=     Run Keyword And Return Status     Wait Until Element Is Visible     ${locator}     timeout=${WAIT_LARGE}
    IF     not ${status_final}
        Registrar Falha de Locator Padronizada     Rolar Até Elemento Inteligente     ${locator}     Elemento não visível após rolagem
    END
    Run Keyword If     ${status_final} Run Keyword If     ${evento}     Capture Page Screenshot     ${evento}
    Run Keyword If     ${status_final} Evaluate     modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If     ${status_final} Log     Rolou até o elemento: ${locator_key}     level=INFO

Verificar Mensagem de Erro Inteligente
    [Documentation]     Verifica se uma mensagem de erro está visível.
    [Arguments]     ${mensagem_esperada}     ${evento}=None
    ${xpath}=     Set Variable     xpath=//*[contains(@text, "${mensagem_esperada}")]
    ${status}=     Run Keyword And Return Status     Wait Until Element Is Visible     ${xpath}     timeout=${WAIT_LARGE}
    IF     not ${status}
        Registrar Falha de Locator Padronizada     Verificar Mensagem de Erro Inteligente     ${xpath}    Mensagem de erro '${mensagem_esperada}' não visível
    END
    Run Keyword If     ${status}     Run Keyword If     ${evento}     Capture Page Screenshot     ${evento}
    Run Keyword If     ${status}     Evaluate     modules.locator_logger.log_success("mensagem=${mensagem_esperada}")    modules.locator_logger
    Run Keyword If     ${status}    Log     Mensagem de erro visível: ${mensagem_esperada}     level=INFO

Validar Tela com Múltiplos Elementos Inteligente
    [Documentation]     Valida se todos os elementos da tela estão visíveis.
    [Arguments]     @{locator_keys}     ${evento}=None
    ${todos_visiveis}=     Set Variable     ${TRUE}
    FOR     ${locator_key}     IN     @{locator_keys}
    ${locator}=     Evaluate     modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status     Wait Until Element Is Visible     ${locator}     timeout=${WAIT_LARGE}
    Run Keyword If     not ${status}     Set Variable     ${todos_visiveis}     ${FALSE}
    IF     not ${status}
        Registrar Falha de Locator Padronizada     Validar Tela com Múltiplos Elementos Inteligente     ${locator}     Elemento da tela não visível
    END
    Run Keyword If     ${status} Evaluate     modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If     ${status} Log     Elemento visível: ${locator_key}     level=INFO
    END
    Run Keyword If     ${todos_visiveis}    Run Keyword If     ${evento} Capture Page Screenshot     ${evento}
    Run Keyword If     ${todos_visiveis}    Log     Todos os elementos da tela estão visíveis     level=INFO
    Run Keyword If     not ${todos_visiveis}     Fail     Um ou mais elementos da tela não estão visíveis

Validar Ausência de Elemento Inteligente
    [Documentation]     Valida se um elemento não está presente na tela.
    [Arguments]     ${locator_key}     ${evento}=None
    ${locator}=     Evaluate     modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status     Wait Until Element Is Visible     ${locator}     timeout=${WAIT_LARGE}
    Run Keyword If     ${status} Run Keyword If     ${evento}     Capture Page Screenshot     ${evento}
    Run Keyword If     ${status} Log    Elemento ausente como esperado: ${locator_key}     level=INFO
    IF     not ${status}
        Registrar Falha de Locator Padronizada     Validar Ausência de Elemento Inteligente     ${locator}     Elemento ainda visível, mas deveria estar ausente
    END

Verificar Elemento ou Executar Alternativa Inteligente
    [Documentation]    Verifica se um elemento está visível ou executa uma alternativa.
    [Arguments]    ${locator_key}    ${keyword_alternativo}    @{args}
    ${locator}=     Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible     ${locator}    timeout=${WAIT_LARGE}
    Run Keyword If     ${status} Log    Elemento visível: ${locator_key} level=INFO
    Run Keyword If     ${status} Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    IF     not ${status}
        Registrar Falha de Locator Padronizada    Verificar Elemento ou Executar Alternativa Inteligente     ${locator}    Elemento não visível, executando alternativa
    END
    Run Keyword If     not ${status}    Run Keyword    ${keyword_alternativo}    @{args}

Validar Tempo de Carregamento de Tela Inteligente
    [Documentation]    Valida o tempo de carregamento de uma tela.
    [Arguments]    ${locator_key}    ${limite_segundos}=5    ${evento}=None
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${inicio}=    Get Time    epoch
    ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${WAIT_LARGE}
    ${fim}=     Get Time    epoch
    ${duracao}=     Evaluate    ${fim} - ${inicio}
    Run Keyword If     ${status} Run Keyword If     ${evento}     Capture Page Screenshot     ${evento}
    Run Keyword If     ${status} Evaluate     modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If     ${status} Log     Tela carregada em ${duracao} segundos: ${locator_key}     level=INFO
    Run Keyword If     ${duracao} > ${limite_segundos} Log     ⚠️ Tempo de carregamento acima do limite: ${duracao}s > ${limite_segundos}s level=WARN
    IF    not ${status}
        Registrar Falha de Locator Padronizada    Validar Tempo de Carregamento de Tela Inteligente    ${locator}    Tela não carregada dentro do tempo
        Fail    Tela não carregada:    ${locator_key}
    END

Validar Estado Visual de Elemento Inteligente
    [Documentation]    Valida o estado visual de um elemento.
    [Arguments]    ${locator_key}    ${atributo}    ${valor_esperado}    ${evento}=None
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=     Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${WAIT_LARGE}
    IF    not ${status}
        Registrar Falha de Locator Padronizada    Validar Estado Visual de Elemento Inteligente    ${locator}    Elemento não visível para validação visual
    END
    IF     ${status}
        ${valor_atual}=    Get Element Attribute    ${locator}    ${atributo}
        Should Be Equal    ${valor_atual}    ${valor_esperado}
        END
    Run Keyword If     ${status} Run Keyword If    ${evento}    Capture Page Screenshot    ${evento}
    Run Keyword If     ${status} Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If     ${status} Log    Estado visual validado: ${atributo} = ${valor_esperado} level=INFO

Validar Conteúdo Dinâmico Inteligente
    [Documentation]    Valida o conteúdo dinâmico de um elemento.
    [Arguments]    ${locator_key}    ${conteudo_esperado}    ${evento}=None
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${WAIT_LARGE}
    IF    not ${status}
        Registrar Falha de Locator Padronizada    Validar Conteúdo Dinâmico Inteligente     ${locator}    Elemento não visível para validação de conteúdo
    END
        IF    ${status}
        ${conteudo_atual}=    Get Text    ${locator}
        Should Be Equal    ${conteudo_atual}    ${conteudo_esperado}
    END
    Run Keyword If     ${status}    Run Keyword If    ${evento}    Capture Page Screenshot    ${evento}
    Run Keyword If     ${status}    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If     ${status}    Log    Conteúdo validado: ${conteudo_atual} level=INFO

Validar Item em Lista Inteligente
    [Documentation]    Valida se um item específico está presente na lista.
    [Arguments]    ${texto_item}    ${evento}=None
    ${xpath}=    Set Variable    xpath=//android.widget.TextView[contains(@text, "${texto_item}")]
    ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${xpath} timeout=${WAIT_LARGE}
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot    ${evento}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("item_lista=${texto_item}")    modules.locator_logger
    Run Keyword If    ${status}    Log    Item encontrado na lista: ${texto_item} level=INFO
    IF    not ${status}
        Registrar Falha de Locator Padronizada    Validar Item em Lista Inteligente    ${xpath}    Item '${texto_item}' não encontrado na lista
        Fail    Item não encontrado na lista: ${texto_item}
    END

Validar Notificação Inteligente
    [Documentation]    Valida se uma notificação específica está presente na tela.
    [Arguments]    ${mensagem_esperada}    ${evento}=None
    ${xpath}=    Set Variable    xpath=//android.widget.Toast[contains(@text, "${mensagem_esperada}")]
    ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${xpath} timeout=${WAIT_LARGE}
    Run Keyword If    ${status}    Run Keyword If    ${evento}    Capture Page Screenshot    ${evento}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("notificacao=${mensagem_esperada}")    modules.locator_logger
    Run Keyword If    ${status}    Log    Notificação exibida: ${mensagem_esperada} level=INFO
    IF    not ${status}
        Registrar Falha de Locator Padronizada    Validar Notificação Inteligente    ${xpath}    Notificação '${mensagem_esperada}' não exibida
        Fail    Notificação não exibida: ${mensagem_esperada}
    END

Validar Comportamento Após Rotação Inteligente
    [Documentation]    Valida se um elemento está visível após a rotação da tela.
    [Arguments]    ${locator_key}    ${orientacao}    ${evento}=None
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    Set Orientation    ${orientacao}
    Sleep    2s
    ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${locator} timeout=${WAIT_LARGE}
    Run Keyword If    ${status}    Run Keyword If    ${evento} Capture Page Screenshot ${evento}
    Run Keyword If    ${status}    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Run Keyword If    ${status}    Log    Elemento visível após rotação (${orientacao}): ${locator_key} level=INFO
    IF    not ${status}
        Registrar Falha de Locator Padronizada    Validar Comportamento Após Rotação Inteligente    ${locator}    Elemento não visível após rotação (${orientacao})
        Fail    Elemento não visível após rotação: ${locator_key}
    END

Página Contém Pelo Menos Um Elemento
    [Documentation]    Verifica se pelo menos um dos locators fornecidos está visível na página.
    [Arguments]    @{locator_keys}
    FOR    ${locator_key}    IN    @{locator_keys}
        ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible ${locator_key}
            IF    ${status}    RETURN
    END
    Fail    Nenhum dos elementos esperados foi encontrado: @{locator_keys}

Get Text Inteligente
    [Documentation]    Obtém o texto de um elemento de forma inteligente.
    [Arguments]    ${locator_key}
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    timeout=${WAIT_LARGE}
    IF    not ${status}
        Registrar Falha de Locator Padronizada    Get Text Inteligente    ${locator}    Elemento não visível para obter texto
        Fail    Elemento não visível para obter texto: ${locator_key}
    END
    ${text}=    Get Text    ${locator}
    Evaluate    modules.locator_logger.log_success("${locator_key}")    modules.locator_logger
    Log    Texto obtido do elemento ${locator_key}: ${text} level=INFO
    RETURN    ${text}

Elemento Está Visível
    [Documentation]    Verifica se um elemento está visível, retornando um status booleano. Não falha o teste.
    [Arguments]    ${locator_key}    ${timeout}=${WAIT_SMALL}
    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${locator} timeout=${timeout}
    RETURN    ${status}

Simular Instabilidade de Rede
    [Documentation]    Simula uma queda temporária de rede no Android.
    # Status 0: Sem conexão, 1: Modo avião, 2: Wi-Fi, 4: Dados móveis ativados
    # 6: Wi-Fi e Dados móveis ativados
    Log    🔌 Simulando instabilidade de rede...    level=INFO
    Set Network Connection Status    0
    Sleep    2s
    Log    🌐 Restaurando conexão Wi-Fi...    level=INFO
    Set Network Connection Status    2
    Sleep    5s
    Log    🌐 Conexão restaurada.    level=INFO

Simular Rede Lenta
    [Documentation]    Simula uma rede lenta no Android.
    Log    🌐 Simulando rede lenta...    level=INFO
    Set Network Connection Status    4
    Sleep    5s
    Log    🔌 Restaurando conexão normal...    level=INFO
    Set Network Connection Status    2
    Sleep    5s
    Log    🌐 Conexão restaurada.    level=INFO

Simular Modo Avião
    [Documentation]    Ativa o modo avião no Android.
    Log    ✈️ Ativando modo avião...    level=INFO
    Set Network Connection Status    1
    Sleep    5s
    Log    🌐 Modo avião ativado.    level=INFO
    Log    🔌 Desativando modo avião...    level=INFO
    Set Network Connection Status    2
    Sleep    5s
    Log    🌐 Modo avião desativado.    level=INFO

Simular Rede de Dados Móvel
    [Documentation]    Simula uma rede de dados no Android.
    Log    🌐 Simulando rede de dados...    level=INFO
    Set Network Connection Status    4
    Sleep    5s
    Log    🌐 Conexão restaurada.    level=INFO
    Log    🔌 Restaurando conexão Wi-Fi...    level=INFO
    Set Network Connection Status    2
    Sleep    5s
    Log    🌐 Conexão restaurada.    level=INFO

Set Orientation
    [Documentation]    Define a orientação da tela.
    [Arguments]    ${orientacao}
    Set Orientation    ${orientacao}
    Sleep    2s
    Log    Orientação da tela definida para: ${orientacao}    level=INFO
