/// Curated catalog of official and popular Ollama registry models.
class LibraryModel {
  const LibraryModel({
    required this.name,
    required this.description,
    required this.category,
    required this.publisher,
    required this.sizes,
    required this.defaultTag,
    this.isPopular = false,
  });

  final String name;
  final String description;
  final String category; // 'Reasoning', 'Coding', 'Vision', 'General', 'Embedding'
  final String publisher;
  final List<String> sizes;
  final String defaultTag;
  final bool isPopular;

  bool get isVision => category == 'Vision';
  bool get isEmbedding => category == 'Embedding';
  bool get isReasoning => category == 'Reasoning';
  bool get isCoding => category == 'Coding';

  /// Returns the complete registry tag for a specific size variant.
  String tagForSize(String size) => '$name:$size';
}

/// Helper function to match a raw user input or tag to a curated [LibraryModel].
LibraryModel? findLibraryModel(String? input) {
  if (input == null) return null;
  final clean = input.trim().toLowerCase();
  if (clean.isEmpty) return null;
  final baseName = clean.split(':').first;

  for (final m in ollamaModelCatalog) {
    if (m.name.toLowerCase() == baseName || m.name.toLowerCase() == clean) {
      return m;
    }
  }
  return null;
}

/// Catalog of curated Ollama models with weight variants.
const List<LibraryModel> ollamaModelCatalog = [
  // ---------------------------------------------------------------------------
  // Reasoning
  // ---------------------------------------------------------------------------
  LibraryModel(
    name: 'deepseek-r1',
    description: 'Open reasoning model trained via reinforcement learning. Excels at complex math, coding, and logical reasoning.',
    category: 'Reasoning',
    publisher: 'DeepSeek',
    sizes: ['1.5b', '7b', '8b', '14b', '32b', '70b'],
    defaultTag: 'deepseek-r1:7b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'qwq',
    description: 'Qwen reasoning model designed for deep mathematical and programming problem solving.',
    category: 'Reasoning',
    publisher: 'Alibaba Cloud',
    sizes: ['32b'],
    defaultTag: 'qwq:32b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'phi4',
    description: 'Microsoft state-of-the-art 14B model with a strong emphasis on synthetic reasoning benchmarks.',
    category: 'Reasoning',
    publisher: 'Microsoft',
    sizes: ['14b'],
    defaultTag: 'phi4:14b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'marco-o1',
    description: 'Reasoning model from Alibaba International focusing on fine-grained chain-of-thought and multilingual search.',
    category: 'Reasoning',
    publisher: 'Alibaba Cloud',
    sizes: ['7b'],
    defaultTag: 'marco-o1:7b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'smallthinker',
    description: 'High-capability 3B reasoning model trained on synthetic chain-of-thought data for efficient logical deduction.',
    category: 'Reasoning',
    publisher: 'Cognitive Computations',
    sizes: ['3b'],
    defaultTag: 'smallthinker:3b',
  ),
  LibraryModel(
    name: 'qwen2.5-math',
    description: 'Specialized mathematical problem solving model with chain-of-thought and tool-integrated reasoning.',
    category: 'Reasoning',
    publisher: 'Alibaba Cloud',
    sizes: ['1.5b', '7b', '72b'],
    defaultTag: 'qwen2.5-math:7b',
  ),

  // ---------------------------------------------------------------------------
  // Coding
  // ---------------------------------------------------------------------------
  LibraryModel(
    name: 'qwen3-coder',
    description: 'Next-generation code generation and repository-level refactoring model from the Qwen3 series.',
    category: 'Coding',
    publisher: 'Alibaba Cloud',
    sizes: ['0.6b', '1.7b', '4b', '8b', '14b', '32b'],
    defaultTag: 'qwen3-coder:8b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'qwen2.5-coder',
    description: 'Specialized code generation, debugging, and multi-file reasoning model trained on 5.5T code tokens.',
    category: 'Coding',
    publisher: 'Alibaba Cloud',
    sizes: ['0.5b', '1.5b', '3b', '7b', '14b', '32b'],
    defaultTag: 'qwen2.5-coder:7b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'codestral',
    description: 'Mistral AI 22B open-weight generative model tailored for 80+ programming languages and fill-in-the-middle.',
    category: 'Coding',
    publisher: 'Mistral AI',
    sizes: ['22b'],
    defaultTag: 'codestral:22b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'deepseek-coder-v2',
    description: 'Mixture-of-Experts code language model with performance rivaling GPT-4 Turbo on coding benchmarks.',
    category: 'Coding',
    publisher: 'DeepSeek',
    sizes: ['16b', '236b'],
    defaultTag: 'deepseek-coder-v2:16b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'granite-code',
    description: 'IBM open-source enterprise foundation model for code intelligence, bug patching, and modernization.',
    category: 'Coding',
    publisher: 'IBM',
    sizes: ['3b', '8b', '20b', '34b'],
    defaultTag: 'granite-code:8b',
  ),
  LibraryModel(
    name: 'codellama',
    description: 'Meta code synthesis and infilling model supporting Python, C++, Java, PHP, and TypeScript.',
    category: 'Coding',
    publisher: 'Meta',
    sizes: ['7b', '13b', '34b', '70b'],
    defaultTag: 'codellama:7b',
  ),
  LibraryModel(
    name: 'starcoder2',
    description: 'BigCode open-access model trained on 600+ programming languages from Software Heritage.',
    category: 'Coding',
    publisher: 'BigCode',
    sizes: ['3b', '7b', '15b'],
    defaultTag: 'starcoder2:7b',
  ),
  LibraryModel(
    name: 'codegemma',
    description: 'Google family of lightweight, powerful models tailored for code completion and code synthesis.',
    category: 'Coding',
    publisher: 'Google',
    sizes: ['2b', '7b'],
    defaultTag: 'codegemma:7b',
  ),

  // ---------------------------------------------------------------------------
  // Vision
  // ---------------------------------------------------------------------------
  LibraryModel(
    name: 'llama3.2-vision',
    description: 'Meta instruction-tuned multimodal model capable of visual reasoning, OCR, and document chart analysis.',
    category: 'Vision',
    publisher: 'Meta',
    sizes: ['11b', '90b'],
    defaultTag: 'llama3.2-vision:11b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'qwen2-vl',
    description: 'Alibaba vision-language model with dynamic resolution support, video comprehension, and multilingual OCR.',
    category: 'Vision',
    publisher: 'Alibaba Cloud',
    sizes: ['2b', '7b', '72b'],
    defaultTag: 'qwen2-vl:7b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'llava',
    description: 'Large Language and Vision Assistant fine-tuned for conversational multi-turn image interrogation.',
    category: 'Vision',
    publisher: 'LLaVA Team',
    sizes: ['7b', '13b', '34b'],
    defaultTag: 'llava:7b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'llava-phi3',
    description: 'Lightweight 3.8B vision-language model combining Microsoft Phi-3 Mini with LLaVA visual architecture.',
    category: 'Vision',
    publisher: 'Microsoft / LLaVA',
    sizes: ['3.8b'],
    defaultTag: 'llava-phi3:3.8b',
  ),
  LibraryModel(
    name: 'minicpm-v',
    description: 'Compact visual-language model with strong OCR and high-resolution perception capabilities.',
    category: 'Vision',
    publisher: 'OpenBMB',
    sizes: ['8b'],
    defaultTag: 'minicpm-v:8b',
  ),
  LibraryModel(
    name: 'moondream',
    description: 'Tiny 1.8B parameter vision language model designed to run smoothly on edge hardware.',
    category: 'Vision',
    publisher: 'Vikhyat',
    sizes: ['1.8b'],
    defaultTag: 'moondream:1.8b',
  ),
  LibraryModel(
    name: 'bakllava',
    description: 'Multimodal vision model combining Mistral 7B architecture with LLaVA visual architecture.',
    category: 'Vision',
    publisher: 'Skunkworks',
    sizes: ['7b'],
    defaultTag: 'bakllava:7b',
  ),

  // ---------------------------------------------------------------------------
  // General LLMs
  // ---------------------------------------------------------------------------
  LibraryModel(
    name: 'qwen3',
    description: 'Next-generation Alibaba Cloud foundation model with enhanced reasoning, coding, math, and multilingual abilities.',
    category: 'General',
    publisher: 'Alibaba Cloud',
    sizes: ['0.6b', '1.7b', '4b', '8b', '14b', '32b', '72b'],
    defaultTag: 'qwen3:8b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'qwen2.5',
    description: 'Alibaba Cloud high-intelligence flagship model with excellent coding, math, and instruction following.',
    category: 'General',
    publisher: 'Alibaba Cloud',
    sizes: ['0.5b', '1.5b', '3b', '7b', '14b', '32b', '72b'],
    defaultTag: 'qwen2.5:7b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'llama3.3',
    description: 'Meta cutting-edge 70B open weight model delivering Llama 3.1 405B level performance.',
    category: 'General',
    publisher: 'Meta',
    sizes: ['70b'],
    defaultTag: 'llama3.3:70b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'llama3.2',
    description: 'Meta multilingual small language models optimized for low latency and high quality on desktop.',
    category: 'General',
    publisher: 'Meta',
    sizes: ['1b', '3b'],
    defaultTag: 'llama3.2:3b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'llama3.1',
    description: 'Meta flagship open weights model family featuring 128k context length and state-of-the-art tool calling.',
    category: 'General',
    publisher: 'Meta',
    sizes: ['8b', '70b', '405b'],
    defaultTag: 'llama3.1:8b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'deepseek-v3',
    description: 'Groundbreaking 671B Mixture-of-Experts language model with Multi-head Latent Attention and FP8 training.',
    category: 'General',
    publisher: 'DeepSeek',
    sizes: ['671b'],
    defaultTag: 'deepseek-v3:latest',
    isPopular: true,
  ),
  LibraryModel(
    name: 'mistral-small',
    description: 'Mistral AI high-efficiency enterprise model offering low latency and premier reasoning benchmarks.',
    category: 'General',
    publisher: 'Mistral AI',
    sizes: ['22b', '24b'],
    defaultTag: 'mistral-small:24b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'mistral-nemo',
    description: '12B multilingual model developed with NVIDIA featuring 128k context window and Tekken tokenizer.',
    category: 'General',
    publisher: 'Mistral AI',
    sizes: ['12b'],
    defaultTag: 'mistral-nemo:12b',
  ),
  LibraryModel(
    name: 'mistral',
    description: 'Mistral AI efficient 7B model using grouped-query attention and sliding-window attention.',
    category: 'General',
    publisher: 'Mistral AI',
    sizes: ['7b'],
    defaultTag: 'mistral:latest',
    isPopular: true,
  ),
  LibraryModel(
    name: 'gemma2',
    description: 'Google open model family built with Gemini architecture innovations and high efficiency.',
    category: 'General',
    publisher: 'Google',
    sizes: ['2b', '9b', '27b'],
    defaultTag: 'gemma2:9b',
    isPopular: true,
  ),
  LibraryModel(
    name: 'granite3.1-dense',
    description: 'IBM enterprise open model trained on 12T tokens with 128k context, tuned for corporate and RAG workflows.',
    category: 'General',
    publisher: 'IBM',
    sizes: ['2b', '8b'],
    defaultTag: 'granite3.1-dense:8b',
  ),
  LibraryModel(
    name: 'dolphin3',
    description: 'Cognitive Computations unaligned conversational model with structured output and agentic capabilities.',
    category: 'General',
    publisher: 'Cognitive Computations',
    sizes: ['8b'],
    defaultTag: 'dolphin3:8b',
  ),
  LibraryModel(
    name: 'command-r-plus',
    description: 'Cohere enterprise 104B model optimized for complex multi-step reasoning, tool use, and enterprise RAG.',
    category: 'General',
    publisher: 'Cohere',
    sizes: ['104b'],
    defaultTag: 'command-r-plus:104b',
  ),
  LibraryModel(
    name: 'command-r',
    description: 'Cohere enterprise model optimized for Retrieval-Augmented Generation (RAG) and tool use.',
    category: 'General',
    publisher: 'Cohere',
    sizes: ['35b'],
    defaultTag: 'command-r:35b',
  ),
  LibraryModel(
    name: 'falcon3',
    description: 'TII open foundation model series designed for fast inference and edge computing efficiency.',
    category: 'General',
    publisher: 'TII',
    sizes: ['1b', '3b', '7b', '10b'],
    defaultTag: 'falcon3:7b',
  ),
  LibraryModel(
    name: 'internlm2.5',
    description: '1M context open model by Shanghai AI Lab with superior reasoning, math, and long-text understanding.',
    category: 'General',
    publisher: 'Shanghai AI Lab',
    sizes: ['1.8b', '7b', '20b'],
    defaultTag: 'internlm2.5:7b',
  ),
  LibraryModel(
    name: 'olmo2',
    description: 'Fully open model by AI2 with open weights, dataset, and training logs, matching top open benchmarks.',
    category: 'General',
    publisher: 'Allen AI',
    sizes: ['7b', '13b'],
    defaultTag: 'olmo2:7b',
  ),
  LibraryModel(
    name: 'mixtral',
    description: 'High-speed sparse Mixture of Experts model with 32k context token window.',
    category: 'General',
    publisher: 'Mistral AI',
    sizes: ['8x7b', '8x22b'],
    defaultTag: 'mixtral:8x7b',
  ),
  LibraryModel(
    name: 'phi3.5',
    description: 'Microsoft compact model family supporting 128k context length with high benchmark scores.',
    category: 'General',
    publisher: 'Microsoft',
    sizes: ['3.8b'],
    defaultTag: 'phi3.5:3.8b',
  ),
  LibraryModel(
    name: 'smollm2',
    description: 'Ultra-lightweight models by Hugging Face trained on diverse curated synthetic and web data.',
    category: 'General',
    publisher: 'Hugging Face',
    sizes: ['135m', '360m', '1.7b'],
    defaultTag: 'smollm2:1.7b',
  ),
  LibraryModel(
    name: 'hermes3',
    description: 'Advanced agentic open-source model fine-tuned by Nous Research on Llama 3.1.',
    category: 'General',
    publisher: 'Nous Research',
    sizes: ['8b', '70b'],
    defaultTag: 'hermes3:8b',
  ),
  LibraryModel(
    name: 'solar',
    description: 'Compact 10.7B parameter model using Depth Up-Scaling (DUS) for powerful natural language processing.',
    category: 'General',
    publisher: 'Upstage',
    sizes: ['10.7b'],
    defaultTag: 'solar:10.7b',
  ),
  LibraryModel(
    name: 'vicuna',
    description: 'Classic open-source chat assistant fine-tuned on user-shared conversations.',
    category: 'General',
    publisher: 'LMSYS',
    sizes: ['7b', '13b'],
    defaultTag: 'vicuna:7b',
  ),

  // ---------------------------------------------------------------------------
  // Embedding
  // ---------------------------------------------------------------------------
  LibraryModel(
    name: 'nomic-embed-text',
    description: 'High-performing 8192-token text embedding model outperforming OpenAI text-embedding-ada-002.',
    category: 'Embedding',
    publisher: 'Nomic AI',
    sizes: ['137m'],
    defaultTag: 'nomic-embed-text:latest',
    isPopular: true,
  ),
  LibraryModel(
    name: 'bge-m3',
    description: 'Multi-lingual, multi-functionality, and multi-granularity embedding model supporting 100+ languages.',
    category: 'Embedding',
    publisher: 'BAAI',
    sizes: ['567m'],
    defaultTag: 'bge-m3:latest',
  ),
  LibraryModel(
    name: 'bge-large',
    description: 'BAAI top-performing text embedding model for semantic retrieval, ranking, and search pipelines.',
    category: 'Embedding',
    publisher: 'BAAI',
    sizes: ['335m'],
    defaultTag: 'bge-large:latest',
  ),
  LibraryModel(
    name: 'all-minilm',
    description: 'Ultra-fast embedding model for semantic search and sentence similarity.',
    category: 'Embedding',
    publisher: 'Sentence Transformers',
    sizes: ['33m'],
    defaultTag: 'all-minilm:latest',
  ),
  LibraryModel(
    name: 'mxbai-embed-large',
    description: 'State-of-the-art sentence embedding model by Mixedbread AI achieving top MTEB scores.',
    category: 'Embedding',
    publisher: 'Mixedbread AI',
    sizes: ['335m'],
    defaultTag: 'mxbai-embed-large:latest',
  ),
  LibraryModel(
    name: 'snowflake-arctic-embed',
    description: 'Enterprise text embedding model suite optimized for vector retrieval performance.',
    category: 'Embedding',
    publisher: 'Snowflake',
    sizes: ['22m', '33m', '110m', '137m', '335m'],
    defaultTag: 'snowflake-arctic-embed:latest',
  ),
];
