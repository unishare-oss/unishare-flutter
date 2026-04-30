# Navigation Design

**Status:** Approved
**Scope:** App-wide navigation shell — bottom nav, navigation rail, route structure, and upload FAB

---

## Overview

Adaptive navigation shell using GoRouter's `StatefulShellRoute`. Bottom nav on mobile (< 600dp), NavigationRail on tablet/desktop (≥ 600dp). Four destination tabs with an Upload FAB scoped to the Feed screen only.

---

## Nav Items & Auth States

| Tab | Guest | Authenticated |
|---|---|---|
| Feed | ✓ | ✓ |
| Departments | ✓ | ✓ |
| Saved | → sign-in prompt | ✓ |
| Profile | → sign-in screen | ✓ (avatar + name) |
| Upload FAB | hidden | Feed screen only |

**Active indicator:** accent color on icon + label, indicator line at top of tab (BottomNavigationBar) or leading edge (NavigationRail). Matches the web platform's amber indicator style.

---

## Adaptive Layout

**Breakpoints (Material 3):**
- `< 600dp` → `BottomNavigationBar`
- `≥ 600dp` → `NavigationRail`

**NavigationRail (tablet/desktop):**
- Fixed left rail, icons + labels visible
- Upload action moves from FAB to a button at the top of the rail
- No collapse/expand at this phase

**Shell:** `AppShell` reads `MediaQuery` width and switches between `BottomNavigationBar` layout and `Row(NavigationRail, VerticalDivider, Expanded(content))` layout.

---

## Route Structure

`StatefulShellRoute` is used (not plain `ShellRoute`) so each tab maintains its own independent navigator stack — navigating deep in one tab does not affect another.

```
GoRouter
├── /welcome                    ← unauthenticated landing
├── /sign-in                    ← email sign-in
├── /sign-up                    ← email sign-up
└── StatefulShellRoute          ← AppShell (nav bar / rail)
    ├── branch: /feed           ← Feed tab (+ Upload FAB)
    │   └── /feed/posts/:id     ← Post detail (stacked within branch)
    ├── branch: /departments    ← Departments tab
    │   └── /departments/:id    ← Department detail (stacked within branch)
    ├── branch: /saved          ← Saved tab
    └── branch: /profile        ← Profile tab
        └── /profile/edit       ← Edit profile (stacked within branch)
```

**Tab index → branch mapping:**

| Index | Branch | Route |
|---|---|---|
| 0 | Feed | `/feed` |
| 1 | Departments | `/departments` |
| 2 | Saved | `/saved` |
| 3 | Profile | `/profile` |

**Redirect logic** lives in the `router.dart` redirect callback, reading from `authStateProvider`:
- No session → `/welcome`
- Authenticated → allow through
- Authenticated user hits `/welcome`, `/sign-in`, `/sign-up` → redirect to `/feed`

---

## File Structure

```
core/
  router/
    router.dart                  ← GoRouter config, StatefulShellRoute, redirects
    app_shell.dart               ← adaptive shell widget

shared/
  widgets/
    bottom_nav_bar.dart          ← BottomNavigationBar wrapper
    navigation_rail.dart         ← NavigationRail wrapper
    upload_fab.dart              ← FAB, visible only when branch index == 0
```

---

## Testing

**Widget tests:**

| File | What it covers |
|---|---|
| `app_shell_test.dart` | Shows `BottomNavigationBar` on narrow screen, `NavigationRail` on wide screen |
| `bottom_nav_bar_test.dart` | Correct tabs render; active tab highlights; tapping switches branch |
| `upload_fab_test.dart` | FAB visible on Feed tab, hidden on all other tabs; hidden for guests |

No unit tests — this feature is pure UI with no business logic.

---

## Out of Scope (this phase)

- Chat tab
- Notifications tab
- Sidebar collapse/expand on desktop
- Admin section in nav
