# Security Policy

## Supported Version

Security fixes target the latest commit on `main`. Unreleased branches and older snapshots are not supported.

## Reporting a Vulnerability

Do not open a public issue. Use GitHub's **Report a vulnerability** option on the repository Security page when available. If that option is unavailable, contact the repository owner privately through the GitHub account profile and include a minimal reproduction without credentials or personal data.

Please describe the affected revision, impact, prerequisites, and safe reproduction steps. Allow reasonable time for investigation before public disclosure.

## Threat Model

The static dashboard is unprivileged and has no backend, accounts, telemetry, or remote configuration. Its main risks are unsafe local configuration, untrusted outbound destinations, browser/protocol behavior, and the optional Windows helper.

The helper is the native trust boundary. Installation registers `livingroomtv://` for the current user in `HKCU`. The browser may request only one of five names: `ping`, `ea`, `sleep`, `restart`, or `shutdown`. The helper maps those names to fixed implementations and rejects malformed or unknown requests. It does not evaluate input, accept command strings, take executable paths, or require administrator rights.

Power actions are consequential. Restart and Shutdown require a second selection in the dashboard, but any local process can invoke a registered custom protocol. Install the helper only on a trusted machine from a revision you have reviewed. Uninstall it with `scripts/uninstall-helper.ps1` when it is not needed.

Helper diagnostics are written under `%LOCALAPPDATA%\LivingRoomTV`. Logs are retained after uninstall and should be reviewed before sharing. This project has not received an independent security audit.

## Secrets and Privacy

Never commit `.env` files, credentials, tokens, cookies, personal URLs, browser exports, local usernames, machine paths, or `favorites.local.js`. The public-readiness checker blocks several high-signal patterns, but it is not a substitute for reviewing the staged diff and repository history.

For future commits, enable GitHub **Keep my email addresses private** and **Block command line pushes that expose my email** under GitHub Settings > Emails, and configure Git to use your GitHub-provided noreply address.
