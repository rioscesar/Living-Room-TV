# Security Policy

## Supported Version

Security fixes target the latest commit on `main`. Unreleased branches and older snapshots are not supported.

## Reporting a Vulnerability

Use the repository's [Security report issue form](https://github.com/rioscesar/Living-Room-TV/issues/new/choose). GitHub Issues are public. Do not include credentials, personal information, private URLs, browser data, exploit payloads, or other details that are unsafe to disclose. If a complete report cannot be shared safely, open only a minimal issue stating the affected revision and that additional coordination is required.

For information that is safe for public disclosure, describe the affected revision, impact, prerequisites, and a sanitized reproduction. This repository does not currently provide a confidential vulnerability-reporting channel and does not promise that issue content will remain private.

## Threat Model

The static dashboard is unprivileged and has no backend, accounts, telemetry, or remote configuration. Its main risks are unsafe local configuration, untrusted outbound destinations, browser/protocol behavior, and the optional Windows helper.

The helper is the native trust boundary. Installation registers `livingroomtv://` for the current user in `HKCU`. The browser may request only one of five names: `ping`, `ea`, `sleep`, `restart`, or `shutdown`. The helper maps those names to fixed implementations and rejects malformed or unknown requests. It does not evaluate input, accept command strings, take executable paths, or require administrator rights.

Power actions are consequential. Any local process can invoke a registered custom protocol, so Sleep, Restart, and Shutdown require a fixed native helper confirmation with No as the default. Dashboard confirmation remains an additional UX safeguard. Install the helper only on a trusted machine from a revision you have reviewed. Uninstall it with `scripts/uninstall-helper.ps1` when it is not needed.

Optional automatic startup creates one current-user Startup-folder shortcut targeting a fixed local wrapper. The wrapper detects only supported browser executables, uses fixed launch arguments, and never accepts browser-provided commands. It does not modify automatic login, Steam startup, machine-wide settings, or other user profiles.

Helper diagnostics are written under `%LOCALAPPDATA%\LivingRoomTV`. Logs are retained after uninstall and should be reviewed before sharing. This project has not received an independent security audit.

## Secrets and Privacy

Never commit `.env` files, credentials, tokens, cookies, personal URLs, browser exports, local usernames, machine paths, or `favorites.local.js`. The public-readiness checker blocks several high-signal patterns, but it is not a substitute for reviewing the staged diff and repository history.

For future commits, enable GitHub **Keep my email addresses private** and **Block command line pushes that expose my email** under GitHub Settings > Emails, and configure Git to use your GitHub-provided noreply address.
