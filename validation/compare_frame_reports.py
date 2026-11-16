"""Check release identity/math; frame distributions remain descriptive, not SLAs."""
import json
import pathlib
import sys
root=pathlib.Path(sys.argv[1])
reports={p.stem:json.loads(p.read_text()) for p in root.glob('*.json') if p.stem not in ['flutter-sdk','runner-metadata']}
for name,report in reports.items():
    assert report['releaseMode'] is True, name
    key='browserRafIntervals' if name.startswith('chrome') else 'frameBuild'
    assert report[key]['samples']>0, (name,'No real frame observations')
for prefix in ['native','chrome']:
    assert reports[prefix+'-default']['checkpointJson']==reports[prefix+'-budgeted']['checkpointJson'], prefix
assert reports['native-default']['checkpointJson']==reports['native-cooperative']['checkpointJson']
print('Release frame reports contain observations and identical per-platform checkpoints')
for name,report in reports.items():
    summary={key:value for key,value in report.items() if key!='checkpointJson'}
    print('NEURAL_RELEASE_FRAME '+json.dumps({'name':name,**summary},separators=(',',':')))
