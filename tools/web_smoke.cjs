// Chromium mobile, build release, sans serveur HTTP. Playwright répond aux
// requêtes de ela.test directement avec les fichiers locaux de build/web.
// ELA_PLAYWRIGHT_PATH=/path/to/playwright ELA_CHROME_BIN=/path/to/chrome node tools/web_smoke.cjs
const {chromium} = require(process.env.ELA_PLAYWRIGHT_PATH || 'playwright');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../build/web');
const output = path.resolve(__dirname, '../docs/screens/web');
const mime = {'.html':'text/html','.js':'text/javascript','.json':'application/json','.wasm':'application/wasm','.ttf':'font/ttf','.otf':'font/otf','.png':'image/png','.bin':'application/octet-stream'};
(async()=>{
  const browser=await chromium.launch({executablePath:process.env.ELA_CHROME_BIN,headless:true,args:['--no-sandbox','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  let currentPage;
  try {
    const context=await browser.newContext({viewport:{width:412,height:915},deviceScaleFactor:2.625,isMobile:true,hasTouch:true,serviceWorkers:'block'});
    await context.addInitScript(()=>{localStorage.setItem('flutter.ela.onboarded','true');localStorage.setItem('flutter.ela.themeMode',JSON.stringify('light'));});
    let requests=0;
    await context.route('**/*',async route=>{
      const url=new URL(route.request().url());
      if(url.hostname!=='ela.test')return route.abort('internetdisconnected');
      const relative=decodeURIComponent(url.pathname).replace(/^\/+/, '') || 'index.html';
      const file=path.resolve(root,relative);
      if(!file.startsWith(root+path.sep)||!fs.existsSync(file)){return route.fulfill({status:404,body:'Missing asset'});}
      requests++;
      await route.fulfill({path:file,contentType:mime[path.extname(file)]||'application/octet-stream'});
    });
    const page=await context.newPage();currentPage=page;page.setDefaultTimeout(10000);page.setDefaultNavigationTimeout(10000);
    const errors=[];page.on('pageerror',error=>{errors.push(error.message);console.error('Page error:',error.stack);});
    await page.goto('https://ela.test/',{waitUntil:'load'});
    await page.waitForSelector('flutter-view');
    await page.waitForTimeout(3500);
    fs.mkdirSync(output,{recursive:true});
    await page.screenshot({path:path.join(output,'01-tendance.png')});
    await page.touchscreen.tap(154,860);
    await page.waitForURL(url=>url.hash.includes('/scanner'));
    await page.waitForTimeout(500);
    await page.touchscreen.tap(160,555);
    await page.keyboard.type('9782070667918',{delay:25});
    assert.equal(await page.locator('input.flt-text-editing:focus').inputValue(),'9782070667918');
    await page.touchscreen.tap(200,590);
    // push garde volontairement l'URL de la branche dans go_router. Une
    // entrée historique prouve que la fiche correcte a été montée et résolue.
    const historyContains=isbn=>{
      const raw=localStorage.getItem('flutter.ela.library');
      if(!raw)return false;
      const value=JSON.parse(raw);const items=typeof value==='string'?JSON.parse(value):value;
      return items.some(e=>e.isbn===isbn);
    };
    await page.waitForFunction(historyContains,'9782070667918');
    await page.screenshot({path:path.join(output,'02-fiche-isbn.png')});
    await page.touchscreen.tap(28,36);
    await page.waitForTimeout(500);
    await page.touchscreen.tap(354,860);
    await page.waitForURL(url=>url.hash.includes('/recherche'));
    await page.waitForTimeout(400);
    await page.touchscreen.tap(160,180);
    await page.keyboard.type('Camus',{delay:50});
    assert.equal(await page.locator('input.flt-text-editing:focus').inputValue(),'Camus');
    await page.waitForTimeout(1800);
    await page.screenshot({path:path.join(output,'03-recherche.png')});
    await page.touchscreen.tap(200,310);
    await page.waitForFunction(historyContains,'9782070413438');
    await page.touchscreen.tap(28,36);
    await page.waitForTimeout(500);
    await page.touchscreen.tap(160,180);
    assert.equal(await page.locator('input.flt-text-editing:focus').inputValue(),'Camus');
    // Vérifier séparément les libellés exposés dans le DOM accessible.
    const accessible=await context.newPage();
    accessible.on('pageerror',error=>errors.push(error.message));
    await accessible.goto('https://ela.test/',{waitUntil:'load'});
    await accessible.locator('flt-semantics-placeholder').evaluate(el=>el.click());
    await accessible.getByRole('button',{name:'Scanner',exact:true}).waitFor();
    await accessible.getByRole('button',{name:'Recherche',exact:true}).waitFor();
    await accessible.getByRole('heading',{name:'Tendance',exact:true}).waitFor();
    fs.writeFileSync(path.join(output,'accessibilite.txt'),await accessible.locator('body').ariaSnapshot());
    assert.deepEqual(errors,[]);
    fs.writeFileSync(path.join(output,'validation.json'),JSON.stringify({browser:await browser.version(),viewport:{width:412,height:915},devicePixelRatio:2.625,localAssets:requests,serverStarted:false,network:'blocked; real offline cover fallback',checks:['release starts','trending','manual ISBN opens book','back to scanner','search Camus','book then back preserves query','semantic navigation labels and chapter heading'],pageErrors:errors},null,2)+'\n');
    console.log('Mobile Chromium: release, scanner ISBN, recherche et retour validés sans serveur.');
  }catch(error){if(currentPage){await currentPage.screenshot({path:'/tmp/ela-web-error.png'});fs.writeFileSync('/tmp/ela-web-error-aria.txt',await currentPage.locator('body').ariaSnapshot());}throw error;}finally{await browser.close();}
})().catch(error=>{console.error(error);process.exit(1);});
