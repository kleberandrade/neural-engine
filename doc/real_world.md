# Real-data examples: fixed recipes and reserved tests

Run `dart run example/real_world.dart`, or choose **Real data** in the Flutter lab.
Both clients share `example/flutter_lab/lib/real_world/` classes, pinned offline observations and
the public asynchronous API. Sources, attribution and snapshot hashes are in
[example/data](../example/data/README.md). No dataset is downloaded at runtime.

## Iris classification

The four measurements in centimeters enter Dense(8, tanh), then Dense(3, softmax).
Seed 42, Adam 0.01, batch 16, gradient clipping 1, 120 epochs are fixed in advance.

1. Remove exact feature/label duplicates from the original 150 source rows.
2. Shuffle each class with seed `42 + classIndex`.
3. Take floor(60%) for training and floor(20%) for validation; reserve the rest.
4. Fit StandardScaler using training features only, then transform other splits.
5. Train with CCE; validation is diagnostic, not a test-driven stopping rule.
6. Evaluate the reserved test partition once, reporting accuracy, macro-F1 and a
   confusion matrix (actual rows, predicted columns). Compare with the majority
   class determined from training counts; ties use the lowest class index.

This snapshot has 147 unique observations: **87 training, 28 validation, 32 test**.
There are no identical feature rows crossing partitions after deduplication.
Original source row indices are retained for audit. The UCI CSV's noted original
measurement differences are preserved rather than silently corrected.

A recorded macOS/Dart run achieved **0.875 accuracy**, **0.872727 macro-F1** and
**0.3125 majority accuracy**. These are one fixed split and recipe, not a
cross-validation estimate, a tuned best result or a production claim. Do not tune
this recipe on the published test results; a new experiment needs a new protocol.

## Monthly AirPassengers forecasting

The 144 monthly observations span January 1949–December 1960, in **thousands of
passengers**. The example predicts one next month from 12 previous observed months.

| Target partition | Dates | Targets |
| --- | --- | --- |
| Training | Jan 1950–Dec 1956 | 84 |
| Validation | Jan 1957–Dec 1958 | 24 |
| Test | Jan 1959–Dec 1960 | 24 |

The first 12 observations supply lags, not training targets. Apply log to the
positive observations and fit StandardScaler on observations through December
1956 only. The scaler never sees later statistics. Each target's input ends at
its previous month; targets are never randomly shuffled into earlier partitions.

The GRU has 8 hidden units and a linear output. Seed 42, Adam 0.01, batch 12,
clipping 1, 100 epochs and `shuffle: false` are fixed. Validation loss is reported;
this example does not choose hyperparameters, model family or best weights from
the test data. Inverse scaling followed by exp returns original units.

Evaluation is **rolling one-step forecasting with observed history**. For February
1959, January 1959's observation is available as an input. This is not a recursive
24-step forecast made from December 1958. Overlap between lag windows is expected;
no input contains the value of its own target or any future month.

Report MAE/RMSE and two baselines under exactly that same information protocol:
previous month (`y[t-1]`) and same month of previous year (`y[t-12]`). A recorded
run gave GRU MAE **68.64 thousand**, versus **44.21** for previous month and **47.58**
for previous year. The neural model lost to both baselines. Preserve that finding;
training a network is not evidence that it is the best forecasting method.

See [recorded outputs](benchmarks/real-world-results.json). Timings describe one
runtime and include async scheduling; metric differences across platforms may be
small floating-point differences. No real-time forecasting service is involved.

## Inspect and extend

- Dataset parsing/splits: `iris_dataset.dart`, `passenger_dataset.dart`.
- Model/configuration and reports: `iris_experiment.dart`, `passenger_experiment.dart`.
- Shared contract: `RealWorldExperiment`, consumed by the CLI and Flutter runner.
- Flutter rendering is separate in `pages/real_world_page.dart`.
- Tests verify embedded CSV equality, disjoint identities, class coverage,
  training-only scaling, causal windows, finite reports and known baselines.

A cancelled run does not evaluate the reserved test partition. These examples
intentionally do not assert that a neural model must beat the baseline in CI.


## Validation-led forecasting experiment (0.4.0)

Run `dart run example/forecast_validation.dart`. The
[protocol fixed before the run](benchmarks/forecast-validation-protocol.txt)
compares four GRU candidates: hidden size 4 or 8, trained for 40 or 100 epochs.
All use seed 42, Adam 0.01, batch 12, clipping 1, chronological order and the
same training-only log scaler. Training ends December 1956; selection uses
January 1957–December 1958 rolling validation MAE. Stable candidate order breaks
ties. Recursive validation scores are diagnostic and cannot change the ranking.

The parser takes only the first 120 observations. It never parses or evaluates
the previously published 1959–1960 test. Rolling forecasts append an observed
month after predicting it; recursive forecasts append predictions from December
1956 onward. Baselines use the same information: observed previous month/year
for rolling, repeated last month/last seasonal cycle for recursive forecasting.

[Recorded validation results](benchmarks/forecast-validation-native.json) select
8 hidden units and 100 epochs, with rolling MAE **27.25 thousand**, compared with
**26.38** for the seasonal baseline. Recursive MAE is **49.27 thousand**, compared
with **46.46** for the repeated seasonal cycle. Selection did not beat either
seasonal baseline. These are validation scores used for selection, not a new
unbiased test estimate. The earlier fixed reference example and its negative
1959–1960 result remain unchanged. A generalization claim needs new independent
data and a separately fixed evaluation protocol.
