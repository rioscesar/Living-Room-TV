# Changelog

All notable changes are recorded here. The project has not published a release.

## Unreleased

### Release-blocker remediation

- Replaced personal-address-specific scanner data with generic checks and synthetic controls, including split-string reconstruction coverage.
- Moved authorization for Sleep, Restart, and Shutdown into a native helper confirmation dialog with Cancel/No as the default.
- Added isolated helper tests for cancellation, confirmation, noninteractive failure, raw protocol invocation, unknown actions, and injection-shaped input without executing power actions.
- Recreated private `main` as a sanitized root history after explicit approval; private vulnerability reporting, physical validation, public visibility, and release publication remain pending human action.

### Public-readiness candidate

- Added standalone README, architecture, security, support, contribution, conduct, issue, and pull-request guidance.
- Added minimal Windows CI and deterministic public-boundary controls.
- Isolated personal Favorites in an ignored local file with a safe example.
- Documented the helper trust boundary, controller mapping, limitations, screenshot hygiene, and release gates.
- Prepared `v0.1.0-beta.1` documentation without publishing a tag or release.

### Product foundation

- Added a compact contextual hero, horizontal rails, tokenized presentation, ambient color, focus depth, and reduced-motion support.
- Added deterministic navigation with independent row and Recent memory.
- Adopted Steam Desktop Layout as the sole controller translation owner.
- Added URL, protocol, placeholder, and optional fixed helper actions.
- Added local recent history and optional private Favorites.
