# Living Room TV

Turn your Windows PC into a Smart TV.

Living Room TV is a local-first, controller-first Smart TV interface for Windows PCs. It transforms a desktop connected to a television into a simple, premium entertainment experience for the whole household.

Unlike traditional game launchers, Living Room TV is designed for everyday entertainment—streaming, web browsing, gaming, and system control—from the couch using only an Xbox controller. It supports games, but it is streaming- and household-first rather than a game-library manager.

The launcher shell is framework-free HTML, CSS, and JavaScript. It has no backend, accounts, telemetry, advertising, cloud dependency, package manager, or build step. Steam Desktop Layout remains the controller translation layer.

## Preview

The interface uses a compact contextual hero, horizontal app rails, clear focus depth, and initials as temporary app identities. A screenshot is optional and is not required for the initial beta. See [docs/SCREENSHOTS.md](docs/SCREENSHOTS.md) before contributing one.

## What It Does

- Presents streaming, games, internet, optional favorites, and settings in a TV-scale interface.
- Provides deterministic arrow-key navigation with remembered positions per row.
- Opens websites and registered application protocols.
- Keeps a five-item Recently Opened list in browser `localStorage`.
- Optionally exposes five fixed Windows helper actions through an allowlisted local protocol.
- Works without the helper and without a private Favorites file.

## Who It Is For

Living Room TV is for people using a Windows media PC from a shared living-room screen who want a simpler launch surface than the Windows desktop. A maintainer can edit the app list without changing layout code.

## Origin

Living Room TV began as a way to make a Windows desktop connected to a television feel natural for the whole family. Existing launchers largely focused on games; this project focuses on everyday living-room entertainment.

## Requirements

- Windows 10 or 11.
- A modern Chromium browser. Google Chrome is the currently tested browser.
- Node.js for development checks only.
- Steam running with Desktop Layout configured for controller use.
- An Xbox controller or keyboard.
- Optional: Windows PowerShell 5.1 for the local helper.

No framework, package manager, build step, backend, database, hosted service, or cloud account is required.

## Quick Start

1. Clone the repository.
2. Open `index.html` in Chrome.
3. Press `F11` for browser fullscreen if desired.
4. Use arrow keys and Enter, or configure Steam Input as described below.

The application loads directly from disk. If Chrome restricts a feature in a local-file context, serve the repository with any static web server; the product itself still has no server-side component.

## Automatic Startup for One Windows User

Living Room TV can open automatically when the current Windows user signs in. Run the installer while signed into the Windows profile that should receive the TV experience:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-autostart.ps1
```

Verify the current-user registration, browser detection, path quoting, and launch plan without opening a browser:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-autostart.ps1
```

Optionally open the launcher once for a non-destructive manual check:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-autostart.ps1 -Launch
```

Remove only the Living Room TV startup entry:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall-autostart.ps1
```

The installer creates one shortcut in the current user's Startup folder. It does not require administrator rights, enable Windows automatic login, alter another Windows profile, or modify Steam startup. It is idempotent and refuses to overwrite an unrelated shortcut with the same name.

The startup wrapper derives the repository location, finds Chrome or Chromium from documented registry and installation locations, and opens `index.html` in a new window with Chrome's `--start-fullscreen` behavior. It retains the user's normal browser profile and does not use kiosk or app mode. Steam should already be configured to start minimized. The launcher does not wait for or reconfigure Steam; if Steam is still starting, the page opens and the local startup log notes that controller translation may not be ready yet.

Startup diagnostics are stored at `%LOCALAPPDATA%\LivingRoomTV\startup.log`. The log records timestamps, local detected paths, Steam readiness, the launch attempt, and failures; it does not inspect or record Favorites, browsing history, credentials, or browser-profile data.

To bypass automatic startup, disable **Living Room TV** under Windows **Settings → Apps → Startup** or run the uninstaller. Close the Living Room TV browser window to return to the normal desktop; it will not reopen until the next sign-in or manual launch. Re-run the installer to restore automatic startup.

## Controller Setup

Steam Input is the sole controller translation layer. The dashboard deliberately does not poll the browser Gamepad API because some Windows systems expose both raw controller input and Steam-generated keyboard input, causing double actions.

Configure Steam **Desktop Layout** with this validated mapping:

| Controller input | Desktop command |
|---|---|
| D-pad | Arrow keys |
| A | Enter |
| Left stick | Joystick Mouse |
| Right stick | Scroll Wheel |
| Right trigger | Left Mouse Click |
| B | Mouse 5 / browser Back, where supported |
| View button | Show Keyboard |

Steam must be running for Desktop Layout translation. Steam Big Picture may temporarily use its own controller layout; verify that Desktop Layout resumes after returning to Chrome. Pointer sensitivity is configured in Steam and may need tuning for the display.

## Private Favorites

Personal bookmarks belong in an ignored local configuration file and must not be committed.

```powershell
Copy-Item .\favorites.local.example.js .\favorites.local.js
```

Edit `favorites.local.js` and keep each entry in this shape:

```js
{
  title: "My Site",
  subtitle: "Personal shortcut",
  initials: "MS",
  accent: "#64748b",
  action: { type: "url", url: "https://example.com" }
}
```

Reload the page. The Favorites row appears automatically. Copy your private file separately to each clone using a trusted private transfer. `favorites.local.js` is ignored by Git; never force-add it.

## Application Configuration

Built-in rows live in `DASHBOARD_CONFIG.rows` in `app.js`. Supported actions are:

```js
action: { type: "url", url: "https://example.com" }
action: { type: "protocol", uri: "steam://open/bigpicture" }
action: { type: "helper", action: "ea" }
action: { type: "placeholder", message: "Not configured yet." }
```

Keep a non-empty `initials` value for every app. Do not add third-party brand assets without a documented license and maintenance plan.

## Optional Windows Helper

The dashboard works without the helper. Install it only if you want EA launch or local power actions.

Install for the current Windows user, without administrator rights:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-helper.ps1
```

Run safe diagnostics:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-helper.ps1
```

Remove the protocol registration:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall-helper.ps1
```

The helper accepts only `ping`, `ea`, `sleep`, `restart`, and `shutdown`. It never accepts browser-provided command strings, executable paths, arguments, or user input. Sleep, Restart, and Shutdown always require an affirmative native Windows confirmation dialog from the interactive local user; Cancel/No is the default. A missing interactive session, dialog failure, or cancellation prevents execution. The dashboard's second selection for Restart and Shutdown remains an additional UX safeguard, but the helper-side dialog is the authorization boundary. Logs and status are stored under `%LOCALAPPDATA%\LivingRoomTV` and are retained after uninstall.

## Security Model

The browser UI is unprivileged. Optional native behavior crosses one explicit boundary: the current-user `livingroomtv://` protocol handler maps a short name to fixed local code. Unknown or malformed actions are blocked. The helper does not require elevation.

Review [SECURITY.md](SECURITY.md) before installing the helper. Only install code from a revision you trust. This project has not received an external security audit.

## Current Limitations

- Chrome and streaming sites are not controlled directly; controller behavior depends on Steam Desktop Layout.
- Browser Back and on-screen keyboard behavior vary by Steam, browser, and website.
- Some streaming sites may resist keyboard focus or open their own overlays.
- The helper is Windows-only and EA discovery checks only known install locations.
- Full physical 4K TV, couch-distance, reconnect, and multi-account testing remains manual.
- Per-user sign-in startup, single-window behavior, and cross-profile isolation require a real Windows sign-out/sign-in test after installation.
- Initials are temporary visual identities; branded assets are deferred.

## Troubleshooting

- **Controller does nothing:** confirm Steam is running and Desktop Layout is enabled for the connected controller.
- **Each press moves twice:** disable any second controller mapper and confirm the page is not running modified Gamepad polling code.
- **A clicks the pointer instead of focus:** map A to Enter; keep pointer click on the right trigger.
- **Pointer is too fast:** lower Steam Input Mouse Sensitivity for the left stick.
- **Helper action does nothing:** run `scripts/test-helper.ps1`, then inspect `%LOCALAPPDATA%\LivingRoomTV\helper.log`.
- **EA is not found:** update only the fixed candidate paths in `scripts/livingroomtv-helper.ps1`.
- **Private Favorites are missing:** confirm `favorites.local.js` is next to `index.html` and loads before `app.js`.
- **Automatic startup is missing:** run `scripts/test-autostart.ps1` from the intended Windows profile and confirm the reported shortcut and wrapper paths.
- **Startup opens without controller input:** confirm Steam is configured separately to start minimized; inspect `%LOCALAPPDATA%\LivingRoomTV\startup.log` for the Steam readiness note.
- **Startup opens more than once:** run the idempotent installer again and confirm `scripts/test-autostart.ps1` reports one matching shortcut.

## Development

Read [CONTRIBUTING.md](CONTRIBUTING.md), [ARCHITECTURE.md](ARCHITECTURE.md), and [AGENTS.md](AGENTS.md). The primary validation command is:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\project-check.tests.ps1
```

It validates JavaScript syntax, navigation behavior, presentation and helper contracts, public-readiness controls, and the checkers' deliberately broken positive controls. Hardware behavior is never inferred from automation.

## Project Status and Roadmap

The current beta candidate is documented in [STATE.md](STATE.md). Planned work and release criteria live in [docs/ROADMAP.md](docs/ROADMAP.md), [docs/BACKLOG.md](docs/BACKLOG.md), and [docs/RELEASE-CHECKLIST.md](docs/RELEASE-CHECKLIST.md).

## Contributing and Support

Contributions are welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md). Use [SUPPORT.md](SUPPORT.md) for help and [SECURITY.md](SECURITY.md) for the current public GitHub Issues security-reporting policy. Participation is governed by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License and Responsible Use

Living Room TV is available under the [MIT License](LICENSE). Product and service names are trademarks of their respective owners. Living Room TV is not affiliated with or endorsed by those companies.

Only configure services and content you are authorized to access. You are responsible for complying with website terms, regional rules, account requirements, and applicable law.
