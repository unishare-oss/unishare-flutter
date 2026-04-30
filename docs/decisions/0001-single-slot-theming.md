---
id: "0001"
title: Single-slot theming for 12-theme design system
status: ACCEPTED
date: 2026-04-30
---

# 0001 — Single-slot theming for 12-theme design system

**Status:** ACCEPTED  **Date:** 2026-04-30

## Context

MaterialApp supports two theme slots (`theme` and `darkTheme`) selected by `ThemeMode`. With 12 hand-authored themes spanning both light and dark palettes, we needed to decide how to route them into MaterialApp.

## Decision

All 12 themes pass through the `theme:` parameter only. `darkTheme:` is unused. `themeMode` is omitted (defaults to `ThemeMode.system`, but with no `darkTheme` set, `theme` is always used).

Material 3 widgets read `colorScheme.brightness` directly for rendering decisions, so dark-palette themes render correctly regardless of `ThemeMode`.

## Consequences

**Positive:** Simple — one provider, one slot, no split logic.

**Negative:** If a future requirement needs OS-level dark/light auto-switching, this approach needs revisiting.
