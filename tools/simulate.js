// Plays the fixed fight (every hero queues its first ready skill) under several setups and prints the outcome.
// Usage: node tools/simulate.js [path/to/index.html]
const path = require('path');
const { chromium } = require('playwright');

(async () => {
  const file = path.resolve(process.argv[2] || path.join(__dirname, '..', 'sandbox', 'index.html'));
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('file://' + file);
  const rows = await page.evaluate(async () => {
    DELAY = 0;
    const fight = on => withRules(on, async () => {
      reset({ skipFormation: true, defaultFormation: true, pristine: true });
      for (let i = 0; i < 30 && S.phase === 'plan'; i++) {
        for (const u of living('P')) {
          if (u.st.stun) continue;
          const idx = u.skills.findIndex((s, j) => u.cd[j] === 0);
          if (idx < 0) continue;
          const key = 's' + idx, a = act(u, key);
          if (a.pattern === 'all') enqueue(u.id, key, u.r, u.c);
          else { const p = pick(u, a); if (p) enqueue(u.id, key, p[0], p[1]); }
        }
        await runRound();
      }
      return { result: S.result || 'timeout', round: S.round, dealt: S.dealt, taken: S.taken,
        lost: S.units.filter(u => u.side === 'P' && !u.alive).map(u => u.name).join(' ') || '-' };
    });
    const six = { sightline: true, screening: true, kindred: true, focus: true, shatter: true, lastStand: true };
    const out = [];
    for (const mode of ['four', 'triangle']) {
      ELEM.mode = mode;
      for (const [label, on] of [['rules off', {}], ['six v0.2 rules', six], ['six + Ashfall', { ...six, ashfall: true }]])
        out.push({ setup: `4x4 · ${mode} elements · ${label}`, ...(await fight(on)) });
    }
    ELEM.mode = 'four';
    return out;
  });
  await browser.close();
  console.table(rows);
})();
