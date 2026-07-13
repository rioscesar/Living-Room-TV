# Architecture

Living Room TV is a static browser application with one optional Windows integration boundary.

## Runtime Components

- `index.html` defines the shell and loads optional local Favorites before `app.js`.
- `style.css` owns design tokens, layout, focus depth, ambient presentation, and reduced motion.
- `app.js` owns app configuration, rendering, deterministic navigation, launch dispatch, confirmation state, and recent history.
- `favorites.local.js` is an optional ignored configuration file created by each user.
- `scripts/livingroomtv-helper.ps1` is an optional current-user native helper.
- `scripts/start-living-room-tv.ps1` is the fixed browser-launch wrapper used by optional per-user automatic startup.

## Input Ownership

The dashboard consumes keyboard and mouse events. Steam Desktop Layout translates Xbox controller input into those events. The browser Gamepad API is intentionally excluded to avoid duplicate input paths across Windows systems.

## Launch Boundary

`app.js` supports four declarative action types: HTTPS URLs, registered protocols, named helper actions, and placeholders. Helper requests use `livingroomtv://action/<name>`. The PowerShell handler parses that URI and dispatches only fixed allowlisted implementations.

Browser content cannot provide commands, paths, arguments, or executable names to the helper. The helper is installed in `HKCU`, runs without elevation, and writes local diagnostics under `%LOCALAPPDATA%\LivingRoomTV`.

## Automatic Startup Boundary

`scripts/install-autostart.ps1` creates one owned shortcut in the current user's Startup folder. The shortcut invokes Windows PowerShell with the repository-derived wrapper path. No machine-wide registry key, Scheduled Task, administrator permission, automatic login setting, Steam setting, or other Windows profile is changed.

The wrapper selects Chrome or Chromium only from fixed registry and installation candidates, converts the local launcher path to an escaped file URI, and supplies only fixed `--new-window` and `--start-fullscreen` arguments. A named one-slot per-session guard prevents simultaneous wrapper invocations. Steam readiness is advisory because controller translation can become available after the static launcher has opened.

## Local Data

Recent history stays in browser `localStorage`. Personal Favorites stay in ignored local configuration. The project has no backend, database, telemetry, account system, or cloud synchronization.

## Change Boundaries

Navigation is a logical state machine rather than DOM focus. Scrolling follows focus. Presentation transforms must not change layout metrics. See `docs/DESIGN.md` for the complete invariants and `SECURITY.md` for the trust model.
