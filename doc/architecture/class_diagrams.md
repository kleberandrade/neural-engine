# Class diagrams / Diagramas de classes

These diagrams show implemented relationships, split by concern. Public exports
are listed in `lib/neural_engine.dart`; executor/cache classes are internal.

## Models and trainer

```mermaid
classDiagram
  direction TB
  class Predictor {
    <<interface>>
    predict(input)
  }
  class ParameterizedModel {
    <<interface>>
    parameterCount
    parameters
  }
  class DifferentiableModel {
    <<interface>>
    gradients(input, target, loss)
    evaluate(inputs, targets, loss)
  }
  class MiniBatchTrainer {
    fit(model, inputs, targets)
  }
  Predictor <|-- DifferentiableModel
  ParameterizedModel <|-- DifferentiableModel
  DifferentiableModel <|.. NeuralNetwork
  DifferentiableModel <|.. ConvolutionalNetwork
  DifferentiableModel <|.. RecurrentNetwork
  MiniBatchTrainer --> DifferentiableModel
```

## Training collaborators

```mermaid
classDiagram
  direction TB
  class Optimizer {
    <<interface>>
    createState(parameterCount)
  }
  class OptimizerState {
    <<interface>>
    update(parameters, gradients)
  }
  class Loss {
    <<interface>>
    value(predicted, target)
    gradient(predicted, target)
  }
  Optimizer <|.. SGD
  Optimizer <|.. Adam
  Optimizer --> OptimizerState : creates per fit
  MiniBatchTrainer --> Optimizer
  MiniBatchTrainer --> Loss
  MiniBatchTrainer --> TrainingHistory : returns
```

## Recurrent transition and session state

```mermaid
classDiagram
  direction TB
  class RecurrentCell {
    <<interface>>
    forward(input, previous)
    backward(step, upstream)
  }
  RecurrentCell <|.. SimpleRnnCell
  RecurrentCell <|.. LstmCell
  RecurrentCell <|.. GruCell
  RecurrentNetwork *-- RecurrentCell
  RecurrentCell --> RecurrentStep : creates
  RecurrentStep *-- RecurrentState
  RecurrentCell --> RecurrentDerivatives : returns
  RecurrentDerivatives *-- RecurrentState : previous gradient
```

## Spatial and dense composition

```mermaid
classDiagram
  direction TB
  SpatialLayer <|-- Conv2D
  SpatialLayer <|-- MaxPool2D
  ConvolutionalNetwork *-- SpatialStage
  SpatialStage --> SpatialLayer
  ConvolutionalNetwork *-- NeuralNetwork : dense head
  ConvolutionalNetwork --> SpatialPass
  SpatialPass *-- ImageTensor
  NeuralNetwork *-- DenseExecution
  DenseExecution --> DensePass
```

## Unsupervised model and preprocessing

```mermaid
classDiagram
  direction TB
  class UnsupervisedModel {
    <<interface>>
    quantizationError(inputs)
  }
  class FeatureTransform {
    <<interface>>
    transform(input)
    inverseTransform(input)
  }
  UnsupervisedModel <|.. SelfOrganizingMap
  SelfOrganizingMap --> SomMatch
  SelfOrganizingMap --> SomHistory
  FeatureTransform <|.. StandardScaler
  FeatureTransform <|.. MinMaxScaler
```

Class names refer to Dart types. Free numerical functions `spatialForward` and
`spatialBackward` are intentionally described in the structure/training documents,
not invented as classes in this diagram. SOM is not a DifferentiableModel.


## Optional persistence contracts

```mermaid
classDiagram
  direction TB
  Optimizer <|-- CheckpointOptimizer
  OptimizerState <|-- CheckpointOptimizerState
  CheckpointOptimizer <|.. Adam
  CheckpointOptimizer <|.. SGD
  TrainingSession --> MiniBatchTrainer
  TrainingSession --> CheckpointOptimizer
  TrainingSession --> CheckpointOptimizerState
  TrainingSession --> TrainingCheckpoint
```

A custom plain Optimizer remains usable without implementing checkpoint support.
TrainingSession.restore accepts explicit application-owned model/optimizer decoders.
