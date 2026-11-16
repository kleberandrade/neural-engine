// Controls an isolated CI Chrome instance serving only the locally built probe.
// Native built-in WebSocket requires Node >=22. No browser account/profile is reused.
const fs=require('node:fs');const http=require('node:http');const path=require('node:path');
const os=require('node:os');const {spawn}=require('node:child_process');const zlib=require('node:zlib');
const root=path.resolve(process.argv[2]);const output=path.resolve(process.argv[3]);
const policy=process.argv[4]||'default';
const server=http.createServer((req,res)=>{
 const pathname=new URL(req.url,'http://localhost').pathname;
 const target=path.resolve(root,'.'+decodeURIComponent(pathname));
 if(!target.startsWith(root+path.sep)&&target!==root) {res.writeHead(403).end();return;}
 const file=target===root?path.join(root,'index.html'):target;
 const types={'.html':'text/html','.js':'text/javascript','.wasm':'application/wasm','.json':'application/json'};
 fs.readFile(file,(error,data)=>{if(error)res.writeHead(404).end();else res.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream'}).end(data);});
});
const delay=ms=>new Promise(r=>setTimeout(r,ms));
async function main(){
 await new Promise(r=>server.listen(0,'127.0.0.1',r));
 const url=`http://127.0.0.1:${server.address().port}/?policy=${policy}`;
 const profile=fs.mkdtempSync(path.join(os.tmpdir(),'neural-chrome-release-'));
 const chrome=spawn(process.env.CHROME_EXECUTABLE||'google-chrome',
  ['--headless','--remote-debugging-port=0',`--user-data-dir=${profile}`,'--no-first-run',url]);
 let port;let socket;
 try {
  await new Promise((resolve,reject)=>{
   const timeout=setTimeout(()=>reject(Error('Chrome did not expose its isolated debugging endpoint')),15000);
   chrome.stderr.on('data',chunk=>{const match=String(chunk).match(/DevTools listening on ws:\/\/127\.0\.0\.1:(\d+)/);if(match){port=match[1];clearTimeout(timeout);resolve();}});
   chrome.on('error',reject);
  });
  let target;
  for(let i=0;i<100;i++){
   const tabs=await fetch(`http://127.0.0.1:${port}/json`).then(r=>r.json());
   target=tabs.find(t=>t.type==='page'&&t.url.startsWith(url));if(target)break;await delay(100);
  }
  if(!target)throw Error('Local release probe page was not created');
  socket=new WebSocket(target.webSocketDebuggerUrl);await new Promise((r,j)=>{socket.onopen=r;socket.onerror=j;});
  let id=0;const pending=new Map();const trace=[];let finishTrace;
  socket.onmessage=event=>{const message=JSON.parse(event.data);
   if(message.id&&pending.has(message.id)){const p=pending.get(message.id);pending.delete(message.id);message.error?p.reject(Error(message.error.message)):p.resolve(message.result);}
   if(message.method==='Tracing.dataCollected')trace.push(...message.params.value);
   if(message.method==='Tracing.tracingComplete')finishTrace?.();
  };
  const call=(method,params={})=>new Promise((resolve,reject)=>{const key=++id;pending.set(key,{resolve,reject});socket.send(JSON.stringify({id:key,method,params}));});
  await call('Tracing.start',{categories:'devtools.timeline,disabled-by-default-devtools.timeline.frame,blink.user_timing',transferMode:'ReportEvents'});
  await call('Runtime.evaluate',{expression:'globalThis.neuralStartProbe = true'});
  let report;
  for(let i=0;i<1200;i++){
   const value=await call('Runtime.evaluate',{expression:'globalThis.neuralFrameReport || null',returnByValue:true});
   if(value.result.value){report=JSON.parse(value.result.value);break;}await delay(100);
  }
  if(!report)throw Error('Release probe did not finish within 120 seconds');
  const stopped=new Promise(resolve=>finishTrace=resolve);await call('Tracing.end');await stopped;
  report.chromeVersion=await fetch(`http://127.0.0.1:${port}/json/version`).then(r=>r.json()).then(v=>({Browser:v.Browser,'V8-Version':v['V8-Version']}));
  fs.mkdirSync(path.dirname(output),{recursive:true});fs.writeFileSync(output,JSON.stringify(report,null,2)+'\n');
  fs.writeFileSync(output+'.trace.json.gz',zlib.gzipSync(JSON.stringify({traceEvents:trace})));
  console.log(`Saved release frame report and ${trace.length} Chrome trace events: ${output}`);
 }finally{
  socket?.close();chrome.kill();server.close();
  // CI-created browser profile only; wait for the process before removing it.
  await new Promise(resolve=>{if(chrome.exitCode!==null)resolve();else{chrome.once('exit',resolve);setTimeout(resolve,3000);}});
  fs.rmSync(profile,{recursive:true,force:true});
 }
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
