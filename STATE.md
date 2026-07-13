# Project State

## Current Milestone

Public Open-Source Release Readiness. The sanitized repository remains private and `v0.1.0-beta.1` has not been published.

## Implemented

- Replaced personal-address-specific checker logic with generic email and split-string reconstruction detection using synthetic controls.
- Added helper-side native confirmation authorization for Sleep, Restart, and Shutdown.
- Kept the dashboard confirmation as defense-in-depth UX rather than treating it as authorization.
- Added isolated helper security tests that mock confirmation and execution and never invoke real power actions.
- Recreated private `main` from the verified remediation tree as a sanitized root history and migrated no old branches or pull-request refs.

## Automated Verification

- Project, navigation, public-readiness, and helper authorization tests pass without executing destructive actions.
- The sanitized root, published refs, reachable history, PII variants, secrets, and clean-clone behavior are verified during repository recreation.

## Still Blocked

- GitHub private vulnerability reporting is unavailable while the repository remains private; no alternative private contact has been verified.
- Physical TV, controller reconnect, Chrome F11, helper dialog, and power behavior remain unvalidated for release.
- Public visibility and release publication require separate approval.

## Next

Establish a working private reporting channel, complete the physical release checklist, and perform a final public-boundary review before separately approving visibility or publication.

## Learning

- 2026-07-13: An allowlist limits what can run but does not authorize a consequential action; power operations need affirmative confirmation inside the native helper boundary.
- 2026-07-13: Safety controls must use synthetic fixtures and detect reconstructed sensitive values without embedding the real value they are intended to remove.
- 2026-07-13: A clean public-history boundary must publish a new root, not merely move a branch whose ancestors still contain the removed data.
