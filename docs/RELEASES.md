# Release Candidate

## v0.1.0-beta.1 — Approved, Not Published

This candidate represents the first externally reviewable baseline: a framework-free Windows Smart TV interface with deterministic navigation, Steam-owned controller translation, private local Favorites, an optional fixed-action helper, and reversible per-user automatic startup.

Automated checks cover syntax, navigation, presentation contracts, helper allowlisting, synthetic PII controls, mocked helper authorization, and isolated autostart lifecycle behavior. Sanitized history and the previously required target-PC, Chrome F11, physical 4K TV, controller reconnect, native helper dialog, and power checks are owner-confirmed. Automatic startup still requires a real sign-in test on the intended profile, a second-profile isolation check, and an uninstall sign-in check.

The owner approved public visibility and `v0.1.0-beta.1` publication on 2026-07-13. No tag, GitHub release, or visibility change is performed by this implementation PR; those actions wait for reviewed code on `main`.
