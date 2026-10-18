# Database-Advanced — Diretrizes Arquiteturais & Especificação Técnica

> Documento de referência técnica para agentes de IA e engenheiros de software sobre o banco de dados relacional corporativo (Oracle Database 19c em 3FN), persistência NoSQL em nuvem (MongoDB Atlas), regras da package PL/SQL (`PKG_PETGUARDIAN`) e auditoria DML.

---

## 🏛️ 1. Arquitetura Poliglota & Persistência

A arquitetura de dados do ecossistema PetGuardian implementa persistência poliglota estrita, desacoplando o núcleo transacional ACID do armazenamento de conteúdo flexível e não-estruturado:

1. **Oracle Database 19c Enterprise (Relacional em 3FN):**
   - Governa entidades transacionais críticas, integridade referencial estrita, integridade de concorrência, regras do Care Circle, esteira de gamificação e trilha de auditoria DML.
   - Nomenclatura normalizada em `snake_case`, chaves primárias numéricas com sequence/identity e constraints declarativas (`NOT NULL`, `UNIQUE`, `CHECK`, `FOREIGN KEY`).
2. **MongoDB Atlas (NoSQL Documental em Nuvem):**
   - Coleção `conteudos_aula` responsável por armazenar conteúdos didáticos extensos em Markdown formatado, links multimídia dinâmicos e metadados de adestramento sem onerar o schema relacional.
3. **Descontinuação do Modelo Clínico Legado:**
   - Remoção de tabelas legadas hospitalares (`veterinario`, `clinica`, `atendimento`, `tipo_atend`), consolidando o foco na governança de rotina preventiva familiar e cotutela.

---

## 🧩 2. Dicionário Técnico de Dados (15 Tabelas em 3FN + Tabela de Auditoria)

### 2.1 Localização e Contatos (Normalização 3FN)

#### 1. `TELEFONE`
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `id_telefone` | `NUMBER(3)` | Não | PK | Identificador único do telefone. |
| `num_ddd` | `VARCHAR2(2)` | Não | - | Código DDD (ex: '11'). |
| `num_tel` | `VARCHAR2(9)` | Não | - | Número telefônico ou celular. |

#### 2. `ESTADO`
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `id_estado` | `NUMBER(3)` | Não | PK | Identificador único da unidade federativa. |
| `nome_estado` | `VARCHAR2(30)` | Não | - | Nome completo do estado (ex: 'São Paulo'). |

#### 3. `CIDADE`
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `id_cidade` | `NUMBER(3)` | Não | PK | Identificador único do município. |
| `nome_cidade` | `VARCHAR2(30)` | Não | - | Nome da cidade (ex: 'São Paulo'). |
| `estado_id_estado` | `NUMBER(3)` | Não | FK | Referência a `ESTADO(id_estado)`. |

#### 4. `BAIRRO`
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `id_bairro` | `NUMBER(3)` | Não | PK | Identificador único do bairro. |
| `nome_bairro` | `VARCHAR2(30)` | Não | - | Nome do bairro (ex: 'Bela Vista'). |
| `cidade_id_cidade` | `NUMBER(3)` | Não | FK | Referência a `CIDADE(id_cidade)`. |

#### 5. `ENDERECO`
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `id_endereco` | `NUMBER(3)` | Não | PK | Identificador único do logradouro. |
| `cep` | `VARCHAR2(8)` | Não | - | CEP numérico (8 dígitos sem hífen). |
| `rua` | `VARCHAR2(150)` | Não | - | Nome do logradouro / avenida / travessa. |
| `numero` | `VARCHAR2(5)` | Não | - | Número do imóvel. |
| `bairro_id_bairro` | `NUMBER(3)` | Não | FK | Referência a `BAIRRO(id_bairro)`. |

---

### 2.2 Usuários, Tutores e Controle de Acesso (RBAC)

#### 6. `USUARIO`
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `id_usuario` | `NUMBER(3)` | Não | PK | Identificador único do usuário. |
| `nome` | `VARCHAR2(100)` | Não | - | Nome completo do usuário. |
| `email` | `VARCHAR2(50)` | Não | UN | E-mail corporativo/pessoal único na base. |
| `senha` | `VARCHAR2(60)` | Não | - | Hash criptográfico BCrypt (60 caracteres). |
| `role` | `VARCHAR2(10)` | Não | - | `CHECK (role IN ('ADMIN', 'COMUM', 'PREMIUM'))`. |
| `telefone_id_telefone` | `NUMBER(3)` | Não | FK, UN | Vínculo 1:1 único com `TELEFONE(id_telefone)`. |
| `endereco_id_endereco` | `NUMBER(3)` | Não | FK | Vínculo N:1 com `ENDERECO(id_endereco)`. |

---

### 2.3 Núcleo do Animal e Governança Familiar (Care Circle)

#### 7. `RACA`
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `id_raca` | `NUMBER(3)` | Não | PK | Identificador único da raça. |
| `nome_raca` | `VARCHAR2(30)` | Não | - | Nome oficial da raça canina/felina. |

#### 8. `PET`
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `id_pet` | `NUMBER(3)` | Não | PK | Identificador único do animal. |
| `nome` | `VARCHAR2(30)` | Não | - | Nome de registro do pet. |
| `data_nasc` | `DATE` | Não | - | Data de nascimento para cálculo dinâmico de idade. |
| `sexo` | `VARCHAR2(1)` | Não | - | `CHECK (sexo IN ('F', 'M'))`. |
| `porte` | `VARCHAR2(10)` | Não | - | `CHECK (porte IN ('GRANDE', 'MEDIO', 'PEQUENO'))`. |
| `castrado` | `NUMBER` | Não | - | `CHECK (castrado IN (0, 1))`. |
| `raca_id_raca` | `NUMBER(3)` | Não | FK | Referência a `RACA(id_raca)`. |

#### 9. `USUARIO_PET` (Associação N:M / Care Circle)
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `usuario_id_usuario` | `NUMBER(3)` | Não | PK, FK | Referência a `USUARIO(id_usuario)`. |
| `pet_id_pet` | `NUMBER(3)` | Não | PK, FK | Referência a `PET(id_pet)`. |
| `respon_princ` | `NUMBER` | Não | - | `CHECK (respon_princ IN (0, 1))`. Flag de titularidade. |

---

### 2.4 Gamificação da Rotina e Cuidados Diários

#### 10. `STATUS` (Domínio de Tarefas)
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `id_status` | `NUMBER(3)` | Não | PK | 1 = PENDENTE, 2 = CONCLUIDO, 3 = EXPIRADO. |
| `nome_status` | `VARCHAR2(15)` | Não | - | `CHECK (nome_status IN ('CONCLUIDO', 'EXPIRADO', 'PENDENTE'))`. |

#### 11. `TAREFA` (Tabela de Fatos de Rotina)
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `id_tarefa` | `NUMBER(3)` | Não | PK | Identificador único da tarefa de cuidado. |
| `titulo` | `VARCHAR2(30)` | Não | - | Título conciso da rotina (ex: 'Ração da Manhã'). |
| `pontos_tarefa` | `NUMBER(3)` | Não | - | `CHECK (pontos_tarefa BETWEEN 0 AND 10)`. |
| `descricao` | `VARCHAR2(200)` | Não | - | Instruções detalhadas da atividade. |
| `criacao` | `TIMESTAMP` | Não | - | Timestamp de agendamento. |
| `prazo` | `TIMESTAMP` | Não | - | Prazo limite planejado para conclusão. |
| `conclusao` | `TIMESTAMP` | Sim | - | Timestamp real em que a tarefa foi finalizada. |
| `pet_id_pet` | `NUMBER(3)` | Não | FK | Referência a `PET(id_pet)`. |
| `status_id_status` | `NUMBER(3)` | Não | FK | Referência a `STATUS(id_status)`. |
| `usuario_id_usuario` | `NUMBER(3)` | Não | FK | Referência ao tutor executor em `USUARIO(id_usuario)`. |

---

### 2.5 Trilhas Educativas de Adestramento e Aulas

#### 12. `TRILHA`
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `id_trilha` | `NUMBER(5)` | Não | PK | Identificador único da trilha educativa. |
| `nome` | `VARCHAR2(30)` | Não | - | Nome da trilha (ex: 'Socialização Canina'). |
| `descricao` | `VARCHAR2(200)` | Não | - | Objetivo pedagógico da trilha. |
| `pet_id_pet` | `NUMBER(3)` | Não | FK | Vínculo direto com `PET(id_pet)`. |

#### 13. `MODULO`
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `id_modulo` | `NUMBER(5)` | Não | PK | Identificador único do módulo temático. |
| `nome` | `VARCHAR2(50)` | Não | - | Título do módulo. |
| `tempo_conclusao`| `VARCHAR2(10)` | Não | - | Estimativa média de duração (ex: '15 min'). |
| `descricao` | `VARCHAR2(100)` | Não | - | Resumo das lições abordadas. |
| `trilha_id_trilha`| `NUMBER(5)` | Não | FK | Referência a `TRILHA(id_trilha)`. |

#### 14. `AULA`
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `id_aula` | `NUMBER(5)` | Não | PK | Identificador relacional da aula (espelhado no NoSQL). |
| `nome` | `VARCHAR2(50)` | Não | - | Título da lição interativa. |
| `descricao` | `VARCHAR2(100)` | Não | - | Sinopse da aula. |
| `pontos_aula` | `NUMBER(5)` | Não | - | Pontos concedidos ao pet na conclusão da aula. |
| `dificuldade` | `VARCHAR2(20)` | Não | - | Grau pedagógico (ex: 'INICIANTE', 'AVANCADO'). |
| `concluida` | `NUMBER` | Não | - | `CHECK (concluida IN (0, 1))`. Flag de finalização. |
| `modulo_id_modulo`| `NUMBER(5)` | Não | FK | Referência a `MODULO(id_modulo)`. |

---

### 2.6 Prontuário e Histórico de Eventos

#### 15. `HISTORICO`
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `id_hist` | `NUMBER(3)` | Não | PK | Identificador do evento clínico / sanitário. |
| `tipo_hist` | `VARCHAR2(30)` | Não | - | Categoria (ex: 'VACINA', 'CONSULTA', 'PESAGEM'). |
| `data_hist` | `TIMESTAMP` | Não | - | Momento do registro. |
| `pet_id_pet` | `NUMBER(3)` | Não | FK | Referência a `PET(id_pet)`. |

---

### 2.7 Auditoria Técnica DML

#### 16. `AUDITORIA_DML_TAREFA`
| Coluna | Tipo | Nulo? | Chave | Descrição / Constraints |
| :--- | :--- | :---: | :---: | :--- |
| `id_auditoria` | `NUMBER` | Não | PK | `GENERATED ALWAYS AS IDENTITY`. |
| `nome_usuario` | `VARCHAR2(50)` | Não | - | Captura `USER` da sessão Oracle do pool JDBC. |
| `tipo_operacao` | `VARCHAR2(10)` | Não | - | 'INSERT', 'UPDATE' ou 'DELETE'. |
| `data_hora_operacao`| `TIMESTAMP` | Não | - | `DEFAULT SYSTIMESTAMP`. |
| `valores_anteriores`| `VARCHAR2(4000)`| Sim | - | String serializada de campos antes da alteração (:OLD). |
| `valores_novos` | `VARCHAR2(4000)`| Sim | - | String serializada de campos após a alteração (:NEW). |

---

## 👥 3. Care Circle: Governança do Responsável Principal

### 3.1 Integridade da Titularidade
A relação entre tutores e animais ocorre via cotutela na tabela `USUARIO_PET`. Para assegurar que exista **no máximo um responsável principal** (`respon_princ = 1`) por animal no banco sem restringir a existência de múltiplos co-cuidadores (`respon_princ = 0`), aplica-se a técnica de **Índice Único Condicional Baseado em Função**:

```sql
CREATE UNIQUE INDEX uq_usuario_pet_principal
ON usuario_pet (
    CASE 
        WHEN respon_princ = 1 THEN pet_id_pet 
    END
);
```

#### Fundamento Técnico:
No Oracle Database, chaves B-Tree não indexam entradas quando todos os termos da expressão resultam em `NULL`. Portanto:
- Linhas com `respon_princ = 0` avaliam para `NULL` e não geram colisão no índice.
- Linhas com `respon_princ = 1` avaliam para `pet_id_pet`. Uma tentativa de inserir um segundo responsável principal para o mesmo animal dispara violação imediata `ORA-00001: unique constraint violated`.

### 3.2 Por que rejeitar FK Composta em `TAREFA` para `USUARIO_PET`
A imposição de uma FK composta `(usuario_id_usuario, pet_id_pet)` diretamente na tabela `TAREFA` viola o isolamento em camadas do Spring Data JPA / Hibernate 7:
1. `Tarefa` no Java mapeia entidades de primeira classe `@ManyToOne Usuario` e `@ManyToOne Pet`. Uma FK composta forçaria o mapeamento de uma entidade associativa complexa `@ManyToOne UsuarioPet`, quebrando DTOs, mappers de domínio e repositórios.
2. A validação do vínculo de autorização é governada na fronteira de confiança (Trust Boundary) da camada de serviço pelo Spring Security via `@PreAuthorize` e `usuarioPetRepository.existsByUsuarioAndPet(...)`.

---

## 📦 4. Especificação Técnica da Package PL/SQL: `PKG_PETGUARDIAN`

O pacote corporativo `PKG_PETGUARDIAN` centraliza regras de negócio analíticas, cálculos agregados de gamificação e mutações transacionais atômicas.

```
┌────────────────────────────────────────────────────────┐
│                   PKG_PETGUARDIAN                      │
├────────────────────────────────────────────────────────┤
│ + pr_calcular_pontuacao_pet(pet_id, out...)           │
│ + pr_calcular_pontuacao_usuario(user_id, out...)       │
│ + pr_obter_resumo_rede_cuidado(user_id, out...)        │
│ + fn_obter_nivel_usuario(user_id) : VARCHAR2           │
│ + pr_transferir_responsavel_principal(pet_id, user_id) │
└────────────────────────────────────────────────────────┘
```

### 4.1 Constantes de Exceção Padronizadas
| Identificador | Código ORA | Significado Técnico |
| :--- | :---: | :--- |
| `e_id_invalido` | `-20018` | Identificador nulo, negativo ou zerado fornecido na chamada. |
| `e_pet_inexistente` | `-20019` | Pet com o identificador informado não existe na tabela `PET`. |
| `e_usuario_inexistente` | `-20022` | Usuário com o identificador informado não existe em `USUARIO`. |
| `e_vinculo_inexistente` | `-20041` | Usuário indicado não pertence ao Care Circle do animal em `USUARIO_PET`. |

---

### 4.2 Detalhamento das Rotinas

#### 1. `pr_calcular_pontuacao_pet`
- **Assinatura:**
  ```sql
  PROCEDURE pr_calcular_pontuacao_pet (
      p_id_pet         IN  NUMBER,
      p_pontos_tarefas OUT NUMBER,
      p_pontos_aulas   OUT NUMBER,
      p_pontos_totais  OUT NUMBER
  );
  ```
- **Comportamento & Regras:**
  1. Valida `p_id_pet` contra nulo/não-positivo (`-20018`) e checa existência na tabela `PET` (`-20019`).
  2. Executa `SUM(t.pontos_tarefa)` filtrando `t.pet_id_pet = p_id_pet` e status concluído (`status_id_status = 2`).
  3. Executa `SUM(a.pontos_aula)` unindo `AULA` -> `MODULO` -> `TRILHA` onde `tr.pet_id_pet = p_id_pet` e `a.concluida = 1`.
  4. Retorna subtotais e a soma aritmética total em `p_pontos_totais`.

#### 2. `pr_calcular_pontuacao_usuario`
- **Assinatura:**
  ```sql
  PROCEDURE pr_calcular_pontuacao_usuario (
      p_id_usuario     IN  NUMBER,
      p_pontos_tarefas OUT NUMBER,
      p_pontos_aulas   OUT NUMBER,
      p_pontos_totais  OUT NUMBER
  );
  ```
- **Comportamento & Regras:**
  1. Valida `p_id_usuario` e existência em `USUARIO` (`-20022`).
  2. Soma pontos de tarefas e aulas de **todos os pets** sob tutela do usuário, utilizando `IN (SELECT up.pet_id_pet FROM usuario_pet up WHERE up.usuario_id_usuario = p_id_usuario)`.
  3. O uso de subquery com `IN` assegura que um animal com múltiplos cuidadores seja computado uma única vez na agregação daquele tutor.

#### 3. `pr_obter_resumo_rede_cuidado`
- **Assinatura:**
  ```sql
  PROCEDURE pr_obter_resumo_rede_cuidado (
      p_id_usuario         IN  NUMBER,
      p_total_pets         OUT NUMBER,
      p_total_cuidadores   OUT NUMBER,
      p_tarefas_pendentes  OUT NUMBER,
      p_tarefas_concluidas OUT NUMBER,
      p_pontos_acumulados  OUT NUMBER
  );
  ```
- **Comportamento & Regras:**
  1. Retorna `p_total_pets`: contagem de pets distintos vinculados ao usuário em `USUARIO_PET`.
  2. Retorna `p_total_cuidadores`: contagem de co-cuidadores distintos que compartilham pelo menos um pet com o usuário.
  3. Agregação unificada com contadores condicionais:
     - `p_tarefas_pendentes`: `NVL(COUNT(CASE WHEN t.status_id_status = 1 THEN 1 END), 0)`.
     - `p_tarefas_concluidas`: `NVL(COUNT(CASE WHEN t.status_id_status = 2 THEN 1 END), 0)`.
  4. Encapsula chamada a `pr_calcular_pontuacao_usuario` para computar `p_pontos_acumulados`.

#### 4. `fn_obter_nivel_usuario`
- **Assinatura:**
  ```sql
  FUNCTION fn_obter_nivel_usuario (
      p_id_usuario IN NUMBER
  ) RETURN VARCHAR2;
  ```
- **Comportamento & Regras:**
  - Classifica a esteira de gamificação do tutor conforme os pontos acumulados em toda a sua rede de pets:
    - **`BRONZE`:** Total acumulado `<= 50`.
    - **`PRATA`:** Total acumulado `> 50` e `<= 150`.
    - **`OURO`:** Total acumulado `> 150`.
  - Integrada no endpoint Java `GET /usuarios/me` e exibida no perfil do tutor no app mobile.

#### 5. `pr_transferir_responsavel_principal`
- **Assinatura:**
  ```sql
  PROCEDURE pr_transferir_responsavel_principal (
      p_id_pet          IN NUMBER,
      p_novo_id_usuario IN NUMBER
  );
  ```
- **Comportamento & Regras:**
  1. Valida existência prévia do vínculo em `USUARIO_PET` (`-20041`).
  2. Executa transição atômica em instrução única:
     ```sql
     UPDATE usuario_pet
        SET respon_princ = CASE 
                               WHEN usuario_id_usuario = p_novo_id_usuario THEN 1 
                               ELSE 0 
                           END
      WHERE pet_id_pet = p_id_pet;
     ```
  3. Elimina estados intermediários sem responsável principal e evita locks de linha concorrentes. Não possui `COMMIT` interno, preservando a integridade transacional do Hibernate/Spring Data.

---

### 4.3 Decisão de Engenharia: Rejeição de `REF_CURSOR`
A adoção de `ParameterMode.REF_CURSOR` no Hibernate 7 / Spring Data JPA foi explicitamente rejeitada pelos seguintes fundamentos de estabilidade:
1. **Risco de Cursor Leak (`ORA-01000`):** Cursores abertos no PL/SQL dependem de fechamento determinístico pelo driver JDBC. Qualquer interrupção na conexão do pool HikariCP mantém o cursor aberto no Oracle, esgotando o limite de `OPEN_CURSORS`.
2. **Incompatibilidade com Chamadas Escalares Existentes:** Os endpoints de gamificação consomem tipos atômicos (`NUMBER` e `VARCHAR2`). Introduzir cursores exigiria deserialização manual de `ResultSet` no Java via `DbUtils` sem benefício funcional.
3. **Imutabilidade das Migrações Flyway:** As migrações `V1` a `V4` encontram-se aplicadas e com hashes protegidos no Oracle Cloud Database.

---

## 🛡️ 5. Trigger de Auditoria: `trg_audit_tarefa`

A trigger `trg_audit_tarefa` atua na auditoria técnica de operações DML sobre a tabela `TAREFA`:

```sql
CREATE OR REPLACE TRIGGER trg_audit_tarefa
AFTER INSERT OR UPDATE OR DELETE ON tarefa
FOR EACH ROW
...
```

- **Serialização de Estado:**
  - `valores_novos` (:NEW): `ID_TAREFA`, `TITULO`, `PONTOS`, `STATUS`, `PET`, `USUARIO`.
  - `valores_anteriores` (:OLD): `ID_TAREFA`, `TITULO`, `PONTOS`, `STATUS`, `PET`, `USUARIO`.
- **Identidade Registrada (`USER`):**
  - Armazena o schema Oracle autenticado na conexão do pool JDBC (ex: `RM550000`). Trata-se de uma auditoria de integridade física de banco de dados, complementando a segurança lógica aplicada pelo Spring Security.
- **Sincronismo Transacional:**
  - A execução ocorre no mesmo contexto da transação da aplicação. Se a operação de negócio for revertida pelo Spring Boot via rollback, o registro de auditoria correspondente é cancelado atomicamente.

---

## 🍃 6. Persistência NoSQL: MongoDB Atlas (`conteudos_aula`)

### 6.1 Estrutura e JSON Schema Validator
A coleção NoSQL `conteudos_aula` armazena o conteúdo didático das aulas interativas:

```javascript
dbTarget.createCollection("conteudos_aula", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["aula_id", "tipo_conteudo", "corpo_markdown"],
      properties: {
        aula_id: {
          bsonType: "int",
          description: "ID relacional da aula de origem no Oracle (inteiro obrigatório e único)."
        },
        tipo_conteudo: {
          bsonType: "string",
          description: "Formato pedagógico (ex: ARTIGO, VIDEO, PASSO_A_PASSO)."
        },
        corpo_markdown: {
          bsonType: "string",
          description: "Texto didático formatado em Markdown sem restrição de tamanho."
        },
        links_recursos: {
          bsonType: "array",
          items: { bsonType: "string" },
          description: "Lista de URLs para mídias externas e vídeos."
        },
        atualizado_em: {
          bsonType: ["string", "date"],
          description: "Timestamp ISO da última modificação."
        }
      }
    }
  }
});
```

### 6.2 Índices Estratégicos NoSQL
1. `idx_aula_id_unique`: `{ "aula_id": 1 }` com constraint `{ unique: true }` — Garante paridade 1:1 estrita com a tabela relacional `AULA`.
2. `idx_tipo_conteudo`: `{ "tipo_conteudo": 1 }` — Otimiza consultas por formato de mídia pedagógica.

---

## ⚡ 7. Estratégia de Índices Secundários (Oracle 19c)

Para prevenir Full Table Scans e mitigar contenção de locks em operações de DELETE/UPDATE nas entidades pai, foram declarados 14 índices secundários:

| Índice | Tabela Alvo | Colunas Indexadas | Finalidade Técnica |
| :--- | :--- | :--- | :--- |
| `idx_cidade_estado` | `CIDADE` | `estado_id_estado` | Otimização de junções geográficas. |
| `idx_bairro_cidade` | `BAIRRO` | `cidade_id_cidade` | Resolução rápida de endereços. |
| `idx_endereco_bairro` | `ENDERECO` | `bairro_id_bairro` | Performance de busca por CEP e bairro. |
| `idx_usuario_endereco` | `USUARIO` | `endereco_id_endereco` | Junção 1:N com endereço do tutor. |
| `idx_pet_raca` | `PET` | `raca_id_raca` | Filtragem por perfil de raça. |
| `idx_usuario_pet_pet` | `USUARIO_PET` | `pet_id_pet` | Busca reversa de cuidadores do animal. |
| `idx_tarefa_pet` | `TAREFA` | `pet_id_pet` | Agregação da rotina diária do pet. |
| `idx_tarefa_status` | `TAREFA` | `status_id_status` | Resolução do ciclo de vida da tarefa. |
| `idx_tarefa_usuario` | `TAREFA` | `usuario_id_usuario` | Listagem de tarefas por cuidador. |
| `idx_tarefa_status_prazo`| `TAREFA` | `status_id_status, prazo` | Índice composto para queries de tarefas pendentes ativas. |
| `idx_trilha_pet` | `TRILHA` | `pet_id_pet` | Carregamento de trilhas por animal. |
| `idx_modulo_trilha` | `MODULO` | `trilha_id_trilha` | Hierarquia trilha -> módulos. |
| `idx_aula_modulo` | `AULA` | `modulo_id_modulo` | Hierarquia módulo -> aulas. |
| `idx_historico_pet` | `HISTORICO` | `pet_id_pet` | Consultas cronológicas do prontuário. |

---

## 🔄 8. Sincronização com Migrações Flyway (Java-Advanced)

A rastreabilidade entre scripts DDL manuais e migrações versionadas do Spring Boot é rigorosamente 1:1:

| Script Database-Advanced | Migração Flyway (Java-Advanced) | Objeto Mapeado |
| :--- | :--- | :--- |
| `2TDSPG_2026_CodigoSql_PetGuardian.sql` | `V1__init_schema.sql` | 15 Tabelas em 3FN, PKs, FKs, Checks e Índices. |
| `2TDSPG_2026_CodigoSql_PetGuardian.sql` | `V2__seed_catalogo.sql` | Catálogo de status, raças e endereços base. |
| `2TDSPG_2026_CodigoSql_PetGuardian.sql` | `V3__seed_demo.sql` | Usuários de teste (ADMIN/COMUM/PREMIUM), pets e tarefas. |
| `sprint4_pkg_petguardian.sql` | `V4__pkg_petguardian.sql` | Package `PKG_PETGUARDIAN` e Trigger `trg_audit_tarefa`. |

> **Nota:** A coluna `pontos_tarefa` é uniformemente tratada como `NUMBER(3)` em todos os schemas e migrações, garantindo consistência estrita de dados em tempo de execução.
