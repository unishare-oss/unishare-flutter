---
id: "0002"
title: border token lives in ColorScheme.outline, not AppColors
status: ACCEPTED
date: 2026-04-30
---

# 0002 — border token lives in ColorScheme.outline, not AppColors

**Date:** 2026-04-30
**Status:** ACCEPTED
**Author:** architect

## Problem

`AppColors` (ThemeExtension) initially carried a `border` field alongside `ColorScheme.outline`, both set to the same value in `AppTheme.build()`. This created two read paths for the same color token, risking drift and confusing callers about which to use.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Remove `border` from `AppColors`, use `colorScheme.outline` | Single source of truth, no drift | Less discoverable — callers must know to use `colorScheme.outline` |
| 2 | Keep `border` in `AppColors`, remove from `ColorScheme` | All custom tokens in one place | Loses Material 3 `outline` semantics used by built-in widgets |
| 3 | Keep both in sync | No migration needed | Duplicated state, drift risk remains |

## Decision

**Chosen:** Option 1 — Remove from `AppColors`

`border` was removed from `AppColors`. Callers use `Theme.of(context).colorScheme.outline`. `AppColors` only carries tokens with no Material 3 ColorScheme equivalent: `amber*`, `success`, `info`, `muted`, `mutedForeground`, `surfaceDark`, `cardDark`, `textSecondary`, `textMuted`.

## Reversal Cost

Low — add `border` field back to `AppColors` and wire it in `AppTheme.build()`. One-line change per theme constant.

## Consequences

Single source of truth for border color. Built-in Material 3 widgets and custom widgets both read from the same `colorScheme.outline`. New engineers must know to reach for `colorScheme.outline` rather than an `AppColors` field.
