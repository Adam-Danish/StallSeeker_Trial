const fs=require('fs'),path=require('path'),crypto=require('crypto');
const {createRequire}=require('module');
const req=createRequire('C:/Users/adama/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/package.json');
const {chromium}=req('playwright'),JSZip=req('jszip');
const out=__dirname;
const source=fs.readFileSync(path.join(out,'StallSeeker-continuous-motion.html'),'utf8');
const moments=[
 [0,'Opening food','0–4 s. Hold the food and headline; gently rotate the food.'],
 [4,'Food begins moving','4–6 s. Move and shrink the same food image into the map pin.'],
 [6,'Food inside the pin','6–9.3 s. Hold the pin while the map slowly pans.'],
 [9.3,'Pin becomes app','9.3–11.5 s. Scale in the phone and move it toward the right.'],
 [11.5,'App arrives','11.5–12.5 s. Replace the map screen with stall details.'],
 [14.5,'Check opening status','12.5–17.2 s. Reveal the opening-status callout and headline.'],
 [17.2,'Move into the menu','17.2–18.5 s. Phone moves away as food scales up.'],
 [20,'Explore the menu','18.5–21.7 s. Reveal the menu headline and labels.'],
 [22.95,'Food becomes destination','21.7–23 s. Shrink the food into the destination pin and draw the route.'],
 [26,'Directions','23–28 s. Move in the directions screen; hold the headline while the map pans.'],
 [32,'Meet StallSeeker','28–33.6 s. Bring back the opening food position on orange.'],
 [34.99,'Return to the opening','33.6–35 s. Fade back to the opening headline. QR stays stationary.']
];
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
 const page=await browser.newPage({viewport:{width:1920,height:1080}});
 await page.setContent(source,{waitUntil:'load'});await page.evaluate(()=>document.fonts.ready);await page.evaluate(()=>pauseMotion());
 const pages=[];
 for(let i=0;i<moments.length;i++){
  const [time,label,notes]=moments[i];await page.evaluate(t=>setTime(t),time);
  const snapshot=await page.evaluate(()=>{
   const original=document.getElementById('stage'), clone=original.cloneNode(true);
   const props=['position','left','top','right','bottom','width','height','display','align-items','justify-content','place-content','gap','flex-direction','margin','padding','box-sizing','font-family','font-size','font-weight','line-height','letter-spacing','text-align','text-transform','color','background','background-image','background-size','opacity','border','border-radius','box-shadow','overflow','object-fit','filter','transform','transform-origin','z-index','stroke','stroke-width','stroke-linecap','stroke-dasharray','stroke-dashoffset','fill'];
   function walk(a,b){
    const c=getComputedStyle(a);if(parseFloat(c.opacity)<.001){b.remove();return;}
    let style=props.map(p=>p+':'+c.getPropertyValue(p)).join(';');b.setAttribute('style',style);b.removeAttribute('id');b.removeAttribute('class');
    for(let j=a.children.length-1;j>=0;j--)walk(a.children[j],b.children[j]);
   }
   walk(original,clone);clone.style.transform='none';clone.style.position='relative';clone.style.margin='0';clone.style.display='block';clone.style.width='1920px';clone.style.height='1080px';
   return clone.outerHTML;
  });
  const safe=s=>s.replaceAll('&','&amp;').replaceAll('"','&quot;').replaceAll('<','&lt;');
  pages.push(snapshot.replace('<div ',`<div data-document-role="page" data-label="${safe(String(i+1).padStart(2,'0')+' · '+label)}" data-speaker-notes="${safe(notes)}" `));
 }
 await browser.close();
 const fontCSS=source.match(/<style>([\s\S]*?)\*\{box-sizing/)[1];
 let html='<!doctype html><html><head><meta charset="utf-8"><title>StallSeeker editable motion keyframes</title><style>'+fontCSS+'html,body{margin:0;padding:0;background:#fff8f2;font-family:P,sans-serif}</style></head><body>'+pages.join('\n')+'</body></html>';
 const zip=new JSZip(),assets=new Map();
 html=html.replace(/data:([^;]+);base64,([A-Za-z0-9+/=]+)/g,(all,mime,b64)=>{
  const hash=crypto.createHash('sha256').update(b64).digest('hex').slice(0,16);
  const ext=mime.includes('png')?'png':mime.includes('jpeg')?'jpg':mime.includes('ttf')?'ttf':'bin';
  const name='assets/'+hash+'.'+ext;if(!assets.has(name)){assets.set(name,true);zip.file(name,Buffer.from(b64,'base64'));}return name;
 });
 zip.file('index.html',html);
 zip.file('TIMING-GUIDE.txt',moments.map(([t,l,n],i)=>`${i+1}. ${l} (${t}s reference)\n${n}\n`).join('\n')+'\nEditable keyframe source. Match & Move and timings need to be applied in Canva. Text and photos are separate objects; phone screens are images. QR boxes are placeholders.\n');
 fs.writeFileSync(path.join(out,'StallSeeker-editable-Canva-source.zip'),await zip.generateAsync({type:'nodebuffer',compression:'DEFLATE'}));
 fs.writeFileSync(path.join(out,'StallSeeker-editable-keyframes.html'),html);
 console.log(JSON.stringify({pages:pages.length,assets:assets.size,path:path.join(out,'StallSeeker-editable-Canva-source.zip')}));
})();
