# Project State

## Current Milestone

Public Positioning and Per-User Automatic Startup. The repository remains private while the implementation is reviewed; public visibility and `v0.1.0-beta.1` publication are owner-approved but not yet executed.

## Implemented

- Replaced personal-address-specific checker logic with generic email and split-string reconstruction detection using synthetic controls.
- Added helper-side native confirmation authorization for Sleep, Restart, and Shutdown.
- Kept the dashboard confirmation as defense-in-depth UX rather than treating it as authorization.
- Added isolated helper security tests that mock confirmation and execution and never invoke real power actions.
- Recreated private `main` from the verified remediation tree as a sanitized root history and migrated no old branches or pull-request refs.
- Sharpened the public positioning around a streaming-first, controller-first Smart TV experience for ordinary household use.
- Added reversible current-user Startup-folder registration with fixed Chrome/Chromium detection, fullscreen launch planning, duplicate suppression, and local diagnostics.
- Documented GitHub Issues as the current public reporting route without claiming confidentiality.

## Automated Verification

- Project, navigation, public-readiness, helper authorization, and isolated autostart lifecycle tests pass without executing destructive actions or installing startup on the user's profile.
- The sanitized root, published refs, reachable history, PII variants, secrets, and clean-clone behavior are verified during repository recreation.

## Still Blocked

- Automatic startup still requires real sign-in testing on the intended Windows profile and an unaffected second profile.
- The implementation PR must be reviewed and merged before the owner changes visibility or publishes the approved beta.

## Next

Review and merge the automatic-startup implementation, complete both-profile sign-in validation, then change visibility and publish the already approved beta only from verified `main`.

## Learning

- 2026-07-13: An allowlist limits what can run but does not authorize a consequential action; power operations need affirmative confirmation inside the native helper boundary.
- 2026-07-13: Safety controls must use synthetic fixtures and detect reconstructed sensitive values without embedding the real value they are intended to remove.
- 2026-07-13: A clean public-history boundary must publish a new root, not merely move a branch whose ancestors still contain the removed data.
- 2026-07-13: Reliable per-user startup separates a visible, owned registration artifact from a fixed and independently testable launch wrapper; public issue reporting must never be described as confidential.
