import {createRequire} from 'node:module';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {dirname,resolve} from 'node:path';
import {mkdir,writeFile} from 'node:fs/promises';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const phone=['01-library','02-reader','03-vertical','04-settings','05-servers','06-favorites'];
const tablet=['01-library','02-reader','03-settings','04-servers'];
const browser=await chromium.launch({channel:'chromium',executablePath:process.env.CHROMIUM_EXECUTABLE,headless:true,args:['--no-sandbox']});
try{
 const page=await browser.newPage({viewport:{width:1080,height:1920},deviceScaleFactor:1});
 for(const [kind,ids] of [['phone',phone],['tablet',tablet],['feature',['feature-graphic']]]){
  await mkdir(resolve(root,'exports',kind==='feature'?'':kind),{recursive:true});
  for(const id of ids){
   await page.setViewportSize(kind==='feature'?{width:1024,height:500}:{width:kind==='tablet'?1200:1080,height:1920});
   const url=pathToFileURL(resolve(root,'source/layout.html'));
   url.searchParams.set('kind',kind);url.searchParams.set('id',id);
   await page.goto(url.href);await page.evaluate(()=>window.assetReady);
   const target=resolve(root,'exports',kind==='feature'?'':kind,id+'.jpg');
   await page.screenshot({path:target,type:'jpeg',quality:96});
   console.log(target);
  }
 }
 const thumbs=phone.map(id=>`<figure><img src="exports/phone/${id}.jpg"><figcaption>${id}</figcaption></figure>`).join('');
 const tablets=tablet.map(id=>`<figure><img src="exports/tablet/${id}.jpg"><figcaption>${id}</figcaption></figure>`).join('');
 await writeFile(resolve(root,'preview.html'),`<!doctype html><html lang="fr"><meta charset="utf-8"><title>ComicStream — Visuels Google Play</title><style>@font-face{font-family:Manrope;src:url(source/fonts/Manrope.ttf)}*{box-sizing:border-box}body{background:#eeebe6;color:#29213f;font-family:Manrope,sans-serif;margin:0;padding:40px}h1{margin:0 0 8px;font-size:32px;letter-spacing:-1px}p{margin:0 0 26px}section{display:grid;grid-template-columns:repeat(6,1fr);gap:20px;margin-bottom:32px}figure{margin:0}img{width:100%;display:block;border-radius:8px;box-shadow:0 4px 15px #0002}figcaption{font-size:13px;margin-top:9px}.bottom{display:grid;grid-template-columns:1fr 1fr;gap:30px}.tablets{grid-template-columns:repeat(4,1fr);gap:12px}h2{font-size:19px;margin:0 0 16px}</style><h1>ComicStream</h1><p>Présentation Google Play · Captures de l’application réelle · FR</p><section>${thumbs}</section><div class="bottom"><div><h2>Bannière · 1024 × 500</h2><img src="exports/feature-graphic.jpg"></div><div><h2>Tablette · Captures sans habillage</h2><section class="tablets">${tablets}</section></div></div></html>`);
 await page.setViewportSize({width:1800,height:1200});
 await page.goto(pathToFileURL(resolve(root,'preview.html')).href);await page.evaluate(async()=>{await Promise.all([...document.images].map(i=>i.decode()));await document.fonts.ready});
 await page.screenshot({path:resolve(root,'preview.jpg'),type:'jpeg',quality:92,fullPage:true});
}finally{await browser.close()}
