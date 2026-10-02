// ====================================================================
// CHALLENGE CLYVO 2026 — SPRINT 4
// DISCIPLINA: Mastering Relational and Non-Relational Database
// REQUISITO 4: Estrutura MongoDB (Código de Criação, Validação e Índices)
// TURMA: 2TDSPG
// ====================================================================

// 1. Seleciona ou cria o banco de dados oficial da aplicação
const dbName = "petguardian_nosql";
const dbTarget = db.getSiblingDB(dbName);

print(">>> Conectado ao banco: " + dbName);

// 2. Remove coleção preexistente se necessário para execução limpa e repetível
dbTarget.trilhas_educativas.drop();
print(">>> Coleção antiga 'trilhas_educativas' removida para recriação limpa.");

// 3. Criação da Coleção com Validação de Schema (JSON Schema Validator)
// Garante integridade estrutural e tipagem dos documentos NoSQL
dbTarget.createCollection("trilhas_educativas", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["trilha_id_origem", "nome", "descricao", "categoria", "modulos"],
      properties: {
        trilha_id_origem: {
          bsonType: "int",
          description: "ID relacional da trilha de origem (inteiro obrigatório para sincronização)."
        },
        nome: {
          bsonType: "string",
          description: "Nome da trilha educacional (string obrigatória)."
        },
        descricao: {
          bsonType: "string",
          description: "Descrição pedagógica dos objetivos da trilha."
        },
        categoria: {
          bsonType: "string",
          description: "Categoria da trilha (COMPORTAMENTO, SAUDE, ADJESTRAMENTO, etc.)."
        },
        pet_alvo: {
          bsonType: "object",
          description: "Dados desnormalizados do pet vinculado para evitar joins de visualização."
        },
        modulos: {
          bsonType: "array",
          description: "Array de subdocumentos embutidos representando os módulos da trilha.",
          items: {
            bsonType: "object",
            required: ["modulo_id", "titulo", "aulas"],
            properties: {
              modulo_id: { bsonType: "int" },
              titulo: { bsonType: "string" },
              tempo_estimado: { bsonType: "string" },
              descricao: { bsonType: "string" },
              aulas: {
                bsonType: "array",
                description: "Array de subdocumentos embutidos representando as aulas práticas.",
                items: {
                  bsonType: "object",
                  required: ["aula_id", "titulo", "pontos_aula", "concluida"],
                  properties: {
                    aula_id: { bsonType: "int" },
                    titulo: { bsonType: "string" },
                    descricao: { bsonType: "string" },
                    pontos_aula: { bsonType: "int" },
                    dificuldade: { bsonType: "string" },
                    concluida: { bsonType: "bool" },
                    conteudo: { bsonType: "string" }
                  }
                }
              }
            }
          }
        },
        criado_em: {
          bsonType: ["string", "date"],
          description: "Data/hora ISO de criação do documento."
        }
      }
    }
  }
});
print(">>> Coleção 'trilhas_educativas' criada com JSON Schema Validator.");

// 4. Criação de Índices Estratégicos para Otimização de Consultas (NoSQL Performance)

// Índice 1: Unicidade no ID de origem do Oracle (idempotência de carga/upsert)
dbTarget.trilhas_educativas.createIndex(
  { "trilha_id_origem": 1 },
  { unique: true, name: "idx_trilha_origem_unique" }
);

// Índice 2: Busca por categoria e pet alvo (filtros comuns no app mobile)
dbTarget.trilhas_educativas.createIndex(
  { "categoria": 1, "pet_alvo.pet_id": 1 },
  { name: "idx_categoria_pet" }
);

// Índice 3: Multikey index para consulta direta por status de conclusão das aulas embutidas
dbTarget.trilhas_educativas.createIndex(
  { "modulos.aulas.concluida": 1 },
  { name: "idx_aulas_concluida_multikey" }
);

// Índice 4: Índice Textual para mecanismo de busca rápida por termos no app mobile
dbTarget.trilhas_educativas.createIndex(
  { "nome": "text", "descricao": "text", "modulos.titulo": "text" },
  { name: "idx_busca_textual_trilhas" }
);

print(">>> 4 Índices estratégicos criados com sucesso.");

// 5. Carga Inicial dos Dados a partir do Dataset embutido
const datasetTrilhas = [
  {
    trilha_id_origem: NumberInt(1),
    nome: "Socialização Básica de Filhotes",
    descricao: "Trilha prática para condicionamento de filhotes e convivência harmoniosa em família",
    categoria: "COMPORTAMENTO",
    pet_alvo: {
      pet_id: NumberInt(1),
      nome: "Thor",
      porte: "MEDIO"
    },
    modulos: [
      {
        modulo_id: NumberInt(1),
        titulo: "Primeiros Passos e Comandos Básicos",
        tempo_estimado: "45 min",
        descricao: "Introdução aos comandos essenciais de obediência e vínculo com o tutor",
        aulas: [
          {
            aula_id: NumberInt(1),
            titulo: "Comando Sentar com Recompensa",
            descricao: "Técnica de indução positiva utilizando petisco de alto valor",
            pontos_aula: NumberInt(20),
            dificuldade: "INICIANTE",
            concluida: true,
            conteudo: "Segure o petisco próximo ao focinho do pet e mova-o suavemente para trás da cabeça. Quando a parte traseira tocar o chão, diga 'Senta', elogie com entusiasmo e entregue o petisco."
          },
          {
            aula_id: NumberInt(2),
            titulo: "Foco no Olhar e Chamado pelo Nome",
            descricao: "Exercício de atenção para ambientes com muitas distrações",
            pontos_aula: NumberInt(25),
            dificuldade: "INICIANTE",
            concluida: true,
            conteudo: "Chame o nome do pet em tom alegre. Assim que ele fizer contato visual direto, marque o comportamento com 'Muito bem!' e recompense imediatamente."
          }
        ]
      },
      {
        modulo_id: NumberInt(2),
        titulo: "Passeio Tranquilo sem Puxar a Guia",
        tempo_estimado: "60 min",
        descricao: "Como acostumar o cão à guia e coleira sem estresse ou tensão",
        aulas: [
          {
            aula_id: NumberInt(3),
            titulo: "Apresentação Positiva da Guia",
            descricao: "Associação da guia e peitoral com momentos prazerosos em casa",
            pontos_aula: NumberInt(30),
            dificuldade: "INTERMEDIARIO",
            concluida: false,
            conteudo: "Coloque o peitoral no pet dentro de casa por 10 minutos antes da refeição, criando associação imediata com coisas boas."
          },
          {
            aula_id: NumberInt(4),
            titulo: "Técnica da Árvore (Parar ao Puxar)",
            descricao: "Ensinar o cão que puxar a guia interrompe o passeio",
            pontos_aula: NumberInt(35),
            dificuldade: "INTERMEDIARIO",
            concluida: false,
            conteudo: "Sempre que o pet tensionar a guia durante o passeio, pare imediatamente e permaneça imóvel como uma árvore. Só retome o passo quando a guia afrouxar."
          }
        ]
      }
    ],
    criado_em: new Date().toISOString()
  },
  {
    trilha_id_origem: NumberInt(2),
    nome: "Enriquecimento Ambiental para Felinos",
    descricao: "Rotina de estímulos sensoriais, cognitivos e físicos para gatos de apartamento",
    categoria: "BEM_ESTAR_FELINO",
    pet_alvo: {
      pet_id: NumberInt(2),
      nome: "Mel",
      porte: "PEQUENO"
    },
    modulos: [
      {
        modulo_id: NumberInt(3),
        titulo: "Verticalização e Território Seguro",
        tempo_estimado: "30 min",
        descricao: "Otimização de prateleiras, arranhadores e nichos suspensos",
        aulas: [
          {
            aula_id: NumberInt(5),
            titulo: "Instalação da Rota de Fuga Vertical",
            descricao: "Criação de rotas aéreas para descanso e sensação de segurança",
            pontos_aula: NumberInt(25),
            dificuldade: "INICIANTE",
            concluida: true,
            conteudo: "Posicione nichos a pelo menos 1,5 metro de altura próximos a janelas teladas, permitindo a observação segura do ambiente externo."
          },
          {
            aula_id: NumberInt(6),
            titulo: "Estímulo Olfativo com Catnip e Silvervine",
            descricao: "Como alternar ervas relaxantes para evitar tédio e estresse",
            pontos_aula: NumberInt(20),
            dificuldade: "INICIANTE",
            concluida: false,
            conteudo: "Ofereça brinquedos com catnip em dias alternados por 15 minutos para manter o interesse olfativo ativo sem saturação de receptores."
          }
        ]
      }
    ],
    criado_em: new Date().toISOString()
  }
];

const resultadoCarga = dbTarget.trilhas_educativas.insertMany(datasetTrilhas);
print(">>> Carga executada! Documentos inseridos com sucesso: " + resultadoCarga.insertedCount);

// 6. Consulta de Verificação com Projeção e Agregação
print(">>> Consulta de teste (Trilhas e quantidade de módulos/aulas):");
dbTarget.trilhas_educativas.find({}, {
  nome: 1,
  categoria: 1,
  "pet_alvo.nome": 1,
  "modulos.titulo": 1
}).forEach(doc => {
  print(" - Trilha: " + doc.nome + " | Categoria: " + doc.categoria + " | Pet: " + doc.pet_alvo.nome);
});
