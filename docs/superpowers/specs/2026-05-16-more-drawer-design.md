# More Drawer — Design Spec

**Status:** Approved — ready for implementation plan
**Date:** 2026-05-16
**Branch:** `fix/more-drawer`
**Figma:** [`246:126`](https://www.figma.com/design/gIUtcwNTmPi17dOuuv5oDB/Unishare?node-id=246-126) — "More popup / Admin (Light)"

## Problem

The current `/more` destination is a full screen rendered as a `ListView` with five rows (Profile, Saved, Departments, Requests, Sign out). It works but it spends a full bottom-nav slot and a full screen on what is really a menu. The Figma design replaces it with a bottom sheet that surfaces the same destinations more compactly, frees the More tab to behave as an action button, and brings the mobile UI closer to the original web vision (node `328:3`).

## Goal

Replace the `/more` screen with a modal bottom sheet ("More drawer") that opens when the More tab in the bottom nav is tapped. Preserve every existing destination. Stay strictly inside the project's theme tokens. Use `liquid_glass_renderer` only where it materially improves the surface.

## Non-goals

- Building a Settings feature. The Figma "SETTINGS" tile is repurposed as the **Profile** entry point (existing screen).
- Building Admin screens (Moderation, Manage Depts, Users). The drawer's ADMIN section is not rendered in this change; the role gate is left as a follow-up.
- Changing guest UX. The guest shell continues to expose Feed + Saved with the existing visual treatment.

---

## Behavior

### Triggering the sheet

`ShellScaffold._handleTabTap` intercepts `NavTab.more` and calls `showMoreDrawer(context)` instead of `navigationShell.goBranch(3)`. The More tab is an **action tab** — it never marks itself as the active branch and the pill never lands on it.

When the drawer is open, whichever tab the user came from (Feed / Posts / Notifs) retains its active state on the nav bar.

### Dismissal

- Tap outside the sheet (barrier)
- Swipe the sheet down
- Tap any destination tile (sheet pops, route pushes)
- Tap Sign out (sheet pops, auth flow runs)

### Routing model

> **Note:** This section was revised after implementation. The earlier draft moved drawer destinations to top-level GoRoutes outside the shell. That approach hid the bottom nav on Profile/Saved/Departments/Requests and was reverted at the user's request — the destinations now live in a dedicated 4th `StatefulShellBranch` so the bottom nav stays visible and the 4th nav slot dynamically reflects the active sub-destination.

Branch 3's old contents (`/more` + nested `MoreScreen`) are deleted. A **new 4th `StatefulShellBranch`** hosts the drawer destinations as siblings:

| Path | Today | After |
|---|---|---|
| `/more` | Branch 3 root (MoreScreen) | **Removed.** Not a valid path; falls through to `/feed` via the unknown-path redirect. |
| `/more/profile` | Branch 3 child | → `/profile` (Branch 3 sibling) |
| `/more/saved` | Branch 3 child | → `/saved` (Branch 3 sibling, also reachable by guests) |
| `/more/departments` | Branch 3 child | → `/departments` (Branch 3 sibling) |
| `/more/departments/:deptId` | Branch 3 child | → `/departments/:deptId` (Branch 3 nested) |
| `/more/requests` | Branch 3 child | → `/requests` (Branch 3 sibling) |
| `/more/requests/:requestId` | Branch 3 child | → `/requests/:requestId` (Branch 3 sibling) |

Activating any of these paths via `context.go(path)` makes Branch 3 the current shell branch. The bottom nav stays visible. The 4th nav slot — driven by a new `DrawerDestination` enum in `router.dart` and consumed by `MainNavBar.currentSubDestination` — renders the active destination's label + icon (e.g. "Saved" + bookmark) and shows the active-pill state. Tapping the 4th slot still opens the More drawer (it's an action tab) — the dynamic label/icon is purely a status indicator.

### `/saved` consolidation

Previously `/saved` lived as branch 4 of the StatefulShellRoute (guest tab destination) and auth users were redirected to `/more/saved`. After this change:

- `/saved` is one canonical path — a sibling route inside the new Branch 3.
- The legacy guest branch 4 (`/saved`) is deleted, along with the `kSavedBranchIndex` constant.
- `GuestNavBar.onSavedTap` switches from `navigationShell.goBranch(4)` to `context.go('/saved')`.
- The guest "Saved" tab's selected state derives from the current URL (`GoRouterState.of(context).uri.path == '/saved'`) instead of branch index.
- The `/saved` → `/more/saved` redirect rule in `_RouterNotifier.redirect` is removed.

Both auth and guest users resolve `/saved` to the same `SavedScreen`. The wrapping scaffold differs by auth state (auth gets `ShellScaffold` with `MainNavBar`; guest gets `GuestShellScaffold` with `GuestNavBar`).

Guest visual behavior is unchanged.

### Guest mode

The drawer is **auth-only**. The guest shell continues to use `GuestNavBar`. The More tab is not part of the guest nav.

---

## Layout

The sheet is a single `Column` inside a top-rounded container. All vertical/horizontal padding values match Figma node `246:126`. Every color, font, and spacing reference resolves through the existing theme tokens — **no hardcoded values**.

### Container

| Property | Value |
|---|---|
| Background | `Theme.of(context).colorScheme.surface` |
| Border radius | `BorderRadius.only(topLeft: 16, topRight: 16)` |
| Width | full screen |
| Safe area | `useSafeArea: true` on `showModalBottomSheet` |

### Content stack (top → bottom)

1. **DragArea** — 20dp tall. Centered 4×32 pill, color `Theme.of(context).dividerColor`.
2. **Header** — 14dp vertical × 16dp horizontal padding, 10dp gap. Children:
   - 28×28 amber tile (`ac.amber`, 6dp radius) with bold white "U" — `theme.textTheme.titleSmall` weight bold.
   - "Unishare" wordmark — `theme.textTheme.titleMedium` weight bold, color `cs.onSurface`.
3. **Divider** — 1dp full width, `theme.dividerColor`.
4. **UserSection** — 14dp vertical × 16dp horizontal, 12dp gap. Display-only (not tappable). Children:
   - 40×40 amber circle (`ac.amber`, fully rounded) with white initials — `theme.textTheme.labelLarge` weight bold.
   - Right column: name in `theme.textTheme.titleSmall` weight bold, color `cs.onSurface`. Below it, the existing `ProfileBadge(user.role.toUpperCase())` widget (already used in `profile_card.dart`).
5. **Divider** — 1dp.
6. **NavGrid** — `ac.muted` background (`ac.cardDark` in dark mode), 20dp horizontal × 16dp vertical padding. A single `Row` of four `Expanded` tiles (see Tile spec below).
7. **Divider** — 1dp (sits on `theme.scaffoldBackgroundColor`).
8. **Sign out row** — 14dp vertical × 16dp horizontal, 12dp gap. Tappable.
   - 28×28 rounded square (10dp radius) with `cs.error.withValues(alpha: 0.15)` fill and `Icons.logout_rounded` in `cs.error`.
   - Label "Sign out" — `theme.textTheme.bodyMedium` weight medium, color `cs.error`.
9. **BottomSafeArea** — 12dp + `MediaQuery.of(context).padding.bottom`.

### Tile spec

| Property | Value |
|---|---|
| Width | `Expanded` (4 tiles share the grid row equally) |
| Vertical padding | 8dp |
| Gap (icon → label) | 6dp |
| Icon container | 44×44, `cs.surface` fill, 8dp radius, 1dp `theme.dividerColor` border |
| Icon | 24px (`Icons.bookmark_outline`, `Icons.apartment_outlined`, `Icons.inbox_outlined`, `Icons.settings_outlined`), color `cs.onSurface` |
| Label | `AppTypography.mono(base: theme.textTheme.labelSmall)`, 10sp, 0.88px letter spacing, uppercase, color `ac.textMuted` |
| Tap target | full tile column (`InkWell`) |

### Destinations

| Tile | Icon | Route |
|---|---|---|
| `SAVED` | `Icons.bookmark_outline` | `/saved` |
| `DEPARTMENTS` | `Icons.apartment_outlined` | `/departments` |
| `REQUESTS` | `Icons.inbox_outlined` | `/requests` |
| `PROFILE` | `Icons.settings_outlined` (Figma uses the gear visual; label clarifies destination) | `/profile` |

### Admin section (deferred)

Per `app_user_model.dart`, `role` defaults to `'student'`. The Figma's ADMIN section (MODERATION · MANAGE DEPTS · USERS) is **not rendered** in this change because the destinations don't exist as screens yet. The drawer is built so the section can be added later with a single `if (user.role == 'admin')` block — no other structural change required.

### Liquid glass usage

Minimal and purposeful, to tie the sheet to the existing liquid-glass nav bar without compromising legibility.

1. **Backdrop scrim.** A `BackdropFilter` with `ImageFilter.blur(sigmaX: 8, sigmaY: 8)` behind the sheet, plus a `Colors.black.withValues(alpha: 0.18)` barrier tint. Frosts the page behind the drawer instead of dimming it flat.
2. **Top specular line.** A 1dp gradient (`transparent → white@0.6 → transparent`) across the top edge of the sheet, echoing the same effect used in `MainNavBar` lines 116–135. Subtle visual continuity with the nav bar's glass material.

The sheet body itself stays **solid** (`cs.surface`), and tiles stay **solid** (`cs.surface` with `theme.dividerColor` border). Glass on either would compete with content and contradict the Figma reference.

### Dark mode

All surfaces resolve through `ColorScheme` and `AppColors`. Specifically:
- Sheet body: `cs.surface` (white → dark gray)
- NavGrid background: `ac.muted` light, `ac.cardDark` dark
- Tile fill: `cs.surface` (auto-adapts)
- All text via `theme.textTheme.*`
- Amber identity colors (avatar, logo) stay constant in both themes
- Sign-out red (`cs.error`) stays constant

---

## Code structure

### New files

```
apps/mobile/lib/features/more/presentation/widgets/
  more_drawer.dart                  ← public showMoreDrawer() + private _MoreDrawerSheet
  more_drawer_user_row.dart         ← header + user info widget
  more_drawer_grid.dart             ← 4-tile grid widget
  more_drawer_tile.dart             ← single tile (icon + uppercase label)

apps/mobile/test/widget/features/more/
  more_drawer_test.dart             ← widget tests for the sheet

apps/mobile/test/widget/core/router/
  shell_scaffold_test.dart          ← (extend if exists) prove More tab opens sheet
```

### Deleted files

```
apps/mobile/lib/features/more/presentation/screens/more_screen.dart
apps/mobile/test/widget/features/more/more_screen_test.dart
```

### Modified files

```
apps/mobile/lib/core/router/router.dart
  - branch 3 (/more) and its child routes removed
  - branch 4 (/saved guest) removed
  - top-level GoRoutes added: /profile, /saved, /departments, /departments/:deptId,
    /requests, /requests/:requestId
  - kSavedBranchIndex constant removed
  - _RouterNotifier.redirect — drop /saved → /more/saved rule; refresh knownPrefixes

apps/mobile/lib/core/router/shell_scaffold.dart
  - _handleTabTap intercepts NavTab.more → showMoreDrawer(context); return
  - scrollTargetKeys length shrinks (no more guest /saved branch)

apps/mobile/lib/core/router/guest_shell_scaffold.dart
  - onSavedTap calls context.go('/saved') instead of goBranch(kSavedBranchIndex)
  - GuestNavBar gets isOnSaved derived from GoRouterState path

apps/mobile/lib/shared/widgets/guest_nav_bar.dart
  - accept isOnSaved bool (or read GoRouterState directly), use it for active state
```

### Public API

```dart
// more_drawer.dart
Future<void> showMoreDrawer(BuildContext context);

class _MoreDrawerSheet extends ConsumerWidget { /* private */ }
```

The function returns `Future<void>` for awaitability but no caller currently needs the result.

---

## Conventions checklist

- [x] Domain layer untouched (this is a Presentation-only change)
- [x] Package imports only (`package:unishare_mobile/...`)
- [x] No hardcoded colors — `cs.*`, `ac.*`, `theme.dividerColor`, etc.
- [x] No hardcoded text styles — `theme.textTheme.*` + `AppTypography.mono(...)` for the uppercase tile labels
- [x] No hardcoded `FontFamily` — Space Grotesk + Fira Code come from the theme
- [x] All icons from `Icons.*` (no new icon packs introduced)
- [x] No new dependencies (`liquid_glass_renderer` already in pubspec)
- [x] Every new widget has a widget test
- [x] `flutter analyze` and `dart format .` clean before commit

---

## Test plan

### `more_drawer_test.dart`

- ✓ renders header, user row, 4-tile grid, sign out row
- ✓ user row shows correct name + role badge (uppercase)
- ✓ ADMIN section is NOT rendered (proves the deferral is intentional)
- ✓ tap SAVED tile → router navigates to `/saved`
- ✓ tap DEPARTMENTS tile → router navigates to `/departments`
- ✓ tap REQUESTS tile → router navigates to `/requests`
- ✓ tap PROFILE tile → router navigates to `/profile`
- ✓ tap sign out row → `signOutUseCase` is invoked, `guestModeProvider.exit()` is called
- ✓ sheet dismisses on barrier tap
- ✓ sheet dismisses on swipe-down gesture

### `shell_scaffold_test.dart`

- ✓ tapping the More tab opens the bottom sheet (`showModalBottomSheet` called)
- ✓ tapping the More tab does NOT call `navigationShell.goBranch`
- ✓ tapping any other tab still calls `navigationShell.goBranch(index)`

### Manual smoke

- Authenticated user on iOS — tap More on Feed → sheet rises → tap each tile, verify destination loads with back arrow that returns to Feed
- Authenticated user on Android — same, plus system back gesture from a destination returns to Feed
- Guest user — verify guest nav bar Saved tab still works (now via `context.go('/saved')`) and visual state unchanged
- Dark mode — sheet, grid background, tile borders, and text all readable; amber and red identity colors unchanged
- Verify `flutter analyze` clean and existing widget tests still pass

---

## Risks & follow-ups

| Risk | Mitigation |
|---|---|
| Top-level sub-routes lose bottom nav — users may feel the change | Deep-linking still works; each sub-screen has a back-arrow AppBar. Acceptable per design decision. |
| Guest shell refactor (Option B) might subtly affect guest navigation | Add an explicit widget test for guest /saved tap before this change ships, alongside the new tests. |
| Admin section deferred — feature gap remains | Tracked separately; drawer code structured to add the gate later in one block. |
| Settings tile relabeled as PROFILE — small UX surprise vs Figma | Label matches destination, which is honest. Note in the PR description. |

## References

- Figma node `246:126` — primary design source
- Figma node `328:3` — original web vision (dark, more tiles); informs naming, not layout
- `apps/mobile/lib/features/profile/presentation/widgets/profile_card.dart` — `ProfileBadge` reused for role chip
- `apps/mobile/lib/shared/widgets/main_nav_bar.dart` lines 116–135 — specular top-edge gradient pattern (reused)
- `apps/mobile/lib/shared/theme/` — `AppColors`, `AppTypography`, theme tokens
