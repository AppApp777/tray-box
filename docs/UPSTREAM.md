# Upstream and local changes

Tray Box is an independent derivative of Thaw, not an official Thaw release.

- Thaw: https://github.com/thaw-app/Thaw
- Pinned version: 2.0.1
- Commit: `d5eab80b4e1f62328a8b130994220e49524a48d1`
- Ice: https://github.com/jordanbaird/Ice
- License: GNU GPL version 3, with original notices retained in the vendored files.

Local integration changes, dated 2026-10-04:

- A compact panel and two-group organizer in `Thaw/TrayBox/`.
- Explicit move buttons and native drag sessions, using the full upstream move and menu engine.
- Cache publication in manual mode and a physical-divider-state predicate.
- Panel focus, outside-click filtering and close protection during operations.
- Separate application and XPC identifiers; local startup defaults, memory-only icon cache and disabled upstream automatic updates.
- Isolated regression host and fixture-only safeguards.
- Public build wrappers and cleared development-team defaults in the Xcode project.

The full vendored source is present. Its own README, release workflows and historical documents describe upstream Thaw; follow this repository's root README and `scripts/` for Tray Box.
