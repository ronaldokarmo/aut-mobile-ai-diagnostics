*** Settings ***
Documentation       Keywords de alto nível específicos para o fluxo do app Itaú.

Library             AppiumLibrary
Library             Collections
Resource            ../resources/keywords.robot


*** Keywords ***
Selecionar Metodo de Login
    [Documentation]    Seleciona o método de login desejado (por CPF ou Agência/Conta), se necessário. Retorna status.
    [Arguments]    ${locator_key}    ${nome_metodo}

    ${locator}=    Evaluate    modules.locator_logger.get_best_locator("${locator_key}")    modules.locator_logger
    ${status}=    Run Keyword And Return Status    Aguardar Elemento Visível Inteligente    ${locator_key}
    IF    not ${status}
        Registrar Falha de Locator Padronizada    Selecionar Metodo de Login    ${locator}    Elemento não visível para obter texto: ${locator_key}
        RETURN    ${FALSE}
    END
    ${metodo_atual}=    Get Text    ${locator}
    Log    Método de login atual: ${metodo_atual}    level=INFO

    IF    "${metodo_atual}" == "${nome_metodo}"
        Log    Já está no método de login desejado: ${nome_metodo}    level=INFO
        RETURN    ${TRUE}
    END

    ${botao_alternar}=    Evaluate    modules.locator_logger.get_best_locator("app_itau_button_metodo_login")    modules.locator_logger
    ${status_botao}=    Run Keyword And Return Status    Aguardar Elemento Visível Inteligente    app_itau_button_metodo_login
    IF    not ${status_botao}
        Registrar Falha de Locator Padronizada    Selecionar Metodo de Login    ${botao_alternar}    Botão para alternar método de login não visível: app_itau_button_metodo_login
        RETURN    ${FALSE}
    END
    Log    Trocando para método de login: ${nome_metodo}
    Clicar Elemento Inteligente    app_itau_button_metodo_login
    ${status_final}=    Run Keyword And Return Status    Wait Until Page Contains    ${nome_metodo}    timeout=${WAIT_SMALL}
    IF    not ${status_final}
        Registrar Falha de Locator Padronizada    Selecionar Metodo de Login    app_itau_button_metodo_login    Método de login '${nome_metodo}' não apareceu após troca
        RETURN    ${FALSE}
    END
    Log    Troca para '${nome_metodo}' realizada com sucesso.    level=INFO
    RETURN    ${TRUE}

Selecionar Ambiente Se Necessario
    [Documentation]    Seleciona um ambiente se não for o que já está selecionado.
    [Arguments]    ${nome_ambiente}    ${evento_clique}=None    ${evento_selecao}=None

    ${texto_atual}=    Get Text Inteligente    app_itau_select_ambiente
    ${texto_atual_stripped}=    Strip String    ${texto_atual}

    IF    "${texto_atual_stripped}" == "${nome_ambiente}"
        Log    Ambiente '${nome_ambiente}' já está selecionado.    level=INFO
        RETURN    ${TRUE}
    END

    Log    Ambiente atual é '${texto_atual_stripped}'. Alterando para '${nome_ambiente}'.    level=INFO
    Clicar Elemento Inteligente    app_itau_select_ambiente    evento=${evento_clique}
    Selecionar Item de Lista Inteligente    ${nome_ambiente}    evento=${evento_selecao}

    Log    Ambiente '${nome_ambiente}' selecionado.    level=INFO
    RETURN    ${TRUE}

Verificar Tela Principal Após Login
    [Documentation]    Verifica se a tela principal foi carregada, tratando pop-ups.
    Tratar Popups Intermediarios

    ${home_visible}=    Elemento Está Visível    main_title_home_bancario
    ${perfil_visible}=    Elemento Está Visível    main_button_perfil_bancario

    IF    ${home_visible} or ${perfil_visible}
        Log    Tela principal confirmada.    level=INFO
        RETURN    ${TRUE}
    END

    Registrar Falha de Locator Padronizada    Verificar Tela Principal    main_title_home_bancario    Tela principal não confirmada.
    RETURN    ${FALSE}

Tratar Popups Intermediarios
    [Documentation]    Trata pop-ups comuns que aparecem após o login.
    FOR    ${i}    IN RANGE    5
        ${popup_tratado}=    Run Keyword And Return Status    Run Keyword If
        ...    '${i}' == '0'    Clicar Elemento Inteligente    login_button_tentar_novamente
        ...    ELSE IF    '${i}' == '1'    Clicar Elemento Inteligente    main_button_nao_habilitar_fido
        ...    ELSE IF    '${i}' == '2'    Clicar Elemento Inteligente    main_button_ativar_localizacao_continuar
        ...    ELSE IF    '${i}' == '3'    Clicar Elemento Inteligente    main_button_ativar_notificaoes_ativar
        ...    ELSE    Pass Execution    Nenhum popup conhecido encontrado.

        IF    ${popup_tratado}
            Log    Popup tratado na iteração ${i}.    level=INFO
            Sleep    2s
        END
    END