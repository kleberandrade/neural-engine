# Training lifecycle and numerical contracts

Dense, CNN and recurrent facades delegate to `MiniBatchTrainer<I>`. Input type I
is a vector, an HWC tensor, or a sequence of vectors. The trainer works against
`DifferentiableModel<I>` and never switches on concrete model types.

1. Validate configuration and evaluate all training/validation data before updates.
2. Create fresh optimizer state and a fresh seeded shuffle sequence.
3. Accumulate per-sample gradients and average by actual mini-batch size.
4. Optionally clip the batch gradient by global L2 norm.
5. Update a candidate parameter vector; validate length and finite values before committing.
6. Measure training and optional validation loss after each epoch.
7. With patience enabled, restore the best qualifying validation epoch at the end.

`bestEpoch` is one-based. Improvement means loss < best − minDelta. History keeps
all executed epochs, so its last value may differ from the restored model's loss.
Clipping is disabled unless `maxGradientNorm` is supplied. A new `fit` continues
weights but resets optimizer moments, stopping counters and the shuffle sequence.
Failures do not roll back previously completed mini-batches.

## Numerical rules

- Dense: Glorot uniform, or He uniform for ReLU; zero biases.
- Sigmoid/tanh avoid positive exponential overflow; softmax subtracts max logits.
- Sigmoid/BCE and softmax/CCE use fused stable logit loss and derivatives.
- MSE/BCE average coordinates then samples; CCE sums classes then averages samples.
- Max pooling routes gradients to the first maximum; overlapping routes sum.
- CNN same padding puts odd excess at bottom/right; stride controls output dimensions.
- Recurrent models use full BPTT and supervise the final output only.
- Each recurrent prediction starts with zero hidden state and zero LSTM memory.
- Simple RNN uses tanh; LSTM has no peepholes; GRU is reset-before.
- StandardScaler uses population standard deviation; constant features use scale 1.
- MinMaxScaler maps training endpoints to 0/1 without clipping held-out values.

## Verification

Central finite differences check every Dense/CNN/recurrent parameter in small
models. Temporal tests use multiple timesteps so recurrent dependencies and gate
paths participate in the derivative. Other tests pin known updates, shape errors,
immutability, saturated logits, optimizer state isolation, seed repeatability,
JSON compatibility and best-validation-weight restoration.

Synthetic convergence examples are checks of numerical behavior, not evidence
of real-world generalization. Benchmarks report workloads and environment; model
families have different parameter counts and compute costs.

## Continuing a session

TrainingSession injects retained optimizer state and an absolute epoch offset into
the same trainer. Its per-epoch shuffle is reproducible across checkpoint
boundaries; ordinary fit retains its existing fresh-run behavior. Sessions use
fixed epochs, with no silent reuse of early-stopping weights and mismatched
optimizer moments. A failed session must restore a previous valid checkpoint.
See [persistence](../persistence.md) for exact-replay requirements.

## Async scheduling (0.3.0)

MiniBatchTrainer.fit drains the same steps iterator used by fitAsync. The iterator
yields after each committed batch. TrainingSession.fitAsync uses retained optimizer
state and absolute epoch shuffles, yields via timers, reports complete epochs, and
checks cancellation only at epoch boundaries. Concurrent session training/checkpoint
calls are rejected. Async sessions have fixed epochs and optional validation metrics,
without best-weight restoration. AsyncTrainingTask selects native isolate transport
or web cooperative execution using conditional imports. Built-in codecs are separate
from the model-agnostic trainer. See [async lifecycle](../async_training.md).
