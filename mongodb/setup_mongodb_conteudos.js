// ====================================================================
// CHALLENGE CLYVO 2026 — SPRINT 4
// DISCIPLINA: Mastering Relational and Non-Relational Database
// REQUISITO 4: Estrutura MongoDB (Código de Criação, Validação e Índices)
// TURMA: 2TDSPG
//
// COMO EXECUTAR:
// 1. No MongoDB Compass:
//    - Abra a aba inferior ">_MONGOSH" conectada ao seu cluster (Atlas ou Local).
//    - Copie e cole todo o conteúdo deste arquivo e pressione Enter.
//    - Ou execute: load("setup_mongodb_conteudos.js")
// 2. Via Linha de Comando (mongosh):
//    mongosh "mongodb+srv://<usuario>:<senha>@cluster.mongodb.net/petguardian" setup_mongodb_conteudos.js
// ====================================================================

// Função de log universal (compatível com mongosh, mongo shell e Node.js)
const log = typeof console !== "undefined" && console.log ? console.log : print;

// 1. Seleciona ou cria o banco de dados oficial da aplicação
const dbName = "petguardian";
const dbTarget = typeof db !== "undefined" && db.getSiblingDB ? db.getSiblingDB(dbName) : db;

log(">>> Conectado ao banco: " + dbName);

// 2. Remove coleção preexistente se necessário para execução limpa e repetível
try {
  dbTarget.conteudos_aula.drop();
  log(">>> Coleção antiga 'conteudos_aula' removida para recriação limpa.");
} catch (e) {
  // Ignora erro se a coleção ainda não existia
}

// 3. Criação da Coleção com Validação de Schema (JSON Schema Validator)
// Garante integridade estrutural e tipagem dos documentos NoSQL
dbTarget.createCollection("conteudos_aula", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["aula_id", "tipo_conteudo", "corpo_markdown"],
      properties: {
        aula_id: {
          bsonType: ["int", "long", "string"],
          description: "ID relacional da aula de origem no Oracle (inteiro/long ou GUID string obrigatório e único)."
        },
        tipo_conteudo: {
          bsonType: "string",
          description: "Classificação do formato pedagógico (ex: ARTIGO, VIDEO, PASSO_A_PASSO)."
        },
        corpo_markdown: {
          bsonType: "string",
          description: "Conteúdo rico formatado em Markdown, sem restrição de tamanho."
        },
        links_recursos: {
          bsonType: "array",
          description: "Lista de URLs para materiais complementares e vídeos de apoio.",
          items: {
            bsonType: "string"
          }
        },
        atualizado_em: {
          bsonType: ["string", "date"],
          description: "Data/hora ISO da última revisão do conteúdo."
        }
      }
    }
  }
});
log(">>> Coleção 'conteudos_aula' criada com JSON Schema Validator.");

// 4. Criação de Índices Estratégicos para Otimização NoSQL
// Índice 1: Unicidade no ID da aula relacional (idempotência e integridade lógica)
dbTarget.conteudos_aula.createIndex(
  { "aula_id": 1 },
  { unique: true, name: "idx_aula_id_unique" }
);

// Índice 2: Índice Textual para buscas por palavras-chave dentro do conteúdo pedagógico
dbTarget.conteudos_aula.createIndex(
  { "corpo_markdown": "text" },
  { name: "idx_busca_textual_conteudo" }
);

// Índice 3: Índice de filtro por formato de conteúdo
dbTarget.conteudos_aula.createIndex(
  { "tipo_conteudo": 1 },
  { name: "idx_tipo_conteudo" }
);

log(">>> Índices estratégicos criados com sucesso.");

// 5. Carga dos Dados a partir do Dataset Estruturado JSON (conteudos_dataset.json)
const fs = require("fs");
const path = require("path");
let caminhoJson = path.resolve(typeof __dirname !== "undefined" ? __dirname : ".", "conteudos_dataset.json");
if (!fs.existsSync(caminhoJson)) {
  const caminhoAlternativo = path.resolve(typeof __dirname !== "undefined" ? __dirname : ".", "mongodb", "conteudos_dataset.json");
  if (fs.existsSync(caminhoAlternativo)) {
    caminhoJson = caminhoAlternativo;
  }
}

if (!fs.existsSync(caminhoJson)) {
  throw new Error("ERRO CRÍTICO: Arquivo 'conteudos_dataset.json' não encontrado no diretório: " + caminhoJson);
}

const conteudoBruto = fs.readFileSync(caminhoJson, "utf8");
const dadosParsed = JSON.parse(conteudoBruto);

const datasetConteudos = dadosParsed.map(item => ({
  ...item,
  aula_id: typeof NumberInt !== "undefined" ? NumberInt(item.aula_id) : item.aula_id,
  atualizado_em: item.atualizado_em || new Date().toISOString()
}));
log(">>> Sucesso: Dataset carregado dinamicamente a partir de 'conteudos_dataset.json' (" + datasetConteudos.length + " documentos).");

const resultadoCarga = dbTarget.conteudos_aula.insertMany(datasetConteudos);
log(">>> Carga executada! Documentos inseridos com sucesso: " + (resultadoCarga.insertedCount || Object.keys(resultadoCarga.insertedIds || {}).length));

// 6. Consulta de Verificação com Projeção
log(">>> Consulta de teste (Conteúdos cadastrados):");
dbTarget.conteudos_aula.find({}, {
  aula_id: 1,
  tipo_conteudo: 1,
  atualizado_em: 1
}).forEach(doc => {
  log(" - Aula ID: " + doc.aula_id + " | Formato: " + doc.tipo_conteudo);
});
