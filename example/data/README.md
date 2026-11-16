# Offline datasets and provenance

These observations are separate from the MIT-licensed engine implementation.
`manifest.json` pins the normalized CSV bytes, row count, source and retrieval date.
The generated `example/flutter_lab/lib/real_world/*_data.dart` strings equal those CSV files; tests
check that equality so Flutter web requires no network or file-system access.

- **Iris:** Fisher, R. (1936). Iris [Dataset]. UCI Machine Learning Repository.
  https://doi.org/10.24432/C56C76. Source CSV:
  https://archive.ics.uci.edu/static/public/53/data.csv.
  Dataset license: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
  Snapshot retains the source measurements, including its noted differences at
  samples 35 and 38; only line endings/trailing newline are normalized. The example
  removes exact duplicate feature/label rows before splitting; it reports counts.
- **AirPassengers:** monthly international airline passenger totals in thousands,
  1949–1960, the Box & Jenkins series documented by R:
  https://stat.ethz.ch/R-manual/R-patched/library/datasets/html/AirPassengers.html.
  Numeric observations transcribed from the year/month table in ETH Zürich's
  Applied Time Series Analysis teaching script, section 1.2.1:
  https://stat.ethz.ch/education/semesters/ss2012/atsa/ATSA-Scriptum-SS2012-120521.pdf.
  Original attribution: Box, Jenkins and Reinsel, *Time Series Analysis,
  Forecasting and Control*. Only observations are included, not R implementation
  code or textbook prose. Dates are added as ISO months; values are unchanged.

To refresh a snapshot, verify its source and attribution, update the CSV, mirror
its exact text in the corresponding Dart raw string, and update its SHA-256.
Do not silently replace a pinned dataset or tune on its reserved test partition.
