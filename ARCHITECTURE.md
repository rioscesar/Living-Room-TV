# Architecture

Living Room TV is a static browser application with one optional Windows integration boundary.

## Runtime Components

- `index.html` defines the shell and loads optional local Favorites before `app.js`.
- `style.css` owns design tokens, layout, focus depth, ambient presentation, and reduced motion.
- `app.js` owns app configuration, rendering, deterministic navigation, launch dispatch, confirmation state, and recent history.
- `favorites.local.js` is an optional ignored configuration file created by each user.
- `scripts/livingroomtv-helper.ps1` is an optional current-user native helper.

## Input Ownership

The dashboard consumes keyboard and mouse events. Steam Desktop Layout translates Xbox controller input into those events. The browser Gamepad API is intentionally excluded to avoid duplicate input paths across Windows systems.

## Launch Boundary

`app.js` supports four declarative action types: HTTPS URLs, registered protocols, named helper actions, and placeholders. Helper requests use `livingroomtv://action/<name>`. The PowerShell handler parses that URI and dispatches only fixed allowlisted implementations.

Browser content cannot provide commands, paths, arguments, or executable names to the helper. The helper is installed in `HKCU`, runs without elevation, and writes local diagnostics under `%LOCALAPPDATA%\LivingRoomTV`.

## Local Data

Recent history stays in browser `localStorage`. Personal Favorites stay in ignored local configuration. The project has no backend, database, telemetry, account system, or cloud synchronization.

## Change Boundaries

Navigation is a logical state machine rather than DOM focus. Scrolling follows focus. Presentation transforms must not change layout metrics. See `docs/DESIGN.md` for the complete invariants and `SECURITY.md` for the trust model.
