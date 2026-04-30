---
id: "0002"
title: border token lives in ColorScheme.outline, not AppColors
status: ACCEPTED
date: 2026-04-30
---

# 0002 — border token lives in ColorScheme.outline, not AppColors

**Status:** ACCEPTED  **Date:** 2026-04-30

## Context

`AppColors` (ThemeExtension) initially carried a `border` field alongside `ColorScheme.outline`, which was already set to the same value in `AppTheme.build()`. This created two read paths for the same color.

## Decision

`border` was removed from `AppColors`. Callers use `Theme.of(context).colorScheme.outline`. `AppColors` only carries tokens with no Material 3 ColorScheme equivalent: `amber*`, `success`, `info`, `muted`, `mutedForeground`, `surfaceDark`, `cardDark`, `textSecondary`, `textMuted`.

## Consequences

**Positive:** Single source of truth; no drift between `appColors.border` and `colorScheme.outline`.

**Negative:** Callers must know to use `colorScheme.outline` rather than an AppColors field — less discoverable for new engineers.
