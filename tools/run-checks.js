// Runs the sandbox's acceptance checks headlessly and exits non-zero if any fail.
// Usage: node tools/run-checks.js [path/to/index.html]
const path = require('path');
const { chromium } = require('playwright');

(async () => {
  const file = path.resolve(process.argv[2] || path.join(__dirname, '..', 'sandbox', 'index.html'));
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('file://' + file);
  const results = await page.evaluate(async () => { DELAY = 0; return runChecks(); });
  await browser.close();

  results.forEach((r, i) => console.log(`${r.pass ? 'PASS' : 'FAIL'} ${i + 1}. ${r.name}\n      ${r.detail}`));
  errors.forEach(e => console.log('PAGE ERROR ' + e));
  const failed = results.filter(r => !r.pass).length;
  console.log(`\n${results.length - failed}/${results.length} passed`);
  process.exit(failed || errors.length ? 1 : 0);
})();
