# neural_engine

A interface oferece Laboratório, Aprender e Exemplos em inglês e português brasileiro,
com bandeiras circulares, preferência de idioma salva e preservação do experimento.

[Laboratório online](https://kleberandrade.github.io/neural-engine/) · [Cenários e limites (EN)](doc/lab_scenarios.md) · [Validação e capturas reais (EN)](doc/lab_validation.md)

Redes neurais em Dart puro para aplicativos Flutter e serviços Dart. Treine
MLPs e CNNs com backpropagation, SGD ou Adam, organize dados com SOM de Kohonen
e explore autoencoders densos. Exporte modelos em JSON versionado. Núcleo sem dependências de execução.

[Extensibilidade](https://github.com/kleberandrade/neural-engine/blob/main/doc/extending.pt-BR.md) · [Persistência e checkpoints](https://github.com/kleberandrade/neural-engine/blob/main/doc/persistence.pt-BR.md) · [Arquitetura, estrutura e diagramas](https://github.com/kleberandrade/neural-engine/blob/main/doc/architecture.md) · [RNN/LSTM/GRU](https://github.com/kleberandrade/neural-engine/blob/main/doc/recurrent.pt-BR.md) · [Métricas e normalização](https://github.com/kleberandrade/neural-engine/blob/main/doc/evaluation.pt-BR.md) · [Guia didático dos modelos](https://github.com/kleberandrade/neural-engine/blob/main/doc/models.pt-BR.md) · [English](https://github.com/kleberandrade/neural-engine/blob/main/README.md) · [Laboratório Flutter](https://github.com/kleberandrade/neural-engine/blob/main/example/flutter_lab/README.md)

**Pacote:** [neural_engine](https://pub.dev/packages/neural_engine), pelo publisher verificado [kleberandrade.dev](https://pub.dev/publishers/kleberandrade.dev). Veja o [changelog](https://github.com/kleberandrade/neural-engine/blob/main/CHANGELOG.md).

## Modelos, exemplos e laboratório

| Modelo | Dart | Aba Flutter | O que observar |
| --- | --- | --- | --- |
| MLP | [XOR](https://github.com/kleberandrade/neural-engine/blob/main/example/neural_engine_example.dart), [regressão](https://github.com/kleberandrade/neural-engine/blob/main/example/regression.dart), [classes](https://github.com/kleberandrade/neural-engine/blob/main/example/classification.dart) | MLP | Perda e fronteira de decisão |
| SOM | [Cores RGB](https://github.com/kleberandrade/neural-engine/blob/main/example/som_colors.dart) | SOM | Protótipos antes/depois e erro de quantização |
| CNN | [Barras com ruído](https://github.com/kleberandrade/neural-engine/blob/main/example/cnn_bars.dart) | CNN | Imagem, probabilidades e canais da convolução |
| Autoencoder denso | [Reconstrução](https://github.com/kleberandrade/neural-engine/blob/main/example/autoencoder.dart) | Autoencoder | Entrada, alvo limpo, reconstrução e código latente |

O [guia completo](https://github.com/kleberandrade/neural-engine/blob/main/doc/models.pt-BR.md) explica cada arquitetura, os formatos dos
dados, os passos de treinamento e experimentos para modificar. Os exemplos dessa tabela usam dados
sintéticos; a aba Real data acrescenta os datasets locais documentados abaixo. RNN, LSTM e GRU estão implementados com saída no último passo; veja o guia de sequências.

## Treinamento assíncrono (0.4.0)

A versão 0.4.0 acrescenta avaliação incremental, progresso de avaliação separado
e controles explícitos de pausas. A 0.3.0 introduziu isolates no nativo, mini-batches cooperativos
na web, progresso e cancelamento com retomada. Veja o
[guia didático](https://github.com/kleberandrade/neural-engine/blob/main/doc/async_training.pt-BR.md)
e a aba **Async training** no Flutter. Use a versão 0.3.0 ou mais recente para essas APIs.
Veja os [exemplos reais](https://github.com/kleberandrade/neural-engine/blob/main/doc/real_world.pt-BR.md),
[medições](https://github.com/kleberandrade/neural-engine/blob/main/doc/benchmarks/responsiveness.md) e
[entregas da 0.4.0](https://github.com/kleberandrade/neural-engine/blob/main/doc/roadmap_0.4.0.md).

## Instalação

```yaml
dependencies:
  neural_engine: ^0.4.0
```

Requer Dart >=3.3.0. Compatível com Flutter.

## Exemplo: aprender XOR

```dart
import 'package:neural_engine/neural_engine.dart';

void main() {
  final network = NeuralNetwork(
    inputSize: 2,
    layers: [
      Dense(8, activation: Activation.tanh),
      Dense(1, activation: Activation.sigmoid),
    ],
    seed: 42,
  );
  final history = network.fit(
    inputs: [[0, 0], [0, 1], [1, 0], [1, 1]],
    targets: [[0], [1], [1], [0]],
    loss: const BinaryCrossEntropy(),
    optimizer: Adam(learningRate: 0.03),
    epochs: 1200,
    batchSize: 4,
  );
  print(history.losses.last);
  print(network.predict([0, 1]));
}
```

## Recursos

- JSON dos normalizadores e checkpoints de sessão com estado de Adam/SGD.
- Consumidor independente validando modelo, perda e otimizador customizados.

- Contratos de modelo/treinador e estrutura documentada com diagramas de classes.
- RNN, LSTM e GRU com BPTT completo, estado isolado e JSON.
- Normalização ajustada no treino, métricas e [medições locais reproduzíveis](https://github.com/kleberandrade/neural-engine/blob/main/doc/benchmarks/README.md).

- SOM retangular de Kohonen com vizinhança gaussiana e cronograma de taxa/raio.
- CNN ponta a ponta com Conv2D, padding valid/same, stride, MaxPool2D e saída densa.
- Exemplo de autoencoder denso, saídas intermediárias e gradientes das entradas.

- MLP com camadas densas; ativações linear, sigmoid, tanh, ReLU e softmax.
- Erro quadrático médio, entropia cruzada binária e categórica.
- Cálculo estável de sigmoid/BCE e softmax/CCE no treinamento e avaliação.
- Mini-batches, SGD e Adam com correção de viés.
- Inicialização e embaralhamento com seed; estado do otimizador isolado por `fit`.
- Histórico por época, conjunto de validação e early stopping.
- JSON versionado, snapshots de parâmetros e gradientes analíticos.
- Extensão por interfaces `Loss` e `Optimizer`.

| Problema | Ativação de saída | Perda | Alvo |
| --- | --- | --- | --- |
| Regressão | linear | `MeanSquaredError` | Vetor numérico |
| Binário ou múltiplos rótulos | sigmoid | `BinaryCrossEntropy` | Valores em `[0, 1]` |
| Classes exclusivas | softmax | `CategoricalCrossEntropy` | Distribuição com soma 1 |

MSE e BCE calculam média por saída e depois por amostra. CCE soma por classe e
calcula média por amostra. BCE exige saída sigmoid; CCE exige softmax.

Para early stopping, informe `validationInputs`, `validationTargets` e
`patience`. `minDelta` define a melhora mínima. Com patience habilitado, o modelo
restaura os pesos da melhor época qualificada, mesmo ao atingir o limite de
épocas. `bestEpoch` começa em 1. O histórico mantém todas as épocas executadas.

`toJson()` produz o modelo; `NeuralNetwork.fromJson(...)` restaura arquitetura e
pesos. Use `dart:convert` para codificar/decodificar. O JSON de inferência não contém momentos do Adam; use
[checkpoints de TrainingSession](https://github.com/kleberandrade/neural-engine/blob/main/doc/persistence.pt-BR.md) para retomar sessões. Cada chamada a `fit` reinicia o estado do
otimizador e a sequência de embaralhamento a partir da seed.

## Exemplos e validação

```sh
dart pub get
dart run example/neural_engine_example.dart
dart run example/regression.dart
dart run example/classification.dart
dart run example/som_colors.dart
dart run example/cnn_bars.dart
dart run example/autoencoder.dart
dart run example/recurrent_sequences.dart
dart run example/evaluation.dart
dart run example/custom_extensions.dart
dart run example/checkpoint.dart
dart run example/async_training.dart
dart run example/real_world.dart
dart analyze --fatal-infos
dart test
```

O laboratório Flutter oferece abas MLP, SOM, CNN e Autoencoder com treinamento
e visualizações próprias, além de Sequences, Checkpoints, Async training e Real data.
Interface em inglês; guia detalhado em português.
Os testes verificam gradientes por diferenças finitas, convergência, estabilidade
numérica, serialização e early stopping.

## Limitações

Voltado a modelos pequenos e aprendizado didático. O `fit` padrão é síncrono;
`AsyncTrainingTask` oferece isolate no nativo e lotes cooperativos na web.
Há alocações intermediárias por amostra; lotes grandes e avaliações do conjunto
ainda são unidades síncronas. Veja o guia assíncrono para os limites de agendamento. Sem GPU, ONNX ou importação TensorFlow. CNN não inclui
dilatação, batch normalization ou dropout; CNN, MLP e modelos recorrentes compartilham validação e early stopping. SOM usa aprendizado competitivo, sem backpropagation.
A repetibilidade é testada no mesmo SDK/plataforma; não há promessa de igualdade
bit a bit entre plataformas. O treinamento modifica os pesos. Em caso de erro,
os batches já concluídos permanecem aplicados.

Separe os conjuntos antes de calcular normalização e avalie generalização em
um conjunto de teste independente. XOR não demonstra qualidade em dados reais.

`fuzzy_engine`, `genetic_engine` e `neural_engine` permanecem independentes.
Os próximos candidatos são modelos clássicos e novas configurações recorrentes, sempre
acompanhados de testes, exemplos Dart/Flutter e documentação didática.

MIT © 2026 Kleber Andrade.

Na aba Flutter **Checkpoints**, salve/carregue JSON e compare a retomada com
um treinamento contínuo. Veja as [medições](https://github.com/kleberandrade/neural-engine/blob/main/doc/benchmarks/README.md)
e a [validação pelo pub.dev](https://github.com/kleberandrade/neural-engine/blob/main/validation/hosted/README.md).


0.4.0: [avaliação incremental e pausas](https://github.com/kleberandrade/neural-engine/blob/main/doc/async_training.pt-BR.md), [medições e limites](https://github.com/kleberandrade/neural-engine/blob/main/doc/benchmarks/scheduling_0.4.0.md).
