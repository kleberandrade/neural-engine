// dart2js expects the browser's `self` timer surface for async scheduling.
// Check a completion marker so an unstarted Future cannot silently pass Node CI.
const {spawnSync} = require('node:child_process');
const path = require('node:path');
const compiled = path.resolve(process.argv[2]);
const result = spawnSync(process.execPath,
  ['-e', 'globalThis.self = globalThis; require(process.argv[1]);', compiled],
  {encoding: 'utf8', timeout: 60000});
process.stdout.write(result.stdout || '');
process.stderr.write(result.stderr || '');
if (result.error || result.status !== 0 || !result.stdout.includes('Async validation passed')) {
  throw new Error(`Async JavaScript did not complete: ${result.error || result.status}`);
}
