# Roadmap

## Current: Public Positioning and Per-User Automatic Startup

- Position Living Room TV as a streaming-first, controller-first Smart TV interface for ordinary household use.
- Add reversible current-user automatic startup without changing automatic login, Steam startup, or other profiles.
- Validate startup registration and fixed launch behavior through isolated Windows tests.

## Next: Automatic Startup Qualification and Beta Publication

- Install autostart from the intended Windows profile and complete a real sign-out/sign-in test.
- Confirm the launcher opens once, reaches fullscreen, and gains controller input when Steam is ready.
- Confirm a second Windows profile is unaffected, then uninstall and validate the next sign-in.
- After merge and owner action, verify public visibility and publish the approved `v0.1.0-beta.1` candidate.

## Future

- Define a dedicated brand-asset licensing and maintenance strategy.
- Improve configuration ergonomics without weakening the private Favorites boundary.
- Expand helper actions only when a concrete need and safe fixed implementation are demonstrated.

Visibility and `v0.1.0-beta.1` publication were approved on 2026-07-13 but remain unexecuted until the implementation is merged and final checks pass.
