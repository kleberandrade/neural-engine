# Avaliação, normalização e validação da CNN

[English](evaluation.md)

Ajuste `StandardScaler.fit(treino)` ou `MinMaxScaler.fit(treino)` apenas com dados
de treino. Reutilize `transform` na validação/teste e `inverseTransform` para
retornar à escala original. Os objetos ajustados são imutáveis. Guarde as
estatísticas públicas junto ao modelo na aplicação quando precisar reproduzir
o pré-processamento em produção.

```dart
final scaler = StandardScaler.fit(trainingRows);
final normalized = trainingRows.map(scaler.transform).toList();
final validation = validationRows.map(scaler.transform).toList();
```

O desvio padrão é populacional. Atributos constantes usam escala 1; no min/max,
usam amplitude 1. MinMaxScaler não corta valores de teste fora da faixa: um valor
normalizado maior que 1 pode ser legítimo. Dimensões e números finitos são
validados. Evite misturar estatísticas de treino com o futuro de uma série temporal.

`ClassificationMetrics.fromLabels` calcula acurácia, precisão, recall e F1 por
classe, além de macro F1. As linhas da matriz de confusão são classes reais e as
colunas são previsões; divisões indefinidas retornam zero. Converta probabilidades
em rótulos com argmax ou um limiar escolhido antes da avaliação final.

```dart
final report = ClassificationMetrics.fromLabels(
  targets: [0, 0, 1, 1], predictions: [0, 1, 1, 1], classCount: 2,
);
print(report.accuracy); // 0.75
print(report.confusionMatrix); // [[1, 1], [0, 2]]
```

`RegressionMetrics` fornece MSE, MAE, RMSE e R². Para alvos constantes, R² vale 1
se todas as previsões forem exatas e 0 nos demais casos. Para reconstrução,
achate coordenadas correspondentes dos alvos e previsões, preservando alinhamento.
Não confunda perda usada no treinamento com métricas de qualidade do produto.

CNN agora oferece a mesma validação, early stopping e clipping dos outros modelos
supervisionados, por meio de `MiniBatchTrainer`:

```dart
final history = cnn.fit(
  inputs: trainingImages, targets: trainingLabels,
  validationInputs: validationImages, validationTargets: validationLabels,
  loss: const CategoricalCrossEntropy(), optimizer: Adam(learningRate: 0.02),
  epochs: 100, patience: 15, minDelta: 0.0001, maxGradientNorm: 1,
);
```

Os nomes referem-se à CNN/dados preparados no exemplo completo. `patience` exige
validação e restaura a melhor época qualificada; o histórico mantém todas as
épocas executadas. O conjunto de teste não escolhe o ponto de parada. Execute
`dart run example/cnn_bars.dart` para ver dados sintéticos separados e o relatório
de classificação. O resultado não comprova qualidade em imagens reais.
