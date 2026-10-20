// ====================================================================
// CHALLENGE CLYVO 2026 — SPRINT 4
// DISCIPLINA: Mastering Relational and Non-Relational Database
// REQUISITO 4: Estrutura MongoDB — Coleção 'aulas' (Metadados Relacionais Exportados)
// TURMA: 2TDSPG
//
// COMO EXECUTAR:
// 1. No MongoDB Compass:
//    - Abra a aba inferior ">_MONGOSH" conectada ao seu cluster (Atlas ou Local).
//    - Copie e cole todo o conteúdo deste arquivo e pressione Enter.
//    - Ou execute: load("setup_mongodb_aulas.js")
// 2. Via Linha de Comando (mongosh):
//    mongosh "mongodb+srv://<usuario>:<senha>@cluster.mongodb.net/petguardian" setup_mongodb_aulas.js
// ====================================================================

const log = typeof console !== "undefined" && console.log ? console.log : print;

// 1. Seleciona o banco oficial da aplicação
const dbName = "petguardian";
const dbTarget = typeof db !== "undefined" && db.getSiblingDB ? db.getSiblingDB(dbName) : db;

log(">>> Conectado ao banco: " + dbName);

// 2. Remove coleção preexistente para recriação limpa e idempotente
try {
  dbTarget.aulas.drop();
  log(">>> Coleção antiga 'aulas' removida para recriação limpa.");
} catch (e) {
  // Ignora erro se a coleção ainda não existia
}

// 3. Criação da coleção 'aulas' com JSON Schema Validator
dbTarget.createCollection("aulas", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["id_aula", "nome", "descricao", "pontos_aula", "dificuldade", "concluida", "modulo_id_modulo"],
      properties: {
        id_aula: {
          bsonType: ["int", "long", "double"],
          description: "Identificador primário da aula de origem no Oracle (obrigatório e único)."
        },
        nome: {
          bsonType: "string",
          description: "Título da aula pedagógica."
        },
        descricao: {
          bsonType: "string",
          description: "Resumo pedagógico da aula."
        },
        pontos_aula: {
          bsonType: ["int", "long", "double"],
          description: "Pontuação atribuída ao pet após a conclusão da aula."
        },
        dificuldade: {
          bsonType: "string",
          description: "Nível de dificuldade (ex: INICIANTE, INTERMEDIARIO, AVANCADO)."
        },
        concluida: {
          bsonType: ["int", "long", "double", "bool"],
          description: "Flag de conclusão da aula (1 concluída, 0 pendente)."
        },
        modulo_id_modulo: {
          bsonType: ["int", "long", "double"],
          description: "ID do módulo relacional ao qual a aula pertence."
        }
      }
    }
  }
});
log(">>> Coleção 'aulas' criada com JSON Schema Validator.");

// 4. Criação de Índices Estratégicos
dbTarget.aulas.createIndex(
  { "id_aula": 1 },
  { unique: true, name: "idx_id_aula_unique" }
);

dbTarget.aulas.createIndex(
  { "modulo_id_modulo": 1 },
  { name: "idx_modulo_id_modulo" }
);

dbTarget.aulas.createIndex(
  { "dificuldade": 1 },
  { name: "idx_dificuldade" }
);

log(">>> Índices estratégicos criados para a coleção 'aulas'.");

// 5. Carga de Dados a partir de 'aulas_dataset.json' (sem fallbacks embutidos)
const fs = require("fs");
const path = require("path");
let caminhoJson = path.resolve(typeof __dirname !== "undefined" ? __dirname : ".", "aulas_dataset.json");
if (!fs.existsSync(caminhoJson)) {
  const caminhoAlternativo = path.resolve(typeof __dirname !== "undefined" ? __dirname : ".", "mongodb", "aulas_dataset.json");
  if (fs.existsSync(caminhoAlternativo)) {
    caminhoJson = caminhoAlternativo;
  }
}

if (!fs.existsSync(caminhoJson)) {
  throw new Error("ERRO CRÍTICO: Arquivo 'aulas_dataset.json' não encontrado no diretório: " + caminhoJson);
}

const conteudoBruto = fs.readFileSync(caminhoJson, "utf8");
const dadosParsed = JSON.parse(conteudoBruto);

const datasetAulas = dadosParsed.map(item => ({
  ...item,
  id_aula: typeof NumberInt !== "undefined" ? NumberInt(item.id_aula) : item.id_aula,
  pontos_aula: typeof NumberInt !== "undefined" ? NumberInt(item.pontos_aula) : item.pontos_aula,
  concluida: typeof NumberInt !== "undefined" ? NumberInt(item.concluida) : item.concluida,
  modulo_id_modulo: typeof NumberInt !== "undefined" ? NumberInt(item.modulo_id_modulo) : item.modulo_id_modulo
}));

const resultadoCarga = dbTarget.aulas.insertMany(datasetAulas);
log(">>> Carga executada! Documentos inseridos na coleção 'aulas': " + (resultadoCarga.insertedCount || Object.keys(resultadoCarga.insertedIds || {}).length));

// 6. Consulta de Verificação
log(">>> Consulta de teste (Aulas cadastradas):");
dbTarget.aulas.find({}, {
  id_aula: 1,
  nome: 1,
  pontos_aula: 1,
  dificuldade: 1,
  modulo_id_modulo: 1
}).forEach(doc => {
  log(" - Aula ID: " + doc.id_aula + " | Título: " + doc.nome + " | Pontos: " + doc.pontos_aula + " | Módulo: " + doc.modulo_id_modulo);
});
