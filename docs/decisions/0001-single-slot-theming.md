---
id: "0001"
title: Single-slot theming for 12-theme design system
status: ACCEPTED
date: 2026-04-30
---

# 0001 — Single-slot theming for 12-theme design system

**Date:** 2026-04-30
**Status:** ACCEPTED
**Author:** architect

## Problem

`MaterialApp` supports two theme slots (`theme` and `darkTheme`) selected by `ThemeMode`. With 12 hand-authored themes spanning both light and dark palettes, routing them through the standard two-slot model would require splitting each theme into a light/dark pair and managing `ThemeMode` state alongside theme selection — doubling complexity for no user benefit.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Single-slot (`theme:` only, no `darkTheme`) | Simple — one provider, one slot, no split logic | OS dark/light auto-switching not supported |
| 2 | Two-slot (split each theme into light + dark pair) | Supports OS auto-switching | 24 theme definitions instead of 12; split logic in provider |
| 3 | `themeMode` driven (light/dark toggle, no multi-theme) | Standard Flutter pattern | Doesn't support 12 distinct themes |

## Decision

**Chosen:** Option 1 — Single-slot

All 12 themes pass through `theme:` only. `darkTheme:` is unused. `themeMode` is omitted (defaults to `ThemeMode.system`, but with no `darkTheme` set, `theme` is always used). Material 3 widgets read `colorScheme.brightness` directly for rendering decisions, so dark-palette themes render correctly regardless of `ThemeMode`.

## Reversal Cost

Medium — would require splitting all 12 `AppThemeData` definitions into light/dark pairs, adding a `ThemeMode` provider, and updating `MaterialApp`. Feasible but non-trivial.

## Consequences

Simpler state management and fewer theme definitions. OS-level dark/light auto-switching is not supported — if that requirement arises, this decision needs revisiting.
