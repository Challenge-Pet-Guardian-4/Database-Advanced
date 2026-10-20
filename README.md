# Database-Advanced — 🐾 PetGuardian
> Engenharia de Banco de Dados Relacional em 3FN, Empacotamento de Processos em Packages (`PKG_PETGUARDIAN`), Rotinas de Exportação NoSQL, Persistência Poliglota com MongoDB Atlas e Governança do Care Circle — Challenge Clyvo 2026 — Turma 2TDSPG.

---

## 👥 Integrantes

| Nome | RM | Turma | GitHub | LinkedIn |
| :--- | :---: | :---: | :--- | :--- |
| **Enzo Okuizumi** | **561432** | 2TDSPG | [EnzoOkuizumiFiap](https://github.com/EnzoOkuizumiFiap) | [Enzo Okuizumi](https://www.linkedin.com/in/enzo-okuizumi-b60292256/) |
| **Gustavo Okada** | **563428** | 2TDSPG | [Gdev3356](https://github.com/Gdev3356) | [Gustavo Okada](https://www.linkedin.com/in/gustavo-okada-53a3b8359/) |
| **Lucas Barros Gouveia** | **566422** | 2TDSPG | [LuzBGouveia](https://github.com/LuzBGouveia) | [Lucas Barros Gouveia](https://www.linkedin.com/in/lucas-barros-gouveia-09b147355/) |
| **Luna de Carvalho Guimarães** | **562290** | 2TDSPG | [lunaguima](https://github.com/lunaguima) | [Luna M. Guimarães](https://www.linkedin.com/in/luna-m-guimar%C3%A3es-1850ab173/) |
| **Milton Marcelino** | **564836** | 2TDSPG | [MiltonMarcelino](https://github.com/MiltonMarcelino) | [Milton Marcelino](http://linkedin.com/in/milton-marcelino-250298142) |

---

## 🔗 Links Oficiais de Entrega

* **Repositório GitHub:** [https://github.com/Challenge-Pet-Guardian-4/Database-Advanced](https://github.com/Challenge-Pet-Guardian-4/Database-Advanced)
* **Documentação Técnica PDF:** [`Documentação Database Advanced Sprint 4 - Pet Guardian.pdf`](./docs/Documenta%C3%A7%C3%A3o%20Database%20Advanced%20Sprint%204%20-%20Pet%20Guardian.pdf)
* **Script SQL Relacional (DDL 3FN + Carga de Dados):** [`2TDSPG_2026_CodigoSql_PetGuardian.sql`](./2TDSPG_2026_CodigoSql_PetGuardian.sql)
* **Script de Empacotamento PL/SQL (Packages Isoladas):** [`sprint4_pkg_petguardian.sql`](./sprint4_pkg_petguardian.sql)
* **Script de Exportação JSON (Oracle 19c):** [`exportar_dataset_conteudos.sql`](./exportar_dataset_conteudos.sql)
* **Script NoSQL JavaScript (MongoDB Shell / Compass):** [`setup_mongodb_conteudos.js`](./setup_mongodb_conteudos.js)
* **Dataset de Conteúdos JSON:** [`conteudos_dataset.json`](./conteudos_dataset.json)
* **Vídeo Demonstrativo da Execução (YouTube):** *[Link do YouTube a ser anexado]*

---

## 🎯 Rastreabilidade dos Requisitos da Sprint 4

| Requisito | Descrição Oficial da Sprint 4 | Peso | Onde Encontrar | Status |
| :--- | :--- | :---: | :--- | :---: |
| **1. Modelo Relacional Normalizado** | Modelo 3FN coerente com a proposta de valor Clyvo, sem redundâncias e com integridade referencial estrita. | 10 pts | Diagramas em `docs/` e tabelas no [`2TDSPG_2026_CodigoSql_PetGuardian.sql`](./2TDSPG_2026_CodigoSql_PetGuardian.sql) | Concluído |
| **2. Empacotamento de Processos (Packages)** | Todas as procedures e functions organizadas em pacotes PL/SQL, com controle de transação e tratamento de exceções. | 30 pts | [`sprint4_pkg_petguardian.sql`](./sprint4_pkg_petguardian.sql) | Concluído |
| **3. Exportação do Dataset JSON** | Script SQL Oracle 19c e dataset estruturado em JSON pronto para carga NoSQL. | 20 pts | [`exportar_dataset_conteudos.sql`](./exportar_dataset_conteudos.sql) e [`conteudos_dataset.json`](./conteudos_dataset.json) | Concluído |
| **4. Estrutura e Carga no MongoDB** | Código MongoDB com criação de coleção, validação de schema (`$jsonSchema`), índices e ingestão do dataset. | 30 pts | [`setup_mongodb_conteudos.js`](./setup_mongodb_conteudos.js) | Concluído |
| **5. Vídeo Demonstrativo** | Vídeo explicando o funcionamento das packages e a estrutura do MongoDB. | 10 pts | Link no README (YouTube) | Em gravação |

---

## 📐 Modelagem Lógica e Relacional do Banco de Dados

### Modelo Lógico
![Modelo Lógico](docs/Logical.png)

### Modelo Relacional (Físico)
![Modelo Relacional](docs/Relational.png)

---

## 💡 Contexto da Solução e Decisões de Engenharia

Seguindo as diretrizes estratégicas da **Mentoria Clyvo 2026**, o ecossistema de dados foi desenhado com base em princípios sólidos de engenharia de software e banco de dados:

1. **Descontinuação do Modelo Clínico Legado:** Foram eliminadas as tabelas legadas de prontuário veterinário comercial (`veterinario`, `clinica`, `atendimento`, `tipo_atend`), concentrando o domínio na **governança preventiva familiar e na rotina diária**.
2. **O Animal no Centro do Domínio (`PET`):** O indivíduo animal é a entidade central. Tarefas, histórico preventivo, trilhas educativas e pontuação convergem para ele.
3. **Care Circle Familiar (`USUARIO_PET`):** Modelagem N:M entre tutores e pets com identificador explícito de tutor titular (`respon_princ = 1`), permitindo cotutela familiar e compartilhamento de rotina.
4. **Índice Condicional de Titularidade Única:** Garantia física no banco de dados de que cada pet possui no máximo **um** tutor principal ativo:
   ```sql
   CREATE UNIQUE INDEX uq_usuario_pet_principal ON usuario_pet (CASE WHEN respon_princ = 1 THEN pet_id_pet END);
   ```
5. **Gamificação da Rotina (`TAREFA` e `STATUS`):** Tarefas com pontuação de bem-estar e máquina de estados canônica (`PENDENTE`, `CONCLUIDO`, `EXPIRADO`).
6. **Gamificação Educativa (`TRILHA`, `MODULO`, `AULA`):** Trilhas de adestramento e enriquecimento ambiental vinculadas ao perfil de espécie e porte do pet.
7. **Normalização Territorial 3FN (`ENDERECO`, `BAIRRO`, `CIDADE`, `ESTADO`, `TELEFONE`):** Estrutura normalizada sem repetição de cidades ou estados.
8. **Persistência Poliglota Desacoplada:** O banco relacional Oracle mantém os metadados de progresso e pontuação das aulas (`AULA`), enquanto os conteúdos ricos e pesados em Markdown (com vídeos e PDFs) residem no MongoDB (`conteudos_aula`).

---

## 📖 Dicionário de Dados Oficial (15 Tabelas + Auditoria)

### 1. `USUARIO`
Armazena os tutores, cuidadores e administradores da plataforma.
* `id_usuario` (`NUMBER(3)`, PK): Identificador único do usuário.
* `nome` (`VARCHAR2(100)`): Nome completo do usuário.
* `email` (`VARCHAR2(50)`, UN): E-mail corporativo/pessoal único no sistema.
* `senha` (`VARCHAR2(60)`): Hash criptográfico BCrypt da senha de acesso.
* `role` (`VARCHAR2(10)`, CK): Perfil de acesso (`'ADMIN'`, `'COMUM'` ou `'PREMIUM'`).
* `telefone_id_telefone` (`NUMBER(3)`, FK, UN): Vínculo 1:1 com a tabela `telefone`.
* `endereco_id_endereco` (`NUMBER(3)`, FK): Vínculo com a tabela `endereco` (1:N).

### 2. `TELEFONE`
Contatos telefônicos associados aos usuários do sistema.
* `id_telefone` (`NUMBER(3)`, PK): Identificador único do telefone.
* `num_ddd` (`VARCHAR2(2)`): Código DDD de discagem (ex: `'11'`).
* `num_tel` (`VARCHAR2(9)`): Número do telefone com até 9 dígitos.

### 3. `PET` (Entidade Nuclear)
Armazena os animais gerenciados pela plataforma PetGuardian.
* `id_pet` (`NUMBER(3)`, PK): Identificador único do pet.
* `nome` (`VARCHAR2(30)`): Nome do pet.
* `data_nasc` (`DATE`): Data de nascimento para cálculo dinâmico de idade.
* `sexo` (`VARCHAR2(1)`, CK): Sexo do pet (`'F'` ou `'M'`).
* `porte` (`VARCHAR2(10)`, CK): Porte do pet (`'GRANDE'`, `'MEDIO'` ou `'PEQUENO'`).
* `castrado` (`NUMBER`, CK): Indicador binário de castração (`1` = Sim, `0` = Não).
* `raca_id_raca` (`NUMBER(3)`, FK): Referência para o catálogo de raças.

### 4. `USUARIO_PET` (Care Circle N:M)
Tabela associativa que formaliza a rede de cotutela sobre cada animal.
* `usuario_id_usuario` (`NUMBER(3)`, PK, FK): Referência ao usuário tutor.
* `pet_id_pet` (`NUMBER(3)`, PK, FK): Referência ao pet tutelado.
* `respon_princ` (`NUMBER`, CK): `1` se for o tutor titular principal, `0` se for co-cuidador.

### 5. `RACA`
Catálogo de raças caninas e felinas.
* `id_raca` (`NUMBER(3)`, PK): Identificador único da raça.
* `nome_raca` (`VARCHAR2(30)`): Nome descritivo da raça (ex: `'Golden Retriever'`).

### 6. `TAREFA` (Tabela de Fatos da Rotina)
Fatos transacionais de alimentação, medicação, passeios e cuidados de saúde.
* `id_tarefa` (`NUMBER(3)`, PK): Identificador único da tarefa.
* `titulo` (`VARCHAR2(30)`): Título descritivo da tarefa.
* `pontos_tarefa` (`NUMBER(3)`): Pontos de bem-estar creditados ao concluir a tarefa.
* `descricao` (`VARCHAR2(200)`): Orientações operacionais de execução.
* `criacao` (`TIMESTAMP`): Data/hora de agendamento da tarefa.
* `prazo` (`TIMESTAMP`): Data/hora limite de execução.
* `conclusao` (`TIMESTAMP`, NULL): Data/hora real de conclusão.
* `pet_id_pet` (`NUMBER(3)`, FK): Pet beneficiado pela tarefa.
* `status_id_status` (`NUMBER(3)`, FK): Status atual de controle.
* `usuario_id_usuario` (`NUMBER(3)`, FK): Cuidador responsável pela execução.

### 7. `STATUS` (Domínio Fechado / State Machine)
Domínio canônico de estados do ciclo de vida das tarefas.
* `id_status` (`NUMBER(3)`, PK): Identificador do status.
* `nome_status` (`VARCHAR2(15)`, CK): Restrição canônica: `'PENDENTE'` (1), `'CONCLUIDO'` (2), `'EXPIRADO'` (3).

### 8. `TRILHA`
Trilhas temáticas de educação, adestramento e enriquecimento ambiental.
* `id_trilha` (`NUMBER(5)`, PK): Identificador único da trilha.
* `nome` (`VARCHAR2(30)`): Nome da trilha temática.
* `descricao` (`VARCHAR2(200)`): Detalhamento dos objetivos pedagógicos.
* `pet_id_pet` (`NUMBER(3)`, FK): Pet associado ao plano educativo.

### 9. `MODULO`
Módulos que segmentam o conteúdo programático de uma trilha.
* `id_modulo` (`NUMBER(5)`, PK): Identificador único do módulo.
* `nome` (`VARCHAR2(50)`): Título do módulo pedagógico.
* `tempo_conclusao` (`VARCHAR2(10)`): Estimativa de tempo (ex: `'45 min'`).
* `descricao` (`VARCHAR2(100)`): Resumo dos tópicos abordados.
* `trilha_id_trilha` (`NUMBER(5)`, FK): Referência para a trilha pai.

### 10. `AULA` (Relacional)
Aulas práticas com pontuação educativa e acompanhamento de progresso.
* `id_aula` (`NUMBER(5)`, PK): Identificador único da aula.
* `nome` (`VARCHAR2(50)`): Título da lição.
* `descricao` (`VARCHAR2(100)`): Descrição curta do objetivo.
* `pontos_aula` (`NUMBER(5)`): Pontuação concedida ao pet/tutor ao concluir.
* `dificuldade` (`VARCHAR2(20)`): Nível de dificuldade (`INICIANTE`, `INTERMEDIARIO`, `AVANCADO`).
* `concluida` (`NUMBER`, CK): `1` se concluída, `0` se pendente.
* `modulo_id_modulo` (`NUMBER(5)`, FK): Referência para o módulo pai.

### 11. `HISTORICO`
Prontuário de eventos de saúde e intervenções preventivas do animal.
* `id_hist` (`NUMBER(3)`, PK): Identificador do evento histórico.
* `tipo_hist` (`VARCHAR2(30)`): Categoria do evento (Vacina, Check-up, Limpeza de Tártaro).
* `data_hist` (`TIMESTAMP`): Data e hora exata do evento de saúde.
* `pet_id_pet` (`NUMBER(3)`, FK): Pet vinculado ao histórico.

### 12. `ENDERECO`
Logradouros físicos normalizados vinculados diretamente aos usuários (1:N).
* `id_endereco` (`NUMBER(3)`, PK): Identificador único do endereço.
* `cep` (`VARCHAR2(8)`): Código postal de 8 posições.
* `rua` (`VARCHAR2(150)`): Nome do logradouro.
* `numero` (`VARCHAR2(5)`): Número predial.
* `bairro_id_bairro` (`NUMBER(3)`, FK): Referência para a tabela `bairro`.

### 13. `BAIRRO`
Divisão territorial urbana (3FN).
* `id_bairro` (`NUMBER(3)`, PK): Identificador único do bairro.
* `nome_bairro` (`VARCHAR2(30)`): Nome descritivo do bairro.
* `cidade_id_cidade` (`NUMBER(3)`, FK): Referência para a tabela `cidade`.

### 14. `CIDADE`
Municípios cadastrados (3FN).
* `id_cidade` (`NUMBER(3)`, PK): Identificador único da cidade.
* `nome_cidade` (`VARCHAR2(30)`): Nome do município.
* `estado_id_estado` (`NUMBER(3)`, FK): Referência para a tabela `estado`.

### 15. `ESTADO`
Unidades Federativas brasileiras (3FN).
* `id_estado` (`NUMBER(3)`, PK): Identificador único do estado.
* `nome_estado` (`VARCHAR2(30)`): Nome por extenso do estado.

### 16. `AUDITORIA_DML_TAREFA`
Estrutura dedicada à rastreabilidade transacional da tabela de fatos `TAREFA`.
* `id_auditoria` (`NUMBER`, PK): Identificador sequencial (`IDENTITY`).
* `nome_usuario` (`VARCHAR2(50)`): Usuário de banco de dados conectado (`USER`).
* `tipo_operacao` (`VARCHAR2(10)`): Operação disparada: `'INSERT'`, `'UPDATE'` ou `'DELETE'`.
* `data_hora_operacao` (`TIMESTAMP`): Timestamp da transação (`SYSTIMESTAMP`).
* `valores_anteriores` (`VARCHAR2(4000)`, NULL): Estado completo dos campos `:OLD`.
* `valores_novos` (`VARCHAR2(4000)`, NULL): Estado completo dos campos `:NEW`.

---

## ⚡ Índices Secundários e Performance (14 Índices + 1 Condicional)

Para mitigar **table locks em operações DML concorrentes**, otimizar planos de execução em `JOIN`s relacionais e acelerar filtros de agregação de dashboards, foram implementados:

| Nome do Índice | Tabela Alvo | Colunas Indexadas | Finalidade Técnica |
| :--- | :--- | :--- | :--- |
| `idx_cidade_estado` | `CIDADE` | `estado_id_estado` | Previne table lock na FK de Estado |
| `idx_bairro_cidade` | `BAIRRO` | `cidade_id_cidade` | Previne table lock na FK de Cidade |
| `idx_endereco_bairro` | `ENDERECO` | `bairro_id_bairro` | Previne table lock na FK de Bairro |
| `idx_usuario_endereco` | `USUARIO` | `endereco_id_endereco` | Otimiza busca de endereço do tutor |
| `idx_pet_raca` | `PET` | `raca_id_raca` | Acelera filtragem por raça/espécie |
| `idx_usuario_pet_pet` | `USUARIO_PET` | `pet_id_pet` | Otimiza listagem reversa do Care Circle |
| `idx_tarefa_pet` | `TAREFA` | `pet_id_pet` | Acelera cálculo de score e tarefas do pet |
| `idx_tarefa_status` | `TAREFA` | `status_id_status` | Otimiza relatórios de tarefas por status |
| `idx_tarefa_usuario` | `TAREFA` | `usuario_id_usuario` | Acelera listagem de tarefas por cuidador |
| `idx_tarefa_status_prazo`| `TAREFA` | `(status_id_status, prazo)` | Otimiza job de expiração e contagem pendente |
| `idx_trilha_pet` | `TRILHA` | `pet_id_pet` | Otimiza navegação de trilhas ativas do pet |
| `idx_modulo_trilha` | `MODULO` | `trilha_id_trilha` | Previne table lock na hierarquia de módulos |
| `idx_aula_modulo` | `AULA` | `modulo_id_modulo` | Previne table lock na listagem de aulas |
| `idx_historico_pet` | `HISTORICO` | `pet_id_pet` | Acelera busca de prontuário clínico |
| **`uq_usuario_pet_principal`** | **`USUARIO_PET`** | `(CASE WHEN respon_princ = 1 THEN pet_id_pet END)` | **Garante unicidade estrita do titular principal** |

---

## 📦 Empacotamento de Processos PL/SQL: `PKG_PETGUARDIAN`

Conforme os requisitos da **Sprint 4**, todas as rotinas procedurais estão encapsuladas no pacote corporativo **`PKG_PETGUARDIAN`**:

### Seção 1: Pontuação Gamificada de Pets e Tutores (Score de Bem-Estar)
* **`pr_calcular_pontuacao_pet` (Procedure):**  
  Calcula os pontos consolidados de tarefas e aulas concluídas do pet individual.  
  *Consumo Java/App:* `GET /pets/{id}/pontos`
* **`pr_calcular_pontuacao_usuario` (Procedure):**  
  Calcula a pontuação agregada de todos os pets sob tutela do usuário autenticado.
* **`pr_obter_resumo_rede_cuidado` (Procedure):**  
  Gera o relatório consolidado da rede de cuidado do usuário em uma única chamada: total de pets, total de cuidadores, tarefas pendentes, tarefas concluídas e pontos acumulados.  
  *Consumo Java/App:* `GET /usuarios/me/rede-cuidado`
* **`fn_obter_nivel_usuario` (Function):**  
  Classifica o nível de gamificação do tutor com base no XP acumulado:
  * `0` a `50 pts`  ➜ **`BRONZE`**
  * `51` a `150 pts` ➜ **`PRATA`**
  * `151+ pts`       ➜ **`OURO`**

### Seção 2: Operações Transacionais do Care Circle
* **`pr_transferir_responsavel_principal` (Procedure):**  
  Transação atômica que garante a transferência de titularidade sobre o pet sem permitir estados intermediários inconsistentes ou múltiplos titulares, utilizando atualização condicional em instrução única.  
  *Consumo Java/App:* `PATCH /pets/{id}/responsavel-principal`

### Seção 3: Auditoria DML em Tabela
* **`trg_audit_tarefa` (Trigger):**  
  Trigger de linha (`FOR EACH ROW`) disparada automaticamente após `INSERT`, `UPDATE` ou `DELETE` na tabela `TAREFA`. Registra o usuário Oracle (`USER`), tipo de operação, data/hora e serialização completa de `:OLD` e `:NEW` na tabela `AUDITORIA_DML_TAREFA`.

### Tabela de Tratamento de Exceções Padronizadas

| Código ORA | Identificador PL/SQL | Descrição / Causa Raiz |
| :---: | :--- | :--- |
| `-20018` | `e_id_invalido` | Identificador nulo, negativo ou zerado passado como argumento. |
| `-20019` | `e_pet_inexistente` | Pet não localizado na base relacional para o ID informado. |
| `-20020` | Genérico Pet Score | Falha inesperada durante a agregação de pontos do pet. |
| `-20022` | `e_usuario_inexistente` | Usuário não localizado na base relacional para o ID informado. |
| `-20023` | Genérico User Score | Falha inesperada durante a agregação de pontos do usuário. |
| `-20024` | Genérico Care Circle | Falha inesperada ao consolidar métricas da rede de cuidado. |
| `-20041` | `e_vinculo_inexistente` | Novo responsável não possui vínculo prévio com o animal em `USUARIO_PET`. |
| `-20042` | Genérico Transferência | Erro durante a transferência de responsabilidade principal. |

---

## 🍃 Persistência Poliglota & Coleção MongoDB (`conteudos_aula`)

Para garantir alta performance e escalabilidade, o sistema adota arquitetura poliglota:
* **Oracle Database 19c:** Integridade relacional em 3FN, transações financeiras/cadastrais e gamificação de tarefas.
* **MongoDB Atlas NoSQL:** Armazenamento flexível e sem restrição de tamanho de conteúdos didáticos em formato Markdown com links multimídia (PDFs, vídeos).

### Schema do Documento NoSQL (`conteudos_aula`)

```json
{
  "_id": "ObjectId('...')",
  "aula_id": 1,
  "tipo_conteudo": "PASSO_A_PASSO",
  "corpo_markdown": "# Introdução ao Clicker\n\nFundamentos de marcação positiva...",
  "links_recursos": [
    "https://www.akc.org/expert-advice/training/clicker-training-your-dog-mark-and-reward/",
    "https://en.wikipedia.org/wiki/Clicker_training"
  ],
  "atualizado_em": "2026-10-08T18:00:00Z"
}
```

### Índices Criados no MongoDB
1. **`idx_aula_id_unique`** (`{ "aula_id": 1 }`, `unique: true`): Garante idempotência e unicidade lógica com a chave da aula no Oracle.
2. **`idx_busca_textual_conteudo`** (`{ "corpo_markdown": "text" }`): Permite buscas textuais rápidas por palavras-chave em todo o material pedagógico.
3. **`idx_tipo_conteudo`** (`{ "tipo_conteudo": 1 }`): Otimiza filtros por categoria (`ARTIGO`, `VIDEO`, `PASSO_A_PASSO`).

---

## 🚀 Guia Passo a Passo de Execução

### Opção 1: Execução no Oracle Database (SQL Developer / SQLcl / VS Code)

A execução no banco relacional é dividida em 2 passos modulares, respeitando a separação entre DDL/DML e objetos procedurais (Packages/Triggers):

1. **Passo 1 — Carga DDL e Sementes (Entregável 1):**
   * Abra e execute o arquivo [`2TDSPG_2026_CodigoSql_PetGuardian.sql`](./2TDSPG_2026_CodigoSql_PetGuardian.sql).
   * Ele remove objetos preexistentes (`DROP TABLE`), cria as 15 tabelas normalizadas em 3FN + tabela de auditoria, adiciona constraints, cria os 14 índices secundários + índice condicional e realiza a carga dos dados iniciais válidos com `COMMIT`.
2. **Passo 2 — Empacotamento PL/SQL e Testes (Entregável 2):**
   * Abra e execute o arquivo [`sprint4_pkg_petguardian.sql`](./sprint4_pkg_petguardian.sql).
   * Ele compila a especificação e o corpo do pacote **`PKG_PETGUARDIAN`**, compila a trigger de auditoria **`TRG_AUDIT_TAREFA`** e dispara a **Bateria de Testes de Integração (Testes 1 a 5)** com saída no `DBMS_OUTPUT` e rollback limpo.
3. **Passo 3 — Exportação do Dataset JSON (Entregável 3):**
   * Abra e execute o arquivo [`exportar_dataset_conteudos.sql`](./exportar_dataset_conteudos.sql).
   * Ele executa uma única consulta nativa SQL (`JSON_SERIALIZE` + `JSON_ARRAYAGG` + `JSON_OBJECT`) sobre a tabela relacional `AULA`, gerando no console exatamente a estrutura e os dados do arquivo [`conteudos_dataset.json`](./conteudos_dataset.json).

---

### Opção 2: Carga do MongoDB via MongoDB Compass (Interface Gráfica)

1. Abra o **MongoDB Compass** e conecte-se ao cluster (Atlas ou local).
2. Na barra inferior da janela do Compass, clique na aba **`>_MONGOSH`**.
3. Copie todo o conteúdo do arquivo [`setup_mongodb_conteudos.js`](./setup_mongodb_conteudos.js), cole no terminal `mongosh` e pressione **Enter**.
4. Ou, se estiver na mesma pasta:
   ```javascript
   load("setup_mongodb_conteudos.js")
   ```
5. O console exibirá a criação da coleção com validação de schema, os índices criados e os 6 documentos inseridos.

---

### Opção 3: Carga do MongoDB via Linha de Comando (`mongosh`)

Execute no terminal:
```bash
mongosh "mongodb+srv://<usuario>:<senha>@cluster0.p7100.mongodb.net/petguardian" setup_mongodb_conteudos.js
```

---

## 🧪 Evidências de Teste da `PKG_PETGUARDIAN`

Ao executar o bloco de testes incluído no final de [`sprint4_pkg_petguardian.sql`](./sprint4_pkg_petguardian.sql), a saída obtida no `DBMS_OUTPUT` valida todos os cenários:

```text
=== TESTE 1: pr_calcular_pontuacao_pet ===
Thor (ID 1) -> Tarefas: 5 | Aulas: 120 | Total: 125

=== TESTE 2: pr_calcular_pontuacao_usuario e fn_obter_nivel_usuario ===
Carlos Silva (ID 1) -> Tarefas: 13 | Aulas: 120 | Total: 133
Nível de Gamificação (FUNCTION): PRATA

=== TESTE 3: pr_obter_resumo_rede_cuidado (Carlos Silva ID 1) ===
Carlos Silva (ID 1) -> Pets: 2 | Cuidadores: 1 | Tarefas Pendentes: 2 | Tarefas Concluídas: 2 | Pontos Acumulados: 133

=== TESTE 4: pr_transferir_responsavel_principal ===
Titularidade de Thor transferida com sucesso para Lucas Mendes (ID 5).

=== TESTE 5: Disparo da Trigger trg_audit_tarefa na Tabela TAREFA ===
Tarefa ID 2 atualizada com sucesso. Registro de auditoria gerado pela trigger:
ID_AUDITORIA: 1 | USUARIO: RM561432 | OPERACAO: UPDATE | VALORES_OLD: ID_TAREFA=2... | VALORES_NEW: ID_TAREFA=2; STATUS=2...
```
