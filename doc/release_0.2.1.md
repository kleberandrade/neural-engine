# 0.2.1 release record

Published on November 16, 2026 under verified publisher `kleberandrade.dev`.

- [Hosted package](https://pub.dev/packages/neural_engine/versions/0.2.1)
- [Release and immutable tag](https://github.com/kleberandrade/neural-engine/releases/tag/v0.2.1)
- [Successful source CI](https://github.com/kleberandrade/neural-engine/actions/runs/43940405042)
- [Successful publication workflow](https://github.com/kleberandrade/neural-engine/actions/runs/43940731380)
- Release commit: `eab11fb66c4fcd0a61642a5636ecbc9fd27dbc83`

## Delivered

1. Hosted installation instructions (`neural_engine: ^0.2.1`) and absolute README
   links, verified in the rendered pub.dev page.
2. Standalone exact hosted consumer, tested on minimum/stable Dart: all model
   families, both fitted scalers, real temporary-file persistence and exact
   Adam checkpoint continuation. It verified 0.2.0 before publication and was
   advanced to 0.2.1 after the artifact became available.
3. Flutter Checkpoints tab for MLP/CNN/RNN/LSTM/GRU, with explicit JSON copying,
   fresh-page loading, 40 + 60 epoch continuation, loss/size/prediction reporting
   and comparison with uninterrupted training. Includes narrow-screen and invalid
   JSON tests. The JSON editor has a separate scroll area from the page.
4. [Recorded benchmark configuration and observations](benchmarks/README.md):
   training/inference, batch-average timing ranges and compact model JSON bytes,
   including SOM BMU inference. No cross-family speed ranking is inferred.
5. [Stable release procedure](releasing.md), generalized tag trigger and an exact
   tag/pubspec guard before mandatory CI and OIDC publication.

The successful release checks include 61 Dart tests, six Flutter widget tests,
Dart 3.3.4/stable, the extension consumer, hosted artifact matrix, JavaScript
examples, Flutter web build and package dry-run. There are no new core runtime
dependencies or changes to the public model/training API.
