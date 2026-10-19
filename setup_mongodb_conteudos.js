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
let datasetConteudos = [];

try {
  // Leitura dinâmica do arquivo exportado do banco relacional
  const fs = require("fs");
  const path = require("path");
  const caminhoJson = path.resolve(typeof __dirname !== "undefined" ? __dirname : ".", "conteudos_dataset.json");

  if (fs.existsSync(caminhoJson)) {
    const conteudoBruto = fs.readFileSync(caminhoJson, "utf8");
    const dadosParsed = JSON.parse(conteudoBruto);

    datasetConteudos = dadosParsed.map(item => ({
      ...item,
      aula_id: typeof NumberInt !== "undefined" ? NumberInt(item.aula_id) : item.aula_id,
      atualizado_em: item.atualizado_em || new Date().toISOString()
    }));
    log(">>> Sucesso: Dataset carregado dinamicamente a partir de 'conteudos_dataset.json' (" + datasetConteudos.length + " documentos).");
  } else {
    throw new Error("Arquivo 'conteudos_dataset.json' não encontrado no diretório.");
  }
} catch (erroCarregamento) {
  log(">>> Aviso: Leitura via sistema de arquivos indisponível no cliente (" + erroCarregamento.message + "). Utilizando dataset estruturado integrado.");
  
  datasetConteudos = [
    {
      aula_id: typeof NumberInt !== "undefined" ? NumberInt(1) : 1,
      tipo_conteudo: "PASSO_A_PASSO",
      corpo_markdown: "# Introdução ao Clicker\n\nFundamentos de marcação positiva utilizando o método de indução positiva com petisco.\n\n### Passo a Passo:\n1. Carregue o clicker com petisco de alto valor.\n2. Clique no exato instante em que o cão oferecer a resposta desejada.\n3. Entregue o petisco em até 2 segundos para fixação cognitiva.\n\n> **Dica de Ouro:** Repita em sessões de no máximo 3 minutos para não causar estresse cognitivo.",
      links_recursos: [
        "https://www.akc.org/expert-advice/training/clicker-training-your-dog-mark-and-reward/",
        "https://en.wikipedia.org/wiki/Clicker_training"
      ],
      atualizado_em: "2026-10-08T18:00:00Z"
    },
    {
      aula_id: typeof NumberInt !== "undefined" ? NumberInt(2) : 2,
      tipo_conteudo: "ARTIGO",
      corpo_markdown: "# Critério de Duração do Fica\n\nAumentando o tempo gradativamente sem que o cão quebre a posição de espera.\n\n### Princípios Fundamentais:\n- Inicie com 3 segundos de permanência.\n- Dê um passo para trás e retorne antes de liberar o animal com comando de liberação ('Ok!').\n- Jamais chame o cão até você quando ele estiver no comando Fica para não gerar antecipação de quebra de postura.",
      links_recursos: [
        "https://www.rspca.org.uk/adviceandwelfare/pets/dogs/training/stay"
      ],
      atualizado_em: "2026-10-08T18:00:00Z"
    },
    {
      aula_id: typeof NumberInt !== "undefined" ? NumberInt(3) : 3,
      tipo_conteudo: "VIDEO",
      corpo_markdown: "# Troca de Foco na Guia\n\nAtenção ao tutor em vez de estímulos da rua durante os passeios urbanos.\n\n### Procedimento Prático:\n1. Use guia de 1,5m sem tensionar.\n2. Sempre que avistar estímulo concorrente na calçada, chame o cão e recompense o contato visual imediato.\n3. Mantenha caminhada fluida e recompense o caminhar ao lado.",
      links_recursos: [
        "https://www.akc.org/expert-advice/training/teach-puppy-walk-leash/"
      ],
      atualizado_em: "2026-10-08T18:00:00Z"
    },
    {
      aula_id: typeof NumberInt !== "undefined" ? NumberInt(4) : 4,
      tipo_conteudo: "PASSO_A_PASSO",
      corpo_markdown: "# Receitas de Enriquecimento\n\nPreparo de petiscos congelados saudáveis para enriquecimento ambiental e redução de ansiedade de separação.\n\n### Receita Kong Calmante:\n- 1 colher de pasta de amendoim 100% integral (sem xilitol e sem açúcar).\n- Frutas picadas permitidas (maçã sem semente e banana amassada).\n- Congele por 4 horas no freezer antes de oferecer ao animal.",
      links_recursos: [
        "https://www.kongcompany.com/recipes/"
      ],
      atualizado_em: "2026-10-08T18:00:00Z"
    },
    {
      aula_id: typeof NumberInt !== "undefined" ? NumberInt(5) : 5,
      tipo_conteudo: "ARTIGO",
      corpo_markdown: "# Rotas de Fuga e Segurança\n\nEvitando que o felino se sinta acuado em ambientes verticais para felinos.\n\n### Recomendações de Instalação:\n- Instale prateleiras e nichos a pelo menos 1,5m de altura com superfície antiderrapante.\n- Nunca crie rotas sem saída ('becos sem saída verticais') em lares com mais de um gato.\n- Garanta redes de proteção testadas em 100% das janelas e sacadas.",
      links_recursos: [
        "https://www.vet.cornell.edu/departments-centers-and-institutes/cornell-feline-health-center/health-information/feline-health-topics/feline-behavior-problems-destructive-behavior"
      ],
      atualizado_em: "2026-10-08T18:00:00Z"
    },
    {
      aula_id: typeof NumberInt !== "undefined" ? NumberInt(6) : 6,
      tipo_conteudo: "ARTIGO",
      corpo_markdown: "# Estímulo Olfativo com Catnip e Silvervine\n\nEnriquecimento olfativo para felinos domésticos para estímulo mental e prevenção de apatia.\n\n### Guia de Aplicação:\n- **Catnip (Nepeta cataria):** aplicar 1 a 2 vezes por semana em brinquedos ou arranhadores.\n- **Silvervine (Actinidia polygama):** opção consagrada para os 30% de felinos que não respondem ao Catnip.\n- Guarde os brinquedos em potes herméticos após a brincadeira para preservar os óleos essenciais.",
      links_recursos: [
        "https://en.wikipedia.org/wiki/Catnip",
        "https://en.wikipedia.org/wiki/Actinidia_polygama"
      ],
      atualizado_em: "2026-10-08T18:00:00Z"
    }
  ];
}

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
