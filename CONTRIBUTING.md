# Contributing

Thank you for improving Living Room TV. Keep changes small, evidence-based, and usable from a shared living-room screen.

## Before You Start

Read `ARCHITECTURE.md`, `docs/DESIGN.md`, and `STATE.md`. Search existing issues before proposing a feature. Explain the observed problem and the environment in which it occurred.

## Local Workflow

1. Create a branch from current `main`.
2. Declare the files your change needs.
3. Preserve unrelated work and private `favorites.local.js` data.
4. Implement the smallest coherent change.
5. Run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\tests\project-check.tests.ps1
   ```

6. Record manual validation separately and only for environments actually tested.
7. Open a draft pull request with the problem, implementation, automated evidence, manual evidence, and remaining limitations.

## Product Contracts

- Up/Down move one logical area and restore destination memory; Left/Right move one item without wrapping.
- Steam Input is the sole controller translation owner; do not add Gamepad polling.
- The hero is presentation-only except for its explicit Recent pills.
- Focus animation must not affect layout geometry.
- Private destinations never enter tracked files, examples, tests, screenshots, or logs.
- Native actions stay short, fixed, and allowlisted. Never introduce arbitrary command execution.
- Keep the application framework-free unless an architectural proposal is approved first.

## App and Asset Changes

Built-in apps belong in `DASHBOARD_CONFIG.rows`. Personal shortcuts belong in `favorites.local.js`. Every app needs an initials fallback. Do not add service logos, fonts, images, or copied code without documenting source, license, redistribution terms, and maintenance ownership.

## Reports and Pull Requests

Bug reports should include exact reproduction steps, browser and Windows versions, input method, expected behavior, and observed behavior. Visual or hardware claims need real screenshots or physical test notes. Pull requests should not include unrelated formatting, generated logs, secrets, personal paths, or private bookmarks.

Be respectful and follow `CODE_OF_CONDUCT.md`. Report vulnerabilities through the private route in `SECURITY.md`, not a public issue.
