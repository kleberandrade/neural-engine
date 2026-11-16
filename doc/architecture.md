# Concepts and architecture

A dense layer computes `activation(Wx + b)`. Training evaluates the chosen loss,
propagates derivatives backward and updates parameters once per mini-batch.

- `activation.dart`: immutable Dense specification and activation operations.
- `loss.dart`: loss/gradient interface and three built-in losses.
- `optimizer.dart`: optimizer configuration and fresh per-fit update state.
- `network.dart`: model parameters, forward/backward passes, training and JSON.
- `neural_engine.dart`: public exports; consumers never need internal imports.

No IO, Flutter, execution workers or other engine packages enter the core.
Layer specifications are immutable and reusable across networks. Training
mutates a network; prediction returns independent immutable snapshots.

## Parameter layout

Layers appear in declaration order. Within a layer, neurons appear in index
order; each neuron's incoming weights are followed by its bias. A dense layer
with input width m and output width n has n × (m + 1) parameters.

`parameters` returns an immutable snapshot. Its setter checks length and finite
values and copies the input. `gradients` returns a sample gradient in exactly
this order, suitable for finite differences or external weight optimization.

## Numerical behavior

Glorot uniform initialization uses ±sqrt(6/(fanIn+fanOut)); ReLU uses He uniform
±sqrt(6/fanIn). Biases start at zero. Sigmoid and tanh avoid positive exponential
overflow. Softmax subtracts the maximum logit. Its backward pass uses the full
Jacobian-vector product y_i × (g_i − dot(y,g)). ReLU's derivative is zero at 0.

Sigmoid/BCE uses softplus(z) − t×z and gradient (sigmoid(z)−t)/outputWidth.
Softmax/CCE uses log-sum-exp and gradient softmax(z)−t. These fused paths preserve
learning even when probabilities round to exactly zero or one. Standalone
probability-space cross-entropy methods clip probabilities to 1e-15; the network
fused path is preferred for extreme logits.

Custom losses provide output-space derivatives. Gradients average over actual
mini-batch size, including a partial final batch. Adam's timestep advances once
per batch; moment correction uses 1−beta^step. Each `fit` starts fresh optimizer
state, even when a configuration is reused. Models are not resumable checkpoints.

Inputs, targets, dimensions, loss/activation pairs and optimizer configuration
are validated. Built-in target domains are checked before the first update.
Nonfinite activations, gradients, losses and candidate parameters fail explicitly.
Optimizer candidates are checked before committing a batch. Earlier completed
batches are not rolled back if a later update fails.

## Early stopping

Losses are measured after each full epoch. Validation is evaluated separately.
With patience set, the best qualifying validation epoch is restored at the end.
Improvement means value < best − minDelta. The first epoch is the initial best;
there is no epoch-zero comparison. Histories keep all executed epochs.

## Verification

Public API tests compare every parameter derivative against central finite
differences for all activations with MSE and the supported cross-entropy pairs,
including a hidden softmax. Other tests cover known updates, saturated logits,
XOR convergence across three seeds, regression, multiclass classification,
partial batches, independent optimizer state, JSON and early stopping.

CI checks the minimum Dart SDK as well as stable. Dart VM tests do not establish
bit-identical floating-point behavior across JS, devices or SDK versions.

## JSON v1

Fields: `format: neural_engine`, `version: 1`, `inputSize`, `seed`, `layers`
(each with units and activation name) and a flat `parameters` array. Import
rejects unknown format/version/activation, invalid dimensions, malformed data
and nonfinite weights. Unknown extra fields are ignored for forward metadata
compatibility. Model files are trusted application data: callers should impose
size limits before decoding untrusted files. There is no optimizer state.
