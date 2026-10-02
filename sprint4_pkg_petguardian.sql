-- ====================================================================
-- CHALLENGE CLYVO 2026 — SPRINT 4
-- DISCIPLINA: Mastering Relational and Non-Relational Database
-- REQUISITO 2: Empacotamento dos Processos (Packages) no Oracle PL/SQL
-- TURMA: 2TDSPG
-- INTEGRANTES:
--   1. Enzo Okuizumi        - RM: 561432
--   2. Gustavo Okada        - RM: 563428
--   3. Lucas Barros Gouveia - RM: 566422
--   4. Luna de Carvalho     - RM: 562290
--   5. Milton Marcelino     - RM: 564836
-- ====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

-- ====================================================================
-- PARTE 1: ESPECIFICAÇÃO DO PACOTE (PACKAGE SPECIFICATION)
-- Declaração das assinaturas públicas, tipos e exceções
-- ====================================================================
CREATE OR REPLACE PACKAGE pkg_petguardian AS

    -- Exceções públicas do pacote com códigos ORA padronizados
    e_id_invalido            EXCEPTION;
    e_dados_incompletos      EXCEPTION;
    e_json_excedente         EXCEPTION;
    e_status_inexistente     EXCEPTION;
    e_sem_registros          EXCEPTION;
    e_pontos_invalido        EXCEPTION;
    e_sem_fatos_cadastrados  EXCEPTION;

    -- Função 1: Serialização manual de tarefa individual em JSON
    FUNCTION fn_tarefa_json (
        p_id_tarefa     IN NUMBER,
        p_titulo        IN VARCHAR2,
        p_pontos        IN NUMBER,
        p_descricao     IN VARCHAR2,
        p_nome_pet      IN VARCHAR2,
        p_nome_status   IN VARCHAR2,
        p_nome_usuario  IN VARCHAR2
    ) RETURN VARCHAR2;

    -- Procedimento 1: Lista tarefas no console via DBMS_OUTPUT
    PROCEDURE pr_listar_tarefas_json (
        p_status_id IN NUMBER DEFAULT NULL
    );

    -- Procedimento 1 (Extensão): Retorna JSON de tarefas via parâmetro OUT CLOB para consumo Java
    PROCEDURE pr_exportar_tarefas_json (
        p_status_id    IN NUMBER DEFAULT NULL,
        p_json_output  OUT CLOB
    );

    -- Função 2: Regra de negócio de gamificação para classificação de pontuação
    FUNCTION fn_classificar_pontos (
        p_pontos IN NUMBER
    ) RETURN VARCHAR2;

    -- Procedimento 2: Relatório analítico tabular com quebra de grupo e subtotais manuais
    PROCEDURE pr_resumo_pontos_tarefas;

END pkg_petguardian;
/

-- ====================================================================
-- PARTE 2: CORPO DO PACOTE (PACKAGE BODY)
-- Implementação concreta das rotinas com tratamento de exceções
-- ====================================================================
CREATE OR REPLACE PACKAGE BODY pkg_petguardian AS

    -- ----------------------------------------------------------------
    -- FUNÇÃO 1: fn_tarefa_json
    -- Serialização determinística manual sem funções built-in
    -- ----------------------------------------------------------------
    FUNCTION fn_tarefa_json (
        p_id_tarefa     IN NUMBER,
        p_titulo        IN VARCHAR2,
        p_pontos        IN NUMBER,
        p_descricao     IN VARCHAR2,
        p_nome_pet      IN VARCHAR2,
        p_nome_status   IN VARCHAR2,
        p_nome_usuario  IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_json VARCHAR2(4000);
    BEGIN
        IF p_id_tarefa IS NULL OR p_id_tarefa <= 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'ID da tarefa fornecido é nulo ou inválido.');
        END IF;

        IF p_titulo IS NULL OR p_nome_pet IS NULL OR p_nome_status IS NULL OR p_nome_usuario IS NULL THEN
            RAISE_APPLICATION_ERROR(-20002, 'Atributos relacionais obrigatórios da tarefa não podem ser nulos.');
        END IF;

        v_json := '{' ||
                  '"id_tarefa":' || p_id_tarefa || ',' ||
                  '"titulo":"' || REPLACE(REPLACE(p_titulo, '\', '\\'), '"', '\"') || '",' ||
                  '"pontos":' || NVL(p_pontos, 0) || ',' ||
                  '"descricao":"' || REPLACE(REPLACE(NVL(p_descricao, ''), '\', '\\'), '"', '\"') || '",' ||
                  '"pet":"' || REPLACE(REPLACE(p_nome_pet, '\', '\\'), '"', '\"') || '",' ||
                  '"status":"' || p_nome_status || '",' ||
                  '"cuidador_responsavel":"' || REPLACE(REPLACE(p_nome_usuario, '\', '\\'), '"', '\"') || '"' ||
                  '}';

        IF LENGTH(v_json) > 3800 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Estrutura JSON excedeu o limite máximo seguro de 3800 bytes.');
        END IF;

        RETURN v_json;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20003 AND -20001 THEN
                RAISE;
            END IF;
            RAISE_APPLICATION_ERROR(-20004, 'Falha inesperada durante a serialização manual JSON: ' || SQLERRM);
    END fn_tarefa_json;

    -- ----------------------------------------------------------------
    -- PROCEDIMENTO 1: pr_listar_tarefas_json (DBMS_OUTPUT)
    -- ----------------------------------------------------------------
    PROCEDURE pr_listar_tarefas_json (
        p_status_id IN NUMBER DEFAULT NULL
    ) IS
        CURSOR c_tarefas IS
            SELECT t.id_tarefa,
                   t.titulo,
                   t.pontos_tarefa,
                   t.descricao,
                   p.nome AS nome_pet,
                   s.nome_status,
                   u.nome AS nome_usuario
              FROM tarefa t
              JOIN pet p     ON t.pet_id_pet = p.id_pet
              JOIN status s  ON t.status_id_status = s.id_status
              JOIN usuario u ON t.usuario_id_usuario = u.id_usuario
             WHERE p_status_id IS NULL OR t.status_id_status = p_status_id
             ORDER BY t.id_tarefa;

        r_tarefa       c_tarefas%ROWTYPE;
        v_check_status NUMBER;
        v_qtd          NUMBER := 0;
    BEGIN
        IF p_status_id IS NOT NULL THEN
            SELECT COUNT(1) INTO v_check_status FROM status WHERE id_status = p_status_id;
            IF v_check_status = 0 THEN
                RAISE_APPLICATION_ERROR(-20005, 'O ID de status informado (' || p_status_id || ') não existe.');
            END IF;
        END IF;

        DBMS_OUTPUT.PUT_LINE('======================================================================');
        DBMS_OUTPUT.PUT_LINE('      [PKG_PETGUARDIAN] RELATÓRIO DE TAREFAS SERIALIZADAS EM JSON     ');
        DBMS_OUTPUT.PUT_LINE('======================================================================');

        OPEN c_tarefas;
        LOOP
            FETCH c_tarefas INTO r_tarefa;
            EXIT WHEN c_tarefas%NOTFOUND;

            DBMS_OUTPUT.PUT_LINE(fn_tarefa_json(
                r_tarefa.id_tarefa,
                r_tarefa.titulo,
                r_tarefa.pontos_tarefa,
                r_tarefa.descricao,
                r_tarefa.nome_pet,
                r_tarefa.nome_status,
                r_tarefa.nome_usuario
            ));
            v_qtd := v_qtd + 1;
        END LOOP;
        CLOSE c_tarefas;

        IF v_qtd = 0 THEN
            RAISE_APPLICATION_ERROR(-20006, 'Nenhuma tarefa atende aos critérios de filtro informados.');
        END IF;

        DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Total de registros processados: ' || v_qtd);
        DBMS_OUTPUT.PUT_LINE('======================================================================');
    EXCEPTION
        WHEN OTHERS THEN
            IF c_tarefas%ISOPEN THEN
                CLOSE c_tarefas;
            END IF;
            IF SQLCODE BETWEEN -20006 AND -20001 THEN
                RAISE;
            END IF;
            RAISE_APPLICATION_ERROR(-20008, 'Erro inesperado em pr_listar_tarefas_json: ' || SQLERRM);
    END pr_listar_tarefas_json;

    -- ----------------------------------------------------------------
    -- PROCEDIMENTO 1 (EXTENSÃO): pr_exportar_tarefas_json (Consumo Java)
    -- Retorna array JSON via parâmetro OUT CLOB
    -- ----------------------------------------------------------------
    PROCEDURE pr_exportar_tarefas_json (
        p_status_id    IN NUMBER DEFAULT NULL,
        p_json_output  OUT CLOB
    ) IS
        CURSOR c_tarefas IS
            SELECT t.id_tarefa,
                   t.titulo,
                   t.pontos_tarefa,
                   t.descricao,
                   p.nome AS nome_pet,
                   s.nome_status,
                   u.nome AS nome_usuario
              FROM tarefa t
              JOIN pet p     ON t.pet_id_pet = p.id_pet
              JOIN status s  ON t.status_id_status = s.id_status
              JOIN usuario u ON t.usuario_id_usuario = u.id_usuario
             WHERE p_status_id IS NULL OR t.status_id_status = p_status_id
             ORDER BY t.id_tarefa;

        r_tarefa       c_tarefas%ROWTYPE;
        v_primeiro     BOOLEAN := TRUE;
        v_json_linha   VARCHAR2(4000);
        v_check_status NUMBER;
    BEGIN
        IF p_status_id IS NOT NULL THEN
            SELECT COUNT(1) INTO v_check_status FROM status WHERE id_status = p_status_id;
            IF v_check_status = 0 THEN
                RAISE_APPLICATION_ERROR(-20005, 'O ID de status informado (' || p_status_id || ') não existe.');
            END IF;
        END IF;

        DBMS_LOB.CREATETEMPORARY(p_json_output, TRUE);
        DBMS_LOB.WRITEAPPEND(p_json_output, 1, '[');

        OPEN c_tarefas;
        LOOP
            FETCH c_tarefas INTO r_tarefa;
            EXIT WHEN c_tarefas%NOTFOUND;

            IF NOT v_primeiro THEN
                DBMS_LOB.WRITEAPPEND(p_json_output, 1, ',');
            END IF;

            v_json_linha := fn_tarefa_json(
                r_tarefa.id_tarefa,
                r_tarefa.titulo,
                r_tarefa.pontos_tarefa,
                r_tarefa.descricao,
                r_tarefa.nome_pet,
                r_tarefa.nome_status,
                r_tarefa.nome_usuario
            );

            DBMS_LOB.WRITEAPPEND(p_json_output, LENGTH(v_json_linha), v_json_linha);
            v_primeiro := FALSE;
        END LOOP;
        CLOSE c_tarefas;

        DBMS_LOB.WRITEAPPEND(p_json_output, 1, ']');
    EXCEPTION
        WHEN OTHERS THEN
            IF c_tarefas%ISOPEN THEN
                CLOSE c_tarefas;
            END IF;
            IF SQLCODE BETWEEN -20006 AND -20001 THEN
                RAISE;
            END IF;
            RAISE_APPLICATION_ERROR(-20008, 'Erro ao exportar tarefas em JSON via CLOB: ' || SQLERRM);
    END pr_exportar_tarefas_json;

    -- ----------------------------------------------------------------
    -- FUNÇÃO 2: fn_classificar_pontos
    -- Regra de negócio corporativa de gamificação
    -- ----------------------------------------------------------------
    FUNCTION fn_classificar_pontos (
        p_pontos IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        IF p_pontos IS NULL THEN
            RAISE_APPLICATION_ERROR(-20009, 'Pontuação informada não pode ser nula.');
        ELSIF p_pontos < 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 'A pontuação não pode ser negativa: ' || p_pontos);
        ELSIF p_pontos > 1000 THEN
            RAISE_APPLICATION_ERROR(-20011, 'Pontuação acima do limite máximo de 1000 pontos: ' || p_pontos);
        END IF;

        IF p_pontos <= 20 THEN
            RETURN 'BRONZE (BÁSICO)';
        ELSIF p_pontos <= 45 THEN
            RETURN 'PRATA (INTERMEDIÁRIO)';
        ELSIF p_pontos <= 75 THEN
            RETURN 'OURO (AVANÇADO)';
        ELSE
            RETURN 'DIAMANTE (MASTER)';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20011 AND -20009 THEN
                RAISE;
            END IF;
            RAISE_APPLICATION_ERROR(-20012, 'Erro ao classificar pontos: ' || SQLERRM);
    END fn_classificar_pontos;

    -- ----------------------------------------------------------------
    -- PROCEDIMENTO 2: pr_resumo_pontos_tarefas
    -- Relatório analítico tabular com quebra de grupo e subtotais
    -- ----------------------------------------------------------------
    PROCEDURE pr_resumo_pontos_tarefas IS
        CURSOR c_fatos IS
            SELECT p.id_pet,
                   p.nome AS nome_pet,
                   s.id_status,
                   s.nome_status,
                   t.pontos_tarefa
              FROM tarefa t
              JOIN pet p    ON t.pet_id_pet = p.id_pet
              JOIN status s ON t.status_id_status = s.id_status
             ORDER BY p.id_pet ASC, s.id_status ASC;

        r_linha             c_fatos%ROWTYPE;
        v_pet_atual         pet.id_pet%TYPE := NULL;
        v_nome_pet_atual    pet.nome%TYPE := NULL;
        v_status_atual      status.id_status%TYPE := NULL;
        v_nome_status_atual status.nome_status%TYPE := NULL;
        v_soma_combinacao   NUMBER(10,2) := 0;
        v_subtotal_pet      NUMBER(10,2) := 0;
        v_total_geral       NUMBER(10,2) := 0;
        v_qtd_linhas        NUMBER := 0;
    BEGIN
        OPEN c_fatos;

        DBMS_OUTPUT.PUT_LINE(RPAD('Pet (Cat 1)', 18) || ' ' || RPAD('Status (Cat 2)', 16) || ' ' || LPAD('Pontos', 12));
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 18, '-')      || ' ' || RPAD('-', 16, '-')       || ' ' || LPAD('-', 12, '-'));

        LOOP
            FETCH c_fatos INTO r_linha;

            IF (c_fatos%NOTFOUND OR r_linha.id_pet <> v_pet_atual OR r_linha.id_status <> v_status_atual) 
               AND v_pet_atual IS NOT NULL THEN

                DBMS_OUTPUT.PUT_LINE(
                    RPAD(TO_CHAR(v_pet_atual) || ' - ' || v_nome_pet_atual, 18) || ' ' ||
                    RPAD(TO_CHAR(v_status_atual) || ' - ' || v_nome_status_atual, 16) || ' ' ||
                    LPAD(TO_CHAR(v_soma_combinacao, 'FM999990.00'), 12)
                );

                v_subtotal_pet    := v_subtotal_pet + v_soma_combinacao;
                v_total_geral     := v_total_geral + v_soma_combinacao;
                v_soma_combinacao := 0;

                IF c_fatos%NOTFOUND OR r_linha.id_pet <> v_pet_atual THEN
                    DBMS_OUTPUT.PUT_LINE(RPAD('Sub Total', 35) || LPAD(TO_CHAR(v_subtotal_pet, 'FM999990.00'), 12));
                    v_subtotal_pet := 0;
                END IF;
            END IF;

            EXIT WHEN c_fatos%NOTFOUND;

            v_pet_atual         := r_linha.id_pet;
            v_nome_pet_atual    := r_linha.nome_pet;
            v_status_atual      := r_linha.id_status;
            v_nome_status_atual := r_linha.nome_status;

            v_soma_combinacao   := v_soma_combinacao + r_linha.pontos_tarefa;
            v_qtd_linhas        := v_qtd_linhas + 1;
        END LOOP;

        CLOSE c_fatos;

        IF v_qtd_linhas = 0 THEN
            RAISE_APPLICATION_ERROR(-20013, 'Nenhum registro de tarefa localizado para sumarização.');
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD('Total Geral', 35) || LPAD(TO_CHAR(v_total_geral, 'FM999990.00'), 12));
    EXCEPTION
        WHEN OTHERS THEN
            IF c_fatos%ISOPEN THEN
                CLOSE c_fatos;
            END IF;
            IF SQLCODE = -20013 THEN
                RAISE;
            END IF;
            RAISE_APPLICATION_ERROR(-20015, 'Erro no relatório analítico pr_resumo_pontos_tarefas: ' || SQLERRM);
    END pr_resumo_pontos_tarefas;

END pkg_petguardian;
/
