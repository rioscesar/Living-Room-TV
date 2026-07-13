# Release Checklist

Candidate: `v0.1.0-beta.1` (not published)

## Repository Boundary

- [x] Full reachable history contains no secrets, personal email addresses, personal paths, or private bookmarks.
- [x] `favorites.local.js`, logs, status files, credentials, and environment files are untracked in the remediation tree.
- [x] Public-readiness controls use synthetic fixtures and detect direct and split-string email values.
- [x] Sanitized history and repository refs are recreated after explicit approval.
- [ ] GitHub email privacy and command-line push protection are enabled for maintainers.
- [ ] A functioning private vulnerability-reporting channel is verified.
- [ ] Repository visibility change is separately approved.

## Automated Verification

- [ ] `powershell -ExecutionPolicy Bypass -File .\tests\project-check.tests.ps1` passes in a clean clone.
- [ ] GitHub Actions passes on the release commit.
- [ ] The staged diff and tracked tree pass the deterministic safety scan.
- [x] Mocked helper authorization tests prove cancellation/noninteractive failure blocks execution and affirmative confirmation reaches only the injected execution path.

## Manual Product Verification

- [ ] Chrome fresh load and F11 layout pass on the target desktop.
- [ ] Xbox Bluetooth reconnect and single-step D-pad navigation pass.
- [ ] A selects logical focus; left stick moves pointer; right stick scrolls.
- [ ] Right trigger clicks, B navigates Back, and View opens text entry.
- [ ] Steam Big Picture returns cleanly to Desktop Layout.
- [ ] Optional helper install, ping, blocked action, EA discovery, and uninstall pass.
- [ ] Native helper confirmation and actual Sleep, Restart, and Shutdown behavior are tested safely on the target machine.
- [ ] Physical 4K TV and couch-distance readability pass.
- [ ] A second user can understand launch, Back, text entry, and return behavior.

## Publication

- [ ] Release notes match verified behavior and list remaining limitations.
- [ ] License, trademark disclaimer, security policy, support path, and contributor guidance are present.
- [ ] No release or public visibility action occurs without explicit owner approval.
