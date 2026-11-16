# Source structure / Estrutura do código

Use this map to locate a responsibility before adding a class. Production code
is under `lib/src`; its classes are exported selectively through the public
`lib/neural_engine.dart`. There are no `part` files hiding a single giant library.

| Directory | Classes / responsibility | Dependency rule |
| --- | --- | --- |
| `lib/src/contracts/` | Predictor, ParameterizedModel, DifferentiableModel, UnsupervisedModel, JsonModel | No concrete model dependency |
| `lib/src/activations/` | Activation and its Jacobian-vector products | Math only |
| `lib/src/layers/` | Dense specification | Activation only |
| `lib/src/layers/spatial/` | SpatialLayer, Conv2D, MaxPool2D, ConvolutionPadding | Specs, not training loops |
| `lib/src/tensors/` | Immutable ImageTensor, HWC indexing | No model dependency |
| `lib/src/losses/` | Loss interface; MSE, binary/ categorical CE in separate files | No trainer/model dependency |
| `lib/src/optimizers/` | Optimizer/OptimizerState contracts; SGD, Adam | Flat vectors, no model dependency |
| `lib/src/training/` | MiniBatchTrainer, TrainingHistory, TrainingSession | Depends on model contract, not concrete family |
| `lib/src/models/dense/` | NeuralNetwork facade, DenseExecution, DensePass/derivatives | Numerical passes separate from lifecycle |
| `lib/src/models/cnn/` | ConvolutionalNetwork, SpatialStage/Pass, separate forward/backward functions | Composes dense head and spatial passes |
| `lib/src/models/som/` | SelfOrganizingMap, SomMatch, SomHistory | Competitive learning independent of supervised trainer |
| `lib/src/models/recurrent/` | RecurrentNetwork, RecurrentCell interface, state/step/derivative types, kind | Sequence composition and BPTT |
| `lib/src/models/recurrent/cells/` | SimpleRnnCell, LstmCell, GruCell, CellWeights | One transition implementation per file; affine helper shared |
| `lib/src/preprocessing/` | FeatureTransform, StandardScaler, MinMaxScaler | Fit on training samples only |
| `lib/src/persistence/` | TrainingCheckpoint, OptimizerCodec and boundary validation | IO stays in applications |
| `lib/src/metrics/` | ClassificationMetrics, RegressionMetrics | Reporting, separate from optimization loss |
| `test/` | Public behavior, finite differences, fixtures | Imports public library, not private implementation |
| `example/` | Runnable Dart walkthroughs | Synthetic data, convergence checks |
| `example/flutter_lab/lib/` | App shell, pages, painters, widgets, data and runners | No Flutter imports enter package core |
| `benchmark/` | Repeatable local workload measurements | IO allowed here, never interpreted as quality tests |
| `doc/architecture/` | Source map, decisions, diagrams, contracts | Must match actual code |

## Navigation examples

- Change early stopping: `training/mini_batch_trainer.dart`, then shared lifecycle tests.
- Inspect CNN padding: `models/cnn/spatial_stage.dart` and spatial gradient tests.
- Inspect LSTM gates: `models/recurrent/cells/lstm_cell.dart`.
- Add a reporting metric: `metrics/`, without changing optimizers.
- Change model JSON: the relevant facade factory, then roundtrip/rejection tests.
- Change Flutter rendering: `pages/`, `widgets/` or `painters/`, not a training runner.

## Naming and ownership

Names describe the role: a specification is not a trained operator, a prediction
is not a metric report, and a serialized model is not an optimizer checkpoint.
Private caches may be colocated with the numerical operation that creates them.
Small shared value objects may share a file when they form one pass result.
Avoid adding interfaces with no consumer; contracts above are used in execution.
