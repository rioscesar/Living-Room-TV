# AGENTS.md — Living Room TV

## Start Here

1. Read `STATE.md` and verify it against the code and Git history.
2. Read `README.md`, then only the relevant document under `docs/`.
3. Start from an up-to-date `main` branch and preserve unrelated local changes.

## Project Rules

- Preserve the local-first, framework-free HTML/CSS/JavaScript architecture unless an approved change requires otherwise.
- Treat the navigation invariants in `docs/DESIGN.md` as behavioral contracts.
- Keep built-in app definitions in `DASHBOARD_CONFIG.rows` in `app.js`.
- Keep private destinations in ignored `favorites.local.js`; never commit personal bookmarks.
- Steam Input owns controller translation. Do not add browser Gamepad polling.
- Keep browser-to-Windows behavior declarative and allowlisted. Never accept command strings, executable paths, or user-entered arguments from the dashboard.
- Do not claim controller, couch, fullscreen, helper, power, or 4K validation without a real run in that environment.
- Run `powershell -ExecutionPolicy Bypass -File .\tests\project-check.tests.ps1` before handoff.
- Keep `STATE.md` and the canonical documents under `docs/` synchronized with verified behavior.
- Open pull requests for implementation changes only. Do not self-merge.
