# Session: 2026-05-05-main-navbar

**Date:** 2026-05-05  
**Member:** Pyae Sone Shin Thant  
**Agent:** flutter-engineer  
**Task:** Implement SPEC-0005 — Main Navigation Bar

## Context

PROP-0005 approved and SPEC-0005 approved by Pyae Sone Shin Thant.
Scaffold complete — all stub files created, router not yet wired.

Relevant docs:
- [PROP-0005](../../tech-proposals/0005-main-navbar.md)
- [SPEC-0005](../../tech-specs/0005-main-navbar.md)
- [ADR-0004](../../docs/decisions/0004-shell-scroll-to-top-pattern.md) — GlobalKey scroll-to-top pattern

## Plan

1. Add `NavTab` enum to `router.dart`
2. Replace `_HomeScreen` GoRoute with `StatefulShellRoute.indexedStack` wiring all 4 branches and MORE child routes
3. Extend `_RouterNotifier.redirect` — `/` → `/feed`, unknown paths → `/feed`, authed on `/welcome` → `/feed`
4. Implement `ShellScaffold.build` — `PopScope` + `Scaffold` + `MainNavBar`
5. Implement `MainNavBar.build` — custom `Row` of `_NavTabItem`s using design tokens
6. Run `flutter analyze` and `flutter test`

## Notes

- `NavTab.index` getter shadows the built-in `Enum.index` — the spec defines it as `NavTab.values.indexOf(this)`. Confirm this is intentional or just use the built-in `index`.
- `GlobalKey<ScrollToTopTarget>` open question: confirm flutter-engineer accepts key ownership constraint before wiring FeedScreen (see SPEC-0005 open question).
- `MoreScreen` is the only tab-root with real content — the 4 destination tiles are already implemented in the skeleton.

## Handoff

**To:** flutter-engineer (or architect for review)  
**Done:** All skeleton files created; folder structure complete; `scroll_to_top_target.dart`, `main_nav_bar.dart` (stub), `shell_scaffold.dart` (stub) written  
**Not done:** `router.dart` not yet modified; `MainNavBar` and `ShellScaffold` not implemented; no tests written  
**Watch out for:** `NavTab` enum must be in `router.dart` — both `shell_scaffold.dart` and `main_nav_bar.dart` import it from there. Don't move it.
