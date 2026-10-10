-- ====================================================================
-- CHALLENGE CLYVO 2026 — SPRINT 4
-- DISCIPLINA: Mastering Relational and Non-Relational Database
-- REQUISITO 2: Empacotamento dos Processos (Packages) no Oracle PL/SQL
-- FOCO: Pontuação Gamificada de Pets, Governança do Care Circle e Transações
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
-- ====================================================================
CREATE OR REPLACE PACKAGE pkg_petguardian AS

    -- Exceções públicas com códigos ORA padronizados
    e_id_invalido            EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_id_invalido, -20018);

    e_pet_inexistente        EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_pet_inexistente, -20019);

    e_usuario_inexistente    EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_usuario_inexistente, -20022);

    e_vinculo_inexistente    EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_vinculo_inexistente, -20041);

    e_tarefa_inexistente     EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_tarefa_inexistente, -20050);

    e_aula_inexistente       EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_aula_inexistente, -20051);

    e_tarefa_nao_pendente    EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_tarefa_nao_pendente, -20052);

    e_pontos_invalido        EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_pontos_invalido, -20053);

    -- ----------------------------------------------------------------
    -- SEÇÃO 1: PONTUAÇÃO GAMIFICADA DE PETS E USUÁRIOS (APP & JAVA)
    -- ----------------------------------------------------------------

    -- 1.1 Cálculo consolidado de pontuação do pet individual (tarefas + aulas)
    PROCEDURE pr_calcular_pontuacao_pet (
        p_id_pet         IN NUMBER,
        p_pontos_tarefas OUT NUMBER,
        p_pontos_aulas   OUT NUMBER,
        p_pontos_totais  OUT NUMBER
    );

    -- 1.2 Cálculo agregado de todos os pets do usuário autenticado (/pets/me/pontos)
    PROCEDURE pr_calcular_pontuacao_usuario (
        p_id_usuario     IN NUMBER,
        p_pontos_tarefas OUT NUMBER,
        p_pontos_aulas   OUT NUMBER,
        p_pontos_totais  OUT NUMBER
    );

    -- 1.3 Relatório consolidado da rede de cuidado do usuário (/usuarios/me/rede-cuidado)
    PROCEDURE pr_obter_resumo_rede_cuidado (
        p_id_usuario         IN NUMBER,
        p_total_pets         OUT NUMBER,
        p_total_cuidadores   OUT NUMBER,
        p_tarefas_pendentes  OUT NUMBER,
        p_tarefas_concluidas OUT NUMBER,
        p_pontos_acumulados  OUT NUMBER
    );

    -- ----------------------------------------------------------------
    -- SEÇÃO 2: OPERAÇÕES TRANSACIONAIS DO APP (REDUÇÃO DE CÓDIGO JAVA)
    -- ----------------------------------------------------------------

    -- 2.1 Transferência atômica de responsabilidade principal no Care Circle (USUARIO_PET)
    PROCEDURE pr_transferir_responsavel_principal (
        p_id_pet          IN NUMBER,
        p_novo_id_usuario IN NUMBER
    );

END pkg_petguardian;
/

-- ====================================================================
-- PARTE 2: CORPO DO PACOTE (PACKAGE BODY)
-- ====================================================================
CREATE OR REPLACE PACKAGE BODY pkg_petguardian AS

    -- ----------------------------------------------------------------
    -- SEÇÃO 1: PONTUAÇÃO GAMIFICADA DE PETS E USUÁRIOS
    -- ----------------------------------------------------------------

    PROCEDURE pr_calcular_pontuacao_pet (
        p_id_pet         IN NUMBER,
        p_pontos_tarefas OUT NUMBER,
        p_pontos_aulas   OUT NUMBER,
        p_pontos_totais  OUT NUMBER
    ) IS
        v_existe NUMBER;
    BEGIN
        IF p_id_pet IS NULL OR p_id_pet <= 0 THEN
            RAISE_APPLICATION_ERROR(-20018, 'ID do pet fornecido é nulo ou inválido.');
        END IF;

        SELECT COUNT(1) INTO v_existe FROM pet WHERE id_pet = p_id_pet;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20019, 'Pet com id ' || p_id_pet || ' não foi encontrado.');
        END IF;

        -- Soma de tarefas concluídas do pet (status_id_status = 2)
        SELECT NVL(SUM(t.pontos_tarefa), 0)
          INTO p_pontos_tarefas
          FROM tarefa t
         WHERE t.pet_id_pet = p_id_pet
           AND t.status_id_status = 2;

        -- Soma de aulas concluídas associadas às trilhas e módulos do pet
        SELECT NVL(SUM(a.pontos_aula), 0)
          INTO p_pontos_aulas
          FROM aula a
          JOIN modulo m ON a.modulo_id_modulo = m.id_modulo
          JOIN trilha tr ON m.trilha_id_trilha = tr.id_trilha
         WHERE tr.pet_id_pet = p_id_pet
           AND a.concluida = 1;

        p_pontos_totais := p_pontos_tarefas + p_pontos_aulas;
    EXCEPTION
        WHEN e_id_invalido OR e_pet_inexistente THEN
            RAISE;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20020, 'Erro ao calcular pontuação consolidada do pet: ' || SQLERRM);
    END pr_calcular_pontuacao_pet;

    PROCEDURE pr_calcular_pontuacao_usuario (
        p_id_usuario     IN NUMBER,
        p_pontos_tarefas OUT NUMBER,
        p_pontos_aulas   OUT NUMBER,
        p_pontos_totais  OUT NUMBER
    ) IS
        v_existe NUMBER;
    BEGIN
        IF p_id_usuario IS NULL OR p_id_usuario <= 0 THEN
            RAISE_APPLICATION_ERROR(-20018, 'ID do usuário fornecido é nulo ou inválido.');
        END IF;

        SELECT COUNT(1) INTO v_existe FROM usuario WHERE id_usuario = p_id_usuario;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20022, 'Usuário com id ' || p_id_usuario || ' não foi encontrado.');
        END IF;

        -- Tarefas concluídas de todos os pets sob tutela do usuário (via USUARIO_PET)
        SELECT NVL(SUM(t.pontos_tarefa), 0)
          INTO p_pontos_tarefas
          FROM tarefa t
         WHERE t.status_id_status = 2
           AND t.pet_id_pet IN (
               SELECT up.pet_id_pet 
                 FROM usuario_pet up 
                WHERE up.usuario_id_usuario = p_id_usuario
           );

        -- Aulas concluídas de todos os pets sob tutela do usuário (via USUARIO_PET)
        SELECT NVL(SUM(a.pontos_aula), 0)
          INTO p_pontos_aulas
          FROM aula a
          JOIN modulo m ON a.modulo_id_modulo = m.id_modulo
          JOIN trilha tr ON m.trilha_id_trilha = tr.id_trilha
         WHERE a.concluida = 1
           AND tr.pet_id_pet IN (
               SELECT up.pet_id_pet 
                 FROM usuario_pet up 
                WHERE up.usuario_id_usuario = p_id_usuario
           );

        p_pontos_totais := p_pontos_tarefas + p_pontos_aulas;
    EXCEPTION
        WHEN e_id_invalido OR e_usuario_inexistente THEN
            RAISE;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20023, 'Erro ao calcular pontuação agregada do usuário: ' || SQLERRM);
    END pr_calcular_pontuacao_usuario;

    -- 1.3 Relatório consolidado da rede de cuidado do usuário (/usuarios/me/rede-cuidado)
    PROCEDURE pr_obter_resumo_rede_cuidado (
        p_id_usuario         IN NUMBER,
        p_total_pets         OUT NUMBER,
        p_total_cuidadores   OUT NUMBER,
        p_tarefas_pendentes  OUT NUMBER,
        p_tarefas_concluidas OUT NUMBER,
        p_pontos_acumulados  OUT NUMBER
    ) IS
        v_existe        NUMBER;
        v_total_tarefas NUMBER;
        v_total_aulas   NUMBER;
    BEGIN
        IF p_id_usuario IS NULL OR p_id_usuario <= 0 THEN
            RAISE_APPLICATION_ERROR(-20018, 'ID do usuário fornecido é nulo ou inválido.');
        END IF;

        SELECT COUNT(1) INTO v_existe FROM usuario WHERE id_usuario = p_id_usuario;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20022, 'Usuário com id ' || p_id_usuario || ' não foi encontrado.');
        END IF;

        -- Total de pets tutelados ou co-tutelados pelo usuário
        SELECT NVL(COUNT(DISTINCT up.pet_id_pet), 0)
          INTO p_total_pets
          FROM usuario_pet up
         WHERE up.usuario_id_usuario = p_id_usuario;

        -- Total de co-cuidadores distintos na rede do tutor
        SELECT NVL(COUNT(DISTINCT up2.usuario_id_usuario), 0)
          INTO p_total_cuidadores
          FROM usuario_pet up2
         WHERE up2.usuario_id_usuario <> p_id_usuario
           AND up2.pet_id_pet IN (
               SELECT up.pet_id_pet
                 FROM usuario_pet up
                WHERE up.usuario_id_usuario = p_id_usuario
            );

        -- Tarefas pendentes válidas (status_id_status = 1 e prazo >= SYSTIMESTAMP)
        SELECT NVL(COUNT(1), 0)
          INTO p_tarefas_pendentes
          FROM tarefa t
         WHERE t.status_id_status = 1
           AND t.prazo >= SYSTIMESTAMP
           AND t.pet_id_pet IN (
               SELECT up.pet_id_pet
                 FROM usuario_pet up
                WHERE up.usuario_id_usuario = p_id_usuario
            );

        -- Tarefas concluídas (status_id_status = 2)
        SELECT NVL(COUNT(1), 0)
          INTO p_tarefas_concluidas
          FROM tarefa t
         WHERE t.status_id_status = 2
           AND t.pet_id_pet IN (
               SELECT up.pet_id_pet
                 FROM usuario_pet up
                WHERE up.usuario_id_usuario = p_id_usuario
            );

        -- Pontuação acumulada total somada (tarefas concluídas + aulas finalizadas)
        pr_calcular_pontuacao_usuario(p_id_usuario, v_total_tarefas, v_total_aulas, p_pontos_acumulados);
    EXCEPTION
        WHEN e_id_invalido OR e_usuario_inexistente THEN
            RAISE;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20024, 'Erro ao obter resumo da rede de cuidado: ' || SQLERRM);
    END pr_obter_resumo_rede_cuidado;

    -- ----------------------------------------------------------------
    -- SEÇÃO 2: OPERAÇÕES TRANSACIONAIS DO APP
    -- ----------------------------------------------------------------


    -- 2.2 Transferência atômica de responsabilidade principal no Care Circle
    PROCEDURE pr_transferir_responsavel_principal (
        p_id_pet          IN NUMBER,
        p_novo_id_usuario IN NUMBER
    ) IS
        v_existe_vinculo NUMBER;
    BEGIN
        IF p_id_pet IS NULL OR p_id_pet <= 0 OR p_novo_id_usuario IS NULL OR p_novo_id_usuario <= 0 THEN
            RAISE_APPLICATION_ERROR(-20018, 'ID do pet e do novo responsável não podem ser nulos ou inválidos.');
        END IF;

        -- Valida se o novo responsável já faz parte do Care Circle do pet
        SELECT COUNT(1) INTO v_existe_vinculo
          FROM usuario_pet up
         WHERE up.pet_id_pet = p_id_pet
           AND up.usuario_id_usuario = p_novo_id_usuario;

        IF v_existe_vinculo = 0 THEN
            RAISE_APPLICATION_ERROR(-20041, 'O novo responsável (id ' || p_novo_id_usuario || ') não está vinculado ao pet ' || p_id_pet || ' em USUARIO_PET.');
        END IF;

        -- Transação atômica: desmarca o atual titular e promove o novo
        UPDATE usuario_pet
           SET respon_princ = 0
         WHERE pet_id_pet = p_id_pet;

        UPDATE usuario_pet
           SET respon_princ = 1
         WHERE pet_id_pet = p_id_pet
           AND usuario_id_usuario = p_novo_id_usuario;
    EXCEPTION
        WHEN e_id_invalido OR e_vinculo_inexistente THEN
            RAISE;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20042, 'Erro ao transferir responsabilidade principal: ' || SQLERRM);
    END pr_transferir_responsavel_principal;

END pkg_petguardian;
/

-- ====================================================================
-- PARTE 3: TRIGGER DE AUDITORIA DML (AUDITORIA_DML_TAREFA)
-- ====================================================================
CREATE OR REPLACE TRIGGER trg_audit_tarefa
AFTER INSERT OR UPDATE OR DELETE ON tarefa
FOR EACH ROW
DECLARE
    v_tipo_operacao VARCHAR2(10);
    v_valores_old   VARCHAR2(4000) := NULL;
    v_valores_new   VARCHAR2(4000) := NULL;
BEGIN
    IF INSERTING THEN
        v_tipo_operacao := 'INSERT';
        v_valores_new   := 'ID_TAREFA=' || :NEW.id_tarefa || 
                           '; TITULO=' || :NEW.titulo || 
                           '; PONTOS=' || :NEW.pontos_tarefa || 
                           '; STATUS=' || :NEW.status_id_status || 
                           '; PET=' || :NEW.pet_id_pet || 
                           '; USUARIO=' || :NEW.usuario_id_usuario;
                           
        INSERT INTO auditoria_dml_tarefa (nome_usuario, tipo_operacao, data_hora_operacao, valores_anteriores, valores_novos)
        VALUES (USER, v_tipo_operacao, SYSTIMESTAMP, NULL, v_valores_new);

    ELSIF UPDATING THEN
        v_tipo_operacao := 'UPDATE';
        v_valores_old   := 'ID_TAREFA=' || :OLD.id_tarefa || 
                           '; TITULO=' || :OLD.titulo || 
                           '; PONTOS=' || :OLD.pontos_tarefa || 
                           '; STATUS=' || :OLD.status_id_status || 
                           '; PET=' || :OLD.pet_id_pet || 
                           '; USUARIO=' || :OLD.usuario_id_usuario;

        v_valores_new   := 'ID_TAREFA=' || :NEW.id_tarefa || 
                           '; TITULO=' || :NEW.titulo || 
                           '; PONTOS=' || :NEW.pontos_tarefa || 
                           '; STATUS=' || :NEW.status_id_status || 
                           '; PET=' || :NEW.pet_id_pet || 
                           '; USUARIO=' || :NEW.usuario_id_usuario;

        INSERT INTO auditoria_dml_tarefa (nome_usuario, tipo_operacao, data_hora_operacao, valores_anteriores, valores_novos)
        VALUES (USER, v_tipo_operacao, SYSTIMESTAMP, v_valores_old, v_valores_new);

    ELSIF DELETING THEN
        v_tipo_operacao := 'DELETE';
        v_valores_old   := 'ID_TAREFA=' || :OLD.id_tarefa || 
                           '; TITULO=' || :OLD.titulo || 
                           '; PONTOS=' || :OLD.pontos_tarefa || 
                           '; STATUS=' || :OLD.status_id_status || 
                           '; PET=' || :OLD.pet_id_pet || 
                           '; USUARIO=' || :OLD.usuario_id_usuario;

        INSERT INTO auditoria_dml_tarefa (nome_usuario, tipo_operacao, data_hora_operacao, valores_anteriores, valores_novos)
        VALUES (USER, v_tipo_operacao, SYSTIMESTAMP, v_valores_old, NULL);
    END IF;
END trg_audit_tarefa;
/

-- ====================================================================
-- PARTE 4: BATERIA DE TESTES DE INTEGRAÇÃO (PKG_PETGUARDIAN)
-- ====================================================================

PROMPT ====================================================================;
PROMPT  TESTES DAS ROTINAS DO PACOTE PKG_PETGUARDIAN (SPRINT 4)
PROMPT ====================================================================;

-- 1. Teste de Pontuação de Pet Individual (Thor - ID 1)
PROMPT === TESTE 1: pr_calcular_pontuacao_pet (Thor ID 1) ===;
DECLARE
    v_tar NUMBER;
    v_aul NUMBER;
    v_tot NUMBER;
BEGIN
    pkg_petguardian.pr_calcular_pontuacao_pet(1, v_tar, v_aul, v_tot);
    DBMS_OUTPUT.PUT_LINE('Thor (ID 1) -> Tarefas: ' || v_tar || ' | Aulas: ' || v_aul || ' | Total: ' || v_tot);
END;
/

-- 2. Teste de Pontuação Agregada dos Pets do Usuário (Carlos Silva - ID 1)
PROMPT === TESTE 2: pr_calcular_pontuacao_usuario (Carlos Silva ID 1) ===;
DECLARE
    v_tar_usr NUMBER;
    v_aul_usr NUMBER;
    v_tot_usr NUMBER;
BEGIN
    pkg_petguardian.pr_calcular_pontuacao_usuario(1, v_tar_usr, v_aul_usr, v_tot_usr);
    DBMS_OUTPUT.PUT_LINE('Carlos Silva (ID 1) -> Tarefas: ' || v_tar_usr || ' | Aulas: ' || v_aul_usr || ' | Total: ' || v_tot_usr);
END;
/

-- 3. Teste de Transferência de Titularidade no Care Circle
PROMPT === TESTE 3: pr_transferir_responsavel_principal (Thor: Carlos -> Lucas Mendes) ===;
BEGIN
    pkg_petguardian.pr_transferir_responsavel_principal(1, 5);
    DBMS_OUTPUT.PUT_LINE('Titularidade de Thor transferida com sucesso para Lucas Mendes (ID 5).');
END;
/

-- 4. Teste de Resumo da Rede de Cuidado (Carlos Silva - ID 1)
PROMPT === TESTE 4: pr_obter_resumo_rede_cuidado (Carlos Silva ID 1) ===;
DECLARE
    v_tot_pets NUMBER;
    v_tot_cuid NUMBER;
    v_tar_pend NUMBER;
    v_tar_conc NUMBER;
    v_pts_acum NUMBER;
BEGIN
    pkg_petguardian.pr_obter_resumo_rede_cuidado(1, v_tot_pets, v_tot_cuid, v_tar_pend, v_tar_conc, v_pts_acum);
    DBMS_OUTPUT.PUT_LINE('Carlos Silva (ID 1) -> Pets: ' || v_tot_pets || 
                         ' | Cuidadores: ' || v_tot_cuid || 
                         ' | Tarefas Pendentes: ' || v_tar_pend || 
                         ' | Tarefas Concluídas: ' || v_tar_conc || 
                         ' | Pontos Acumulados: ' || v_pts_acum);
END;
/

-- 5. Evidências de Auditoria DML Registradas pela Trigger
PROMPT === TESTE 5: Evidência na Tabela AUDITORIA_DML_TAREFA ===;
SELECT id_auditoria, nome_usuario, tipo_operacao, data_hora_operacao, valores_novos
  FROM auditoria_dml_tarefa
 ORDER BY id_auditoria ASC;

COMMIT;
