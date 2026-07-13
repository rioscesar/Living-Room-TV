# Living Room TV

Living Room TV is a local-first, controller-oriented home screen for a Windows PC connected to a television. It turns a browser tab into a calm launcher for streaming sites, Steam Big Picture, and a small set of optional local actions.

The project is a framework-free HTML, CSS, and JavaScript application. It has no backend, cloud account, package manager, or runtime dependency beyond a modern browser.

## Preview

The interface uses a compact contextual hero, horizontal app rails, clear focus depth, and initials as temporary app identities. A repository screenshot is intentionally not included until a clean public configuration can be captured. See [docs/SCREENSHOTS.md](docs/SCREENSHOTS.md) for the capture checklist.

## What It Does

- Presents streaming, games, internet, optional favorites, and settings in a TV-scale interface.
- Provides deterministic arrow-key navigation with remembered positions per row.
- Opens websites and registered application protocols.
- Keeps a five-item Recently Opened list in browser `localStorage`.
- Optionally exposes five fixed Windows helper actions through an allowlisted local protocol.
- Works without the helper and without a private Favorites file.

## Who It Is For

Living Room TV is for people using a Windows media PC from a shared living-room screen who want a simpler launch surface than the Windows desktop. A maintainer can edit the app list without changing layout code.

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
- Initials are temporary visual identities; branded assets are deferred.

## Troubleshooting

- **Controller does nothing:** confirm Steam is running and Desktop Layout is enabled for the connected controller.
- **Each press moves twice:** disable any second controller mapper and confirm the page is not running modified Gamepad polling code.
- **A clicks the pointer instead of focus:** map A to Enter; keep pointer click on the right trigger.
- **Pointer is too fast:** lower Steam Input Mouse Sensitivity for the left stick.
- **Helper action does nothing:** run `scripts/test-helper.ps1`, then inspect `%LOCALAPPDATA%\LivingRoomTV\helper.log`.
- **EA is not found:** update only the fixed candidate paths in `scripts/livingroomtv-helper.ps1`.
- **Private Favorites are missing:** confirm `favorites.local.js` is next to `index.html` and loads before `app.js`.

## Development

Read [CONTRIBUTING.md](CONTRIBUTING.md), [ARCHITECTURE.md](ARCHITECTURE.md), and [AGENTS.md](AGENTS.md). The primary validation command is:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\project-check.tests.ps1
```

It validates JavaScript syntax, navigation behavior, presentation and helper contracts, public-readiness controls, and the checkers' deliberately broken positive controls. Hardware behavior is never inferred from automation.

## Project Status and Roadmap

The current beta candidate is documented in [STATE.md](STATE.md). Planned work and release criteria live in [docs/ROADMAP.md](docs/ROADMAP.md), [docs/BACKLOG.md](docs/BACKLOG.md), and [docs/RELEASE-CHECKLIST.md](docs/RELEASE-CHECKLIST.md).

## Contributing and Support

Contributions are welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md). Use [SUPPORT.md](SUPPORT.md) for help and [SECURITY.md](SECURITY.md) for private vulnerability reporting. Participation is governed by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License and Responsible Use

Living Room TV is available under the [MIT License](LICENSE). Product and service names are trademarks of their respective owners. Living Room TV is not affiliated with or endorsed by those companies.

Only configure services and content you are authorized to access. You are responsible for complying with website terms, regional rules, account requirements, and applicable law.
