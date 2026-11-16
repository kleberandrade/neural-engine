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
