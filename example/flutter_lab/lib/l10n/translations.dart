/// English keys stay next to their usages; technical identifiers are not localized.
String translate(String value, bool portuguese) {
  if (!portuguese) return value;
  final exact = portugueseCopy[value];
  if (exact != null) return exact;
  final upper = _upperCopy[value];
  if (upper != null) return upper;
  if (value.startsWith('Objective: ')) {
    return 'Objetivo: ${translate(value.substring(11), true)}';
  }
  if (value.startsWith('Complete when: ')) {
    return 'Conclua quando: ${translate(value.substring(15), true)}';
  }
  if (value.contains(' · ')) {
    return value.split(' · ').map((part) => translate(part, true)).join(' · ');
  }
  var result = value;
  for (final entry in _phraseMatchers) {
    result = result.replaceAll(entry.$1, entry.$2);
  }
  return result;
}

const portugueseCopy = <String, String>{
  'Main navigation': 'Navegação principal',
  '1 batch': '1 lote',
  'Chronological targets, 12 observed monthly lags, log + training-only scaler, rolling one-step forecast; not a recursive 24-month forecast. Fixed recipe; no test tuning.':
      'Alvos cronológicos, 12 meses observados de histórico, log e normalizador ajustado só no treino, previsão móvel de um passo; não é uma previsão recursiva de 24 meses. Receita fixa; sem ajuste pelo teste.',
  'READY-TO-RUN': 'PRONTO PARA EXECUTAR',
  'Objective': 'Objetivo',
  'Complete when': 'Conclua quando',
  "Laboratory": "Laboratório",
  "Learn": "Aprender",
  "Examples": "Exemplos",
  "Documentation": "Documentação",
  "Change language": "Trocar idioma",
  "The learning laboratory": "O laboratório de aprendizado",
  "Neural Engine logo": "Logotipo do Neural Engine",
  "How to use this lab": "Como usar este laboratório",
  "EXPLORE MODELS": "EXPLORE OS MODELOS",
  "TRAIN & EVALUATE": "TREINE E AVALIE",
  "Learn the XOR rule": "Aprenda a regra XOR",
  "Organize color space": "Organize o espaço de cores",
  "See patterns in pixels": "Encontre padrões nos pixels",
  "Compress and reconstruct": "Comprima e reconstrua",
  "RNN, LSTM and GRU": "RNN, LSTM e GRU",
  "Save and replay a model": "Salve e reproduza um modelo",
  "Pause, resume, compare": "Pause, retome e compare",
  "Evaluate beyond training": "Avalie além do treino",
  "Runs on your device": "Executa no seu dispositivo",
  "No uploads. No account.\nJust you, the data and the model.":
      "Sem envios. Sem conta.\nSó você, os dados e o modelo.",
  "7 model families": "7 famílias de modelos",
  "Experiment": "Experimento",
  "Sequences": "Sequências",
  "Checkpoints": "Checkpoints",
  "Async training": "Treino assíncrono",
  "Real data": "Dados reais",
  "01 / Multilayer perceptron": "01 / Perceptron multicamadas",
  "A simple rule.\nA learned decision.":
      "Uma regra simples.\nUma decisão aprendida.",
  "Teach a neural network to separate XOR. Explore how a hidden layer turns four examples into a decision surface.":
      "Ensine uma rede neural a separar XOR. Explore como uma camada oculta transforma quatro exemplos em uma superfície de decisão.",
  "Supervised learning": "Aprendizado supervisionado",
  "4 synthetic samples": "4 amostras sintéticas",
  "Runs locally": "Execução local",
  "01 / CONFIGURE": "01 / CONFIGURE",
  "Build your network": "Monte sua rede",
  "Change one setting. Train again. Observe what changes.":
      "Altere uma configuração. Treine novamente. Observe o que muda.",
  "Hidden layer": "Camada oculta",
  "Neurons": "Neurônios",
  "Learning rate": "Taxa de aprendizado",
  "Optimizer": "Otimizador",
  "Epochs": "Épocas",
  "Random seed": "Semente aleatória",
  "Loss": "Perda",
  "Binary cross entropy": "Entropia cruzada binária",
  "Train network": "Treinar rede",
  "Training…": "Treinando…",
  "Controls apply to the next run. Charts keep the last completed result.":
      "Os controles valem para a próxima execução. Os gráficos mantêm o último resultado concluído.",
  "Need pause and resume?": "Precisa pausar e retomar?",
  "02 / LEARNING": "02 / APRENDIZADO",
  "Training loss": "Perda de treino",
  "Binary cross entropy · lower is better":
      "Entropia cruzada binária · menor é melhor",
  "Ready when you are": "Pronto quando você estiver",
  "Train the network to trace its learning curve. No training starts automatically.":
      "Treine a rede para visualizar a curva de aprendizado. Nenhum treino começa automaticamente.",
  "Final loss": "Perda final",
  "800 completed epochs": "800 épocas concluídas",
  "02 / DECISION SPACE": "02 / ESPAÇO DE DECISÃO",
  "What the network sees": "O que a rede vê",
  "Untrained weights · seed 42": "Pesos não treinados · semente 42",
  "Last completed run · seed 42": "Última execução concluída · semente 42",
  "Untrained XOR decision surface": "Superfície de decisão XOR não treinada",
  "Trained XOR decision surface; blue is class zero and orange is class one":
      "Superfície de decisão XOR treinada; azul é a classe zero e laranja é a classe um",
  "●  Class 0": "●  Classe 0",
  "●  Class 1": "●  Classe 1",
  "03 / ARCHITECTURE": "03 / ARQUITETURA",
  "From inputs to a prediction": "Das entradas à previsão",
  "Not trained": "Não treinado",
  "Trained": "Treinado",
  "Training": "Treinamento",
  "Inputs": "Entradas",
  "Hidden": "Oculta",
  "Output": "Saída",
  "Input values → tanh activation → sigmoid probability":
      "Entradas → ativação tanh → probabilidade sigmoide",
  "04 / VERIFY": "04 / VERIFIQUE",
  "Four examples. One rule.": "Quatro exemplos. Uma regra.",
  "XOR returns 1 when its two inputs differ.":
      "XOR retorna 1 quando suas duas entradas são diferentes.",
  "This truth table is the whole XOR task. Training loss measures fit to these four rows; it does not establish performance on unseen real-world data.":
      "Esta tabela-verdade é toda a tarefa XOR. A perda mede o ajuste a essas quatro linhas; não comprova desempenho em dados reais inéditos.",
  "02 / Self-organizing map": "02 / Mapa auto-organizável",
  "03 / Convolutional network": "03 / Rede convolucional",
  "04 / Autoencoder": "04 / Autoencoder",
  "Similar colors.\nShared neighborhoods.":
      "Cores semelhantes.\nVizinhanças compartilhadas.",
  "Small filters.\nA different way to see.":
      "Pequenos filtros.\nOutra forma de enxergar.",
  "Less information.\nA familiar pattern.":
      "Menos informação.\nUm padrão familiar.",
  "Watch a map organize RGB colors without labels. Nearby prototypes learn to represent similar inputs.":
      "Veja um mapa organizar cores RGB sem rótulos. Protótipos vizinhos aprendem a representar entradas semelhantes.",
  "Train a convolutional network to recognize vertical and horizontal bars. Inspect the filters, then test your own drawing.":
      "Treine uma rede convolucional para reconhecer barras verticais e horizontais. Inspecione os filtros e teste seu próprio desenho.",
  "Compress a noisy pattern to two coordinates, then reconstruct a clean target. Explore what the bottleneck keeps.":
      "Comprima um padrão ruidoso em duas coordenadas e reconstrua um alvo limpo. Explore o que o gargalo preserva.",
  "Unsupervised learning": "Aprendizado não supervisionado",
  "Image classification": "Classificação de imagens",
  "Denoising": "Remoção de ruído",
  "Synthetic data": "Dados sintéticos",
  "Seed 42": "Semente 42",
  "01 / THE RECIPE": "01 / A RECEITA",
  "A map of color space": "Um mapa do espaço de cores",
  "From pixels to probabilities": "Dos pixels às probabilidades",
  "Encode, compress, decode": "Codifique, comprima, decodifique",
  "RGB · 3 features": "RGB · 3 características",
  "6×6 prototypes": "Protótipos 6×6",
  "Gaussian neighborhood": "Vizinhança gaussiana",
  "6×6×1 input": "Entrada 6×6×1",
  "3×3 convolution · 4 filters": "Convolução 3×3 · 4 filtros",
  "Max pooling": "Agrupamento máximo",
  "2-class softmax": "Softmax de 2 classes",
  "8 inputs": "8 entradas",
  "6 hidden": "6 na camada oculta",
  "2 latent": "2 coordenadas latentes",
  "8 outputs": "8 saídas",
  "80 epochs · learning rate 0.5 → 0.05 · radius 3 → 0.4":
      "80 épocas · taxa 0.5 → 0.05 · raio 3 → 0.4",
  "16 training / 8 test images · Adam 0.02 · batch 8 · 100 epochs · categorical cross entropy":
      "16 imagens de treino / 8 de teste · Adam 0.02 · lote 8 · 100 épocas · entropia cruzada categórica",
  "20 training / 20 test patterns · Adam 0.02 · batch 8 · 400 epochs · binary cross entropy":
      "20 padrões de treino / 20 de teste · Adam 0.02 · lote 8 · 400 épocas · entropia cruzada binária",
  "Open live training →": "Abrir treino ao vivo →",
  "02 / OBSERVE": "02 / OBSERVE",
  "Make the invisible visible": "Torne o invisível visível",
  "A neighborhood waiting to form": "Uma vizinhança esperando para se formar",
  "Let the filters learn": "Deixe os filtros aprenderem",
  "Find the two-value representation":
      "Encontre a representação com dois valores",
  "Train the map to compare its initial and learned prototypes, neighborhood distances and sample hits.":
      "Treine o mapa para comparar protótipos iniciais e aprendidos, distâncias entre vizinhos e contagens de amostras.",
  "After training, compare held-out probabilities, explore a feature channel and draw a new pattern.":
      "Após o treino, compare as probabilidades de teste, explore um canal e desenhe um novo padrão.",
  "After training, compare noisy inputs with clean targets, reconstructions and latent coordinates.":
      "Após o treino, compare entradas ruidosas, alvos limpos, reconstruções e coordenadas latentes.",
  "02 / LEARNING CURVE": "02 / CURVA DE APRENDIZADO",
  "Quantization error": "Erro de quantização",
  "Euclidean distance to the winning prototype · lower is better":
      "Distância euclidiana ao protótipo vencedor · menor é melhor",
  "Cross entropy over completed epochs":
      "Entropia cruzada nas épocas concluídas",
  "Final quantization error": "Erro de quantização final",
  "Final training loss": "Perda de treino final",
  "Held-out noise accuracy": "Acurácia com ruído de teste",
  "03 / EXPLORE THE RESULT": "03 / EXPLORE O RESULTADO",
  "Color space, organized": "O espaço de cores, organizado",
  "Inspect an image and its features":
      "Inspecione uma imagem e suas características",
  "What did the bottleneck preserve?": "O que o gargalo preservou?",
  "Before training": "Antes do treino",
  "After training": "Depois do treino",
  "U-matrix: neighbor distance": "Matriz U: distância entre vizinhos",
  "BMU sample counts": "Contagens de amostras por vencedora",
  "04 / TRY YOUR OWN": "04 / EXPERIMENTE",
  "Does your pattern look familiar?": "Seu padrão parece familiar?",
  "Cell positions are not class labels. Compare topology as well as error; a low quantization error alone does not prove a useful neighborhood.":
      "As posições das células não são rótulos de classe. Compare a topologia e o erro; um erro baixo isolado não comprova uma vizinhança útil.",
  "Test samples change noise, not bar positions or shape families. Arbitrary drawings can be outside the training distribution. Feature channels use independent contrast normalization.":
      "As amostras de teste mudam o ruído, não as posições das barras ou famílias de formas. Desenhos livres podem estar fora da distribuição de treino. Os canais usam normalização de contraste independente.",
  "Test noise is new, but all four clean patterns are familiar. Reconstruction quality here does not establish anomaly detection or compression on real data.":
      "O ruído de teste é novo, mas os quatro padrões limpos são conhecidos. A qualidade de reconstrução aqui não comprova detecção de anomalias ou compressão em dados reais.",
  "Input": "Entrada",
  "Clean target": "Alvo limpo",
  "Reconstruction": "Reconstrução",
  "Inspect filter channel": "Inspecionar canal do filtro",
  "Draw a 6×6 pattern": "Desenhe um padrão 6×6",
  "Tap or use Tab and Enter to toggle pixels; drag to draw. This model learned only vertical/horizontal bars. Arbitrary drawings can be outside its training distribution.":
      "Toque ou use Tab e Enter para alternar pixels; arraste para desenhar. O modelo aprendeu apenas barras verticais e horizontais. Desenhos livres podem estar fora da distribuição de treino.",
  "Clear drawing": "Limpar desenho",
  "Classify drawing": "Classificar desenho",
  "05 / Sequence models": "05 / Modelos de sequência",
  "A little history.\nThe next prediction.":
      "Um pouco de história.\nA próxima previsão.",
  "Give RNN, LSTM and GRU the same six-step sine sequence. Compare how they learn, what they predict and the states they carry.":
      "Forneça a mesma sequência de seno de seis passos à RNN, LSTM e GRU. Compare como aprendem, o que preveem e os estados que mantêm.",
  "3 recurrent models": "3 modelos recorrentes",
  "24 training phases": "24 fases de treino",
  "24 interleaved test phases": "24 fases de teste intercaladas",
  "01 / COMPARE THE MODELS": "01 / COMPARE OS MODELOS",
  "Same data. Different memory.": "Mesmos dados. Memórias diferentes.",
  "6 time steps": "6 passos de tempo",
  "1 feature": "1 característica",
  "6 hidden units": "6 unidades ocultas",
  "1 output": "1 saída",
  "Adam 0.015 · 180 epochs · batch 8 · gradient clip 1 · seed 42":
      "Adam 0.015 · 180 épocas · lote 8 · limite do gradiente 1 · semente 42",
  "Compare sequence models": "Comparar modelos de sequência",
  "Sequence comparison complete": "Comparação de sequências concluída",
  "Three ways to carry context": "Três formas de manter contexto",
  "A sequence waiting to be learned":
      "Uma sequência esperando para ser aprendida",
  "Train the three models to compare held-out errors, learning curves and internal states. Every input sequence begins from zero state.":
      "Treine os três modelos para comparar erros de teste, curvas e estados internos. Cada sequência de entrada começa com estado zero.",
  "02 / COMPARE THE EVIDENCE": "02 / COMPARE AS EVIDÊNCIAS",
  "Held-out errors": "Erros no teste reservado",
  "Parameter counts differ. Device timings are descriptive, not a controlled model ranking.":
      "A quantidade de parâmetros varia. Os tempos do dispositivo são descritivos, não um ranking controlado de modelos.",
  "Model": "Modelo",
  "Parameters": "Parâmetros",
  "Test MSE": "MSE de teste",
  "Train ms": "Treino em ms",
  "03 / INSPECT A MODEL": "03 / INSPECIONE UM MODELO",
  "Inside the sequence": "Por dentro da sequência",
  "Model to inspect": "Modelo a inspecionar",
  "Next target": "Próximo alvo",
  "Predicted next value": "Próximo valor previsto",
  "Test MAE": "MAE de teste",
  "Hidden state · timestep × unit": "Estado oculto · passo de tempo × unidade",
  "LSTM memory state": "Estado de memória da LSTM",
  "Test phases interleave the same sine family. These results do not establish long-memory capability or performance on real time series.":
      "As fases de teste intercalam a mesma família de seno. Os resultados não comprovam memória de longo prazo ou desempenho em séries reais.",
  "Checkpoints / Reproducibility": "Checkpoints / Reprodutibilidade",
  "Close the tab.\nKeep the learning.": "Feche a aba.\nMantenha o aprendizado.",
  "Save a model after 40 epochs, restore it and train 60 more. Then compare the full state with an uninterrupted 100-epoch run.":
      "Salve um modelo após 40 épocas, restaure e treine mais 60. Compare o estado completo com uma execução contínua de 100 épocas.",
  "Model + Adam state": "Modelo + estado do Adam",
  "Exact replay": "Reprodução exata",
  "01 / THE WALKTHROUGH": "01 / PASSO A PASSO",
  "One model. Two training sessions.": "Um modelo. Duas sessões de treino.",
  "Model family": "Família do modelo",
  "Train 40 epochs": "Treinar 40 épocas",
  "Resume +60 epochs": "Retomar +60 épocas",
  "Train first, copy the JSON below and save it as a text file. To restore, select the same model, paste the JSON and press Load JSON.":
      "Primeiro treine, copie o JSON abaixo e salve como arquivo de texto. Para restaurar, selecione o mesmo modelo, cole o JSON e pressione Carregar JSON.",
  "02 / VERIFY THE REPLAY": "02 / VERIFIQUE A REPRODUÇÃO",
  "Did the model remember everything?": "O modelo lembrou de tudo?",
  "Mean training loss": "Perda média de treino",
  "Checkpoint size": "Tamanho do checkpoint",
  "UTF-8 bytes": "Bytes UTF-8",
  "State matches reference": "Estado igual à referência",
  "Target": "Alvo",
  "Restored prediction": "Previsão restaurada",
  "Uninterrupted prediction": "Previsão contínua",
  "03 / SAVE & RESTORE": "03 / SALVE E RESTAURE",
  "Your portable checkpoint": "Seu checkpoint portátil",
  "The JSON is the source of truth. Nothing is saved automatically when you close the tab.":
      "O JSON é a fonte de verdade. Nada é salvo automaticamente ao fechar a aba.",
  "Checkpoint JSON": "JSON do checkpoint",
  "Copy JSON to save": "Copiar JSON para salvar",
  "Load JSON": "Carregar JSON",
  "Exact continuation requires the same data, order, loss, batch size, clipping, SDK and platform. This walkthrough fixes those settings. Its JSON format differs from Async training. SOM uses a separate schedule. Browser compute can briefly block.":
      "A continuação exata exige os mesmos dados, ordem, perda, lotes, limite do gradiente, SDK e plataforma. Este exemplo fixa essas configurações. O formato JSON difere do treino assíncrono. O SOM usa outro cronograma. O compute no navegador pode bloquear brevemente.",
  "JSON copied. Save it as a text file to keep it after closing the app.":
      "JSON copiado. Salve como arquivo de texto para mantê-lo após fechar o aplicativo.",
  "Training workspace": "Área de treinamento",
  "Keep learning.\nStay in control.":
      "Continue aprendendo.\nMantenha o controle.",
  "Train a little at a time. Pause safely, inspect what changed and continue from exactly where you left off.":
      "Treine um pouco por vez. Pause com segurança, inspecione as mudanças e continue exatamente de onde parou.",
  "6 model recipes": "6 receitas de modelos",
  "Live validation": "Validação ao vivo",
  "Resumable checkpoints": "Checkpoints retomáveis",
  "01 / EXPERIMENT": "01 / EXPERIMENTO",
  "Set up your run": "Configure sua execução",
  "Target total epochs": "Total de épocas desejado",
  "Training samples": "Amostras de treino",
  "Validation samples": "Amostras de validação",
  "Browser scheduling": "Agendamento no navegador",
  "Advanced · trade throughput for more UI pauses":
      "Avançado · troque vazão por mais pausas para a interface",
  "Batches per UI yield": "Lotes por pausa da interface",
  "Evaluation block": "Bloco de avaliação",
  "Use an 8 ms work budget": "Usar um orçamento de 8 ms",
  "Checked between work units; not a frame-time guarantee.":
      "Verificado entre unidades de trabalho; não garante o tempo de um quadro.",
  "02 / TRAIN & OBSERVE": "02 / TREINE E OBSERVE",
  "Your learning session": "Sua sessão de aprendizado",
  "Running": "Em execução",
  "Not started": "Não iniciado",
  "Saved": "Salvo",
  "Start fresh": "Começar do zero",
  "Pause training": "Pausar treinamento",
  "Cancel safely": "Cancelar com segurança",
  "Ready": "Pronto",
  "Paused": "Pausado",
  "Cancelled": "Cancelado",
  "Comparing uninterrupted run": "Comparando execução contínua",
  "Comparison cancelled": "Comparação cancelada",
  "Comparison complete": "Comparação concluída",
  "Cancelling after current epoch": "Cancelando após a época atual",
  "Pausing after current epoch": "Pausando após a época atual",
  "Failed; previous saved checkpoint retained":
      "Falhou; checkpoint anterior preservado",
  "Checking training data": "Verificando dados de treino",
  "Checking validation data": "Verificando dados de validação",
  "Measuring training loss": "Medindo perda de treino",
  "Measuring validation loss": "Medindo perda de validação",
  "Evaluation": "Avaliação",
  "Epoch": "Época",
  "Validation loss": "Perda de validação",
  "The next curve starts here": "A próxima curva começa aqui",
  "Choose a recipe above and start a fresh run to see training and validation evolve together.":
      "Escolha uma receita acima e comece do zero para acompanhar a evolução do treino e da validação.",
  "Pause and cancel finish the current epoch, then keep a resumable checkpoint. Start fresh replaces it with a newly seeded run.":
      "Pausar e cancelar terminam a época atual e mantêm um checkpoint retomável. Começar do zero o substitui por uma execução com a semente inicial.",
  "03 / CONTINUE & REPLAY": "03 / CONTINUE E REPRODUZA",
  "Keep the state, not just the weights": "Mantenha o estado, não só os pesos",
  "A checkpoint includes the model, Adam state and random seed. Copy the JSON to save it outside this tab.":
      "Um checkpoint inclui o modelo, o estado do Adam e a semente aleatória. Copie o JSON para salvá-lo fora desta aba.",
  "Resume checkpoint": "Retomar checkpoint",
  "Compare uninterrupted": "Comparar execução contínua",
  "Reset experiment": "Reiniciar experimento",
  "First validation predictions": "Primeiras previsões de validação",
  "Copy checkpoint JSON": "Copiar JSON do checkpoint",
  "Load checkpoint JSON": "Carregar JSON do checkpoint",
  "Checkpoint copied. Save it before closing the tab.":
      "Checkpoint copiado. Salve antes de fechar a aba.",
  "Browser runs yield between batches and evaluation blocks. An indivisible work unit can still take a frame. Exact replay needs the same recipe, runtime and platform; SOM has a separate unsupervised schedule.":
      "O navegador pausa entre lotes e blocos de avaliação. Uma unidade indivisível ainda pode levar um quadro. A reprodução exata exige a mesma receita, ambiente e plataforma; o SOM usa outro cronograma não supervisionado.",
  "Real data / Evaluation": "Dados reais / Avaliação",
  "Good fit is a start.\nEvidence goes further.":
      "Um bom ajuste é o começo.\nAs evidências vão além.",
  "Train on one partition, validate on another and reserve the test set for the final report. Then compare the network with a simple baseline.":
      "Treine em uma partição, valide em outra e reserve o teste para o relatório final. Compare a rede com uma referência simples.",
  "Offline datasets": "Conjuntos de dados offline",
  "Reserved test partition": "Partição de teste reservada",
  "No uploads": "Sem envios de dados",
  "Choose your question": "Escolha sua pergunta",
  "Dataset": "Conjunto de dados",
  "Classify a flower from four measurements.":
      "Classifique uma flor a partir de quatro medidas.",
  "Predict the next month of airline demand.":
      "Preveja a demanda aérea do próximo mês.",
  "MLP 4 → 8 tanh → 3 softmax. Exact duplicates are removed before a seeded, stratified split. The scaler is fitted on training data only.":
      "MLP 4 → 8 tanh → 3 softmax. Duplicatas exatas são removidas antes da divisão estratificada com semente fixa. O normalizador usa somente dados de treino.",
  "GRU with 12 monthly lags and 8 hidden units. Train through 1956, validate in 1957–1958 and test in 1959–1960. One-step predictions use observations available before each target.":
      "GRU com 12 meses de histórico e 8 unidades ocultas. Treino até 1956, validação em 1957–1958 e teste em 1959–1960. As previsões de um passo usam observações disponíveis antes de cada alvo.",
  "120 epochs": "120 épocas",
  "100 epochs": "100 épocas",
  "Batch 16": "Lote 16",
  "Batch 12": "Lote 12",
  "Cross entropy": "Entropia cruzada",
  "Mean squared error": "Erro quadrático médio",
  "Train on real data": "Treinar com dados reais",
  "Cancel": "Cancelar",
  "Complete": "Concluído",
  "Cancelled; test partition was not evaluated":
      "Cancelado; partição de teste não avaliada",
  "Failed; start again to retry": "Falhou; comece novamente para tentar",
  "Training and validation, side by side": "Treino e validação, lado a lado",
  "An honest comparison starts here": "Uma comparação honesta começa aqui",
  "Start a run to see both loss curves on the same scale. Test data stays reserved until training is complete.":
      "Inicie uma execução para ver as duas curvas na mesma escala. Os dados de teste permanecem reservados até o fim do treino.",
  "03 / RESERVED TEST SET": "03 / TESTE RESERVADO",
  "How well did it generalize?": "Como foi a generalização?",
  "Test accuracy": "Acurácia de teste",
  "Macro F1": "F1 macro",
  "Majority baseline": "Referência da classe majoritária",
  "Test RMSE": "RMSE de teste",
  "Previous year MAE": "MAE do ano anterior",
  "Previous month MAE": "MAE do mês anterior",
  "Thousands of passengers": "Milhares de passageiros",
  "A small classic dataset is an educational benchmark, not a production-quality claim.":
      "Um pequeno conjunto clássico é uma referência didática, não uma comprovação de qualidade para produção.",
  "The baseline can win. These are one-step predictions, not a recursive 24-month forecast.":
      "A referência pode vencer. Estas previsões são de um passo, não uma previsão recursiva de 24 meses.",
  "Split, protocol and complete metrics":
      "Divisão, protocolo e métricas completas",
  "04 / INSPECT THE EXAMPLES": "04 / INSPECIONE OS EXEMPLOS",
  "Reserved test predictions": "Previsões do teste reservado",
  "Dataset snapshots and attribution are included with the project. Validation and test statistics never enter the scaler fit. Cancelling skips test evaluation; starting again trains a fresh model.":
      "As cópias dos dados e seus créditos acompanham o projeto. Estatísticas de validação e teste nunca entram no ajuste do normalizador. Cancelar pula a avaliação do teste; começar novamente treina um novo modelo.",
  "Loss by epoch · current run only":
      "Perda por época · somente a execução atual",
  "Mint line: training · Gold line with dots: validation":
      "Linha verde: treino · Linha dourada com pontos: validação",
  "Learn / Neural Engine 0.4.0": "Aprender / Neural Engine 0.4.0",
  "Understand the model.\nThen make it yours.":
      "Entenda o modelo.\nDepois, experimente.",
  "A practical guide to the models implemented in this engine. Read the idea, interpret the math and open a real experiment.":
      "Um guia prático dos modelos implementados neste engine. Entenda a ideia, interprete a matemática e abra um experimento real.",
  "Real source documentation": "Documentação real do projeto",
  "5 practical exercises": "5 exercícios práticos",
  "START HERE": "COMECE AQUI",
  "The learning loop": "O ciclo de aprendizado",
  "Data provides examples. A model produces predictions. A loss measures error. An optimizer changes parameters. Validation checks what the training curve alone cannot tell you.":
      "Os dados fornecem exemplos. O modelo produz previsões. A perda mede o erro. O otimizador altera parâmetros. A validação verifica o que a curva de treino sozinha não revela.",
  "FUNDAMENTALS & ALGORITHMS": "FUNDAMENTOS E ALGORITMOS",
  "Read the formula": "Leia a fórmula",
  "A small, real API example": "Um pequeno exemplo real da API",
  "Import package:neural_engine/neural_engine.dart. These snippets construct models; use the linked laboratory preset for the complete training recipe.":
      "Importe package:neural_engine/neural_engine.dart. Os trechos constroem modelos; use o preset do laboratório para a receita completa de treinamento.",
  "Open this experiment": "Abrir este experimento",
  "Copy code": "Copiar código",
  "Example code copied.": "Código de exemplo copiado.",
  "Read the source guide ↗": "Ler o guia de origem ↗",
  "REFERENCES": "REFERÊNCIAS",
  "Built from this project’s documentation":
      "Baseado na documentação deste projeto",
  "Model guide ↗": "Guia dos modelos ↗",
  "Evaluation guide ↗": "Guia de avaliação ↗",
  "Async training guide ↗": "Guia de treino assíncrono ↗",
  "Architecture ↗": "Arquitetura ↗",
  "PRACTICE": "PRATIQUE",
  "Five practical exercises": "Cinco exercícios práticos",
  "1. Explore XOR capacity": "1. Explore a capacidade para XOR",
  "Compare two and eight hidden neurons with the same learning rate.":
      "Compare dois e oito neurônios ocultos com a mesma taxa de aprendizado.",
  "Record both final losses and the four predicted classes.":
      "Registre as duas perdas finais e as quatro classes previstas.",
  "2. Inspect SOM topology": "2. Inspecione a topologia do SOM",
  "Compare prototypes before and after training with the U-matrix.":
      "Compare os protótipos antes e depois do treino com a matriz U.",
  "Identify two neighboring similar prototypes and record their RGB values.":
      "Identifique dois protótipos vizinhos semelhantes e registre seus valores RGB.",
  "3. Test the CNN distribution": "3. Teste a distribuição da CNN",
  "Classify a vertical bar and a diagonal drawing.":
      "Classifique uma barra vertical e um desenho diagonal.",
  "Record both probability vectors and explain why only the bar matches training data.":
      "Registre os dois vetores de probabilidades e explique por que só a barra corresponde aos dados de treino.",
  "4. Verify exact continuation": "4. Verifique a continuação exata",
  "Pause, copy/load JSON, resume and compare an async run.":
      "Pause, copie/carregue o JSON, retome e compare uma execução assíncrona.",
  "Reach the target epoch and obtain an exact checkpoint match on the same platform.":
      "Alcance a época desejada e obtenha igualdade exata do checkpoint na mesma plataforma.",
  "5. Compare forecasting baselines": "5. Compare as referências de previsão",
  "Train AirPassengers and compare its test MAE with both baselines.":
      "Treine AirPassengers e compare o MAE de teste com as duas referências.",
  "Name the best method and state the test dates and one-step forecast limitation.":
      "Identifique o melhor método e informe as datas de teste e a limitação da previsão de um passo.",
  "Examples / Ready-to-run recipes":
      "Exemplos / Receitas prontas para executar",
  "Start with a question.\nLoad a real experiment.":
      "Comece com uma pergunta.\nCarregue um experimento real.",
  "These presets use the actual data generators and runners in this repository. Loading configures the workspace; training still starts only when you press its button.":
      "Estes presets usam os geradores de dados e executores reais do repositório. Carregar configura a área de trabalho; o treino só começa quando você pressiona o botão.",
  "Deterministic recipes": "Receitas determinísticas",
  "No automatic training": "Sem treino automático",
  "Learn by changing one setting": "Aprenda alterando uma configuração",
  "Load example": "Carregar exemplo",
  "Changing sections or languages preserves the active experiment. Loading a preset is an explicit configuration change; finish or cancel an active run before replacing its recipe.":
      "Trocar de seção ou idioma preserva o experimento ativo. Carregar um preset altera a configuração explicitamente; termine ou cancele uma execução antes de substituir a receita.",
  "Finish or cancel the active run before loading another recipe.":
      "Termine ou cancele a execução ativa antes de carregar outra receita.",
  "Learn XOR": "Aprenda XOR",
  "Separate four examples with a nonlinear hidden layer.":
      "Separe quatro exemplos com uma camada oculta não linear.",
  "A smaller hidden layer": "Uma camada oculta menor",
  "Compare the capacity of two hidden neurons with the eight-neuron recipe.":
      "Compare a capacidade de dois neurônios ocultos com a receita de oito neurônios.",
  "Organize RGB colors": "Organize cores RGB",
  "Discover neighborhoods without assigning class labels.":
      "Descubra vizinhanças sem atribuir rótulos de classe.",
  "Recognize noisy bars": "Reconheça barras ruidosas",
  "Train shared filters, inspect channels and draw a new pattern.":
      "Treine filtros compartilhados, inspecione canais e desenhe um novo padrão.",
  "Denoise a pattern": "Remova o ruído de um padrão",
  "Explore what a two-value bottleneck can preserve.":
      "Explore o que um gargalo com dois valores pode preservar.",
  "Compare recurrent memory": "Compare memórias recorrentes",
  "Give RNN, LSTM and GRU the same sine-wave windows.":
      "Forneça as mesmas janelas de seno à RNN, LSTM e GRU.",
  "Replay an exact continuation": "Reproduza uma continuação exata",
  "Restore model and optimizer state, then compare with a reference.":
      "Restaure o modelo e o estado do otimizador e compare com uma referência.",
  "Classify Iris flowers": "Classifique flores Iris",
  "Compare held-out accuracy and F1 against a majority baseline.":
      "Compare a acurácia e o F1 de teste com a referência majoritária.",
  "Forecast airline demand": "Preveja a demanda aérea",
  "Compare a one-step GRU forecast with two simple baselines.":
      "Compare uma previsão GRU de um passo com duas referências simples.",
  "Training failed. Try a fresh run with these settings.":
      "O treinamento falhou. Tente uma nova execução com estas configurações.",
  "Training failed. The previous saved checkpoint is still available.":
      "O treinamento falhou. O checkpoint anterior continua disponível.",
  "Checkpoint rejected. Use JSON exported by this lab with the matching model, optimizer and seed.":
      "Checkpoint rejeitado. Use um JSON exportado por este laboratório com o modelo, otimizador e semente correspondentes.",
  "Could not restore this checkpoint. Select the matching model and use JSON exported by this walkthrough.":
      "Não foi possível restaurar o checkpoint. Selecione o modelo correspondente e use um JSON exportado por este passo a passo.",
  "id": "ID",
  "actual": "Real",
  "prediction": "Previsão",
  "month": "Mês",
  "seasonal": "Sazonal",
  "loss": "perda",
  "parameters": "parâmetros",
  "epochs": "épocas",
  "min": "mín",
  "max": "máx"
};
const phraseCopy = <String, String>{
  'loss ': 'perda ',
  'validation ': 'validação ',
  'last run': 'última execução',
  'Imported JSON': 'JSON importado',
  'predicted probabilities [vertical, horizontal]':
      'probabilidades previstas [vertical, horizontal]',
  'learning rate': 'taxa de aprendizado',
  'batch': 'lote',
  'seed': 'semente',
  'gradient clip': 'limite do gradiente',
  'Input': 'Entrada',
  'Clean target': 'Alvo limpo',
  'Reconstruction': 'Reconstrução',
  'min ': 'mín ',
  'max ': 'máx ',
  "Final binary cross entropy:": "Entropia cruzada binária final:",
  "Held-out reconstruction MSE:": "MSE de reconstrução no teste:",
  "Quantization error:": "Erro de quantização:",
  "Full model + Adam state matches uninterrupted run:":
      "Modelo completo + estado do Adam iguais à execução contínua:",
  "Maximum prediction difference:": "Maior diferença de previsão:",
  "Exact checkpoint match:": "Igualdade exata do checkpoint:",
  "Completed epochs:": "Épocas concluídas:",
  "Completed at epoch": "Concluído na época",
  "Loaded at epoch": "Carregado na época",
  "Paused at epoch": "Pausado na época",
  "Cancelled at epoch": "Cancelado na época",
  "Saved epoch:": "Época salva:",
  " · Imported JSON": " · JSON importado",
  " · last run": " · última execução",
  "Adam · learning rate": "Adam · taxa de aprendizado",
  " · batch": " · lote",
  " · seed": " · semente",
  " · gradient clip": " · limite do gradiente",
  "UI interactions:": "Interações na interface:",
  "Drawing probabilities [vertical, horizontal]:":
      "Probabilidades do desenho [vertical, horizontal]:",
  " · predicted probabilities [vertical, horizontal]:":
      " · probabilidades previstas [vertical, horizontal]:",
  "Latent coordinates:": "Coordenadas latentes:",
  "Convolution channel": "Canal da convolução",
  "Test sample": "Amostra de teste",
  " hidden neurons": " neurônios ocultos",
  " target epochs": " épocas desejadas",
  " batches": " lotes",
  " samples": " amostras",
  " at epoch": " na época",
  "Loss curve over": "Curva de perda ao longo de",
  " completed epochs.": " épocas concluídas.",
  "Training loss from": "Perda de treino de",
  " in 800 epochs": " em 800 épocas",
  " over": " ao longo de",
  " epochs": " épocas",
  " timesteps": " passos de tempo",
  " hidden units": " unidades ocultas",
  " filters": " filtros",
  " monthly lags": " meses de histórico",
  " map": " mapa",
  " radius": " raio",
  " reserved test set": " teste reservado",
  " model families": " famílias de modelos",
  "Epoch": "Época",
  " · loss": " · perda",
  " · validation": " · validação",
  "Training": "Treino",
  "Validation": "Validação",
  "Learning rate": "Taxa de aprendizado",
  "Loss:": "Perda:",
  "Target:": "Alvo:",
  "Target": "Alvo",
  "Input:": "Entrada:",
  "Objective:": "Objetivo:",
  "Complete when:": "Conclua quando:",
  "EXAMPLE /": "EXEMPLO /",
  " results": " resultados",
  "Pixel row": "Pixel na linha",
  " row": " linha",
  ", column": ", coluna",
  " of": " de",
  " to": " até",
  "vertical": "vertical",
  "horizontal": "horizontal",
  "binaryCrossEntropy": "entropia cruzada binária",
  "categoricalCrossEntropy": "entropia cruzada categórica",
  "meanSquaredError": "erro quadrático médio",
  "true": "sim",
  "false": "não",
  "id:": "ID:",
  "actual:": "Real:",
  "prediction:": "Previsão:",
  "month:": "Mês:",
  "seasonal:": "Sazonal:",
  "dataset:": "Conjunto de dados:",
  "sourceRows:": "Linhas originais:",
  "uniqueRows:": "Linhas únicas:",
  "trainTargets:": "Alvos de treino:",
  "validationTargets:": "Alvos de validação:",
  "testTargets:": "Alvos de teste:",
  "train:": "Treino:",
  "validation:": "Validação:",
  "test:": "Teste:",
  "epochs:": "Épocas:",
  "loss:": "Perda:",
  "validationLoss:": "Perda de validação:",
  "testAccuracy:": "Acurácia de teste:",
  "testMacroF1:": "F1 macro de teste:",
  "confusionMatrix:": "Matriz de confusão:",
  "baselineAccuracy:": "Acurácia da referência:",
  "milliseconds:": "Milissegundos:",
  "protocol:": "Protocolo:",
  "trainEnd:": "Fim do treino:",
  "validationEnd:": "Fim da validação:",
  "testEnd:": "Fim do teste:",
  "lookback:": "Janela de histórico:",
  "testMAEThousands:": "MAE de teste em milhares:",
  "testRMSEThousands:": "RMSE de teste em milhares:",
  "seasonalMAEThousands:": "MAE sazonal em milhares:",
  "persistenceMAEThousands:": "MAE do mês anterior em milhares:",
  "Exact-row deduplication, seeded stratified 60/20/remainder split; scaler fit on training only; fixed recipe, test not used for selection.":
      "Remoção de duplicatas exatas, divisão estratificada 60/20/restante com semente; normalizador ajustado só no treino; receita fixa, teste fora da seleção.",
  "The link could not be opened. Please allow a new tab or copy the address:":
      "Não foi possível abrir o link. Permita uma nova aba ou copie o endereço:"
};

final _orderedPhraseCopy = phraseCopy.entries.toList()
  ..sort((a, b) => b.key.length.compareTo(a.key.length));

final _upperCopy = {
  for (final entry in portugueseCopy.entries)
    entry.key.toUpperCase(): entry.value.toUpperCase()
};

final _phraseMatchers = _orderedPhraseCopy.map((entry) {
  final word = RegExp(r'[A-Za-zÀ-ÿ0-9_]');
  final before = word.hasMatch(entry.key[0]) ? r'(?<![A-Za-zÀ-ÿ0-9_])' : '';
  final after = word.hasMatch(entry.key[entry.key.length - 1])
      ? r'(?![A-Za-zÀ-ÿ0-9_])'
      : '';
  return (RegExp('$before${RegExp.escape(entry.key)}$after'), entry.value);
}).toList();
