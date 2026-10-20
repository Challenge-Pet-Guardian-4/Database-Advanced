-- ====================================================================
-- CHALLENGE CLYVO 2026 — SPRINT 4
-- DISCIPLINA: Mastering Relational and Non-Relational Database
-- REQUISITO 3: Exportação do Dataset JSON a partir do Banco Relacional (Oracle 19c)
-- FINALIDADE: Extração dos metadados pedagógicos da tabela relacional AULA
--             para geração do arquivo 'conteudos_dataset.json' e posterior
--             ingestão no MongoDB Atlas via 'setup_mongodb_conteudos.js'.
-- TURMA: 2TDSPG
-- INTEGRANTES:
--   1. Enzo Okuizumi        - RM: 561432
--   2. Gustavo Okada        - RM: 563428
--   3. Lucas Barros Gouveia - RM: 566422
--   4. Luna de Carvalho     - RM: 562290
--   5. Milton Marcelino     - RM: 564836
-- ====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET PAGESIZE 0;
SET FEEDBACK OFF;
SET LINESIZE 5000;
SET TRIMSPOOL ON;

-- --------------------------------------------------------------------
-- OPÇÃO 1: CONSULTA NATIVA SQL (JSON_OBJECT + JSON_ARRAYAGG + JSON_SERIALIZE)
-- Executar no SQL Developer / SQLcl / DBeaver para visualizar o JSON:
-- --------------------------------------------------------------------
SELECT JSON_SERIALIZE(
    JSON_ARRAYAGG(
        JSON_OBJECT(
            'aula_id'        VALUE a.id_aula,
            'tipo_conteudo'  VALUE CASE 
                                     WHEN a.dificuldade = 'INICIANTE' THEN 'PASSO_A_PASSO'
                                     WHEN a.dificuldade = 'INTERMEDIARIO' THEN 'ARTIGO'
                                     ELSE 'VIDEO'
                                   END,
            'corpo_markdown' VALUE '# ' || a.nome || CHR(10) || CHR(10) || 
                                   a.descricao || CHR(10) || CHR(10) ||
                                   '### Detalhes Pedagógicos:' || CHR(10) ||
                                   '- Pontuação concedida: ' || a.pontos_aula || ' XP' || CHR(10) ||
                                   '- Nível de dificuldade: ' || a.dificuldade,
            'links_recursos' VALUE JSON_ARRAY(
                'https://petguardian.fiap.com.br/materiais/aula_' || a.id_aula || '.pdf',
                'https://petguardian.fiap.com.br/videos/aula_' || a.id_aula || '.mp4'
            ),
            'atualizado_em'  VALUE '2026-10-08T18:00:00Z'
        )
    ) RETURNING CLOB PRETTY
) AS json_dataset_exportado
FROM aula a;

-- --------------------------------------------------------------------
-- OPÇÃO 2: BLOCO ANÔNIMO PL/SQL COM DBMS_OUTPUT (DEMONSTRAÇÃO EM VÍDEO)
-- Executar com SET SERVEROUTPUT ON para exibir no console:
-- --------------------------------------------------------------------
DECLARE
    v_json_clob CLOB;
BEGIN
    SELECT JSON_SERIALIZE(
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'aula_id'        VALUE a.id_aula,
                'tipo_conteudo'  VALUE CASE 
                                         WHEN a.dificuldade = 'INICIANTE' THEN 'PASSO_A_PASSO'
                                         WHEN a.dificuldade = 'INTERMEDIARIO' THEN 'ARTIGO'
                                         ELSE 'VIDEO'
                                       END,
                'corpo_markdown' VALUE '# ' || a.nome || CHR(10) || CHR(10) || a.descricao,
                'links_recursos' VALUE JSON_ARRAY(
                    'https://petguardian.fiap.com.br/materiais/aula_' || a.id_aula || '.pdf'
                ),
                'atualizado_em'  VALUE TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
            )
        ) RETURNING CLOB PRETTY
    )
    INTO v_json_clob
    FROM aula a;

    DBMS_OUTPUT.PUT_LINE('=== DATASET JSON EXPORTADO DO BANCO RELACIONAL ORACLE (TABELA AULA) ===');
    DBMS_OUTPUT.PUT_LINE(SUBSTR(v_json_clob, 1, 3000));
    DBMS_OUTPUT.PUT_LINE('=== FIM DO DATASET EXPORTADO ===');
END;
/
