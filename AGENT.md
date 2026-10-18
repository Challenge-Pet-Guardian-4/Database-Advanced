# Database-Advanced — Diretrizes Arquiteturais & Especificação Técnica

> Documento de referência técnica para agentes de IA e engenheiros sobre o banco de dados relacional (Oracle Database 19c em 3FN), persistência NoSQL (MongoDB Atlas) e empacotamento PL/SQL (`PKG_PETGUARDIAN`).

---

## 👥 Metadados do Projeto & Equipe FIAP (2TDSPG — Sprint 4)

- **Disciplina:** Database Advanced (Sprint 4 — Challenge Clyvo 2026)
- **Equipe:**
  - Enzo Okuizumi — RM 561432
  - Gustavo Okada — RM 563428
  - Lucas Barros Gouveia — RM 566422
  - Luna de Carvalho Guimarães — RM 562290
  - Milton Marcelino — RM 564836

---

## 🏛️ 1. Arquitetura Poliglota & Persistência

1. **Oracle Database 19c Enterprise (Relacional em 3FN):**
   - Modela entidades transacionais críticas, integridade referencial ACID estrita, regras de Care Circle, gamificação e auditoria DML.
   - Nomes normalizados em snake_case, chaves primárias numéricas com sequence/identity e constraints declarativas (`NOT NULL`, `UNIQUE`, `CHECK`, `FOREIGN KEY`).
2. **MongoDB Atlas (NoSQL Documental):**
   - Coleção `conteudos_aula` para conteúdos pedagógicos longos em Markdown formatado, links multimídia dinâmicos e metadados de adestramento sem poluir o schema relacional.
3. **Descontinuação do Modelo Clínico Legado:**
   - Remoção de tabelas legadas hospitalares (`veterinario`, `clinica`, `atendimento`) para priorizar a governança colaborativa familiar (Care Circle) e prevenção.

---

## 🧩 2. Modelagem Relacional (Schema Oracle 19c)

### Entidades Centrais e Governança Familiar
- **`USUARIO`:** Tutores e administradores (`id_usuario`, `nome`, `email` UNIQUE, `senha` BCrypt, `role` CHECK 'COMUM'/'PREMIUM'/'ADMIN', `telefone_id_telefone`, `endereco_id_endereco`).
- **`PET`:** O indivíduo central do sistema (`id_pet`, `nome`, `data_nasc`, `sexo` CHECK 'M'/'F', `porte` CHECK 'PEQUENO'/'MEDIO'/'GRANDE', `castrado` NUMBER(1), `raca_id_raca`).
- **`USUARIO_PET` (Care Circle):** Associação N:M entre tutor e animal com chave composta (`usuario_id_usuario`, `pet_id_pet`) e indicador de titularidade (`respon_princ` NUMBER(1)). É o grafo central de autorização do ecossistema.
- **`RACA`:** Catálogo de raças caninas e felinas (`id_raca`, `nome` UNIQUE).

### Gamificação da Rotina e Cuidados
- **`TAREFA`:** Atividades diárias de cuidado (`id_tarefa`, `nome`, `descricao`, `criacao`, `prazo`, `conclusao`, `pontos_tarefa` NUMBER(3), `pet_id_pet`, `usuario_id_usuario`, `status_id_status`).
- **`STATUS`:** Ciclo de vida das tarefas (`id_status`, `nome_status` CHECK 'PENDENTE'/'CONCLUIDO'/'EXPIRADO').

### Trilhas Educativas de Adestramento
- **`TRILHA`:** Trilhas temáticas vinculadas ao pet (`id_trilha`, `nome`, `descricao`, `icone`, `pet_id_pet`).
- **`MODULO`:** Etapas progressivas da trilha (`id_modulo`, `nome`, `ordem`, `trilha_id_trilha`).
- **`AULA`:** Unidades de aprendizado gamificadas (`id_aula`, `titulo`, `ordem`, `pontos_aula` NUMBER(3), `concluida` NUMBER(1), `modulo_id_modulo`).

### Localização Normalizada
- **`ENDERECO`**, **`BAIRRO`**, **`CIDADE`**, **`ESTADO`**, **`TELEFONE`**: Normalização 3FN completa com integridade referencial.

---

## 📦 3. Package PL/SQL: `PKG_PETGUARDIAN`

O pacote corporativo PL/SQL centraliza cálculos transacionais e regras de gamificação:

| Rotina | Tipo | Finalidade Técnica |
| :--- | :---: | :--- |
| `pr_transferir_responsavel_principal` | Procedure | Transfere a titularidade do pet no Care Circle atomicamente em um único UPDATE, promovendo o novo responsável e rebaixando os demais sem commit prematuro. |
| `pr_calcular_pontuacao_pet` | Procedure | Valida o pet e consolida os pontos de tarefas concluídas e aulas finalizadas associadas às trilhas do animal. |
| `pr_calcular_pontuacao_usuario` | Procedure | Agrega os pontos de bem-estar de todos os pets vinculados ao tutor no Care Circle. |
| `pr_obter_resumo_rede_cuidado` | Procedure | Retorna 5 métricas agregadas da rede: `p_total_pets`, `p_total_cuidadores`, `p_tarefas_pendentes`, `p_tarefas_concluidas`, `p_pontos_acumulados`. |
| `fn_obter_nivel_usuario` | Function | Classifica o tutor na esteira de gamificação ('BRONZE' <= 50, 'PRATA' <= 150, 'OURO' > 150) com base nos pontos agregados de sua rede. |

---

## 🛡️ 4. Auditoria DML: `trg_audit_tarefa`

- **Tabela:** `AUDITORIA_DML_TAREFA`
- **Operações:** `INSERT`, `UPDATE`, `DELETE` sobre a tabela `TAREFA`.
- **Campos Auditados:** `id_auditoria`, `operacao`, `id_tarefa`, `nome_tarefa_antigo`, `nome_tarefa_novo`, `status_antigo`, `status_novo`, `pontos_antigos`, `pontos_novos`, `data_hora`, `nome_usuario`.
- **Comportamento Transacional:** A auditoria opera no mesmo contexto transacional da operação DML. Caso a transação seja revertida pelo backend Java, os registros de auditoria também são revertidos atomicamente, mantendo a consistência do banco.

---

## ⚡ 5. Alinhamento com Migrações Flyway (Java-Advanced)

- O arquivo [`sprint4_pkg_petguardian.sql`](./sprint4_pkg_petguardian.sql) espelha com fidelidade a migração [`V4__pkg_petguardian.sql`](../Java-Advanced/src/main/resources/db/migration/V4__pkg_petguardian.sql).
- O DDL relacional em [`2TDSPG_2026_CodigoSql_PetGuardian.sql`](./2TDSPG_2026_CodigoSql_PetGuardian.sql) está perfeitamente alinhado com as migrações `V1__init_schema.sql`, `V2__seed_catalogo.sql` e `V3__seed_demo.sql`.
- A coluna `pontos_tarefa` é uniformemente tratada como `NUMBER(3)` em todo o ecossistema.
