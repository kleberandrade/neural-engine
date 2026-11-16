# neural_engine

Redes neurais em Dart puro para aplicativos Flutter e serviços Dart. Treine
redes densas feedforward com backpropagation, SGD ou Adam e exporte modelos de
inferência em JSON versionado. Núcleo sem dependências de execução.

[English](README.md) · [Arquitetura](doc/architecture.md) · [Laboratório Flutter](example/flutter_lab/README.md)

**Estado:** versão inicial 0.1.0 no código-fonte, ainda não publicada no pub.dev.

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
| Binário ou múltiplos rótulos | sigmoid | `BinaryCrossEntropy` | Valores em [0, 1] |
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
dart analyze --fatal-infos
dart test
```

O laboratório Flutter permite ajustar neurônios e taxa de aprendizado e ver a
curva de perda, a superfície de decisão e as previsões. Interface em inglês.
Os testes verificam gradientes por diferenças finitas, convergência, estabilidade
numérica, serialização e early stopping.

## Limitações

Voltado inicialmente a modelos densos pequenos. Treinamento síncrono, com
alocações intermediárias por amostra; use isolate no Flutter nativo para cargas
maiores. Na web, `compute` executa na thread principal: use worker para cargas
maiores. Sem GPU, CNN, redes recorrentes, ONNX ou importação TensorFlow.
A repetibilidade é testada no mesmo SDK/plataforma; não há promessa de igualdade
bit a bit entre plataformas. O treinamento modifica os pesos. Em caso de erro,
os batches já concluídos permanecem aplicados.

Separe os conjuntos antes de calcular normalização e avalie generalização em
um conjunto de teste independente. XOR não demonstra qualidade em dados reais.

`fuzzy_engine`, `genetic_engine` e `neural_engine` permanecem independentes.
Uma integração de neuroevolução poderá ser adicionada em exemplo separado.

MIT © 2026 Kleber Andrade.
