---
id: "0004"
title: "0004: GlobalKey mixin pattern for shell-triggered scroll-to-top"
status: ACCEPTED
date: 2026-05-05
---

# 0004 — GlobalKey mixin pattern for shell-triggered scroll-to-top

**Date:** 2026-05-05  
**Status:** ACCEPTED  
**Author:** architect

## Problem

SPEC-0005 requires that tapping the already-active tab in `MainNavBar` scrolls the branch's content back to the top — a standard mobile convention. The `ShellScaffold` (the `StatefulShellRoute` builder widget) must trigger this scroll without importing or depending on any concrete tab screen class. Four tab screens — `FeedScreen`, `MyPostsScreen`, `NotificationsScreen`, `MoreScreen` — each owns its own `ScrollController`, and those screens are defined in separate feature packages. The shell must reach into the currently mounted tab screen and call `scrollToTop()` without coupling itself to any specific screen type.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | `GlobalKey<ScrollToTopTarget>` where `ScrollToTopTarget` is a mixin on `State` | No Riverpod state; zero indirect coupling between shell and screen; key is allocated once at `static final` in `ShellScaffold` and survives hot reload; standard Flutter pattern for cross-widget imperative calls | Each tab screen's `StatefulWidget` must use the shell-allocated key as its `key:` argument, meaning the screen cannot independently manage its own `Key`; the mixin pattern is unfamiliar to developers who have not encountered it before |
| 2 | `ScrollControllerRegistry` — a `keepAlive` Riverpod provider that maps `NavTab` → `ScrollController` | Familiar Riverpod pattern; shell reads the controller from the provider without needing a `GlobalKey`; testable with `ProviderScope` overrides | The `ScrollController` lifecycle is owned by the screen's `State` but registered in a global provider — `dispose` ordering becomes fragile; a screen that disposes its controller before deregistering it leaves a stale entry in the registry; the Domain layer prohibition on framework imports does not apply here (this is Presentation), but the stale-controller risk is real |
| 3 | `EventChannel` via a `StreamController<NavTab>` in a top-level provider — shell broadcasts a "scroll-to-top" event and each screen subscribes | Fully decoupled; screens react to the stream independently | Over-engineered for this use case; `StreamController` adds lifecycle complexity (cancel on dispose); the stream is a global side-channel that is harder to reason about in tests |
| 4 | Callback prop drilling — `ShellScaffold` passes an `onScrollToTop` callback into each tab screen | Explicit, no magic | `ShellScaffold` must import every tab screen class; tightly couples the shell to concrete feature types; breaks as new tabs are added |

## Decision

**Chosen:** Option 1 — `GlobalKey<ScrollToTopTarget>` with a `ScrollToTopTarget` mixin on `State`.

The `GlobalKey<T>` pattern is the idiomatic Flutter mechanism for making imperative calls into a `State` object without coupling the caller to the concrete `State` type. Allocating the keys once at `static final` in `ShellScaffold` ensures they survive across rebuilds and hot reloads. The mixin is defined in `apps/mobile/lib/shared/widgets/scroll_to_top_target.dart` and depends only on `package:flutter/widgets.dart`, keeping the shared widget layer free of feature-specific imports. The trade-off — that each tab screen's `StatefulWidget` must accept the key as its `key:` argument — is documented in SPEC-0005 as an open question to be confirmed with the flutter-engineer before tab screen implementation begins.

## Reversal Cost

Low-to-medium. Switching to Option 2 (`ScrollControllerRegistry`) requires adding a Riverpod provider, updating each screen's `initState`/`dispose` to register/deregister, and updating `ShellScaffold._handleTabTap` to read from the provider. The `GlobalKey` parameters can be removed from each screen's constructor. No Firebase or domain changes are required.

## Consequences

- **Easier:** Shell has zero imports of any tab screen class; adding a fifth tab in the future requires only extending `NavTab` and allocating one more `GlobalKey`.
- **Harder:** Tab screens cannot be independently keyed by their callers; developers must understand that the `key:` argument is owned by the shell.
- **Follow-up required:** The flutter-engineer must confirm the `key:` ownership constraint before implementing `FeedScreen` and peers. If the constraint is unacceptable, Option 2 is the fallback — raise a follow-up ADR before implementation.
