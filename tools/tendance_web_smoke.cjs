// Validation du build réellement servi sur :8240. Aucun serveur créé ici.
const {chromium} = require(process.env.ELA_PLAYWRIGHT_PATH || 'playwright');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const output = path.resolve(__dirname, '../docs/screens/tendance/web');
const base = process.env.ELA_WEB_URL || 'http://127.0.0.1:8240/';
const errors = [];
const readLibrary = () => {
  const raw = localStorage.getItem('flutter.ela.library');
  if (!raw) return [];
  const value = JSON.parse(raw);
  return typeof value === 'string' ? JSON.parse(value) : value;
};
async function swipe(context, page, from, to) {
  const cdp = await context.newCDPSession(page);
  await cdp.send('Input.dispatchTouchEvent', {type:'touchStart', touchPoints:[{x:from[0], y:from[1]}]});
  for (let step = 1; step <= 16; step++) {
    await cdp.send('Input.dispatchTouchEvent', {type:'touchMove', touchPoints:[{x:from[0]+(to[0]-from[0])*step/16, y:from[1]+(to[1]-from[1])*step/16}]});
    await page.waitForTimeout(15);
  }
  await cdp.send('Input.dispatchTouchEvent', {type:'touchEnd', touchPoints:[]});
  await cdp.detach();
  await page.waitForTimeout(1100);
}
(async () => {
  fs.mkdirSync(output, {recursive:true});
  const browser = await chromium.launch({executablePath:process.env.ELA_CHROME_BIN, headless:true, args:['--no-sandbox','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  try {
    const context = await browser.newContext({viewport:{width:412,height:915},deviceScaleFactor:2.625,isMobile:true,hasTouch:true,serviceWorkers:'block'});
    await context.addInitScript(() => {
      localStorage.setItem('flutter.ela.onboarded', 'true');
      localStorage.setItem('flutter.ela.themeMode', JSON.stringify('light'));
    });
    await context.route('https://covers.openlibrary.org/**', route => route.abort('internetdisconnected'));
    const page = await context.newPage();
    page.on('pageerror', error => errors.push(error.message));
    await page.goto(base, {waitUntil:'load'});
    await page.waitForSelector('flutter-view');
    await page.waitForTimeout(3000);
    // Mettre l'auto-défilement en pause pour des captures comparables.
    await page.touchscreen.tap(372,147);
    await page.waitForTimeout(400);
    await page.screenshot({path:path.join(output,'01-hero-jour.png')});
    // PAL de la première carte : vérification de l'ISBN réellement persisté.
    await page.touchscreen.tap(206,737);
    await page.waitForFunction(() => {
      const raw = localStorage.getItem('flutter.ela.library');
      if (!raw) return false;
      const v=JSON.parse(raw); const entries=typeof v==='string'?JSON.parse(v):v;
      return entries.some(e=>e.isbn==='9782070667918'&&e.section==='toRead');
    });
    await page.waitForTimeout(4200); // disparition de la confirmation
    for (let i=2; i<=4; i++) {
      await swipe(context,page,[320,360],[80,360]);
      await page.screenshot({path:path.join(output,`0${i}-hero-jour.png`)});
    }
    await page.touchscreen.tap(206,360);
    await page.waitForFunction(() => {
      const raw = localStorage.getItem('flutter.ela.library');
      if (!raw) return false;
      const v=JSON.parse(raw); const entries=typeof v==='string'?JSON.parse(v):v;
      return entries.some(e=>e.isbn==='9782081641624'&&e.section==='history');
    });
    await page.screenshot({path:path.join(output,'05-fiche-hero.png')});
    await page.touchscreen.tap(28,36);
    await page.waitForTimeout(700);
    await page.touchscreen.tap(372,40);
    await page.waitForTimeout(700);
    await page.screenshot({path:path.join(output,'06-hero-nuit.png')});
    const library = await page.evaluate(readLibrary);
    assert(library.some(e=>e.isbn==='9782070667918'&&e.section==='toRead'));
    const compact = await browser.newContext({viewport:{width:360,height:640},deviceScaleFactor:2,reducedMotion:'reduce',isMobile:true,hasTouch:true,serviceWorkers:'block'});
    await compact.addInitScript(() => {localStorage.setItem('flutter.ela.onboarded','true');localStorage.setItem('flutter.ela.themeMode',JSON.stringify('dark'));});
    await compact.route('https://covers.openlibrary.org/**', route=>route.abort('internetdisconnected'));
    const small = await compact.newPage();
    small.on('pageerror', error=>errors.push(error.message));
    await small.goto(base,{waitUntil:'load'});
    await small.waitForSelector('flutter-view');
    await small.waitForTimeout(3000);
    await small.screenshot({path:path.join(output,'07-compact-nuit.png')});
    await swipe(compact,small,[300,360],[60,360]);
    await swipe(compact,small,[180,540],[180,190]);
    await small.screenshot({path:path.join(output,'08-compact-rayons.png')});
    // Le pont sémantique est activé dans une page séparée des gestes CDP.
    const accessible = await compact.newPage();
    await accessible.setViewportSize({width:412,height:915});
    accessible.on('pageerror', error=>errors.push(error.message));
    await accessible.goto(base,{waitUntil:'load'});
    await accessible.locator('flt-semantics-placeholder').evaluate(el=>el.click());
    await accessible.getByRole('heading',{name:'Tendance',exact:true}).waitFor();
    await accessible.getByRole('button',{name:'Livre 1 sur 5 : Le Petit Prince',exact:true}).waitFor();
    fs.writeFileSync(path.join(output,'accessibilite.txt'),await accessible.locator('body').ariaSnapshot());
    assert.deepEqual(errors,[]);
    fs.writeFileSync(path.join(output,'validation.json'),JSON.stringify({url:base,browser:await browser.version(),serverStarted:false,viewport:{width:412,height:915},compact:{width:360,height:640,reducedMotion:true},network:'local assets over HTTP, remote covers blocked to verify offline edition',checks:['served release on :8240','four touch carousel positions','quick PAL persists correct ISBN','cover opens correct book','back to carousel','night theme','compact swipe and vertical scroll','semantic heading and carousel buttons'],pageErrors:errors},null,2)+'\n');
    console.log('Tendance : release HTTP :8240, gestes, PAL, fiche, nuit et sémantique validés.');
  } finally {
    await browser.close();
  }
})().catch(error=>{console.error(error);process.exit(1);});
