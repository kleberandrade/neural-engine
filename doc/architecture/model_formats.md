# Model formats and parameter ordering

All model JSON is versioned inference data, not a resumable optimizer checkpoint.
Use the matching family factory. Applications own IO and file-size/resource limits
when accepting untrusted model files.

| Family | Format / version | Parameter layout |
| --- | --- | --- |
| Dense / dense autoencoder | `neural_engine`, 1 | Layers, neurons, incoming weights, bias |
| SOM | `neural_engine_som`, 1 | Row-major neurons, feature prototypes |
| CNN | `neural_engine_cnn`, 1 | Spatial layers, filters, kernel row/column/input channel, filter bias; then dense head |
| Recurrent | `neural_engine_recurrent`, 1 | Cell gate blocks; then dense output head |

Each recurrent gate block contains rows in hidden-unit order. Each row contains
input weights, previous-hidden weights and bias. RNN has one tanh block; LSTM
order is input/forget/output/candidate; GRU order is update/reset/candidate.
GRU candidate uses reset-before `U(r*h)` and is not weight-compatible with
reset-after implementations. JSON retains the recurrent kind and output activation.

Initializers are deterministic for the same seed/SDK/platform. Imports validate
format/version, dimensions, finite parameters and matching nested head dimensions.
Older Dense, SOM and CNN version-1 model payloads remain loadable after the folder
refactor. The public package import remains stable; internal source imports are
unsupported and changed locations.

StandardScaler/MinMaxScaler fitted statistics must be saved alongside a model by
the application when deployment needs the same preprocessing; model JSON does not
silently fit or embed a scaler. Do not refit against production/test inputs.
