// ====================================================================
// CHALLENGE CLYVO 2026 — SPRINT 4
// DISCIPLINA: Mastering Relational and Non-Relational Database
// REQUISITO 4: Estrutura MongoDB (Código de Criação, Validação e Índices)
// TURMA: 2TDSPG
// ====================================================================

// 1. Seleciona ou cria o banco de dados oficial da aplicação
const dbName = "petguardian";
const dbTarget = db.getSiblingDB(dbName);

print(">>> Conectado ao banco: " + dbName);

// 2. Remove coleção preexistente se necessário para execução limpa e repetível
dbTarget.conteudos_aula.drop();
print(">>> Coleção antiga 'conteudos_aula' removida para recriação limpa.");

// 3. Criação da Coleção com Validação de Schema (JSON Schema Validator)
// Garante integridade estrutural e tipagem dos documentos NoSQL
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
print(">>> Coleção 'conteudos_aula' criada com JSON Schema Validator.");

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

print(">>> Índices estratégicos criados com sucesso.");

// 5. Carga dos Dados a partir do Dataset Estruturado JSON (conteudos_dataset.json)
let datasetConteudos = [];

try {
  // Leitura dinâmica do arquivo exportado do banco relacional
  const fs = require("fs");
  const path = require("path");
  const caminhoJson = path.resolve(__dirname ? __dirname : ".", "conteudos_dataset.json");

  if (fs.existsSync(caminhoJson)) {
    const conteudoBruto = fs.readFileSync(caminhoJson, "utf8");
    const dadosParsed = JSON.parse(conteudoBruto);

    datasetConteudos = dadosParsed.map(item => ({
      ...item,
      aula_id: typeof NumberInt !== "undefined" ? NumberInt(item.aula_id) : item.aula_id,
      atualizado_em: item.atualizado_em || new Date().toISOString()
    }));
    print(">>> Sucesso: Dataset carregado dinamicamente a partir de 'conteudos_dataset.json' (" + datasetConteudos.length + " documentos).");
  } else {
    throw new Error("Arquivo 'conteudos_dataset.json' não encontrado no diretório.");
  }
} catch (erroCarregamento) {
  print(">>> Aviso: Leitura via sistema de arquivos indisponível no cliente (" + erroCarregamento.message + "). Utilizando dataset estruturado integrado.");
  
  datasetConteudos = [
    {
      aula_id: typeof NumberInt !== "undefined" ? NumberInt(1) : 1,
      tipo_conteudo: "PASSO_A_PASSO",
      corpo_markdown: "# Comando Sentar com Recompensa Positiva\n\nNesta aula prática, você aprenderá o método de indução positiva utilizando petisco de alto valor biológico para ensinar o comando sentar sem empurrar o pet.\n\n### Passo a Passo:\n1. Posicione o petisco a 1 cm do focinho do pet, permitindo que ele sinta o aroma.\n2. Mova sua mão lentamente em arco para cima e ligeiramente para trás da cabeça.\n3. O cão erguerá a cabeça e, por mecânica postural, baixará o quadril.\n4. No exato instante em que as ancas tocarem o chão, pronuncie a palavra-marcador: *'Muito bem!'* ou clique.\n5. Entregue o petisco imediatamente e libere com *'Ok!'*.\n\n> **Dica de Ouro:** Repita em sessões de no máximo 3 minutos para não causar estresse cognitivo.",
      links_recursos: [
        "https://materiais.petguardian.com.br/guias/reforco-positivo-iniciante.pdf",
        "https://storage.petguardian.com.br/videos/aula-01-comando-sentar.mp4"
      ],
      atualizado_em: new Date().toISOString()
    },
    {
      aula_id: typeof NumberInt !== "undefined" ? NumberInt(2) : 2,
      tipo_conteudo: "ARTIGO",
      corpo_markdown: "# Foco no Olhar e Chamado pelo Nome\n\nO nome do animal nunca deve ser associado a broncas ou punições. Esta aula ensina como criar valor reflexo ao chamado pelo nome em ambientes com estímulos concorrentes.\n\n### Princípios Fundamentais:\n- **Associação Pura:** Fale o nome uma única vez. Se o cão olhar nos seus olhos, recompense com festa e petisco.\n- **Distrações Progressivas:** Inicie em quarto fechado e silencioso. Avance para a sala, quintal e calçada gradualmente.\n- **Jamais repita em sequência rápida:** Evite falar *'Thor, Thor, Thor'*, pois isso dessensibiliza o cão ao som.",
      links_recursos: [
        "https://materiais.petguardian.com.br/guias/foco-atencao-canina.pdf"
      ],
      atualizado_em: new Date().toISOString()
    },
    {
      aula_id: typeof NumberInt !== "undefined" ? NumberInt(3) : 3,
      tipo_conteudo: "VIDEO",
      corpo_markdown: "# Apresentação Positiva da Guia e Peitoral\n\nMuitos cães travam ou fogem ao ver a guia. Esta aula aborda a dessensibilização sistemática do equipamento de passeio antes de pisar na rua.\n\n### Procedimento:\n1. Deixe o peitoral no chão próximo ao pote de comida por 2 dias.\n2. Vista o equipamento dentro de casa antes de oferecer a refeição principal.\n3. Deixe o pet se movimentar pela casa com o peitoral solto por 10 minutos.\n4. Retire o peitoral e encerre a interação.",
      links_recursos: [
        "https://storage.petguardian.com.br/videos/aula-03-dessensibilizacao-guia.mp4"
      ],
      atualizado_em: new Date().toISOString()
    },
    {
      aula_id: typeof NumberInt !== "undefined" ? NumberInt(4) : 4,
      tipo_conteudo: "PASSO_A_PASSO",
      corpo_markdown: "# Técnica da Árvore (Cão que Puxa a Guia)\n\nO cão puxa a guia porque aprendeu que a tração o leva para onde ele deseja ir. A Técnica da Árvore reverte esse aprendizado de forma passiva e sem trancos.\n\n### Regra Operacional:\n- Sempre que a guia tensionar, **pare imediatamente** e fique imóvel como um tronco de árvore.\n- Não puxe a guia para trás nem dê broncas verbais.\n- Espere o cão olhar para você ou dar um passo atrás, afrouxando a guia.\n- Assim que a guia afrouxar, avance o passo e elogie calmamente.",
      links_recursos: [
        "https://materiais.petguardian.com.br/guias/passeio-tranquilo.pdf"
      ],
      atualizado_em: new Date().toISOString()
    },
    {
      aula_id: typeof NumberInt !== "undefined" ? NumberInt(5) : 5,
      tipo_conteudo: "ARTIGO",
      corpo_markdown: "# Verticalização e Território Seguro para Felinos\n\nGatos são predadores e presas ao mesmo tempo. A ausência de rotas de fuga verticais gera estresse crônico e agressividade territorial em ambientes fechados.\n\n### Recomendações de Instalação:\n- Prateleiras com superfície antiderrapante a pelo menos 1,5m de altura.\n- Nunca crie rotas sem saída ('becos sem saída verticais') em lares com mais de um gato.\n- Posicione nichos próximos a janelas com rede de proteção para enriquecimento visual externo.",
      links_recursos: [
        "https://materiais.petguardian.com.br/guias/gatificacao-apartamentos.pdf"
      ],
      atualizado_em: new Date().toISOString()
    },
    {
      aula_id: typeof NumberInt !== "undefined" ? NumberInt(6) : 6,
      tipo_conteudo: "ARTIGO",
      corpo_markdown: "# Estímulo Olfativo com Catnip e Silvervine\n\nO enriquecimento olfativo ativa centros de recompensa neurológica em gatos domésticos, prevenindo apatia e obesidade.\n\n### Guia de Aplicação:\n- **Catnip (Nepeta cataria):** Oferecer 1 a 2 vezes por semana por 15 minutos.\n- **Silvervine (Actinidia polygama):** Excelente alternativa para os 30% de felinos imunes aos efeitos do Catnip.\n- Guarde os brinquedos impregnados em recipientes herméticos após o uso para não saturar os receptores olfativos.",
      links_recursos: [
        "https://materiais.petguardian.com.br/guias/aromaterapia-felina-segura.pdf"
      ],
      atualizado_em: new Date().toISOString()
    }
  ];
}

const resultadoCarga = dbTarget.conteudos_aula.insertMany(datasetConteudos);
print(">>> Carga executada! Documentos inseridos com sucesso: " + resultadoCarga.insertedCount);

// 6. Consulta de Verificação com Projeção
print(">>> Consulta de teste (Conteúdos cadastrados):");
dbTarget.conteudos_aula.find({}, {
  aula_id: 1,
  tipo_conteudo: 1,
  atualizado_em: 1
}).forEach(doc => {
  print(" - Aula ID: " + doc.aula_id + " | Formato: " + doc.tipo_conteudo);
});
