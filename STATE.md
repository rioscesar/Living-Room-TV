# Project State

## Current Milestone

Public Release Blocker Remediation. The repository remains private and `v0.1.0-beta.1` has not been published.

## Implemented on the Remediation Branch

- Replaced personal-address-specific checker logic with generic email and split-string reconstruction detection using synthetic controls.
- Added helper-side native confirmation authorization for Sleep, Restart, and Shutdown.
- Kept the dashboard confirmation as defense-in-depth UX rather than treating it as authorization.
- Added isolated helper security tests that mock confirmation and execution and never invoke real power actions.

## Automated Verification

- Project, navigation, public-readiness, and helper authorization tests run without executing destructive actions.
- Final clean-clone, history, safety, and GitHub Actions evidence must be recorded for the remediation commit before approval.

## Still Blocked

- Existing candidate history contains the superseded personal-address-specific checker and requires an explicitly approved repository recreation.
- GitHub private vulnerability reporting is unavailable while the repository remains private; no alternative private contact has been verified.
- Physical TV, controller reconnect, Chrome F11, helper dialog, and power behavior remain unvalidated for this remediation.
- Public visibility and release publication require separate approval.

## Next

Review the remediation draft PR and the offline recreation plan, establish a working private reporting channel, then explicitly approve or reject Phase B history sanitation.

## Learning

- 2026-07-13: An allowlist limits what can run but does not authorize a consequential action; power operations need affirmative confirmation inside the native helper boundary.
- 2026-07-13: Safety controls must use synthetic fixtures and detect reconstructed sensitive values without embedding the real value they are intended to remove.
