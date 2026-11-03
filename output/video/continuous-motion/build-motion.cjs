const fs=require('fs');
const path=require('path');
const {createRequire}=require('module');
const {spawn}=require('child_process');
const req=createRequire('C:/Users/adama/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/package.json');
const {chromium}=req('playwright');
const sharp=req('sharp');
const out=__dirname;
const root=path.resolve(out,'../../..');
const pack=path.join(root,'output/banner-asset-pack');
const uri=(p,m)=>`data:${m};base64,${fs.readFileSync(p).toString('base64')}`;
const img=n=>uri(path.join(pack,'03-RASTER-ASSETS',n),n.endsWith('.png')?'image/png':'image/jpeg');
const food=img('nasi-lemak-cutout.png'),logo=img('original-app-logo.png'),map=img('nearby-map-original.jpg'),details=img('stall-details-original.jpg');
const directions=uri(path.join(root,'output/video/scene4-flow-references/4C-directions.jpg'),'image/jpeg');
const fonts=['Regular','SemiBold','Bold','ExtraBold'].map((n,i)=>`@font-face{font-family:P;src:url('${uri(path.join(pack,'04-FONTS',`Poppins-${n}.ttf`),'font/ttf')}');font-weight:${[400,600,700,800][i]}}`).join('');
const html=`<!doctype html><html><head><meta charset="utf-8"><title>StallSeeker — continuous motion concept</title><style>${fonts}
*{box-sizing:border-box}html,body{margin:0;overflow:hidden;background:#fff8f2;font-family:P,sans-serif}#stage{position:relative;width:1920px;height:1080px;transform-origin:top left;overflow:hidden;background:#fff8f2;color:#241e1b}#orange{position:absolute;inset:0;background:linear-gradient(120deg,#d94b16,#f88a25)}#grain{position:absolute;inset:0;opacity:.12;background-image:radial-gradient(#ffedce 1px,transparent 1px);background-size:24px 24px}#mapworld{position:absolute;inset:-100px;transform-origin:50% 50%;overflow:hidden;background:#f5f0dd}#mapworld img{position:absolute;width:2386px;left:-102px;top:-1390px;opacity:.6;filter:blur(1px)}#mapwash{position:absolute;inset:0;background:linear-gradient(90deg,#fff8f2dc,#fff8f240)}#maproads{position:absolute;inset:0;width:100%;height:100%;opacity:.7}.road{stroke:#fff;stroke-width:19;fill:none}.roadline{stroke:#e5d3bc;stroke-width:23;fill:none}#route{position:absolute;inset:0;width:1920px;height:1080px;pointer-events:none}#route path{stroke:#bd3d12;stroke-width:9;stroke-linecap:round;stroke-dasharray:1800;fill:none}#route circle{fill:#fff8f2;stroke:#bd3d12;stroke-width:8}.brand{position:absolute;left:80px;top:58px;display:flex;align-items:center;gap:17px;z-index:20}.brand img{width:65px;height:65px}.brand span{font-size:33px;font-weight:700;letter-spacing:-1px}#caption{position:absolute;left:86px;top:315px;z-index:12;width:1120px;transform-origin:0 50%}#caption h1{font-size:118px;line-height:1.12;font-weight:800;letter-spacing:-4px;margin:0}#caption p{font-size:34px;line-height:1.5;margin:28px 0 0}#caption .small{font-size:21px;letter-spacing:4px;text-transform:uppercase;font-weight:600;margin-bottom:24px}#food{position:absolute;width:850px;height:650px;left:0;top:0;object-fit:contain;transform-origin:center;z-index:9;filter:drop-shadow(0 30px 25px #67391122)}#pin{position:absolute;width:210px;height:260px;left:0;top:0;z-index:7;transform-origin:50% 32%}#pin svg{width:100%;height:100%}#pinring{position:absolute;width:330px;height:130px;border:4px solid #c43d0630;background:#c43d0610;border-radius:50%;left:0;top:0;z-index:5}.phone{position:absolute;left:0;top:0;width:406px;height:860px;z-index:10;transform-origin:center;filter:drop-shadow(0 25px 30px #5e311526)}.phone img{position:absolute;inset:0;width:100%;height:100%;object-fit:contain}#status{position:absolute;left:1050px;top:390px;background:#fff;padding:30px 40px;border-radius:26px;box-shadow:0 20px 50px #66301520;z-index:13;font-size:38px;font-weight:700;color:#2e7d32;transform-origin:right center}#status small{display:block;font-size:21px;color:#786456;font-weight:400;margin-top:12px}.dot{display:inline-block;width:15px;height:15px;border-radius:50%;background:#2e7d32;margin-right:12px}#menuwords{position:absolute;left:95px;top:680px;z-index:12;display:flex;gap:18px}.chip{padding:14px 28px;background:#fff;border:1px solid #e9ccb4;border-radius:99px;color:#934322;font-size:25px;font-weight:600}#scan{position:absolute;bottom:45px;right:60px;z-index:30;display:flex;align-items:center;gap:20px;font-size:22px;font-weight:600}.qr{height:122px;width:122px;border:1px solid #ecd9ca;border-radius:14px;background:#fff;color:#b83d11;display:grid;place-content:center;font-size:14px;text-align:center;line-height:1.5;letter-spacing:1px}#scan small{display:block;font-size:14px;font-weight:400;opacity:.7;text-align:right;margin-top:4px}#halo{position:absolute;width:960px;height:960px;border:2px solid #fff7;border-radius:50%;left:975px;top:60px;z-index:3}#halo:after{content:'';position:absolute;inset:60px;border-radius:50%;border:1px solid #fff5}#endmark{position:absolute;left:100px;top:255px;width:130px;height:130px;z-index:15}#endmark img{width:100%;height:100%}
</style></head><body><div id="stage">
<div id="orange"></div><div id="grain"></div>
<div id="mapworld"><img src="${map}"><svg id="maproads" viewBox="0 0 2120 1280"><path class="roadline" d="M-100 950L230 780 480 1020 1000 690 1500 830 2200 310M500-80L780 300 580 660 1000 1150M-100 300L450 400 1100 100 1700 420 2200 240"/><path class="road" d="M-100 950L230 780 480 1020 1000 690 1500 830 2200 310M500-80L780 300 580 660 1000 1150M-100 300L450 400 1100 100 1700 420 2200 240"/></svg><div id="mapwash"></div></div>
<div id="halo"></div>
<svg id="route" viewBox="0 0 1920 1080"><path id="routepath" d="M350 850C610 900 680 710 900 740S1170 790 1280 610 1450 530 1510 340"/><circle cx="350" cy="850" r="15"/><circle cx="1510" cy="340" r="15"/></svg>
<div class="brand" id="brand"><img src="${logo}"><span>StallSeeker</span></div>
<div id="caption"></div><div id="pinring"></div>
<div id="pin"><svg viewBox="0 0 210 260"><path d="M105 5C47 5 5 47 5 104c0 70 100 150 100 150s100-80 100-150C205 47 163 5 105 5Z" fill="#c43d06"/><circle cx="105" cy="101" r="74" fill="#fff8f2"/></svg></div>
<img id="food" src="${food}">
<div class="phone" id="phone"><img id="screenmap" src="${map}"><img id="screendetails" src="${details}"><img id="screendirections" src="${directions}"></div>
<div id="status"><span class="dot"></span>Open now<small>Check opening status & hours.</small></div>
<div id="menuwords"><span class="chip">Dishes</span><span class="chip">Prices</span><span class="chip">Availability</span></div>
<div id="endmark"><img src="${logo}"></div>
<div id="scan"><div>Scan to explore.<small>Try StallSeeker</small></div><div class="qr">YOUR QR<br>HERE</div></div>
</div><script>
const $=id=>document.getElementById(id), clamp=x=>Math.max(0,Math.min(1,x));
const ease=x=>{x=clamp(x);return x*x*(3-2*x)};
const mix=(a,b,p)=>a+(b-a)*p;
const between=(t,a,b)=>ease((t-a)/(b-a));
const op=(id,v)=>$(id).style.opacity=clamp(v);
const tr=(id,x,y,s=1,r=0)=>$(id).style.transform='translate('+x+'px,'+y+'px) scale('+s+') rotate('+r+'deg)';
function caption(title,sub,small,white,opacity=1,x=0,y=0){
 $('caption').innerHTML='<div class="small">'+small+'</div><h1>'+title+'</h1>'+(sub?'<p>'+sub+'</p>':'');
 $('caption').style.color=white?'#fff8f2':'#241e1b';op('caption',opacity);tr('caption',x,y);
}
window.setTime=function(time){
 const t=((time%35)+35)%35;
 $('menuwords').style.top='790px';
 const close=between(t,28,30), opening=1-between(t,4,6),orange=Math.max(opening,close);
 op('orange',orange);op('grain',orange*.7);op('halo',orange*.7);
 $('brand').style.color=orange>.5?'#fff8f2':'#241e1b';$('scan').style.color=orange>.5?'#fff8f2':'#241e1b';
 op('mapworld',between(t,4,6)*(1-between(t,28,30)));
 tr('mapworld',-35*Math.sin(t*.2),-20*Math.cos(t*.2),1.08+Math.sin(t*.12)*.025);
 op('pin',0);op('pinring',0);op('phone',0);op('status',0);op('menuwords',0);op('food',0);op('endmark',0);op('route',0);
 op('screenmap',1);op('screendetails',0);op('screendirections',0);
 if(t<6){
  const p=between(t,4,6);op('food',1);tr('food',mix(1020,550,p),mix(245,129,p),mix(1,.18,p),mix(-3,0,p));
  op('pin',p);tr('pin',870,353,mix(.3,1,p));op('pinring',p);tr('pinring',808,570,1+.05*Math.sin(t*2));
  caption('Hungry?<br>Let’s find food.','Your next favourite stall<br>could be nearby.','STALLSEEKER',true,1-between(t,3.8,5.2),-150*p,0);
 }else if(t<11.5){
  const p=between(t,9.3,11.5);op('food',1-p);tr('food',550,129+Math.sin(t*2)*7,.18,0);op('pin',1-p);tr('pin',870,353+Math.sin(t*2)*7,1+p*.6);op('pinring',1-p);tr('pinring',808,570,1+.06*Math.sin(t*2));
  op('phone',p);tr('phone',mix(760,1240,p),mix(190,110,p),mix(.4,.92,p),mix(-8,-3,p));
  caption('Find it<br><span style="color:#b83d11">nearby.</span>','Explore stalls around you.','FOLLOW YOUR CRAVING',false,between(t,6,6.5)*(1-between(t,10.2,11.5)),0,10*Math.sin(t*.5));
 }else if(t<18.5){
  const p=between(t,11.5,12.5),away=between(t,17.2,18.5);op('phone',1-away);tr('phone',1240-180*away,110-35*away,.92+away*.2,-3+5*away);op('screendetails',p);
  caption('Open now?<br><span style="color:#b83d11">Check first.</span>','See opening status<br>before you go.','PLAN YOUR VISIT',false,p*(1-between(t,16.9,18.2)),0,25*(1-p));
  const c=between(t,12.8,13.4)*(1-between(t,16.9,18));op('status',c);tr('status',0,20*(1-c),.96+.04*c);
  const f=between(t,17.1,18.5);op('food',f);tr('food',mix(1100,1010,f),mix(380,250,f),mix(.25,1,f),mix(12,-3,f));
 }else if(t<23){
  const p=between(t,18.5,19.1),away=between(t,21.7,23);op('food',1);tr('food',mix(1010,635,away),mix(250,161,away),mix(1,.18,away),-3*(1-away));
  caption('What’s on<br><span style="color:#b83d11">the menu?</span>','Find something delicious.','YOUR NEXT FOOD FIND',false,p*(1-between(t,21.8,22.8)),0,25*(1-p));
  op('menuwords',between(t,19.3,20)*(1-between(t,21.7,22.6)));tr('menuwords',0,25*(1-between(t,19.3,20)));
  op('pin',away);tr('pin',955,385,away);op('route',away);$('routepath').style.strokeDashoffset=1800*(1-away);
 }else if(t<29.5){
  const p=between(t,23,24),away=between(t,28,29.5);op('phone',p*(1-away));tr('phone',mix(1460,1240,p),110-250*away,.92-.3*away,3-6*p);op('screendirections',1);
  op('food',1-p);tr('food',635,161,.18);op('pin',1-p);tr('pin',955,385,1);op('route',1-away);$('routepath').style.strokeDashoffset=1800*(1-between(t,22,25));
  caption('Found it?<br><span style="color:#b83d11">Let’s go.</span>','Get directions to your<br>next favourite stall.','FOLLOW THE FLAVOUR',false,p*(1-between(t,27.7,29)),0,25*(1-p));
 }else{
  const p=between(t,29.5,30.5),loop=between(t,33.6,35);op('food',p);tr('food',1020,245,1,-3);op('endmark',p*(1-loop));tr('endmark',0,15*(1-p));
  if(t<33.6)caption('Meet<br>StallSeeker.','Find your next favourite stall.','',true,p,0,76);
  else caption('Hungry?<br>Let’s find food.','Your next favourite stall<br>could be nearby.','STALLSEEKER',true,loop,0,0);
 }
};
let paused=false,start=performance.now();window.pauseMotion=()=>{paused=true};
function tick(now){if(!paused)window.setTime((now-start)/1000);requestAnimationFrame(tick)}
function resize(){$('stage').style.transform='scale('+Math.min(innerWidth/1920,innerHeight/1080)+')'}
addEventListener('resize',resize);resize();setTime(0);requestAnimationFrame(tick);
</script></body></html>`;
fs.writeFileSync(path.join(out,'StallSeeker-continuous-motion.html'),html);
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
 const page=await browser.newPage({viewport:{width:1280,height:720},deviceScaleFactor:1});
 await page.setContent(html,{waitUntil:'load'});await page.evaluate(()=>document.fonts.ready);await page.evaluate(()=>pauseMotion());
 const times=[2,7.5,14.5,20,26,32];const names=['01-craving','02-food-becomes-a-pin','03-check-the-stall','04-explore-the-menu','05-follow-the-route','06-loop-back'];
 const tiles=[];
 for(let i=0;i<times.length;i++){
  await page.evaluate(t=>setTime(t),times[i]);const p=path.join(out,names[i]+'.png');await page.screenshot({path:p});
  tiles.push({input:await sharp(p).resize(800,450).toBuffer(),left:40+(i%2)*840,top:145+Math.floor(i/2)*510});
  const label=Buffer.from('<svg width="800" height="42"><text x="0" y="26" font-family="Arial" font-size="20" font-weight="bold" fill="#3c2317">'+names[i].replaceAll('-',' ').toUpperCase()+'</text><text x="800" y="26" text-anchor="end" font-family="Arial" font-size="19" fill="#8e6348">'+times[i]+'s</text></svg>');
  tiles.push({input:label,left:40+(i%2)*840,top:105+Math.floor(i/2)*510});
 }
 const title=Buffer.from('<svg width="1680" height="95"><text x="40" y="49" font-family="Arial" font-size="32" font-weight="bold" fill="#3c2317">StallSeeker · One continuous journey</text><text x="40" y="80" font-family="Arial" font-size="19" fill="#8e6348">Key moments from the motion preview — moving food, map, app and route / QR placeholder</text></svg>');
 await sharp({create:{width:1720,height:1640,channels:3,background:'#eee2d5'}}).composite([{input:title,left:0,top:0},...tiles]).png().toFile(path.join(out,'00-motion-storyboard.png'));
 console.log('Key frames ready. Rendering silent 35-second motion preview.');
 const ffmpeg='C:/Users/adama/AppData/Local/ms-playwright/ffmpeg-1011/ffmpeg-win64.exe';
 const enc=spawn(ffmpeg,['-hide_banner','-loglevel','error','-y','-f','image2pipe','-r','24','-vcodec','mjpeg','-i','pipe:0','-an','-c:v','libvpx','-b:v','2300k','-deadline','realtime','-cpu-used','6',path.join(out,'StallSeeker-continuous-motion.webm')],{windowsHide:true,stdio:['pipe','ignore','pipe']});
 let err='';enc.stderr.on('data',x=>err+=x);let encoderError;enc.on('error',e=>encoderError=e);
 for(let f=0;f<840;f++){
  await page.evaluate(t=>setTime(t),f/24);
  const buf=await page.screenshot({type:'jpeg',quality:86});
  if(!enc.stdin.write(buf))await new Promise(resolve=>enc.stdin.once('drain',resolve));
  if(f%168===0)console.log('Rendered '+Math.round(f/840*100)+'%');
 }
 enc.stdin.end();await new Promise((resolve,reject)=>enc.on('close',code=>code===0?resolve():reject(new Error(err||String(encoderError)))));
 await browser.close();
 fs.writeFileSync(path.join(out,'CANVA-NOTES.txt'),'Continuous motion concept, 35 seconds, silent. This preview is a visual reference, not an editable Canva project. Recreate linked movements using duplicated elements, position/scale changes and Match & Move where available. Food to pin: scale food into the circular pin, then move camera toward app. Keep the same phone element as screens change. Return to the opening food position for the loop. QR box is a labelled placeholder. HTML opens locally and loops automatically; WEBM is the rendered video.\n');
 console.log('DONE: '+out);
})();
