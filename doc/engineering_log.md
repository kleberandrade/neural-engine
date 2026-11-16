# Engineering log

## Initial 0.1.0 implementation

Action: create an independent pure Dart dense neural-network package with
training, inference and JSON interchange, plus CLI and Flutter examples.
Reason: extend the engine family with supervised gradient-based learning.

Local validation (Dart 3.11.5 / Flutter 3.41.9, macOS arm64):

- 19 public-API tests passed, including every-parameter finite differences,
  extreme-logit stability, seeded XOR convergence, SGD regression, multiclass
  classification, optimizer isolation, JSON roundtrip and early stopping.
- Core analyzer and Flutter lab analyzer passed with no issues.
- Three CLI examples passed their convergence assertions.
- Core XOR example compiled to JavaScript.
- Flutter widget test could not start its localhost socket under the execution
  sandbox. Flutter web build was blocked by a child compiler analytics write
  outside the writable workspace. These are not recorded as passing checks.
- Full publish dry-run needs network access unavailable to the shell here;
  GitHub CI performs this validation before a manual publish is considered.

CI is configured for Dart minimum/stable and Flutter stable. Its actual results
must be inspected independently; configuration alone is not a passing result.

CI follow-up: Dart 3.3.4 and stable jobs passed, including the publish dry-run.
Latest Flutter stable deprecated the legacy Material forwarding import. Keep
that import for compatibility with older Flutter versions and suppress only
its specific deprecation at the two import sites. The first Flutter CI run
stopped at analysis; a new run validates the change. Local direct compilation
of the complete Flutter lab to JavaScript also succeeded.
