# Persistence and training continuation

[Português](persistence.pt-BR.md) · [Extension guide](extending.md)

Inference JSON, fitted preprocessing and resumable optimizer state are separate
artifacts. `StandardScaler` and `MinMaxScaler` now have version-1 `toJson`/`fromJson`
formats. Restoring does not fit against new data. Dimensions, finite vectors and
positive scales/ranges are validated; constant features retain scale/range 1.
Exported objects and checkpoint getters are independent snapshots.

```dart
final restored = StandardScaler.fromJson(
  jsonDecode(jsonEncode(scaler.toJson())) as Map<String, dynamic>,
);
```

Import `dart:convert` and the public package. Save input and target transforms
with the model when needed by the application.

## Fixed-epoch sessions

Ordinary `model.fit` still starts fresh optimizer state. To preserve Adam moments
and batch order, start with `TrainingSession<I>` and use it throughout:

```dart
final session = TrainingSession<List<double>>(
  model: network, optimizer: Adam(learningRate: 0.03), seed: 42,
);
session.fit(inputs: x, targets: y, loss: const MeanSquaredError(),
  epochs: 40, batchSize: 3);
final checkpoint = TrainingCheckpoint.fromJson(
  jsonDecode(jsonEncode(session.checkpoint().toJson())) as Map<String, dynamic>,
);
final resumed = TrainingSession<List<double>>.restore(
  checkpoint: checkpoint, modelDecoder: NeuralNetwork.fromJson,
);
resumed.fit(inputs: x, targets: y, loss: const MeanSquaredError(),
  epochs: 60, batchSize: 3);
```

The complete fixture is `dart run example/checkpoint.dart`. It checks that 100
continuous session epochs equal 40 + restore + 60, including Adam moments/step.
Tests cover Dense, CNN, RNN, LSTM and GRU with both Adam and SGD, shuffling,
partial batches and clipping.

A checkpoint contains model JSON, optimizer configuration/state, completed epoch
count and seed. Each session epoch derives its own shuffle from its absolute
epoch index. To replay exactly, retain the same ordered data, loss, batch size,
shuffle and clipping settings, within the same SDK/platform. Ordinary `fit` and
session shuffle policies are intentionally distinct; replay starts in a session.

Do not mutate model weights outside an active session. Capture checkpoints only
between completed fits, not mid-batch. A failed session cannot continue or emit
a checkpoint; restore its last valid snapshot. Earlier committed batches are
not rolled back on failure.

Sessions currently use fixed epochs. Ordinary early stopping restores the best
weights but does not promise optimizer continuation. This prevents pairing
restored older weights with newer Adam moments. Datasets, loss, histories,
scalers and validation policies are not silently embedded in checkpoints.

## External codecs

`CheckpointOptimizer`/`CheckpointOptimizerState` are optional extensions of the
existing optimizer contracts. Custom plain Optimizer implementations continue to
work in MiniBatchTrainer. For resumable custom state, supply explicit loaders:

```dart
final resumed = TrainingSession<List<double>>.restore(
  checkpoint: checkpoint, modelDecoder: LinearModel.fromJson,
  optimizerDecoder: MomentumOptimizer.fromJson,
);
```

Those examples live in the independent `example/extensions` consumer. The built-in
optimizer codec only accepts Adam/SGD. The checkpoint envelope validates format
and progress; family model and optimizer decoders validate their payloads when
restoring. IO and untrusted-file size limits remain application responsibilities.
SOM inference JSON remains supported, but competitive-learning schedules are not
an optimizer checkpoint handled by TrainingSession.

## Flutter save/load experiment

The [Checkpoints walkthrough](../example/flutter_lab/README.md#checkpoint-walkthrough)
trains MLP, CNN, RNN, LSTM or GRU for 40 epochs, exports editable JSON via an
explicit copy action and restores a new model/session after reopening the app.
Resuming 60 epochs compares predictions and full Adam/model state with an
uninterrupted reference. The page reports training loss and checkpoint bytes.
Save the copied text yourself; clipboard export does not automatically write a
file. The [hosted consumer](../validation/hosted/README.md) demonstrates real
Dart file IO and verifies the released pub.dev artifact independently.
