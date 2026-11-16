"""Extract one completed machine-readable report from Dart/Flutter console logs."""
import json
import pathlib
import sys

text = pathlib.Path(sys.argv[1]).read_text()
marker = 'NEURAL_RESPONSIVENESS '
if marker not in text:
    raise SystemExit('Missing completed responsiveness report')
report, _ = json.JSONDecoder().raw_decode(text.split(marker, 1)[1])
if len(report.get('rows', [])) != 12:
    raise SystemExit('Incomplete responsiveness scenario matrix')
output = pathlib.Path(sys.argv[2])
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(report, indent=2) + '\n')
print(f'Saved {len(report["rows"])} scenarios to {output}')
