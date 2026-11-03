const fs=require('fs'),path=require('path');
const {createRequire}=require('module'),{spawn}=require('child_process');
const req=createRequire('C:/Users/adama/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/package.json');
const {chromium}=req('playwright'),sharp=req('sharp');
const out=__dirname,root=path.resolve(out,'../../..'),pack=path.join(root,'output/banner-asset-pack');
const data=(p,m)=>`data:${m};base64,${fs.readFileSync(p).toString('base64')}`;
const pic=n=>data(path.join(pack,'03-RASTER-ASSETS',n),n.endsWith('.png')?'image/png':'image/jpeg');
const food=pic('nasi-lemak-cutout.png'),logo=pic('original-app-logo.png'),map=pic('nearby-map-original.jpg'),details=pic('stall-details-original.jpg');
const directions=data(path.join(root,'output/video/scene4-flow-references/4C-directions.jpg'),'image/jpeg');
const fonts=['Regular','SemiBold','ExtraBold','Black'].map((n,i)=>`@font-face{font-family:P;src:url('${data(path.join(pack,'04-FONTS',`Poppins-${n}.ttf`),'font/ttf')}');font-weight:${[400,600,800,900][i]}}`).join('');
const html=`<!doctype html><html><head><meta charset="utf-8"><title>StallSeeker — Fast type</title><style>${fonts}
*{box-sizing:border-box}body,html{margin:0;overflow:hidden;background:#211b18;font-family:P,sans-serif}#stage{position:relative;width:1920px;height:1080px;transform-origin:top left;background:#ff6a1a;color:#fff3dd;overflow:hidden}#texture{position:absolute;inset:0;opacity:.08;background-image:radial-gradient(currentColor 1px,transparent 1px);background-size:13px 13px;pointer-events:none}.header{position:absolute;left:74px;right:74px;top:54px;display:flex;align-items:center;justify-content:space-between;z-index:30}.brand{display:flex;gap:16px;align-items:center;font-weight:800;font-size:31px;letter-spacing:-1px}.brand img{width:60px;height:60px}.header .meta{font-size:16px;font-weight:600;letter-spacing:4px}.footer{position:absolute;bottom:46px;left:80px;right:80px;display:flex;justify-content:space-between;z-index:30;font-size:18px;font-weight:600;letter-spacing:2px}#headline{position:absolute;z-index:15;left:80px;top:250px;width:1750px;transform-origin:0 50%;font-weight:900;line-height:1;letter-spacing:-9px;font-size:205px}.line{display:block;white-space:nowrap;overflow:hidden;padding-bottom:10px;margin-bottom:-10px}.word{display:inline-block;transform-origin:0 50%}.accent{color:#ff6a1a}#sub{position:absolute;left:88px;top:810px;z-index:16;font-size:32px;line-height:1.4;font-weight:400;letter-spacing:-.5px}#food{position:absolute;left:0;top:0;width:1050px;height:770px;object-fit:contain;z-index:10;transform-origin:50% 50%;filter:drop-shadow(0 30px 30px #0003)}#phone{position:absolute;left:0;top:0;width:415px;height:880px;z-index:18;transform-origin:50% 50%;filter:drop-shadow(0 25px 25px #0004)}#phone img{position:absolute;inset:0;width:100%;height:100%;object-fit:contain}#map{position:absolute;inset:0;overflow:hidden;transform-origin:center;z-index:2}#map img{position:absolute;width:2240px;left:-130px;top:-1375px;filter:grayscale(.5);opacity:.52}#map:after{content:'';position:absolute;inset:0;background:linear-gradient(90deg,#211b18ee,#211b1870)}#disc{position:absolute;left:1130px;top:235px;width:740px;height:740px;border-radius:50%;background:#ff6a1a;z-index:4}#status{position:absolute;left:1080px;top:660px;z-index:22;color:#fff3dd;background:#2e7d32;padding:18px 30px;border-radius:9px;font-size:32px;font-weight:800;transform:rotate(-5deg)}#ticker{position:absolute;left:-300px;top:870px;width:2600px;font-size:55px;letter-spacing:3px;font-weight:800;border-top:3px solid currentColor;border-bottom:3px solid currentColor;padding:12px 0;white-space:nowrap;z-index:12}#route{position:absolute;inset:0;z-index:6;width:1920px;height:1080px}#route path{fill:none;stroke:#ff6a1a;stroke-width:12;stroke-linecap:round;stroke-dasharray:1700}#arrow{position:absolute;z-index:14;font-size:250px;line-height:1;left:0;top:0;font-family:Arial,sans-serif;font-weight:700}#logoBig{position:absolute;z-index:20;width:140px;height:140px;left:90px;top:200px}#wipe{position:absolute;z-index:40;width:300px;height:1600px;left:0;top:-200px;transform:translateX(-600px) rotate(15deg);background:#fff3dd}
</style></head><body><main id="stage"><div id="texture"></div><div id="map"><img src="${map}"></div><div id="disc"></div><svg id="route" viewBox="0 0 1920 1080"><path id="path" d="M140 870C410 850 490 970 770 700S1170 850 1470 370"/></svg><img id="food" src="${food}"><div id="phone"><img id="mapScreen" src="${map}"><img id="detailScreen" src="${details}"><img id="directionScreen" src="${directions}"></div><div id="headline"></div><div id="sub"></div><div id="status">● OPEN NOW</div><div id="ticker">DISHES / PRICES / AVAILABILITY / DISHES / PRICES / AVAILABILITY /</div><div id="arrow">↗</div><img id="logoBig" src="${logo}"><div class="header"><div class="brand"><img src="${logo}">StallSeeker</div><div class="meta">FIND / CHECK / GO</div></div><div class="footer"><span>GOOD FOOD. CLOSER.</span><span id="footright">DISCOVER LOCAL STALLS ↗</span></div><div id="wipe"></div></main><script>
const $=id=>document.getElementById(id),clamp=x=>Math.max(0,Math.min(1,x));
const out=x=>1-Math.pow(1-clamp(x),4),smooth=x=>{x=clamp(x);return x*x*(3-2*x)},mix=(a,b,p)=>a+(b-a)*p;
const tr=(id,x,y,s=1,r=0)=>$(id).style.transform='translate('+x+'px,'+y+'px) scale('+s+') rotate('+r+'deg)';
const op=(id,a)=>$(id).style.opacity=clamp(a);
const scenes=[
 {a:0,b:1.5,bg:'#ff6a1a',fg:'#fff3dd',lines:['HUNGRY?'],size:280,x:80,y:350,sub:'',kind:'hook'},
 {a:1.5,b:3,bg:'#211b18',fg:'#fff3dd',lines:['WHAT’S','NEARBY?'],size:225,x:80,y:270,sub:'Let’s find your next food stop.',kind:'question'},
 {a:3,b:5,bg:'#fff3dd',fg:'#211b18',lines:['GOOD','FOOD.'],size:260,x:80,y:260,sub:'Discover your next favourite stall.',kind:'food'},
 {a:5,b:7.8,bg:'#211b18',fg:'#fff3dd',lines:['FIND','A STALL.'],size:218,x:80,y:270,sub:'Explore stalls around you.',kind:'discover'},
 {a:7.8,b:10.5,bg:'#fff3dd',fg:'#211b18',lines:['OPEN','NOW?'],size:250,x:80,y:245,sub:'Check opening status before you go.',kind:'status'},
 {a:10.5,b:13.6,bg:'#ff6a1a',fg:'#211b18',lines:['SEE THE','MENU.'],size:222,x:80,y:230,sub:'',kind:'menu'},
 {a:13.6,b:16.7,bg:'#211b18',fg:'#fff3dd',lines:['PICK A','FAVOURITE.'],size:186,x:80,y:240,sub:'Find something delicious.',kind:'pick'},
 {a:16.7,b:20,bg:'#fff3dd',fg:'#211b18',lines:['LET’S','GO.'],size:265,x:80,y:245,sub:'Get directions to the stall.',kind:'go'},
 {a:20,b:23,bg:'#ff6a1a',fg:'#fff3dd',lines:['STALL','SEEKER.'],size:230,x:80,y:295,sub:'Find your next favourite stall.',kind:'brand'},
 {a:23,b:24,bg:'#ff6a1a',fg:'#fff3dd',lines:['HUNGRY?'],size:280,x:80,y:350,sub:'',kind:'hook'}
];
window.setTime=function(seconds){
 const t=((seconds%24)+24)%24,s=scenes.find(s=>t>=s.a&&t<s.b),l=t-s.a,d=s.b-s.a,ent=out(l/.23),exit=s.a===23?0:out((l-(d-.16))/.16),isHook=s.kind==='hook';
 $('headline').style.wordSpacing='18px';$('headline').style.letterSpacing='-6px';
 $('stage').style.background=s.bg;$('stage').style.color=s.fg;
 for(const id of ['food','phone','map','status','ticker','arrow','disc','route','logoBig'])op(id,0);
 op('mapScreen',0);op('detailScreen',0);op('directionScreen',0);
 $('headline').style.left=s.x+'px';$('headline').style.top=s.y+'px';$('headline').style.fontSize=s.size+'px';$('headline').style.width='1760px';
 $('headline').innerHTML=s.lines.map((line,i)=>'<div class="line"><span class="word" style="transform:translate('+((isHook?0:1-out((l-i*.055)/.2))*160-exit*230)+'px,'+((isHook?0:1-out((l-i*.055)/.2))*s.size*.85)+'px) skewX('+((isHook?0:1-ent)*-10)+'deg);opacity:'+(1-exit)+'">'+line+'</span></div>').join('');
 $('sub').textContent=s.sub;$('sub').style.color=s.fg;op('sub',out((l-.27)/.18)*(1-exit));tr('sub',0,(1-out((l-.27)/.18))*30);$('sub').style.top=(s.kind==='pick'?720:810)+'px';
 tr('food',1050,235,1,0);tr('phone',1255,125,.88,0);op('wipe',0);
 if(s.kind==='hook'){
  tr('arrow',1580,360,1,0);op('arrow',1-exit);$('arrow').style.fontSize='270px';
  if(t<1.5&&l>1.31)op('wipe',exit);
 }else if(s.kind==='question'){
  op('arrow',1-exit);tr('arrow',1430+(1-ent)*500,360,1+Math.sin(l*3)*.04,-8+ent*8);$('arrow').style.fontSize='330px';
 }else if(s.kind==='food'){
  op('food',1-exit);tr('food',1000+(1-ent)*750,230,1.03+.04*l,-12+ent*10);op('disc',1-exit);$('disc').style.background='#ff6a1a';
 }else if(s.kind==='discover'){
  op('map',.85);tr('map',-20*l,0,1.08);op('phone',1-exit);op('mapScreen',1);tr('phone',1255+(1-ent)*700,125,.88+.01*l,-7+ent*4);
 }else if(s.kind==='status'){
  op('phone',1-exit);op('detailScreen',1);tr('phone',1255+(1-ent)*500,125,.88,-3+ent*5);op('status',out((l-.28)/.15)*(1-exit));tr('status',0,(1-out((l-.28)/.15))*80,1,-5);
 }else if(s.kind==='menu'){
  op('food',1-exit);tr('food',1090+(1-ent)*600,145,1.2+.02*l,-8+ent*5);op('ticker',out((l-.25)/.2)*(1-exit));tr('ticker',-l*125,-75,1,-3);$('ticker').style.color='#211b18';
 }else if(s.kind==='pick'){
  op('food',1-exit);tr('food',1080+(1-ent)*600,280,.87+.03*l,4-ent*7);op('disc',1-exit);$('disc').style.background='#ff6a1a';
 }else if(s.kind==='go'){
  op('phone',1-exit);op('directionScreen',1);tr('phone',1255+(1-ent)*700,125,.88,-8+ent*10);op('route',ent*(1-exit));$('path').style.strokeDashoffset=1700*(1-smooth(l/1.1));
 }else if(s.kind==='brand'){
  op('food',1-exit);tr('food',1070+(1-ent)*650,250,.92+.02*l,-9+ent*7);
 }
 if(l<.14&&s.a>0){op('wipe',1);tr('wipe',-550+out(l/.14)*3100,0,1,15)}else{op('wipe',0)}
};
let paused=false,start=performance.now();window.pauseMotion=()=>paused=true;function tick(now){if(!paused)setTime((now-start)/1000);requestAnimationFrame(tick)}
function resize(){$('stage').style.transform='scale('+Math.min(innerWidth/1920,innerHeight/1080)+')'}addEventListener('resize',resize);resize();setTime(0);requestAnimationFrame(tick);
</script></body></html>`;
fs.writeFileSync(path.join(out,'StallSeeker-fast-type.html'),html);
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
 const page=await browser.newPage({viewport:{width:1280,height:720},deviceScaleFactor:1});
 await page.setContent(html,{waitUntil:'load'});await page.evaluate(()=>document.fonts.ready);await page.evaluate(()=>pauseMotion());
 const times=[.6,2.2,4,6.3,9,12,15,18.2,21.5],tiles=[];
 for(let i=0;i<times.length;i++){
  await page.evaluate(t=>setTime(t),times[i]);const p=path.join(out,'frame-'+String(i+1).padStart(2,'0')+'.png');await page.screenshot({path:p});
  tiles.push({input:await sharp(p).resize(640,360).toBuffer(),left:30+(i%3)*660,top:125+Math.floor(i/3)*408});
  const label=Buffer.from('<svg width="640" height="32"><text x="0" y="22" font-family="Arial" font-size="18" font-weight="bold" fill="#fff3dd">'+String(i+1).padStart(2,'0')+' / '+times[i]+'s</text></svg>');tiles.push({input:label,left:30+(i%3)*660,top:92+Math.floor(i/3)*408});
 }
 const title=Buffer.from('<svg width="2000" height="85"><text x="30" y="43" font-family="Arial" font-size="32" font-weight="bold" fill="#fff3dd">StallSeeker / FAST TYPE</text><text x="30" y="73" font-family="Arial" font-size="18" fill="#ff9d62">24-second silent loop / fast text / punch-in visuals / snap cuts</text></svg>');
 await sharp({create:{width:2020,height:1330,channels:3,background:'#211b18'}}).composite([{input:title,left:0,top:0},...tiles]).png().toFile(path.join(out,'00-fast-type-storyboard.png'));
 console.log('Key frames ready. Rendering fast-type video.');
 const enc=spawn('C:/Users/adama/AppData/Local/ms-playwright/ffmpeg-1011/ffmpeg-win64.exe',['-hide_banner','-loglevel','error','-y','-f','image2pipe','-r','30','-vcodec','mjpeg','-i','pipe:0','-an','-c:v','libvpx','-b:v','3000k','-deadline','realtime','-cpu-used','6',path.join(out,'StallSeeker-fast-type.webm')],{windowsHide:true,stdio:['pipe','ignore','pipe']});
 let error='';enc.stderr.on('data',x=>error+=x);const done=new Promise((resolve,reject)=>enc.on('close',code=>code===0?resolve():reject(new Error(error))));
 for(let f=0;f<720;f++){await page.evaluate(t=>setTime(t),f/30);const buf=await page.screenshot({type:'jpeg',quality:88});if(!enc.stdin.write(buf))await new Promise(r=>enc.stdin.once('drain',r));if(f%144===0)console.log('Rendered '+Math.round(f/720*100)+'%')}
 enc.stdin.end();await done;await browser.close();console.log('DONE: '+out);
})();
