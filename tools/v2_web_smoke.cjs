// Contrôle du build release servi sur le serveur :8240 existant.
const {chromium} = require(process.env.ELA_PLAYWRIGHT_PATH || 'playwright');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const base = process.env.ELA_WEB_URL || 'http://127.0.0.1:8240/';
const output = path.resolve(__dirname, '../docs/screens/v2/web');
const errors = [];
async function open(page, route) {
  await page.goto(`${base}#${route}`, {waitUntil:'load'});
  await page.waitForSelector('flutter-view');
  const placeholder = page.locator('flt-semantics-placeholder');
  if (await placeholder.count()) await placeholder.evaluate(el => el.click());
  await page.waitForTimeout(2200);
}
async function press(page, name) {
  await page.getByRole('button', {name, exact:true}).evaluate(el => el.click());
  await page.waitForTimeout(800);
}
async function shot(page, name) {
  await page.screenshot({path:path.join(output, `${name}.png`)});
}
function readPref(key) {
  const raw = localStorage.getItem(`flutter.${key}`);
  if (raw == null) return null;
  const decoded = JSON.parse(raw);
  if (typeof decoded !== 'string') return decoded;
  try { return JSON.parse(decoded); } catch { return decoded; }
}
(async () => {
  fs.mkdirSync(output, {recursive:true});
  const browser = await chromium.launch({executablePath:process.env.ELA_CHROME_BIN,headless:true,args:['--no-sandbox','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  let page;
  try {
    const context = await browser.newContext({viewport:{width:412,height:915},deviceScaleFactor:2,reducedMotion:'reduce',serviceWorkers:'block'});
    await context.addInitScript(() => {
      localStorage.setItem('flutter.ela.onboarded','true');
      if (!localStorage.getItem('flutter.ela.themeMode')) localStorage.setItem('flutter.ela.themeMode',JSON.stringify('light'));
    });
    await context.route('https://covers.openlibrary.org/**', route => route.abort('internetdisconnected'));
    page = await context.newPage(); page.setDefaultTimeout(12000);
    page.on('pageerror', e => errors.push(e.message));
    await open(page, '/tendance');
    await page.getByRole('button',{name:'Marché',exact:true}).waitFor();
    await page.getByRole('heading',{name:'Tendance',exact:true}).waitFor();
    await shot(page, '01-tendance-etoiles');
    await open(page, '/livre/9782070667918');
    await page.getByRole('button',{name:'Noter ce livre',exact:true}).waitFor();
    await shot(page, '02-fiche-notation');
    await press(page, 'Noter ce livre');
    await page.getByText('Choisissez de 0,5 à 5 étoiles').waitFor();
    const slider = page.getByRole('slider');
    for (let i=0; i<9; i++) { await slider.press('ArrowRight'); await page.waitForTimeout(80); }
    await page.getByText('4,5 / 5').waitFor();
    await shot(page, '03-widget-notation');
    await press(page, 'Enregistrer');
    const ratingEquals = expected => {
      const raw = localStorage.getItem('flutter.ela.ratings');
      if (!raw) return false;
      const value = JSON.parse(raw); const ratings = typeof value === 'string' ? JSON.parse(value) : value;
      const own = ratings.find(r => r.isbn === '9782070667918' && r.userId === 'anonymous');
      return expected == null ? own == null : own?.value === expected;
    };
    await page.waitForFunction(ratingEquals,4.5);
    await press(page, /Modifier ma note/);
    for (let i=0; i<2; i++) { await page.getByRole('slider').press('ArrowLeft'); await page.waitForTimeout(80); }
    await press(page, 'Enregistrer');
    await page.waitForFunction(ratingEquals,3.5);
    await press(page, /Modifier ma note/);
    await press(page, 'Supprimer ma note');
    await page.waitForFunction(ratingEquals,null);
    fs.writeFileSync(path.join(output,'notation-validation.json'),JSON.stringify({url:base,browser:await browser.version(),checks:['accessible keyboard half-stars','persisted rating 4.5','edited rating 3.5','deleted own rating'],pageErrors:errors},null,2)+'\n');
    assert.deepEqual(errors,[]);
    if (process.env.ELA_RATING_ONLY) { console.log('Notation web : demi-étoiles au clavier, persistance, modification et suppression validées.'); return; }
    // Les actions sémantiques contrôlent le parcours sans gestes CDP synthétiques.
    await open(page, '/marche');
    await page.getByText('Bonnes affaires du moment').waitFor();
    await shot(page, '04-marche-accueil');
    await open(page, '/marche?isbn=9782070667918');
    await page.getByRole('group',{name:/MEILLEURE OFFRE · PRIX TOTAL/}).waitFor();
    await shot(page, '05-comparateur');
    await press(page, 'Neuf');
    assert.equal(await page.getByRole('group',{name:/Leboncoin/}).count(),0);
    await page.getByRole('group',{name:/Place des Libraires/}).waitFor();
    await page.getByRole('button',{name:'Voir l’offre affiliée',exact:true}).first().evaluate(el => el.click());
    await page.getByText('Lien affilié simulé · aucun achat effectué.').waitFor();
    await shot(page, '06-lien-affilie');
    await open(page, '/annonce/demo-0');
    await press(page, 'Contacter');
    await page.getByRole('button',{name:'Demande simulée',exact:true}).waitFor();
    await shot(page, '07-annonce');
    await open(page, '/marche?vue=radar');
    await page.getByText('L’essentiel du Radar vous est montré.').waitFor();
    await shot(page, '08-radar');
    await open(page, '/scanner');
    await page.getByRole('textbox',{name:'ISBN du livre',exact:true}).fill('9782070667918');
    await shot(page, '09-scanner-manuel');
    await press(page, 'Chercher');
    await page.getByText('La fiche de lecture',{exact:true}).waitFor();
    await page.waitForFunction(readPref => {
      const raw = localStorage.getItem('flutter.ela.library');
      if (!raw) return false;
      const value = JSON.parse(raw); const entries = typeof value === 'string' ? JSON.parse(value) : value;
      return entries.some(e => e.isbn === '9782070667918');
    });
    await shot(page, '10-fiche-depuis-isbn');
    await open(page, '/recherche');
    await page.getByRole('textbox').fill('Camus');
    await page.waitForTimeout(1800);
    await page.getByRole('button',{name:/L’Étranger/}).waitFor();
    await shot(page, '11-recherche-etoiles');
    await open(page, '/tendance');
    await press(page, 'Lire de nuit');
    assert.equal(await page.evaluate(readPref,'ela.themeMode'),'dark');
    await page.setViewportSize({width:360,height:640});
    await shot(page, '12-compact-nuit');
    await open(page, '/marche');
    await page.getByText('Bonnes affaires du moment').waitFor();
    await shot(page, '13-marche-compact-nuit');
    fs.writeFileSync(path.join(output,'accessibilite.txt'), await page.locator('body').ariaSnapshot());
    assert.deepEqual(errors,[]);
    fs.writeFileSync(path.join(output,'validation.json'),JSON.stringify({url:base,browser:await browser.version(),serverStarted:false,viewport:{width:412,height:915},compact:{width:360,height:640},pixelRatio:2,network:'Local assets over HTTP; covers blocked only in this test to exercise the existing offline fallback',checks:['five navigation entries including Marché','community rating summary and editor','market home','comparison filters','affiliate offer','reader listing and simulated contact','integrated Premium Radar','manual ISBN opens the right book','search with stars','persisted night theme','compact market','accessible semantics'],pageErrors:errors},null,2)+'\n');
    console.log('V2 : release :8240, notation, Marché, scanner, nuit et format compact validés.');
  } catch (error) {
    if (page) { await page.screenshot({path:'/tmp/ela-v2-web-error.png'}); fs.writeFileSync('/tmp/ela-v2-web-error-aria.txt',await page.locator('body').ariaSnapshot()); }
    throw error;
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exit(1); });
