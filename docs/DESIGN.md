# Design and Navigation Contracts

## Presentation

- Use television-scale type, restrained metadata, and a calm dark visual system.
- Keep the compact hero height stable while focus changes.
- Keep left hero context and right artwork fixed; center Recent pills only within the flexible middle column.
- Use shared CSS tokens for safe areas, geometry, spacing, typography, motion, depth, surfaces, and colors.
- Keep focused items unmistakable without changing layout metrics or clipping rail edges.
- Respect `prefers-reduced-motion` by disabling nonessential transitions and smooth scrolling.
- Keep initials as the temporary app identity. Future assets must be local and licensed.
- Omit repetitive card descriptions while retaining useful context in the hero.

## Navigation

Navigation is a logical state machine. Scrolling follows focus; focus never follows scrolling.

- Steam Desktop Layout owns all Xbox controller translation.
- The dashboard consumes keyboard and mouse events and never polls the Gamepad API.
- Up and Down move exactly one logical area.
- Vertical movement restores the destination area's remembered item and clamps only when that item no longer exists.
- Left and Right move exactly one item without wrapping.
- Movement does not depend on browser focus, DOM geometry, or scroll position.
- Each app row and Recently Opened maintains independent remembered state.
- Horizontal movement never requests vertical page alignment.
- There is exactly one logical focus target.
- The hero is presentation-only except for explicit Recent pills.
- When Recent items exist, Up from Streaming enters them and Down restores Streaming state.
- When no Recent items exist, Up from Streaming is a no-op.

## Layout

All rails share header, card, gap, and safe-area metrics. Returning to the first item resets that rail to its deterministic starting position. The full viewport uses responsive safe areas rather than a fixed webpage maximum. Settings remains available but visually secondary to entertainment.

## Content and Local Data

Show Recently Opened only from real browser-local launch history. Load optional Favorites from ignored `favorites.local.js`; the tracked example defines only a safe schema. Never import bookmarks automatically or display technical paths and protocols in the main interface.

## Failure Behavior

If configuration or initialization fails, show a calm, actionable message rather than an empty or broken screen. Activation feedback confirms the input was received; it must not claim an external app or website successfully opened.
