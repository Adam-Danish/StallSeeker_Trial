const fs=require('fs'),path=require('path');
let source=fs.readFileSync(path.join(__dirname,'../continuous-motion/prepare-canva-editable.cjs'),'utf8');
const moments=[
 [.6,'Hungry','0–1.5 s. Opening text is fully visible at the loop seam. Fast masked slide out at 1.34 s.'],
 [2.2,'What is nearby','1.5–3 s. Slide headline words up in 0.2 s, staggered by 0.055 s; arrow punches in.'],
 [4,'Good food','3–5 s. Oversized text snaps upward; food slides in from the right with a small rotation.'],
 [6.3,'Find a stall','5–7.8 s. Quick diagonal wipe, 0.2 s text reveal and phone punch-in.'],
 [9,'Open now','7.8–10.5 s. Phone swings in; open status label follows after 0.28 s.'],
 [12,'See the menu','10.5–13.6 s. Oversized food close-up; 0.2 s text slide and moving menu ticker.'],
 [15,'Pick a favourite','13.6–16.7 s. Fast staggered words with food and orange circle moving in from right.'],
 [18.2,'Lets go','16.7–20 s. Directions phone punches in; route draws in 1.1 s.'],
 [21.5,'StallSeeker','20–23 s. Brand headline slides in with the food cutout.'],
 [23.6,'Loop join','23–24 s. Return to opening composition and hold through the loop seam.']
];
source=source.replace('StallSeeker-continuous-motion.html','StallSeeker-fast-type.html');
source=source.replace(/const moments=\[[\s\S]*?\n\];/,'const moments='+JSON.stringify(moments)+';');
source=source.replace("snapshot.replace('<div ',", "snapshot.replace('<main ',");
source=source.replace('`<div data-document-role=', '`<main data-document-role=');
source=source.replace('StallSeeker editable motion keyframes','StallSeeker fast-type editable keyframes');
fs.writeFileSync(path.join(__dirname,'prepare-canva-source.cjs'),source);
require('./prepare-canva-source.cjs');
