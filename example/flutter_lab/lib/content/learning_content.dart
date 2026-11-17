typedef LessonCopy = (String, String);

class LabLesson {
  final String id, exampleId, source;
  final LessonCopy title, summary, explanation, interpretation, limit;
  final String formula, code;
  const LabLesson(
      {required this.id,
      required this.exampleId,
      required this.source,
      required this.title,
      required this.summary,
      required this.explanation,
      required this.interpretation,
      required this.limit,
      required this.formula,
      required this.code});
}

const lessons = <LabLesson>[
  LabLesson(
      id: 'mlp',
      exampleId: 'xor',
      source: 'models',
      title: ('MLP & backpropagation', 'MLP e retropropagação'),
      summary: (
        'A nonlinear hidden layer can separate XOR, where one linear boundary cannot.',
        'Uma camada oculta não linear pode separar XOR, onde uma única fronteira linear não consegue.'
      ),
      explanation: (
        'Each Dense layer computes weighted sums and an activation. Backpropagation differentiates the loss with respect to every parameter; Adam updates the parameters in mini-batches. An epoch visits the whole training set.',
        'Cada camada Dense calcula somas ponderadas e uma ativação. A retropropagação deriva a perda em relação a cada parâmetro; Adam atualiza os parâmetros em minilotes. Uma época percorre todo o conjunto de treino.'
      ),
      formula:
          'z = wᵀx + b     σ(z) = 1 / (1 + e⁻ᶻ)\nL = −[y ln(p) + (1 − y) ln(1 − p)]',
      interpretation: (
        'x contains input features, w the learned weights and b the bias. The sigmoid turns z into a probability p. Binary cross entropy penalizes a confident prediction that disagrees with target y.',
        'x contém as características de entrada, w os pesos aprendidos e b o viés. A sigmoide transforma z em uma probabilidade p. A entropia cruzada binária penaliza previsões confiantes que discordam do alvo y.'
      ),
      limit: (
        'The lab reuses all four XOR rows for its fit check. This is not evidence of generalization to unseen real data.',
        'O laboratório reutiliza as quatro linhas de XOR para verificar o ajuste. Isso não comprova generalização para dados reais inéditos.'
      ),
      code:
          "final model = NeuralNetwork(inputSize: 2, seed: 42, layers: [\n  Dense(8, activation: Activation.tanh),\n  Dense(1, activation: Activation.sigmoid),\n]);\nprint(model.predict([0, 1]));"),
  LabLesson(
      id: 'som',
      exampleId: 'som',
      source: 'models',
      title: ('SOM neighborhoods', 'Vizinhanças do SOM'),
      summary: (
        'A Kohonen map organizes vectors into neighboring prototypes without class targets.',
        'Um mapa de Kohonen organiza vetores em protótipos vizinhos sem alvos de classe.'
      ),
      explanation: (
        'For each RGB sample, find the best matching unit using Euclidean distance. Move its prototype and its grid neighbors toward the sample. The learning rate and Gaussian neighborhood radius decrease during training; the grid does not wrap.',
        'Para cada amostra RGB, encontre a unidade vencedora pela distância euclidiana. Aproxime seu protótipo e os vizinhos da amostra. A taxa de aprendizado e o raio da vizinhança gaussiana diminuem durante o treino; a grade não conecta bordas opostas.'
      ),
      formula: 'c = argminᵢ ‖x − wᵢ‖\nwᵢ ← (1 − αhᶜᵢ)wᵢ + αhᶜᵢx',
      interpretation: (
        'c is the winning cell. α controls the update size and h the influence of the winner on a neighboring cell. Quantization error averages the distance to winners; it is not classification accuracy.',
        'c é a célula vencedora. α controla o tamanho da atualização e h a influência da vencedora sobre uma vizinha. O erro de quantização calcula a distância média às vencedoras; não é acurácia de classificação.'
      ),
      limit: (
        'A low error alone does not establish good topology. Grid coordinates are not named classes, and error may rise between epochs.',
        'Um erro baixo isolado não comprova boa topologia. Coordenadas não são classes nomeadas, e o erro pode aumentar entre épocas.'
      ),
      code:
          'final map = SelfOrganizingMap(\n  rows: 6, columns: 6, inputSize: 3, seed: 42,\n);\nfinal red = map.winner([1, 0, 0]);\nprint([red.row, red.column]);'),
  LabLesson(
      id: 'cnn',
      exampleId: 'cnn',
      source: 'models',
      title: ('CNN filters', 'Filtros da CNN'),
      summary: (
        'Shared filters detect local spatial patterns before a dense head decides the class.',
        'Filtros compartilhados detectam padrões espaciais locais antes de uma camada densa decidir a classe.'
      ),
      explanation: (
        'Conv2D performs cross-correlation with trainable kernels. ReLU creates feature maps and MaxPool2D reduces their spatial size. The convolution and softmax head train together. The implementation supports valid and same padding.',
        'Conv2D faz correlação cruzada com núcleos treináveis. ReLU gera mapas de características e MaxPool2D reduz suas dimensões espaciais. A convolução e a saída softmax treinam juntas. A implementação aceita preenchimento valid e same.'
      ),
      formula: 'aᵢⱼ = ReLU(Σₘₙ kₘₙ xᵢ₊ₘ,ⱼ₊ₙ + b)\npᵢ = exp(zᵢ) / Σⱼ exp(zⱼ)',
      interpretation: (
        'The same kernel k is reused across image positions. Softmax probabilities sum to one for mutually exclusive classes. Inspecting a feature channel helps explain the representation, but is not a guarantee of interpretability.',
        'O mesmo núcleo k é reutilizado nas posições da imagem. As probabilidades softmax somam um para classes mutuamente exclusivas. Inspecionar um canal ajuda a entender a representação, sem garantir interpretabilidade.'
      ),
      limit: (
        'Held-out bars change noise, not positions or shape families. Channel colors use independent contrast normalization. Arbitrary drawings may be outside the training distribution.',
        'As barras de teste mudam o ruído, não as posições ou famílias de formas. Cada canal usa normalização de contraste independente. Desenhos livres podem estar fora da distribuição de treino.'
      ),
      code:
          'final model = ConvolutionalNetwork(\n  inputHeight: 6, inputWidth: 6, seed: 42,\n  layers: [Conv2D(filters: 4, padding: ConvolutionPadding.same), MaxPool2D()],\n  denseLayers: [Dense(2, activation: Activation.softmax)],\n);'),
  LabLesson(
      id: 'autoencoder',
      exampleId: 'autoencoder',
      source: 'models',
      title: ('Autoencoder bottlenecks', 'Gargalos do autoencoder'),
      summary: (
        'An autoencoder is an encoder/decoder architecture made from Dense layers, not a separate model class.',
        'Um autoencoder é uma arquitetura de codificador/decodificador feita com camadas Dense, não uma classe de modelo separada.'
      ),
      explanation: (
        'The encoder compresses eight noisy input values into two latent coordinates. The decoder reconstructs eight clean target values. This recipe uses untied Dense weights and binary cross entropy, and reports held-out reconstruction MSE.',
        'O codificador comprime oito entradas ruidosas em duas coordenadas latentes. O decodificador reconstrói oito alvos limpos. Esta receita usa pesos Dense independentes e entropia cruzada binária, e relata o erro quadrático médio da reconstrução no teste.'
      ),
      formula: 'z = encoder(x)     x̂ = decoder(z)\nMSE = (1/N) Σᵢ (xᵢ − x̂ᵢ)²',
      interpretation: (
        'z is a learned representation, not a class label. Reconstruction MSE averages squared differences between clean target coordinates and the reconstructed output.',
        'z é uma representação aprendida, não um rótulo de classe. O MSE de reconstrução calcula a média dos quadrados das diferenças entre os alvos limpos e a saída reconstruída.'
      ),
      limit: (
        'There are four underlying clean patterns. New test noise is not a new pattern family, and these results do not establish anomaly detection on real data.',
        'Há quatro padrões limpos básicos. Novo ruído de teste não representa uma nova família de padrões, e estes resultados não comprovam detecção de anomalias em dados reais.'
      ),
      code:
          'final model = NeuralNetwork(inputSize: 8, seed: 42, layers: [\n  Dense(6, activation: Activation.tanh),\n  Dense(2, activation: Activation.tanh),\n  Dense(6, activation: Activation.tanh),\n  Dense(8, activation: Activation.sigmoid),\n]);'),
  LabLesson(
      id: 'recurrent',
      exampleId: 'sequences',
      source: 'recurrent',
      title: ('RNN, LSTM & GRU', 'RNN, LSTM e GRU'),
      summary: (
        'Many-to-one recurrent models read a sequence and predict from its final hidden state.',
        'Modelos recorrentes muitos-para-um leem uma sequência e preveem a partir do último estado oculto.'
      ),
      explanation: (
        'Simple RNN carries a tanh hidden state. LSTM adds input, forget and output gates plus a memory cell, without peepholes. GRU uses update and reset gates; this engine implements reset-before. Training uses full backpropagation through time.',
        'A RNN simples mantém um estado oculto com tanh. A LSTM adiciona portas de entrada, esquecimento e saída e uma célula de memória, sem peepholes. A GRU usa portas de atualização e reinicialização; este engine implementa reset-before. O treino usa retropropagação completa no tempo.'
      ),
      formula:
          'RNN: hₜ = tanh(Wxₜ + Uhₜ₋₁ + b)\nLSTM: cₜ = fₜcₜ₋₁ + iₜgₜ; hₜ = oₜ tanh(cₜ)\nGRU: hₜ = (1 − zₜ)nₜ + zₜhₜ₋₁',
      interpretation: (
        'Gates choose what information to retain or replace. Each independent predict call begins at zero state. Equal hidden sizes do not imply equal parameter counts.',
        'As portas escolhem quais informações manter ou substituir. Cada chamada independente de predict começa com estado zero. Tamanhos ocultos iguais não significam a mesma quantidade de parâmetros.'
      ),
      limit: (
        'The lab interpolates interleaved sine phases. It does not prove long-term memory. Stacking, masks, bidirectionality and GPU training are not implemented.',
        'O laboratório interpola fases intercaladas de seno. Isso não comprova memória de longo prazo. Empilhamento, máscaras, bidirecionalidade e treino em GPU não estão implementados.'
      ),
      code:
          'final model = RecurrentNetwork(\n  inputSize: 1, hiddenSize: 6, outputSize: 1,\n  kind: RecurrentKind.lstm, seed: 42,\n);\nprint(model.predict([[0.0], [0.2], [0.4]]));'),
  LabLesson(
      id: 'evaluation',
      exampleId: 'iris',
      source: 'evaluation',
      title: ('Validation & test data', 'Validação e dados de teste'),
      summary: (
        'Training loss, validation loss and final test metrics answer different questions.',
        'Perda de treino, perda de validação e métricas finais de teste respondem a perguntas diferentes.'
      ),
      explanation: (
        'Fit preprocessing only on training observations. Use validation for recipe selection and reserve test data for the final report. For time series, keep chronological partitions. The lab compares neural results with simple baselines even when the baselines win.',
        'Ajuste o pré-processamento somente nas observações de treino. Use a validação para selecionar a receita e reserve o teste para o relatório final. Em séries temporais, mantenha divisões cronológicas. O laboratório compara as redes com referências simples, mesmo quando elas vencem.'
      ),
      formula:
          'Accuracy = correct / total\nF1 = 2 × precision × recall / (precision + recall)\nMAE = (1/N) Σᵢ |yᵢ − ŷᵢ|',
      interpretation: (
        'Macro F1 averages class F1 values equally. MAE has the original target units. In a confusion matrix, rows are true classes and columns are predictions. Undefined ratios are reported as zero.',
        'O F1 macro dá o mesmo peso ao F1 de cada classe. O MAE usa a unidade original do alvo. Na matriz de confusão, linhas representam as classes reais e colunas as previstas. Razões indefinidas são relatadas como zero.'
      ),
      limit: (
        'Iris is a small classic dataset. AirPassengers is a one-step forecast, not a recursive two-year forecast. Neither is a production-quality claim.',
        'Iris é um pequeno conjunto clássico. AirPassengers usa previsão de um passo, não uma previsão recursiva de dois anos. Nenhum dos dois comprova qualidade para produção.'
      ),
      code:
          'final report = ClassificationMetrics.fromLabels(\n  targets: [0, 0, 1, 1], predictions: [0, 1, 1, 1], classCount: 2,\n);\nprint(report.accuracy); // 0.75\nprint(report.confusionMatrix); // [[1, 1], [0, 2]]'),
  LabLesson(
      id: 'checkpoint',
      exampleId: 'checkpoint',
      source: 'persistence',
      title: ('Checkpoint & replay', 'Checkpoint e reprodução'),
      summary: (
        'Weights reproduce predictions; a training checkpoint also retains optimizer and random-state information.',
        'Os pesos reproduzem previsões; um checkpoint de treino também mantém informações do otimizador e da aleatoriedade.'
      ),
      explanation: (
        'TrainingCheckpoint stores model JSON, optimizer configuration and moments, completed epochs and the session seed. Continuation also needs the same data, loss, ordering and batch recipe. Async cancellation finishes the current epoch before returning a resumable checkpoint.',
        'TrainingCheckpoint guarda o JSON do modelo, configuração e momentos do otimizador, épocas concluídas e semente da sessão. A continuação também exige os mesmos dados, perda, ordem e receita de lotes. O cancelamento assíncrono termina a época atual antes de devolver um checkpoint retomável.'
      ),
      formula:
          'same initial state + same updates → same final state\n40 epochs + restored 60 epochs ↔ uninterrupted 100 epochs',
      interpretation: (
        'An exact comparison checks learned parameters and Adam state, not just a rounded prediction. Copy and save the JSON explicitly; the two lab checkpoint envelopes are intentionally different.',
        'A comparação exata verifica parâmetros aprendidos e estado do Adam, não apenas uma previsão arredondada. Copie e salve o JSON explicitamente; os dois formatos de checkpoint do laboratório são intencionalmente diferentes.'
      ),
      limit: (
        'Exact replay requires the same SDK and platform. SOM has its own neighborhood schedule, outside TrainingSession. Browser cooperative batches are not a parallel worker.',
        'A reprodução exata exige o mesmo SDK e plataforma. O SOM possui seu próprio cronograma de vizinhança, fora de TrainingSession. Os lotes cooperativos do navegador não são um worker paralelo.'
      ),
      code:
          'final session = TrainingSession(\n  model: NeuralNetwork(inputSize: 2, seed: 42,\n    layers: [Dense(1, activation: Activation.sigmoid)]),\n  optimizer: Adam(learningRate: 0.02), seed: 42,\n);\nfinal snapshot = session.checkpoint();\nprint(snapshot.toJson());'),
];
