const fs=require('fs'),http=require('http'),path=require('path');
const {createRequire}=require('module');
const req=createRequire('C:/Users/adama/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/package.json');
const {chromium}=req('playwright'),sharp=req('sharp');
const file='C:/Users/adama/.codex/codex-remote-attachments/01a1a16f-d717-7603-a5c9-f251a57cd1a5/2A15CFF5-1877-460A-AEE8-AF96BF13BB49/1-v1c044g50000d8g0v87og65u7fu4mmug.mp4';
(async()=>{
 const server=http.createServer((r,s)=>{s.setHeader('Access-Control-Allow-Origin','*');const size=fs.statSync(file).size;const range=r.headers.range;if(range){const m=/bytes=(\d+)-(\d*)/.exec(range),start=+m[1],end=m[2]?+m[2]:size-1;s.writeHead(206,{'Content-Type':'video/mp4','Content-Range':`bytes ${start}-${end}/${size}`,'Accept-Ranges':'bytes','Content-Length':end-start+1});fs.createReadStream(file,{start,end}).pipe(s)}else{s.writeHead(200,{'Content-Type':'video/mp4','Content-Length':size,'Accept-Ranges':'bytes'});fs.createReadStream(file).pipe(s)}});
 await new Promise(r=>server.listen(0,'127.0.0.1',r));const port=server.address().port;
 const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});const page=await browser.newPage();
 await page.setContent(`<video id="v" muted preload="auto" crossorigin="anonymous" src="http://127.0.0.1:${port}/reference.mp4"></video>`);
 const meta=await page.evaluate(()=>new Promise((resolve,reject)=>{const v=document.getElementById('v');const ready=()=>resolve({duration:v.duration,width:v.videoWidth,height:v.videoHeight});v.onloadeddata=ready;v.onerror=()=>reject(new Error('Video load error '+v.error?.message));if(v.readyState>=2)ready();if(v.error)reject(new Error(v.error.message))}));
 console.log(JSON.stringify(meta));fs.writeFileSync(path.join(__dirname,'metadata.json'),JSON.stringify(meta,null,2));
 const tiles=[],count=30,w=320,h=Math.round(w*meta.height/meta.width),cellH=h+30;
 for(let i=0;i<count;i++){
  const t=Math.min(meta.duration-.05,(i+.1)/count*meta.duration);
  const url=await page.evaluate(t=>new Promise(resolve=>{const v=document.getElementById('v');v.onseeked=()=>{const c=document.createElement('canvas');c.width=v.videoWidth;c.height=v.videoHeight;c.getContext('2d').drawImage(v,0,0);resolve(c.toDataURL('image/png'))};v.currentTime=t}),t);
  const buf=Buffer.from(url.split(',')[1],'base64');fs.writeFileSync(path.join(__dirname,`ref-${String(i).padStart(2,'0')}.png`),buf);
  const x=(i%6)*340,y=Math.floor(i/6)*cellH;
  tiles.push({input:await sharp(buf).resize(w,h).toBuffer(),left:x,top:y+30});
  tiles.push({input:Buffer.from(`<svg width="320" height="30"><text x="8" y="22" font-family="Arial" font-size="18" fill="white">${t.toFixed(2)}s</text></svg>`),left:x,top:y});
 }
 await sharp({create:{width:2040,height:Math.ceil(count/6)*cellH,channels:3,background:'#222'}}).composite(tiles).png().toFile(path.join(__dirname,'reference-contact-sheet.png'));
 await browser.close();server.close();console.log('Reference contact sheet ready.');
})();
