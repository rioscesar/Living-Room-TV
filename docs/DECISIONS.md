# Decisions

## Framework-Free Local Shell

Use static HTML, CSS, and JavaScript. The current product does not need a framework, build system, backend, or cloud service.

## Steam Owns Controller Translation

Steam Desktop Layout translates Xbox input into keyboard and mouse events. The dashboard does not poll the Gamepad API. Physical testing showed that mixed raw and synthetic input can double-trigger actions on some Windows systems.

## Deterministic Navigation

Navigation is stored in a logical model with independent remembered positions. It does not rely on browser focus or infer state from scroll position.

## Optional Allowlisted Helper

Native Windows behavior uses a current-user custom protocol with a fixed action table. Browser data can select only a known name and can never supply a command, path, executable, or argument. Sleep, Restart, and Shutdown require affirmative interaction with a fixed native Windows dialog inside the helper; a noninteractive session, dialog failure, or cancellation fails closed. Dashboard confirmation remains defense in depth and is not the authorization boundary. The dashboard remains usable without the helper.

## Private Favorites Boundary

Personal destinations live only in ignored `favorites.local.js`. The repository ships a schema example with reserved example domains and never imports browser bookmarks automatically.

## Current-User Automatic Startup

Use one shortcut in the current user's Startup folder to invoke a fixed PowerShell wrapper. The shortcut is visible, requires no administrator rights, handles repository paths with spaces, is idempotent, and can be removed without touching Steam or other profiles. HKCU Run was rejected because it is less transparent and adds registry quoting risk. A logon Scheduled Task was rejected because its policy, trigger, and maintenance complexity do not improve this single-user static launcher. Direct registration without a wrapper was rejected because it cannot provide deterministic browser discovery, local logging, or duplicate suppression.

The wrapper retains the normal Chrome profile and uses fixed `--new-window` and `--start-fullscreen` arguments. It does not use kiosk, app mode, a dedicated browser profile, or browser Gamepad input. Steam readiness is advisory rather than a blocking wait because the static launcher remains usable and controller translation can become available after Steam starts.

## Public Issue Reporting

GitHub Issues is the owner-approved security and conduct reporting route for the initial public beta. Issues are public, so repository documentation and issue forms require sanitized information and make no confidentiality claim. A dedicated private reporting channel remains a possible future improvement rather than a release requirement.

## Brand Asset Licensing

Simple Icons and other third-party logo repositories are not used. The UI retains initials as its temporary visual identity because service marks, redistribution terms, upstream changes, and asset maintenance require explicit ownership.

Brand assets require a dedicated licensing and maintenance strategy and will be implemented in a future milestone.

## Public History Boundary

Before a public release, reachable history must be free of personal email addresses, secrets, private destinations, and machine-specific data. Public-readiness checks supplement, but do not replace, staged-diff and history review.

Public-readiness controls use synthetic fixtures. They detect direct email values and split-string reconstruction without storing the private value that motivated the control.

On 2026-07-13, the private repository was recreated from the verified remediation tree as a new root history. Old branches, pull-request refs, and original-history commits remain only in private recovery backups and were not migrated.
