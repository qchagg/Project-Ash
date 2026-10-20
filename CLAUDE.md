# Working on Project Ash

- The sandbox is `sandbox/index.html`, a single page with no build step. Keep it self-contained.
- It is published as the artifact https://claude.ai/artifact/Ln4qNwpjb9wkEykWCy2ShL. After changing it, republish to that URL so the link stays the same, and commit the same file here.
- Design decisions live in the Docs tracker (https://claude.ai/code/artifact/5425ff38-fc13-4ad2-99de-10ba5c00adea). Log decisions there, newest first in the decisions table.
- Run `node tools/run-checks.js` before committing; every check must pass. The two reference fights replay under the v0.1 element triangle and must not change.
- Add an acceptance check to `CHECKS` in the sandbox for each new rule or system.
- The user is learning French: a short French line with its English translation is welcome in replies.
