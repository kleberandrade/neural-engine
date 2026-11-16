# Persistência e retomada de treinamento

[English](persistence.md) · [Extensibilidade](extending.pt-BR.md)

Há três tipos de artefato, com responsabilidades diferentes:

| Artefato | Conteúdo | Uso |
| --- | --- | --- |
| Modelo de inferência | Arquitetura, pesos e seed | Prever com Dense, CNN, recorrentes ou SOM |
| Normalizador ajustado | Médias/escalas ou mínimos/amplitudes | Reproduzir o pré-processamento sem ajustar novos dados |
| Checkpoint de sessão | Modelo, configuração/estado do otimizador, seed e épocas completas | Continuar treinamento supervisionado por épocas fixas |

## Normalizadores

`StandardScaler` e `MinMaxScaler` implementam `JsonModel` e têm `fromJson`.
Os formatos v1 validam vetores finitos, dimensões iguais e escalas/amplitudes
estritamente positivas. Atributos constantes continuam usando escala/amplitude 1.
O JSON exportado é independente dos dados internos do normalizador.

```dart
final scaler = StandardScaler.fit(trainingInputs);
final encoded = jsonEncode(scaler.toJson());
final restored = StandardScaler.fromJson(
  jsonDecode(encoded) as Map<String, dynamic>,
);
final prepared = restored.transform(newInput);
```

Importe `dart:convert` e a biblioteca pública. Para min/max, use
`MinMaxScaler.fromJson`. Ajuste apenas no treino. Salve normalizadores de entrada
e de alvo junto ao modelo quando a aplicação usar ambos.

## Sessões com Adam ou SGD

`fit` comum inicia um novo estado de otimizador a cada chamada. Para continuar
momentos de Adam e a sequência de mini-batches, use `TrainingSession<I>` desde
o início. O modelo continua sendo acessível por `session.model`.

```dart
final session = TrainingSession<List<double>>(
  model: network,
  optimizer: Adam(learningRate: 0.03),
  seed: 42,
);
session.fit(inputs: x, targets: y, loss: const MeanSquaredError(),
  epochs: 40, batchSize: 3);
final saved = jsonEncode(session.checkpoint().toJson());
final checkpoint = TrainingCheckpoint.fromJson(
  jsonDecode(saved) as Map<String, dynamic>,
);
final resumed = TrainingSession<List<double>>.restore(
  checkpoint: checkpoint,
  modelDecoder: NeuralNetwork.fromJson,
);
resumed.fit(inputs: x, targets: y, loss: const MeanSquaredError(),
  epochs: 60, batchSize: 3);
```

O trecho assume `network`, `x` e `y` preparados. O programa completo verifica
igualdade de pesos **e** estado do otimizador entre 100 épocas contínuas e
40 + salvar/restaurar + 60:

```sh
dart run example/checkpoint.dart
```

Para CNN ou recorrentes, escolha o tipo de entrada e o decoder correspondente.
Os testes verificam ambas as estratégias de otimizador em Dense, CNN, RNN, LSTM
e GRU, com embaralhamento e mini-batch final parcial.

### O que torna a retomada equivalente?

O checkpoint guarda momentos m/v e contador de passos do Adam, configuração do
otimizador, pesos, seed e número de épocas concluídas. A sessão calcula o
embaralhamento de cada época com sua posição absoluta, sem depender de um objeto
Random não serializável.

Para repetição exata, mantenha os mesmos dados e ordem inicial, função de perda,
tamanho do batch, opção shuffle e clipping, no mesmo SDK/plataforma. A sessão
usa uma política de embaralhamento por época própria: uma execução iniciada por
`model.fit` comum não deve ser comparada como se fosse a mesma sessão.

Não altere pesos do modelo externamente enquanto a sessão estiver ativa. Salve
apenas em fronteiras entre chamadas completas de `session.fit`. Não há checkpoint
no meio de um batch. Depois de uma falha, a sessão recusa novos fits/checkpoints;
restaure o último checkpoint válido. Updates de batches já concluídos não são
revertidos automaticamente.

A sessão atual é de épocas fixas. Early stopping e restauração do melhor modelo
continuam no `fit` comum, que não promete retomar momentos. Isso evita apresentar
pesos de uma época anterior junto a momentos de uma época posterior como um
checkpoint coerente. Dados, perda, histórico, normalizadores e políticas de
validação não são incorporados silenciosamente ao checkpoint.

## Otimizadores e modelos externos

`CheckpointOptimizer` e `CheckpointOptimizerState` são extensões opcionais dos
contratos originais. Um otimizador customizado que só implementa `Optimizer`
continua funcionando no treinador comum. Para checkpoint, forneça serialização
e restauração de estado e passe seu decoder explicitamente:

```dart
final resumed = TrainingSession<List<double>>.restore(
  checkpoint: checkpoint,
  modelDecoder: LinearModel.fromJson,
  optimizerDecoder: MomentumOptimizer.fromJson,
);
```

Essas classes estão em `example/extensions/`, um projeto consumidor independente.
Não é necessário registrar o modelo ou o otimizador no núcleo. O codec integrado
aceita apenas Adam/SGD; formatos desconhecidos falham em vez de perder estado.
O envelope do checkpoint valida formato/progresso; o decoder do modelo e a
restauração do otimizador validam suas estruturas ao restaurar a sessão.

IO pertence à aplicação. Limite tamanho de arquivos antes de decodificar dados
não confiáveis. SOM possui modelo JSON, mas não usa este checkpoint de otimizador:
seu aprendizado competitivo e cronograma de vizinhança são outra responsabilidade.
