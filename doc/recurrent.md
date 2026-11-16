# RNN, LSTM and GRU sequence forecasting

[Português](recurrent.pt-BR.md) · [Class diagrams](architecture/class_diagrams.md)

`RecurrentNetwork` implements a many-to-one model: read a sequence of feature
vectors, then project the final hidden state through a Dense output layer. Data
shape is samples × timesteps × features. Each independent call starts at zero
hidden/memory state; no inference session leaks into the next prediction.

```dart
final model = RecurrentNetwork(
  inputSize: 1, hiddenSize: 6, outputSize: 1,
  kind: RecurrentKind.lstm, outputActivation: Activation.linear, seed: 42,
);
final history = model.fit(
  inputs: trainingSequences, targets: trainingTargets,
  loss: const MeanSquaredError(), optimizer: Adam(learningRate: 0.015),
  epochs: 180, batchSize: 8, maxGradientNorm: 1,
);
final states = model.trace([[0.0], [0.2], [0.4]]);
```

Import the public library. The complete data preparation and evaluation are in:

```sh
dart run example/recurrent_sequences.dart
```

The same sine-family forecasting problem compares six hidden units in each
model. Inputs contain six samples separated by 0.25 radians; the target is the
next sample. Test phases interleave training phases, so this is an interpolation
fixture, not evidence of generalization to real series or long-term memory.

| Cell | Equations / variant |
| --- | --- |
| Simple RNN | `h = tanh(Wx + Uh_previous + b)` |
| LSTM | `c = f*c_previous + i*g`, `h = o*tanh(c)`; sigmoid i/f/o, tanh g; no peepholes |
| GRU | `n = tanh(Wx + U(r*h_previous) + b)`, `h = (1-z)*n + z*h_previous`; reset-before |

GRU reset-before weights are not compatible with reset-after implementations.
Equal hidden sizes do not imply equal parameter counts; the example reports
counts, held-out MSE/MAE and local elapsed training time.

Full backpropagation through time accumulates gradients of the same cell weights
across all timesteps. Every-parameter finite-difference tests span several steps.
The common trainer supports validation, early stopping and optional global-norm
clipping of averaged batch gradients. Clipping is a tool, not a guarantee of
convergence. Model JSON preserves architecture/weights, not optimizer moments
or a live sequence state.

Flutter's **Sequences** tab compares all three and plots loss and hidden states,
plus LSTM memory. Maps use local contrast; tooltips show actual values. Try
changing window size, frequency and hidden units before applying the model to
real data. Real time series require temporal splits without future leakage and
normalization fitted exclusively on training observations.

Current limits: final-step supervision only; no stacking, bidirectionality,
masks, padding, truncated BPTT, recurrent dropout or GPU. Variable-length
nonempty sequences are accepted; intermediate storage grows with sequence length.
