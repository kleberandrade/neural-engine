# Extensibilidade validada pela API pública

[English](extending.md) · [Persistência](persistence.pt-BR.md)

`example/extensions/` é um pacote Dart consumidor, com seu próprio `pubspec.yaml`.
Ele depende do SDK pela API pública e não importa `lib/src`. A mesma verificação
executa no Dart mínimo e estável no CI.

```sh
dart run example/custom_extensions.dart
cd example/extensions
dart pub get
dart analyze --fatal-infos
dart run main.dart
```

| Implementação externa | Contrato | Verificação |
| --- | --- | --- |
| `HuberLoss` | Loss | Derivada numérica e treino no modelo denso integrado |
| `MomentumOptimizer` | CheckpointOptimizer | Estado novo por fit e continuação exata com decoder próprio |
| `LinearModel` | DifferentiableModel e JsonModel | Treinamento pelo MiniBatchTrainer sem herdar NeuralNetwork |

A perda Huber é quadrática perto de zero e linear fora de delta. O gradiente deve
corresponder à mesma redução usada por `value`, incluindo média por saída.
O modelo linear fornece previsão, parâmetros imutáveis por snapshot, derivadas
de uma amostra e perda média de um conjunto. O otimizador mantém velocidade
apenas no estado de cada execução, não na configuração compartilhável.

Para iniciar a exploração, leia os três arquivos separados em
`example/extensions/`. O teste também serializa e restaura modelo/otimizador
externos com callbacks explícitos e compara o checkpoint completo com uma
execução contínua. Não há alteração de registro ou checagem do nome da classe
customizada no treinador.

## Contratos e limites

- `predict` retorna uma previsão independente; os parâmetros não vazam por listas mutáveis.
- `gradients` deve ter a dimensão de `parameterCount`, na mesma ordem dos parâmetros.
- `evaluate` deve validar seu conjunto e devolver perda finita; o treinador rejeita NaN/Infinity na fronteira.
- `OptimizerState.update` altera somente o vetor candidato recebido; dimensão e finitude são verificadas antes de confirmar os pesos.
- Configuração do otimizador não deve compartilhar estado de treino entre modelos.
- Persistência customizada exige esquema versionado e decoder de estado explícito.

Os testes negativos cobrem gradiente de dimensão errada, avaliação não finita e
um otimizador que muda o tamanho do vetor, sem confirmar pesos inválidos.

Esses contratos não prometem extensão automática de toda família. Uma nova
`SpatialLayer` ainda exige suporte explícito no executor/serialização da CNN.
Uma `RecurrentCell` pode ser implementada/combinada pela aplicação, mas o seletor
integrado `RecurrentKind` e seu JSON reconhecem apenas RNN/LSTM/GRU conhecidos.
Novas famílias numéricas continuam exigindo gradientes, testes e documentação.
