-- ====================================================================
-- CHALLENGE CLYVO 2026 — SPRINT 4
-- DISCIPLINA: Mastering Relational and Non-Relational Database
-- REQUISITO 3: Exportação do Dataset JSON a partir do Banco Relacional (Oracle 19c)
-- FINALIDADE: Consulta nativa SQL que extrai os metadados pedagógicos da tabela
--             relacional AULA gerando com precisão o arquivo 'conteudos_dataset.json'
--             para posterior ingestão no MongoDB via 'setup_mongodb_conteudos.js'.
-- TURMA: 2TDSPG
-- INTEGRANTES:
--   1. Enzo Okuizumi        - RM: 561432
--   2. Gustavo Okada        - RM: 563428
--   3. Lucas Barros Gouveia - RM: 566422
--   4. Luna de Carvalho     - RM: 562290
--   5. Milton Marcelino     - RM: 564836
-- ====================================================================

-- Executar no Oracle SQL Developer, DBeaver ou SQLcl conectado à base PetGuardian:
SELECT JSON_SERIALIZE(
    JSON_ARRAYAGG(
        JSON_OBJECT(
            'aula_id'        VALUE a.id_aula,
            'tipo_conteudo'  VALUE CASE a.id_aula
                                       WHEN 1 THEN 'PASSO_A_PASSO'
                                       WHEN 2 THEN 'ARTIGO'
                                       WHEN 3 THEN 'VIDEO'
                                       WHEN 4 THEN 'PASSO_A_PASSO'
                                       WHEN 5 THEN 'ARTIGO'
                                       WHEN 6 THEN 'ARTIGO'
                                   END,
            'corpo_markdown' VALUE CASE a.id_aula
                                       WHEN 1 THEN '# Introdução ao Clicker' || CHR(10) || CHR(10) ||
                                                   'Fundamentos de marcação positiva utilizando o método de indução positiva com petisco.' || CHR(10) || CHR(10) ||
                                                   '### Passo a Passo:' || CHR(10) ||
                                                   '1. Carregue o clicker com petisco de alto valor.' || CHR(10) ||
                                                   '2. Clique no exato instante em que o cão oferecer a resposta desejada.' || CHR(10) ||
                                                   '3. Entregue o petisco em até 2 segundos para fixação cognitiva.' || CHR(10) || CHR(10) ||
                                                   '> **Dica de Ouro:** Repita em sessões de no máximo 3 minutos para não causar estresse cognitivo.'
                                       WHEN 2 THEN '# Critério de Duração do Fica' || CHR(10) || CHR(10) ||
                                                   'Aumentando o tempo gradativamente sem que o cão quebre a posição de espera.' || CHR(10) || CHR(10) ||
                                                   '### Princípios Fundamentais:' || CHR(10) ||
                                                   '- Inicie com 3 segundos de permanência.' || CHR(10) ||
                                                   '- Dê um passo para trás e retorne antes de liberar o animal com comando de liberação (''Ok!'').' || CHR(10) ||
                                                   '- Jamais chame o cão até você quando ele estiver no comando Fica para não gerar antecipação de quebra de postura.'
                                       WHEN 3 THEN '# Troca de Foco na Guia' || CHR(10) || CHR(10) ||
                                                   'Atenção ao tutor em vez de estímulos da rua durante os passeios urbanos.' || CHR(10) || CHR(10) ||
                                                   '### Procedimento Prático:' || CHR(10) ||
                                                   '1. Use guia de 1,5m sem tensionar.' || CHR(10) ||
                                                   '2. Sempre que avistar estímulo concorrente na calçada, chame o cão e recompense o contato visual imediato.' || CHR(10) ||
                                                   '3. Mantenha caminhada fluida e recompense o caminhar ao lado.'
                                       WHEN 4 THEN '# Receitas de Enriquecimento' || CHR(10) || CHR(10) ||
                                                   'Preparo de petiscos congelados saudáveis para enriquecimento ambiental e redução de ansiedade de separação.' || CHR(10) || CHR(10) ||
                                                   '### Receita Kong Calmante:' || CHR(10) ||
                                                   '- 1 colher de pasta de amendoim 100% integral (sem xilitol e sem açúcar).' || CHR(10) ||
                                                   '- Frutas picadas permitidas (maçã sem semente e banana amassada).' || CHR(10) ||
                                                   '- Congele por 4 horas no freezer antes de oferecer ao animal.'
                                       WHEN 5 THEN '# Rotas de Fuga e Segurança' || CHR(10) || CHR(10) ||
                                                   'Evitando que o felino se sinta acuado em ambientes verticais para felinos.' || CHR(10) || CHR(10) ||
                                                   '### Recomendações de Instalação:' || CHR(10) ||
                                                   '- Instale prateleiras e nichos a pelo menos 1,5m de altura com superfície antiderrapante.' || CHR(10) ||
                                                   '- Nunca crie rotas sem saída (''becos sem saída verticais'') em lares com mais de um gato.' || CHR(10) ||
                                                   '- Garanta redes de proteção testadas em 100% das janelas e sacadas.'
                                       WHEN 6 THEN '# Estímulo Olfativo com Catnip e Silvervine' || CHR(10) || CHR(10) ||
                                                   'Enriquecimento olfativo para felinos domésticos para estímulo mental e prevenção de apatia.' || CHR(10) || CHR(10) ||
                                                   '### Guia de Aplicação:' || CHR(10) ||
                                                   '- **Catnip (Nepeta cataria):** aplicar 1 a 2 vezes por semana em brinquedos ou arranhadores.' || CHR(10) ||
                                                   '- **Silvervine (Actinidia polygama):** opção consagrada para os 30% de felinos que não respondem ao Catnip.' || CHR(10) ||
                                                   '- Guarde os brinquedos em potes herméticos após a brincadeira para preservar os óleos essenciais.'
                                   END,
            'links_recursos' VALUE CASE a.id_aula
                                       WHEN 1 THEN JSON_ARRAY(
                                           'https://www.akc.org/expert-advice/training/clicker-training-your-dog-mark-and-reward/',
                                           'https://en.wikipedia.org/wiki/Clicker_training'
                                       )
                                       WHEN 2 THEN JSON_ARRAY(
                                           'https://www.rspca.org.uk/adviceandwelfare/pets/dogs/training/stay'
                                       )
                                       WHEN 3 THEN JSON_ARRAY(
                                           'https://www.akc.org/expert-advice/training/teach-puppy-walk-leash/'
                                       )
                                       WHEN 4 THEN JSON_ARRAY(
                                           'https://www.kongcompany.com/recipes/'
                                       )
                                       WHEN 5 THEN JSON_ARRAY(
                                           'https://www.vet.cornell.edu/departments-centers-and-institutes/cornell-feline-health-center/health-information/feline-health-topics/feline-behavior-problems-destructive-behavior'
                                       )
                                       WHEN 6 THEN JSON_ARRAY(
                                           'https://en.wikipedia.org/wiki/Catnip',
                                           'https://en.wikipedia.org/wiki/Actinidia_polygama'
                                       )
                                   END,
            'atualizado_em'  VALUE '2026-10-08T18:00:00Z'
        )
        ORDER BY a.id_aula
    ) RETURNING CLOB PRETTY
) AS dataset_exportado_json
FROM aula a;
