# neural_engine

Redes neurais em Dart puro para aplicativos Flutter e serviços Dart. Treine
MLPs e CNNs com backpropagation, SGD ou Adam, organize dados com SOM de Kohonen
e explore autoencoders densos. Exporte modelos em JSON versionado. Núcleo sem dependências de execução.

[Arquitetura, estrutura e diagramas](doc/architecture.md) · [RNN/LSTM/GRU](doc/recurrent.pt-BR.md) · [Métricas e normalização](doc/evaluation.pt-BR.md) · [Guia didático dos modelos](doc/models.pt-BR.md) · [English](README.md) · [Arquitetura](doc/architecture.md) · [Laboratório Flutter](example/flutter_lab/README.md)

**Versão do código-fonte:** 0.2.0. Veja a [preparação da release](doc/release_0.2.0.md). Publicação é uma etapa manual.

## Modelos, exemplos e laboratório

| Modelo | Dart | Aba Flutter | O que observar |
| --- | --- | --- | --- |
| MLP | [XOR](example/neural_engine_example.dart), [regressão](example/regression.dart), [classes](example/classification.dart) | MLP | Perda e fronteira de decisão |
| SOM | [Cores RGB](example/som_colors.dart) | SOM | Protótipos antes/depois e erro de quantização |
| CNN | [Barras com ruído](example/cnn_bars.dart) | CNN | Imagem, probabilidades e canais da convolução |
| Autoencoder denso | [Reconstrução](example/autoencoder.dart) | Autoencoder | Entrada, alvo limpo, reconstrução e código latente |

O [guia completo](doc/models.pt-BR.md) explica cada arquitetura, os formatos dos
dados, os passos de treinamento e experimentos para modificar. Os dados são
sintéticos e gerados localmente. RNN, LSTM e GRU estão implementados com saída no último passo; veja o guia de sequências.

## Instalação pelo GitHub

```yaml
dependencies:
  neural_engine:
    git:
      url: https://github.com/kleberandrade/neural-engine.git
      ref: main
```

Fixe um commit para aplicações reproduzíveis. Requer Dart >=3.3.0.

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

- Contratos de modelo/treinador e estrutura documentada com diagramas de classes.
- RNN, LSTM e GRU com BPTT completo, estado isolado e JSON.
- Normalização ajustada no treino, métricas e [medições locais reproduzíveis](doc/benchmarks/README.md).

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
pesos. Use `dart:convert` para codificar/decodificar. O formato não contém momentos
do Adam ou progresso de treinamento. Cada chamada a `fit` reinicia o estado do
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
dart analyze --fatal-infos
dart test
```

O laboratório Flutter oferece abas MLP, SOM, CNN e Autoencoder com treinamento
e visualizações próprias. Interface em inglês; guia detalhado em português.
Os testes verificam gradientes por diferenças finitas, convergência, estabilidade
numérica, serialização e early stopping.

## Limitações

Voltado a modelos pequenos e aprendizado didático. Treinamento síncrono, com
alocações intermediárias por amostra; use isolate no Flutter nativo para cargas
maiores. Na web, `compute` executa na thread principal: use worker para cargas
maiores. Sem GPU, ONNX ou importação TensorFlow. CNN não inclui
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
