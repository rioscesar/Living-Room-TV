# Release Checklist

Candidate: `v0.1.0-beta.1` (not published)

## Repository Boundary

- [x] Full reachable history contains no secrets, personal email addresses, personal paths, or private bookmarks.
- [x] `favorites.local.js`, logs, status files, credentials, and environment files are untracked in the remediation tree.
- [x] Public-readiness controls use synthetic fixtures and detect direct and split-string email values.
- [x] Sanitized history and repository refs are recreated after explicit approval.
- [x] GitHub email privacy and command-line push protection are enabled for maintainers.
- [x] GitHub Issues is enabled and documented as the public, non-confidential reporting route.
- [x] Repository visibility change is separately approved but not yet applied.

## Automated Verification

- [x] `powershell -ExecutionPolicy Bypass -File .\tests\project-check.tests.ps1` passes in a clean clone of the sanitized baseline.
- [x] GitHub Actions passes on the sanitized baseline.
- [x] The sanitized baseline passed the deterministic safety scan.
- [x] Mocked helper authorization tests prove cancellation/noninteractive failure blocks execution and affirmative confirmation reaches only the injected execution path.

## Manual Product Verification

- [x] Chrome fresh load and F11 layout pass on the target desktop.
- [x] Xbox Bluetooth reconnect and single-step D-pad navigation pass.
- [x] A selects logical focus; left stick moves pointer; right stick scrolls.
- [x] Right trigger clicks, B navigates Back, and View opens text entry.
- [x] Steam Big Picture returns cleanly to Desktop Layout.
- [x] Optional helper install, ping, blocked action, EA discovery, and uninstall pass.
- [x] Native helper confirmation and actual Sleep, Restart, and Shutdown behavior are tested safely on the target machine.
- [x] Physical 4K TV and couch-distance readability pass.
- [ ] A second user can understand launch, Back, text entry, and return behavior.

## Automatic Startup Manual Validation

- [ ] Install from the Windows profile intended for Living Room TV.
- [ ] Sign out and back in; confirm Steam starts minimized and Living Room TV opens once.
- [ ] Confirm the automatic window reaches fullscreen and controller input works after Steam is ready.
- [ ] Sign into another Windows profile and confirm it is unaffected.
- [ ] Uninstall autostart, sign out and back in, and confirm Living Room TV no longer opens automatically.

## Publication

- [x] Release notes match verified behavior and list remaining limitations.
- [x] License, trademark disclaimer, security policy, support path, and contributor guidance are present.
- [x] Public visibility and `v0.1.0-beta.1` publication have explicit owner approval; execution waits for reviewed `main`.
