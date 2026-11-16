"""Profile identical 0.3-compatible workloads via the authenticated local VM service.
No third-party Python or Dart package is needed. Never persist the service URI/token.
"""
import argparse
import json
import pathlib
import queue
import re
import subprocess
import threading
import urllib.parse
import urllib.request

parser = argparse.ArgumentParser()
parser.add_argument('--dart', default='dart')
parser.add_argument('--packages', required=True)
parser.add_argument('--script', default='benchmark/profiling/allocation_harness.dart')
parser.add_argument('--out', required=True)
args = parser.parse_args()


def profile(kind):
    command = [args.dart, '--enable-vm-service=0',
               '--packages=' + str(pathlib.Path(args.packages).resolve()),
               str(pathlib.Path(args.script).resolve()), kind]
    process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, text=True, bufsize=1)
    messages = queue.Queue()
    def drain(stream):
        for line in stream:
            messages.put(line.strip())
    for stream in [process.stdout, process.stderr]:
        threading.Thread(target=drain, args=(stream,), daemon=True).start()
    uri = None
    def wait(prefix):
        nonlocal uri
        while True:
            try:
                line = messages.get(timeout=60)
            except queue.Empty:
                raise RuntimeError('VM workload did not reach ' + prefix) from None
            match = re.search(r'(http://127\.0\.0\.1:\d+/[^\s]*/)', line)
            if match:
                uri = match[1]
            if line.startswith(prefix):
                return line[len(prefix):].strip()
            if process.poll() is not None:
                raise RuntimeError('VM workload exited before ' + prefix)
    def send(command):
        process.stdin.write(command + '\n')
        process.stdin.flush()
    def rpc(method, **params):
        url = uri + method + '?' + urllib.parse.urlencode(params)
        # HTTP errors are reported without their URL, which includes a local auth token.
        try:
            with urllib.request.urlopen(url, timeout=20) as response:
                result = json.load(response)
        except Exception as error:
            raise RuntimeError('VM service request failed: ' + method) from None
        if 'error' in result:
            raise RuntimeError(method + ': ' + str(result['error'].get('message')))
        return result['result']
    try:
        wait('PROFILE_READY')
        if uri is None:
            raise RuntimeError('No authenticated local VM service was advertised')
        vm = rpc('getVM')
        isolate = next(i['id'] for i in vm['isolates'] if not i.get('isSystemIsolate', False))
        send('warm'); wait('PROFILE_WARMED')
        measurements = []
        for _ in range(3):
            rpc('getAllocationProfile', isolateId=isolate, reset='true', gc='true')
            send('measure')
            workload = json.loads(wait('PROFILE_RESULT '))
            allocation = rpc('getAllocationProfile', isolateId=isolate)
            members = allocation.get('members', [])
            measurements.append({'workload': workload, 'memoryUsage': allocation.get('memoryUsage'),
                                 'classes': [{'name': m['class']['name'],
                                              'accumulatedBytes': m.get('accumulatedSize', 0),
                                              'accumulatedInstances': m.get('instancesAccumulated', 0),
                                              'liveBytes': m.get('bytesCurrent', 0)} for m in members
                                             if m.get('accumulatedSize', 0) or m.get('bytesCurrent', 0)]})
        classes = rpc('getClassList', isolateId=isolate)['classes']
        traced = [c for c in classes if c['name'] in ['_List', '_GrowableList']]
        for item in traced:
            rpc('setTraceClassAllocation', isolateId=isolate, classId=item['id'], enable='true')
        origin = rpc('getVMTimelineMicros')['timestamp']
        send('measure'); wait('PROFILE_RESULT ')
        traces = rpc('getAllocationTraces', isolateId=isolate, timeOriginMicros=origin)
        functions = traces.get('functions', [])
        stacks = []
        for sample in traces.get('samples', []):
            names = []
            for index in sample.get('stack', []):
                if index < len(functions):
                    function = functions[index].get('function', {})
                    names.append(function.get('name', functions[index].get('name', '?')))
            stacks.append(names)
        return {'kind': kind, 'runtime': vm.get('version'), 'architecture': vm.get('architectureBits'),
                'measurements': measurements, 'tracedClasses': [c['name'] for c in traced],
                'allocationStackSampleCount': len(stacks), 'allocationStacks': stacks,
                'notes': 'Warm JIT, 3 fresh-model measurements. Accumulators reset before each. Allocation tracing is a separate pass and never used for throughput. VM live bytes and cumulative allocations are distinct.'}
    finally:
        if process.poll() is None:
            try:
                send('quit'); process.wait(timeout=5)
            except Exception:
                process.kill(); process.wait()

result = {'protocol': 'authenticated VM service getAllocationProfile + setTraceClassAllocation/getAllocationTraces',
          'source': 'https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md',
          'workloads': [profile(kind) for kind in ['flat', 'mlp']]}
output = pathlib.Path(args.out)
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(result, indent=2) + '\n')
print('Saved allocation evidence:', output)
