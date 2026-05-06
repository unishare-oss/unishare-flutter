---
title: "0005: GlobalKey<State> with runtime cast replaces GlobalKey<ScrollToTopTarget>"
description: "ADR-0004 prescribed GlobalKey<ScrollToTopTarget>, but Dart's type system prohibits it when the mixin has no on-constraint. Implementation uses GlobalKey<State> with a guarded is-cast instead."
---

# 0005 — GlobalKey<State> with runtime cast replaces GlobalKey<ScrollToTopTarget>

**Status:** ACCEPTED  
**Author:** flutter-engineer  
**Date:** 2026-05-05  
**Amends:** [ADR-0004](0004-shell-scroll-to-top-pattern.md)

## Problem

ADR-0004 specified `GlobalKey<ScrollToTopTarget>` as the mechanism for `ShellScaffold` to trigger scroll-to-top on a tab screen's `State`. During implementation of SPEC-0005 this was found to be invalid Dart.

`GlobalKey<T>` has a type bound `T extends State<StatefulWidget>`. For `GlobalKey<ScrollToTopTarget>` to satisfy that bound, `ScrollToTopTarget` must extend `State<StatefulWidget>`. Adding `on State<StatefulWidget>` to the mixin declaration achieves this in theory, but produces a compile error in practice:

```
error: The class '_FeedScreenState' can't implement both
  'State<FeedScreen>' and 'State<StatefulWidget>'
  because the type arguments are different.
```

Dart does not allow a class to implement two instantiations of the same generic interface (`State<FeedScreen>` and `State<StatefulWidget>`) simultaneously. Since every tab screen's `State` already extends `State<SpecificScreen>`, adding the `on State<StatefulWidget>` constraint to `ScrollToTopTarget` is incompatible with any concrete `State` subclass.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | `GlobalKey<State>` + guarded `is ScrollToTopTarget` cast | Compiles; retains zero coupling between shell and concrete screen types; identical runtime safety to the typed key | Key type is less descriptive; a developer reading `GlobalKey<State>` cannot tell it expects a `ScrollToTopTarget` without reading the call site |
| 2 | `ScrollControllerRegistry` Riverpod provider (ADR-0004 Option 2) | Familiar pattern; no casting | Stale-controller risk on `dispose`; more moving parts; identified as fallback in ADR-0004 |
| 3 | `GlobalKey<ScrollToTopMixin>` where `ScrollToTopMixin` is a separate abstract `State` subclass (not a mixin) | Satisfies the type bound | Requires all tab screens to extend a base class rather than mixin in behaviour; forces single-inheritance; more invasive change |

## Decision

**Chosen:** Option 1 — `GlobalKey<State>` with a guarded runtime cast.

`ShellScaffold.scrollTargetKeys` is declared as `List<GlobalKey<State>>`. In `_handleTabTap`, after confirming the same-index tap, the shell calls:

```dart
final state = scrollTargetKeys[index].currentState;
if (state is ScrollToTopTarget) {
  (state as ScrollToTopTarget).scrollToTop();
}
```

The `is` check makes the cast safe (null is excluded; wrong type is excluded). The explicit cast `as ScrollToTopTarget` is required because Dart's flow-type promotion does not apply when `state` is typed as `State?` and `ScrollToTopTarget` has no `on` constraint — the intersection type `State & ScrollToTopTarget` is not promoted automatically by this version of the Dart analyzer.

`ScrollToTopTarget` stays as a plain mixin (no `on` constraint) so tab screen `State` classes can mix it in alongside their existing `extends State<SpecificScreen>`:

```dart
class _FeedScreenState extends State<FeedScreen> with ScrollToTopTarget { … }
```

## Reversal Cost

Low. Switching to Option 2 (`ScrollControllerRegistry`) requires: adding one Riverpod provider, updating each tab screen's `initState`/`dispose`, and removing the `GlobalKey` parameters from screen constructors. No Firebase or domain changes needed.

## Consequences

- **Easier:** `ScrollToTopTarget` mixin remains usable by any `State` subclass without inheritance constraints.
- **Harder:** The key type `GlobalKey<State>` doesn't self-document its expected `currentState` type; add a doc comment on `scrollTargetKeys` explaining the contract (done in `shell_scaffold.dart`).
- **ADR-0004 status:** ADR-0004 remains `ACCEPTED` as the architectural pattern (GlobalKey + mixin for shell-triggered scroll). This ADR amends the specific type used — the intent and trade-offs in ADR-0004 are unchanged.
