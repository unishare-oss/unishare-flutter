---
title: "0005: Main Navigation Bar"
description: "Persistent 4-tab bottom navigation bar for authenticated users, integrated with GoRouter and matching the Figma design exactly."
---

# PROP-0005: Main Navigation Bar

**Status:** ACCEPTED  
**Author:** architect  
**Date:** 2026-05-05  
**Spec:** [SPEC-0005](../tech-specs/0005-main-navbar.md)  
**Approved by:** Pyae Sone Shin Thant

---

## Problem

The app currently has no persistent navigation surface for authenticated users. After sign-in, users land on a placeholder home screen with no mechanism to reach any core destination — Feed, My Posts, or Notifications are unreachable without manually typing deep-link URLs. The router serves three routes (`/welcome`, `/`, `/posts/create`) but nothing ties them into a navigable shell that persists across tab switches.

All authenticated users are affected immediately upon sign-in. Until a main navbar exists, the app cannot be exercised as a product: the feed is reachable only because `/` happens to be the default redirect, and every other first-class destination is effectively hidden. Navigation is the prerequisite for every other feature; this is the highest-priority UX gap in the codebase.

The Figma design specifies a **4-tab bottom bar**: FEED, POSTS, NOTIFS, MORE. The bar must be present on all authenticated, non-modal screens and absent from the auth flow (Welcome, Sign In, Sign Up) and from full-screen creation and detail flows (New Post steps 1–3, Post Details, Terms of Service, Privacy Policy).

---

## Goals

- Render a persistent 4-tab bottom bar on all authenticated shell screens.
- Match the Figma design tokens exactly: background `#f7f3ee`, active accent `#d97706`, Space Grotesk labels, border `#e2dad0`.
- Integrate cleanly with GoRouter so that deep links resolve to the correct tab and tab state is preserved across switches.
- Suppress the navbar entirely on auth screens and creation/detail flows — no conditional visibility hacks inside individual screens.
- Keep the Domain layer untouched — this is a Presentation-layer concern.

---

## Non-goals

- Navigation within a tab (sub-routes under FEED, POSTS, etc.) — that belongs to each feature's own spec.
- The content of the MORE tab destinations (Profile, Saved, Departments, Requests) — each destination is a separate feature spec.
- Push notification badge wiring — badge count on NOTIFS is deferred to a separate proposal (see Open Questions).
- Guest-mode partial access — treated as out-of-scope for v1 (see Open Questions).

---

## Proposed Solution

Use Flutter's **`StatefulShellRoute`** (part of `go_router` 7+) with a **custom-painted bottom bar widget** that mirrors the Figma spec pixel-accurately.

### Router integration — `StatefulShellRoute`

`StatefulShellRoute` was introduced specifically to solve the tab-bar navigation problem in GoRouter. It wraps a set of branches, each backed by its own `Navigator` stack, and preserves scroll position and navigation state independently per branch when the user switches tabs. This matches standard mobile tab-bar expectations.

The shell route sits at the root of the authenticated route tree. The `_RouterNotifier` continues to redirect unauthenticated users to `/welcome` before they can reach the shell. Because the shell is a named parent route, any deep link under `/feed`, `/posts`, `/notifications`, or `/more` resolves inside the correct branch automatically — no manual tab-index synchronization is needed.

The four branches map to:

| Tab | Branch root path | Initial screen |
|-----|-----------------|----------------|
| FEED | `/feed` | Feed screen (from PROP-0003) |
| POSTS | `/posts` | My Posts screen |
| NOTIFS | `/notifications` | Notifications screen |
| MORE | `/more` | More menu (see below) |

The existing `/` route is aliased to `/feed` via a redirect so existing deep links and the post-login redirect continue to work without breakage.

Routes that must not show the navbar — Post Details, New Post steps 1–3, Terms of Service, Privacy Policy — are declared **outside** the `StatefulShellRoute` as top-level routes. They push modally or via standard navigation, which means the shell (and its bottom bar) is not in their widget tree at all. No per-screen `bottomNavigationBar: null` override is needed.

Secondary destinations reachable from the MORE tab use paths nested under `/more` (e.g., `/more/profile`, `/more/saved`, `/more/departments`, `/more/requests`). They are registered as child routes on the MORE branch of the `StatefulShellRoute`, so the navbar remains visible when navigating into them and back-button behavior is handled by the branch's own `Navigator`.

### Bottom bar widget

Rather than using `NavigationBar` (Material 3) or `BottomNavigationBar` (Material 2), a **custom widget** is used. The Figma design does not follow Material Design conventions closely enough for either stock widget to reproduce it without fighting the theme. Specifically:

- The background color (`#f7f3ee`) is a warm off-white, not a Material surface.
- The top border (`#e2dad0`, 1 px) is a design-system token with no direct Material equivalent.
- Labels are uppercase, Space Grotesk, 11 px (Fira Code style, matching the project's tag convention) — not the default `NavigationBar` label style.
- The active indicator is an amber underline or tint, not Material's pill indicator.

A custom widget avoids theme-fighting and guarantees pixel parity with Figma. The widget is a `Row` of four `InkWell`-wrapped tab items, each composed of a small icon and a label. The active tab receives the `#d97706` amber accent on both icon and label; inactive tabs use a muted foreground. The widget is stateless — it receives the current tab index and an `onTap` callback from the shell, which drives GoRouter navigation.

### Auth-awareness

The `_RouterNotifier` already redirects unauthenticated users away from `/` to `/welcome`. Because the `StatefulShellRoute` is declared inside the authenticated route tree, an unauthenticated user never reaches the shell and never sees the navbar. No additional auth check is needed inside the bar widget itself — the router is the single source of truth.

### MORE tab

The MORE tab navigates to a lightweight **More screen** (`/more`) that renders a scrollable list of secondary destinations: User Profile (`/more/profile`), Saved (`/more/saved`), Departments (`/more/departments`), Requests (`/more/requests`). This is preferred over a bottom sheet because:

1. A dedicated route is deep-linkable — `/more/profile` can be reached from a push notification without opening a sheet first.
2. It composes cleanly with the `StatefulShellRoute` branch — the More branch has its own `Navigator` stack, so tapping into Profile and pressing Back returns to the More list without resetting other tabs.
3. A bottom sheet would need to be dismissed and re-opened on every entry, breaking the "persistent shell" mental model.

Secondary destinations use `/more/`-prefixed paths so they remain within the MORE branch navigator and the navbar stays visible.

The More screen itself is minimal — it is a styled list of `ListTile`s. Its content is out of scope for this proposal.

### Active-tab highlight

GoRouter exposes the current location via `GoRouterState`. The shell's `builder` receives a `navigationShell` parameter that includes the current branch index. The custom bar widget receives this index as `activeIndex` and applies the amber accent (`#d97706`) to the corresponding tab's icon and label. No external state management (Riverpod provider) is needed for the tab index — GoRouter owns that state.

---

## Alternatives Considered

### A — Material 3 `NavigationBar` inside `StatefulShellRoute`

Flutter's `NavigationBar` widget (Material 3) provides built-in semantics, animated indicators, badge support, and keyboard navigation out of the box. Paired with `StatefulShellRoute` it handles the GoRouter integration correctly.

**Pros:**
- Zero custom painting — widget is maintained by the Flutter team.
- Built-in `Badge` support for notification counts.
- Accessibility labels and semantics are correct by default.
- Significantly less code than a custom widget.

**Cons:**
- Reproducing the Figma design requires overriding nearly every `NavigationBarThemeData` token: indicator color, background color, label style, icon size, height. The cumulative theme override is fragile and harder to maintain than a bespoke widget.
- The animated pill indicator is a Material 3 affordance that does not exist in the Figma design; suppressing it cleanly requires a transparent `indicatorColor`, which can cause rendering artifacts in some Flutter versions.
- Uppercase 11 px Space Grotesk labels conflict with `NavigationBar`'s default label treatment; forcing this through `labelTextStyle` is possible but adds theme complexity.

**Effort:** S (widget) + M (theme fight) = M overall. Risk of pixel drift against Figma over future Flutter upgrades.

**Verdict:** Not recommended. The theme-override surface is large enough that a custom widget would be cleaner in the long run.

---

### B — Custom-painted bottom bar (proposed solution above)

Fully hand-crafted `Row` of tab items built from `InkWell`, `Icon`, and `Text`. No dependency on Material `NavigationBar` or `BottomNavigationBar`.

**Pros:**
- Exact pixel control — every color, spacing, and typography token comes directly from the project's design system with no theme override indirection.
- Isolated from Material widget changes in future Flutter upgrades — the widget's appearance is determined entirely by the project's token constants.
- Easy to extend with custom affordances (e.g., animated underline, pulse on new notification) without working against a widget's internal state machine.

**Cons:**
- No built-in accessibility semantics — `Semantics` wrappers must be added manually.
- Badge support must be implemented from scratch.
- More initial code than Option A.

**Effort:** M. Most of the code is mechanical; the design tokens are already defined.

**Verdict:** Recommended. The extra upfront code is justified by long-term fidelity and freedom from theme-fighting.

---

### C — Material 2 `BottomNavigationBar`

The older Material 2 widget, available without enabling `useMaterial3: true`. Some teams use it because it is well-understood and has stable behavior across Flutter versions.

**Pros:**
- Familiar API — most Flutter developers know it.
- Stable, no active churn in the Flutter framework.

**Cons:**
- Material 2 is in maintenance mode; the Flutter team recommends migrating to Material 3 `NavigationBar`.
- The Figma design clearly does not follow Material 2 conventions (background color, label treatment, no ripple, amber accent) — the same theme-fighting problem as Option A applies here, arguably more so because M2's theming is less granular.
- No `StatefulShellRoute`-specific drawbacks, but the widget itself is the wrong starting point for this design.

**Effort:** S (widget) + L (theme fight) = L overall.

**Verdict:** Ruled out. Deprecated direction and the heaviest customization burden of the three options.

---

### D — `IndexedStack` with manual tab state (no `StatefulShellRoute`)

Manage tab state inside a single `Scaffold` using an `IndexedStack` of four subtrees, with a manually maintained `currentIndex` Riverpod provider. GoRouter would treat the entire shell as a single route.

**Pros:**
- Conceptually simple — no need to understand `StatefulShellRoute`.
- Tab state is in a Riverpod provider, which is easy to test and observe.

**Cons:**
- Deep-link compatibility is severely degraded. If a push notification deep-links to `/notifications/123`, GoRouter has no mechanism to set the active tab index — the app lands on the wrong tab or the home route. Workarounds require listening to `GoRouter.routeInformationProvider` and manually syncing with the index provider, which is exactly the problem `StatefulShellRoute` was designed to solve.
- `IndexedStack` keeps all four tab subtrees in the widget tree simultaneously, increasing memory overhead regardless of which tabs have been visited.
- Tab-level `Navigator` stacks are not isolated — navigating within one tab and then switching tabs resets back-stack state unexpectedly.

**Effort:** M (but produces an inferior result).

**Verdict:** Ruled out. Deep-link compatibility is a hard requirement, and this approach cannot satisfy it without significant fragile workarounds.

---

## Open Questions

1. **MORE tab: bottom sheet vs dedicated screen** — The proposed solution recommends a dedicated `/more` route with secondary destinations at `/more/profile`, `/more/saved`, etc. A bottom sheet alternative would be lighter but not deep-linkable. **Resolved: dedicated `/more` screen with `/more/*` child paths.** No team decision needed.

2. **Guest-mode navbar** — The `_RouterNotifier` currently tracks `guestModeProvider`. Should a guest-mode user see the navbar with certain tabs disabled (e.g., POSTS and NOTIFS are authentication-gated), or should guest mode always redirect to `/welcome`? v1 scope and behavior must be agreed before implementation.

3. **NOTIFS badge count** — The Figma design implies a badge on the NOTIFS tab when unread notifications exist. Should this count come from a Firestore real-time listener (accurate but adds a persistent listener per session) or from a client-side counter incremented locally (cheap but drifts)? This likely warrants its own proposal but the answer affects whether the navbar widget needs to accept a `badgeCount` parameter from day one.

4. **Tab-switch animation** — The Figma file does not specify a transition between tabs. Should switching tabs use Flutter's default (instant swap with no animation), a fade, or a slide? An explicit decision prevents inconsistency across platform (iOS vs. Android).

5. **Back-gesture behavior on Android** — When the user is on a non-FEED tab and presses the Android back button, should the app navigate to the FEED tab or exit the app? GoRouter's `StatefulShellRoute` does not standardize this — the behavior must be specified and implemented explicitly.

---

## Acceptance Criteria

- Authenticated users see a persistent 4-tab bottom bar (FEED, POSTS, NOTIFS, MORE) on all shell screens after sign-in.
- The navbar is completely absent from: Welcome, Sign In, Sign Up, New Post (all steps), Post Details, Terms of Service, and Privacy Policy screens.
- Tapping each tab navigates to the correct branch root; tapping an already-active tab scrolls the branch's content to the top (standard mobile convention).
- Deep-linking to any route under `/feed`, `/posts`, `/notifications`, or `/more` resolves in the correct tab with the bar reflecting the correct active state.
- Tab navigation state is preserved independently per branch: navigating into a sub-screen on POSTS and switching to FEED, then switching back to POSTS, returns the user to the same sub-screen (not the branch root).
- The bottom bar's visual output matches the Figma design tokens: background `#f7f3ee`, active accent `#d97706`, inactive foreground muted, top border `#e2dad0` 1 px, Space Grotesk labels uppercase 11 px.
- `flutter analyze` reports zero errors or warnings on all new code.
- Every new screen introduced under the shell has a corresponding widget test asserting the navbar is present and the correct tab is active.
- Auth-flow screens have a widget test asserting the navbar is absent.
- The implementation introduces no new pub.dev dependencies beyond the packages already in `pubspec.yaml`.
