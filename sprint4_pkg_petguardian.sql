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

    -- 1.2 Cálculo agregado de todos os pets do usuário (usado internamente por pr_obter_resumo_rede_cuidado)
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

    -- 1.4 Classificação de gamificação do tutor baseada no XP acumulado (BRONZE, PRATA, OURO)
    FUNCTION fn_obter_nivel_usuario (
        p_id_usuario IN NUMBER
    ) RETURN VARCHAR2;

    -- ----------------------------------------------------------------
    -- SEÇÃO 2: OPERAÇÕES TRANSACIONAIS DO APP & AUDITORIA EMPACOTADA
    -- ----------------------------------------------------------------

    -- 2.1 Transferência atômica de responsabilidade principal no Care Circle (USUARIO_PET)
    PROCEDURE pr_transferir_responsavel_principal (
        p_id_pet          IN NUMBER,
        p_novo_id_usuario IN NUMBER
    );

    -- 2.2 Gravação modular de auditoria DML (invocado pela trigger trg_audit_tarefa)
    PROCEDURE pr_registrar_auditoria_tarefa (
        p_tipo_operacao  IN VARCHAR2,
        p_old_id_tarefa  IN NUMBER,
        p_old_titulo     IN VARCHAR2,
        p_old_pontos     IN NUMBER,
        p_old_status     IN NUMBER,
        p_old_pet        IN NUMBER,
        p_old_usuario    IN NUMBER,
        p_new_id_tarefa  IN NUMBER,
        p_new_titulo     IN VARCHAR2,
        p_new_pontos     IN NUMBER,
        p_new_status     IN NUMBER,
        p_new_pet        IN NUMBER,
        p_new_usuario    IN NUMBER
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

    -- 1.1 Cálculo consolidado de pontuação do pet individual (tarefas + aulas)
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

    -- 1.2 Cálculo agregado de todos os pets do usuário (usado internamente por pr_obter_resumo_rede_cuidado)
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

        -- Tarefas pendentes e concluídas da rede do tutor (agregação unificada condicional)
        SELECT NVL(COUNT(CASE WHEN t.status_id_status = 1 THEN 1 END), 0),
               NVL(COUNT(CASE WHEN t.status_id_status = 2 THEN 1 END), 0)
          INTO p_tarefas_pendentes,
               p_tarefas_concluidas
          FROM tarefa t
         WHERE t.pet_id_pet IN (
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

    -- 1.4 Classificação de gamificação do tutor baseada no XP acumulado (BRONZE, PRATA, OURO)
    FUNCTION fn_obter_nivel_usuario (
        p_id_usuario IN NUMBER
    ) RETURN VARCHAR2 IS
        v_tar NUMBER;
        v_aul NUMBER;
        v_tot NUMBER;
    BEGIN
        IF p_id_usuario IS NULL OR p_id_usuario <= 0 THEN
            RAISE_APPLICATION_ERROR(-20018, 'ID do usuário fornecido é nulo ou inválido.');
        END IF;

        pr_calcular_pontuacao_usuario(p_id_usuario, v_tar, v_aul, v_tot);

        IF v_tot <= 50 THEN
            RETURN 'BRONZE';
        ELSIF v_tot <= 150 THEN
            RETURN 'PRATA';
        ELSE
            RETURN 'OURO';
        END IF;
    END fn_obter_nivel_usuario;

    -- ----------------------------------------------------------------
    -- SEÇÃO 2: OPERAÇÕES TRANSACIONAIS DO APP & AUDITORIA EMPACOTADA
    -- ----------------------------------------------------------------

    -- 2.1 Transferência atômica de responsabilidade principal no Care Circle (USUARIO_PET)
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

        -- Transação atômica otimizada em uma única operação DML (evita duplo lock e estado intermediário sem titular)
        UPDATE usuario_pet
           SET respon_princ = CASE 
                                  WHEN usuario_id_usuario = p_novo_id_usuario THEN 1 
                                  ELSE 0 
                              END
         WHERE pet_id_pet = p_id_pet;
    EXCEPTION
        WHEN e_id_invalido OR e_vinculo_inexistente THEN
            RAISE;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20042, 'Erro ao transferir responsabilidade principal: ' || SQLERRM);
    END pr_transferir_responsavel_principal;

    -- 2.2 Gravação modular de auditoria DML (invocado pela trigger trg_audit_tarefa)
    PROCEDURE pr_registrar_auditoria_tarefa (
        p_tipo_operacao  IN VARCHAR2,
        p_old_id_tarefa  IN NUMBER,
        p_old_titulo     IN VARCHAR2,
        p_old_pontos     IN NUMBER,
        p_old_status     IN NUMBER,
        p_old_pet        IN NUMBER,
        p_old_usuario    IN NUMBER,
        p_new_id_tarefa  IN NUMBER,
        p_new_titulo     IN VARCHAR2,
        p_new_pontos     IN NUMBER,
        p_new_status     IN NUMBER,
        p_new_pet        IN NUMBER,
        p_new_usuario    IN NUMBER
    ) IS
        v_valores_old VARCHAR2(4000) := NULL;
        v_valores_new VARCHAR2(4000) := NULL;
    BEGIN
        IF p_tipo_operacao IN ('INSERT', 'UPDATE') THEN
            v_valores_new := 'ID_TAREFA=' || p_new_id_tarefa || 
                             '; TITULO=' || p_new_titulo || 
                             '; PONTOS=' || p_new_pontos || 
                             '; STATUS=' || p_new_status || 
                             '; PET=' || p_new_pet || 
                             '; USUARIO=' || p_new_usuario;
        END IF;

        IF p_tipo_operacao IN ('UPDATE', 'DELETE') THEN
            v_valores_old := 'ID_TAREFA=' || p_old_id_tarefa || 
                             '; TITULO=' || p_old_titulo || 
                             '; PONTOS=' || p_old_pontos || 
                             '; STATUS=' || p_old_status || 
                             '; PET=' || p_old_pet || 
                             '; USUARIO=' || p_old_usuario;
        END IF;

        INSERT INTO auditoria_dml_tarefa (
            nome_usuario, tipo_operacao, data_hora_operacao, valores_anteriores, valores_novos
        ) VALUES (
            USER, p_tipo_operacao, SYSTIMESTAMP, v_valores_old, v_valores_new
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20043, 'Erro ao registrar auditoria de tarefa: ' || SQLERRM);
    END pr_registrar_auditoria_tarefa;

END pkg_petguardian;
/

-- ====================================================================
-- PARTE 3: TRIGGER DE AUDITORIA DML (AUDITORIA_DML_TAREFA)
-- DISPARADOR LEVE QUE DELEGA A EXECUÇÃO PARA A PACKAGE EMPACOTADA
-- ====================================================================
CREATE OR REPLACE TRIGGER trg_audit_tarefa
AFTER INSERT OR UPDATE OR DELETE ON tarefa
FOR EACH ROW
BEGIN
    pkg_petguardian.pr_registrar_auditoria_tarefa(
        p_tipo_operacao  => CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        p_old_id_tarefa  => :OLD.id_tarefa,
        p_old_titulo     => :OLD.titulo,
        p_old_pontos     => :OLD.pontos_tarefa,
        p_old_status     => :OLD.status_id_status,
        p_old_pet        => :OLD.pet_id_pet,
        p_old_usuario    => :OLD.usuario_id_usuario,
        p_new_id_tarefa  => :NEW.id_tarefa,
        p_new_titulo     => :NEW.titulo,
        p_new_pontos     => :NEW.pontos_tarefa,
        p_new_status     => :NEW.status_id_status,
        p_new_pet        => :NEW.pet_id_pet,
        p_new_usuario    => :NEW.usuario_id_usuario
    );
END trg_audit_tarefa;
/

-- ====================================================================
-- PARTE 4: BATERIA DE TESTES DE INTEGRAÇÃO (PKG_PETGUARDIAN)
-- ====================================================================

-- 1. Teste de Pontuação de Pet Individual (Thor - ID 1)
DECLARE
    v_tar NUMBER;
    v_aul NUMBER;
    v_tot NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTE 1: pr_calcular_pontuacao_pet ===');
    pkg_petguardian.pr_calcular_pontuacao_pet(1, v_tar, v_aul, v_tot);
    DBMS_OUTPUT.PUT_LINE('Thor (ID 1) -> Tarefas: ' || v_tar || ' | Aulas: ' || v_aul || ' | Total: ' || v_tot);
END;
/

-- 2. Teste de Pontuação Agregada e Nível de Gamificação do Usuário (Carlos Silva - ID 1)
DECLARE
    v_tar_usr NUMBER;
    v_aul_usr NUMBER;
    v_tot_usr NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTE 2: pr_calcular_pontuacao_usuario e fn_obter_nivel_usuario ===');
    pkg_petguardian.pr_calcular_pontuacao_usuario(1, v_tar_usr, v_aul_usr, v_tot_usr);
    DBMS_OUTPUT.PUT_LINE('Carlos Silva (ID 1) -> Tarefas: ' || v_tar_usr || ' | Aulas: ' || v_aul_usr || ' | Total: ' || v_tot_usr);
    DBMS_OUTPUT.PUT_LINE('Nível de Gamificação (FUNCTION): ' || pkg_petguardian.fn_obter_nivel_usuario(1));
END;
/

-- 3. Teste de Resumo da Rede de Cuidado (Carlos Silva - ID 1)
DECLARE
    v_tot_pets NUMBER;
    v_tot_cuid NUMBER;
    v_tar_pend NUMBER;
    v_tar_conc NUMBER;
    v_pts_acum NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTE 3: pr_obter_resumo_rede_cuidado (Carlos Silva ID 1) ===');
    pkg_petguardian.pr_obter_resumo_rede_cuidado(1, v_tot_pets, v_tot_cuid, v_tar_pend, v_tar_conc, v_pts_acum);
    DBMS_OUTPUT.PUT_LINE('Carlos Silva (ID 1) -> Pets: ' || v_tot_pets || 
                         ' | Cuidadores: ' || v_tot_cuid || 
                         ' | Tarefas Pendentes: ' || v_tar_pend || 
                         ' | Tarefas Concluídas: ' || v_tar_conc || 
                         ' | Pontos Acumulados: ' || v_pts_acum);
END;
/

-- 4. Teste de Transferência de Titularidade no Care Circle
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTE 4: pr_transferir_responsavel_principal ===');
    pkg_petguardian.pr_transferir_responsavel_principal(1, 5);
    DBMS_OUTPUT.PUT_LINE('Titularidade de Thor transferida com sucesso para Lucas Mendes (ID 5).');
END;
/

-- 5. Disparo e Evidências da Trigger de Auditoria DML (TRG_AUDIT_TAREFA)
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTE 5: Disparo da Trigger trg_audit_tarefa na Tabela TAREFA ===');
    UPDATE tarefa
       SET status_id_status = 2,
           conclusao = SYSTIMESTAMP
     WHERE id_tarefa = 2;
    DBMS_OUTPUT.PUT_LINE('Tarefa ID 2 atualizada com sucesso. Registro de auditoria gerado pela trigger:');
END;
/

SELECT id_auditoria, nome_usuario, tipo_operacao, data_hora_operacao, valores_anteriores, valores_novos
  FROM auditoria_dml_tarefa
 ORDER BY id_auditoria ASC;

-- Rollback das operações demonstrativas de teste para preservar o estado limpo das sementes
ROLLBACK;
