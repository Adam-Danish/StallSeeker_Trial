const fs=require('fs'),path=require('path'),crypto=require('crypto');
const {createRequire}=require('module');
const req=createRequire('C:/Users/adama/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/package.json');
const {chromium}=req('playwright'),JSZip=req('jszip');
const out=__dirname;
const source=fs.readFileSync(path.join(out,'StallSeeker-fast-type.html'),'utf8');
const moments=[[0.6,"Hungry","0–1.5 s. Opening text is fully visible at the loop seam. Fast masked slide out at 1.34 s."],[2.2,"What is nearby","1.5–3 s. Slide headline words up in 0.2 s, staggered by 0.055 s; arrow punches in."],[4,"Good food","3–5 s. Oversized text snaps upward; food slides in from the right with a small rotation."],[6.3,"Find a stall","5–7.8 s. Quick diagonal wipe, 0.2 s text reveal and phone punch-in."],[9,"Open now","7.8–10.5 s. Phone swings in; open status label follows after 0.28 s."],[12,"See the menu","10.5–13.6 s. Oversized food close-up; 0.2 s text slide and moving menu ticker."],[15,"Pick a favourite","13.6–16.7 s. Fast staggered words with food and orange circle moving in from right."],[18.2,"Lets go","16.7–20 s. Directions phone punches in; route draws in 1.1 s."],[21.5,"StallSeeker","20–23 s. Brand headline slides in with the food cutout."],[23.6,"Loop join","23–24 s. Return to opening composition and hold through the loop seam."]];
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
  pages.push(snapshot.replace('<main ',`<main data-document-role="page" data-label="${safe(String(i+1).padStart(2,'0')+' · '+label)}" data-speaker-notes="${safe(notes)}" `));
 }
 await browser.close();
 const fontCSS=source.match(/<style>([\s\S]*?)\*\{box-sizing/)[1];
 let html='<!doctype html><html><head><meta charset="utf-8"><title>StallSeeker fast-type editable keyframes</title><style>'+fontCSS+'html,body{margin:0;padding:0;background:#fff8f2;font-family:P,sans-serif}</style></head><body>'+pages.join('\n')+'</body></html>';
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
