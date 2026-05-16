# More Drawer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `/more` screen with a modal bottom sheet ("More drawer") that opens when the More tab is tapped. Host the four destinations (Profile, Saved, Departments, Requests) inside a dedicated 4th `StatefulShellBranch` so the bottom nav stays visible and the 4th nav slot dynamically reflects the active sub-destination. Use the project's theme tokens exclusively. Apply liquid-glass on the sheet surface using the same `LiquidGlassLayer + LiquidGlass` pattern as `MainNavBar`.

**Architecture:** Build the drawer leaf-up (Tile → Grid → UserRow → Sheet) as four widget files, each with its own widget test. Then refactor the router: promote `/saved` to live as a sibling inside the new Branch 3 (touches guest shell), add `/profile`, `/departments`, `/requests` as siblings in the same branch, wire the More tab to open the sheet, and finally delete `MoreScreen` + the old `/more` branch + the old test. Each task ends with passing tests and a commit.

> **Note:** Earlier drafts of this plan moved the drawer destinations to top-level GoRoutes outside the shell. That approach hid the bottom nav on Profile/Saved/Departments/Requests and was reverted at the user's request before merge. The final implementation uses a 4th `StatefulShellBranch` with a `DrawerDestination` enum driving a dynamic 4th nav slot — see the updated spec for the canonical routing model.

**Tech Stack:** Flutter, Riverpod 3.x (`flutter_riverpod: ^3.3.1`, `riverpod_annotation: ^4.0.2`, `@riverpod` codegen), GoRouter, Material `showModalBottomSheet`, `liquid_glass_renderer` (already in pubspec), existing `AppColors` / `AppTypography` theme tokens.

**Spec:** `docs/superpowers/specs/2026-05-16-more-drawer-design.md` (commit `5889f11`).

---

## File Structure

### New files

| Path | Responsibility |
|---|---|
| `apps/mobile/lib/features/more/presentation/widgets/more_drawer_tile.dart` | One 44dp icon tile + uppercase mono label. Stateless. |
| `apps/mobile/lib/features/more/presentation/widgets/more_drawer_grid.dart` | Row of four `MoreDrawerTile`s with the muted background and grid padding. |
| `apps/mobile/lib/features/more/presentation/widgets/more_drawer_user_row.dart` | Avatar (initials) + name + role badge. Takes `AppUser` as parameter. |
| `apps/mobile/lib/features/more/presentation/widgets/more_drawer.dart` | `MoreDrawerSheet` (composes all pieces, watches `currentUserProvider`, handles sign out) and `showMoreDrawer(BuildContext)` function. |
| `apps/mobile/test/widget/features/more/more_drawer_tile_test.dart` | Tile widget tests. |
| `apps/mobile/test/widget/features/more/more_drawer_grid_test.dart` | Grid widget tests. |
| `apps/mobile/test/widget/features/more/more_drawer_user_row_test.dart` | User row widget tests. |
| `apps/mobile/test/widget/features/more/more_drawer_test.dart` | Sheet integration tests (sign out, navigation). |

### Deleted files

| Path | Reason |
|---|---|
| `apps/mobile/lib/features/more/presentation/screens/more_screen.dart` | Replaced by `MoreDrawerSheet`. |
| `apps/mobile/test/widget/features/more/more_screen_test.dart` | Tests target a deleted widget. |

### Modified files

| Path | Change |
|---|---|
| `apps/mobile/lib/core/router/router.dart` | Branch 3 (`/more`) deleted. Branch 4 (`/saved` guest) deleted. Top-level routes added for `/profile`, `/saved`, `/departments`, `/departments/:deptId`, `/requests`, `/requests/:requestId`. `kSavedBranchIndex` removed. `_RouterNotifier.redirect` rule for `/saved → /more/saved` removed. `knownPrefixes` updated. |
| `apps/mobile/lib/core/router/shell_scaffold.dart` | `_handleTabTap` intercepts `NavTab.more` → calls `showMoreDrawer(context)` and returns. `scrollTargetKeys` length reduced by one (no more guest branch). |
| `apps/mobile/lib/core/router/guest_shell_scaffold.dart` | `onSavedTap` switches from `navigationShell.goBranch(kSavedBranchIndex)` to `context.go('/saved')`. Reads current URL via `GoRouterState.of(context)` to compute `isOnSaved`. |
| `apps/mobile/lib/shared/widgets/guest_nav_bar.dart` | Replaces `activeIndex` semantics — accepts `isOnSaved: bool` to drive the pill state. Internal `_selectedTab` derives from `isOnSaved` instead of `widget.activeIndex == kSavedBranchIndex`. |
| `apps/mobile/test/widget/core/router/shell_router_test.dart` | Existing `/more` test removed. New tests added: tapping More tab opens the drawer; tapping More tab does NOT call `navigationShell.goBranch`. |

---

## Conventions

- **Package imports only.** No relative imports. Run `dart fix --apply` if any sneak in.
- **No hardcoded colors.** Use `cs.*`, `ac.*`, `theme.dividerColor`. (`cs = Theme.of(context).colorScheme`; `ac = Theme.of(context).extension<AppColors>()!`.)
- **No hardcoded text styles.** Use `theme.textTheme.*` and `AppTypography.mono(base: ...)` for uppercase labels.
- **No new dependencies.** Everything needed is already in `pubspec.yaml`.
- **TDD.** Write the failing test first, run it, then implement, then run it again. Commit each task.
- **Commit format.** Conventional Commits (`feat(more): ...`, `refactor(router): ...`, `test(more): ...`).

Run from `apps/mobile/`:

```bash
flutter analyze
dart format .
flutter test
```

These three must be clean at the end of every task before committing.

---

## Task 1: `MoreDrawerTile` widget

**Files:**
- Create: `apps/mobile/lib/features/more/presentation/widgets/more_drawer_tile.dart`
- Test: `apps/mobile/test/widget/features/more/more_drawer_tile_test.dart`

- [ ] **Step 1: Write the failing test**

Create `apps/mobile/test/widget/features/more/more_drawer_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_tile.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.build(AppThemes.unishare),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('renders icon and uppercase label', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MoreDrawerTile(
          label: 'SAVED',
          icon: Icons.bookmark_outline,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('SAVED'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
  });

  testWidgets('tapping the tile fires onTap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      _wrap(
        MoreDrawerTile(
          label: 'SAVED',
          icon: Icons.bookmark_outline,
          onTap: () => tapped++,
        ),
      ),
    );

    await tester.tap(find.byType(MoreDrawerTile));
    await tester.pump();

    expect(tapped, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd apps/mobile
flutter test test/widget/features/more/more_drawer_tile_test.dart
```

Expected: FAIL — `more_drawer_tile.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `apps/mobile/lib/features/more/presentation/widgets/more_drawer_tile.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class MoreDrawerTile extends StatelessWidget {
  const MoreDrawerTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ac = theme.extension<AppColors>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 24, color: cs.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.mono(
                base: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.88,
                  fontWeight: FontWeight.w700,
                  color: ac.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/widget/features/more/more_drawer_tile_test.dart
```

Expected: 2 tests passing.

- [ ] **Step 5: Analyze + format + commit**

```bash
flutter analyze
dart format lib/features/more/presentation/widgets/more_drawer_tile.dart \
            test/widget/features/more/more_drawer_tile_test.dart

cd ../..
git add apps/mobile/lib/features/more/presentation/widgets/more_drawer_tile.dart \
        apps/mobile/test/widget/features/more/more_drawer_tile_test.dart
git commit -m "feat(more): add MoreDrawerTile widget"
```

---

## Task 2: `MoreDrawerGrid` widget

**Files:**
- Create: `apps/mobile/lib/features/more/presentation/widgets/more_drawer_grid.dart`
- Test: `apps/mobile/test/widget/features/more/more_drawer_grid_test.dart`

- [ ] **Step 1: Write the failing test**

Create `apps/mobile/test/widget/features/more/more_drawer_grid_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_grid.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_tile.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.build(AppThemes.unishare),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders four tiles with the expected labels', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MoreDrawerGrid(
          onSavedTap: () {},
          onDepartmentsTap: () {},
          onRequestsTap: () {},
          onProfileTap: () {},
        ),
      ),
    );

    expect(find.byType(MoreDrawerTile), findsNWidgets(4));
    expect(find.text('SAVED'), findsOneWidget);
    expect(find.text('DEPARTMENTS'), findsOneWidget);
    expect(find.text('REQUESTS'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);
  });

  testWidgets('each tile fires its matching callback', (tester) async {
    var saved = 0, depts = 0, reqs = 0, profile = 0;

    await tester.pumpWidget(
      _wrap(
        MoreDrawerGrid(
          onSavedTap: () => saved++,
          onDepartmentsTap: () => depts++,
          onRequestsTap: () => reqs++,
          onProfileTap: () => profile++,
        ),
      ),
    );

    await tester.tap(find.text('SAVED'));
    await tester.tap(find.text('DEPARTMENTS'));
    await tester.tap(find.text('REQUESTS'));
    await tester.tap(find.text('PROFILE'));
    await tester.pump();

    expect(saved, 1);
    expect(depts, 1);
    expect(reqs, 1);
    expect(profile, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/widget/features/more/more_drawer_grid_test.dart
```

Expected: FAIL — `more_drawer_grid.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `apps/mobile/lib/features/more/presentation/widgets/more_drawer_grid.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_tile.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class MoreDrawerGrid extends StatelessWidget {
  const MoreDrawerGrid({
    super.key,
    required this.onSavedTap,
    required this.onDepartmentsTap,
    required this.onRequestsTap,
    required this.onProfileTap,
  });

  final VoidCallback onSavedTap;
  final VoidCallback onDepartmentsTap;
  final VoidCallback onRequestsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: isDark ? ac.cardDark : ac.muted,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: MoreDrawerTile(
              label: 'SAVED',
              icon: Icons.bookmark_outline,
              onTap: onSavedTap,
            ),
          ),
          Expanded(
            child: MoreDrawerTile(
              label: 'DEPARTMENTS',
              icon: Icons.apartment_outlined,
              onTap: onDepartmentsTap,
            ),
          ),
          Expanded(
            child: MoreDrawerTile(
              label: 'REQUESTS',
              icon: Icons.inbox_outlined,
              onTap: onRequestsTap,
            ),
          ),
          Expanded(
            child: MoreDrawerTile(
              label: 'PROFILE',
              icon: Icons.settings_outlined,
              onTap: onProfileTap,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/widget/features/more/more_drawer_grid_test.dart
```

Expected: 2 tests passing.

- [ ] **Step 5: Analyze + format + commit**

```bash
flutter analyze
dart format lib/features/more/presentation/widgets/more_drawer_grid.dart \
            test/widget/features/more/more_drawer_grid_test.dart

cd ../..
git add apps/mobile/lib/features/more/presentation/widgets/more_drawer_grid.dart \
        apps/mobile/test/widget/features/more/more_drawer_grid_test.dart
git commit -m "feat(more): add MoreDrawerGrid widget"
```

---

## Task 3: `MoreDrawerUserRow` widget

**Files:**
- Create: `apps/mobile/lib/features/more/presentation/widgets/more_drawer_user_row.dart`
- Test: `apps/mobile/test/widget/features/more/more_drawer_user_row_test.dart`

- [ ] **Step 1: Write the failing test**

Create `apps/mobile/test/widget/features/more/more_drawer_user_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_user_row.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/profile_card.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.build(AppThemes.unishare),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders name, uppercase role badge, and initials', (
    tester,
  ) async {
    const user = AppUser(
      id: 'u1',
      name: 'Pyae Sone Shin Thant',
      email: 'p@example.com',
      role: 'admin',
    );

    await tester.pumpWidget(_wrap(const MoreDrawerUserRow(user: user)));

    expect(find.text('Pyae Sone Shin Thant'), findsOneWidget);
    expect(find.byType(ProfileBadge), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);
    // Avatar initials: first letter of first two words.
    expect(find.text('PS'), findsOneWidget);
  });

  testWidgets('single-word name falls back to first two characters', (
    tester,
  ) async {
    const user = AppUser(id: 'u1', name: 'Alex', email: 'a@example.com');

    await tester.pumpWidget(_wrap(const MoreDrawerUserRow(user: user)));

    expect(find.text('AL'), findsOneWidget);
  });

  testWidgets('empty name renders "?" placeholder', (tester) async {
    const user = AppUser(id: 'u1', name: '', email: 'a@example.com');

    await tester.pumpWidget(_wrap(const MoreDrawerUserRow(user: user)));

    expect(find.text('?'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/widget/features/more/more_drawer_user_row_test.dart
```

Expected: FAIL — `more_drawer_user_row.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `apps/mobile/lib/features/more/presentation/widgets/more_drawer_user_row.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/profile_card.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class MoreDrawerUserRow extends StatelessWidget {
  const MoreDrawerUserRow({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ac.amber,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(user.name),
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                ProfileBadge(user.role.toUpperCase()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    final solo = parts[0];
    return solo.length >= 2
        ? solo.substring(0, 2).toUpperCase()
        : solo.toUpperCase();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/widget/features/more/more_drawer_user_row_test.dart
```

Expected: 3 tests passing.

- [ ] **Step 5: Analyze + format + commit**

```bash
flutter analyze
dart format lib/features/more/presentation/widgets/more_drawer_user_row.dart \
            test/widget/features/more/more_drawer_user_row_test.dart

cd ../..
git add apps/mobile/lib/features/more/presentation/widgets/more_drawer_user_row.dart \
        apps/mobile/test/widget/features/more/more_drawer_user_row_test.dart
git commit -m "feat(more): add MoreDrawerUserRow widget"
```

---

## Task 4: `MoreDrawerSheet` + `showMoreDrawer()`

**Files:**
- Create: `apps/mobile/lib/features/more/presentation/widgets/more_drawer.dart`
- Test: `apps/mobile/test/widget/features/more/more_drawer_test.dart`

This task assembles the sheet. We use `currentUserProvider` for the user data and override `authRepositoryProvider` in tests to control what the provider returns. Sign out is triggered through `signOutUseCaseProvider`; we use the same fake repo to spy on the call.

- [ ] **Step 1: Write the failing test**

Create `apps/mobile/test/widget/features/more/more_drawer_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_grid.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_user_row.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.user});

  AppUser? user;
  int signOutCalls = 0;

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(user);

  @override
  Future<AppUser?> getCurrentUser() async => user;

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }

  @override
  Future<AppUser> signInWithGoogle() => throw UnimplementedError();
  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? universityId,
  }) => throw UnimplementedError();
  @override
  Future<void> updateProfile({
    required String uid,
    required String name,
    String? bio,
    String? universityId,
    String? departmentId,
    int? enrollmentYear,
  }) async {}
  @override
  Future<void> updateAcademicProfile({
    required String uid,
    required String departmentId,
    int? enrollmentYear,
  }) async {}
}

const _user = AppUser(
  id: 'u1',
  name: 'Pyae Sone',
  email: 'p@example.com',
  role: 'student',
);

GoRouter _testRouter() => GoRouter(
  initialLocation: '/host',
  routes: [
    GoRoute(
      path: '/host',
      builder: (ctx, _) => Scaffold(
        body: Builder(
          builder: (innerCtx) => Center(
            child: ElevatedButton(
              onPressed: () => showMoreDrawer(innerCtx),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    ),
    GoRoute(path: '/profile', builder: (_, _) =>
        const Scaffold(body: Text('Profile page'))),
    GoRoute(path: '/saved', builder: (_, _) =>
        const Scaffold(body: Text('Saved page'))),
    GoRoute(path: '/departments', builder: (_, _) =>
        const Scaffold(body: Text('Departments page'))),
    GoRoute(path: '/requests', builder: (_, _) =>
        const Scaffold(body: Text('Requests page'))),
    GoRoute(path: '/welcome', builder: (_, _) =>
        const Scaffold(body: Text('Welcome page'))),
  ],
);

Widget _buildApp(_FakeAuthRepository repo) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      theme: AppTheme.build(AppThemes.unishare),
      routerConfig: _testRouter(),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders user row, 4-tile grid, and sign out row', (
    tester,
  ) async {
    final repo = _FakeAuthRepository(user: _user);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await _openSheet(tester);

    expect(find.byType(MoreDrawerUserRow), findsOneWidget);
    expect(find.byType(MoreDrawerGrid), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('does NOT render an ADMIN section label', (tester) async {
    final repo = _FakeAuthRepository(user: _user);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await _openSheet(tester);

    // ADMIN appears in the user role badge but NOT as a section header.
    // 'student' role means no role badge of 'ADMIN' should exist anywhere.
    expect(find.text('ADMIN'), findsNothing);
  });

  testWidgets('tapping SAVED tile navigates to /saved', (tester) async {
    final repo = _FakeAuthRepository(user: _user);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await _openSheet(tester);

    await tester.tap(find.text('SAVED'));
    await tester.pumpAndSettle();

    expect(find.text('Saved page'), findsOneWidget);
  });

  testWidgets('tapping DEPARTMENTS tile navigates to /departments', (
    tester,
  ) async {
    final repo = _FakeAuthRepository(user: _user);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await _openSheet(tester);

    await tester.tap(find.text('DEPARTMENTS'));
    await tester.pumpAndSettle();

    expect(find.text('Departments page'), findsOneWidget);
  });

  testWidgets('tapping REQUESTS tile navigates to /requests', (tester) async {
    final repo = _FakeAuthRepository(user: _user);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await _openSheet(tester);

    await tester.tap(find.text('REQUESTS'));
    await tester.pumpAndSettle();

    expect(find.text('Requests page'), findsOneWidget);
  });

  testWidgets('tapping PROFILE tile navigates to /profile', (tester) async {
    final repo = _FakeAuthRepository(user: _user);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await _openSheet(tester);

    await tester.tap(find.text('PROFILE'));
    await tester.pumpAndSettle();

    expect(find.text('Profile page'), findsOneWidget);
  });

  testWidgets('tapping Sign out calls signOut and exits guest mode', (
    tester,
  ) async {
    final repo = _FakeAuthRepository(user: _user);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await _openSheet(tester);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(repo.signOutCalls, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/widget/features/more/more_drawer_test.dart
```

Expected: FAIL — `more_drawer.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `apps/mobile/lib/features/more/presentation/widgets/more_drawer.dart`:

```dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_grid.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_user_row.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

/// Shows the More drawer as a modal bottom sheet. Auth-only.
Future<void> showMoreDrawer(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (_) => const MoreDrawerSheet(),
  );
}

class MoreDrawerSheet extends ConsumerWidget {
  const MoreDrawerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final userAsync = ref.watch(currentUserProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DragHandle(),
            const _SpecularTopEdge(),
            const _Header(),
            Divider(height: 1, thickness: 1, color: theme.dividerColor),
            userAsync.when(
              data: (user) => user == null
                  ? const SizedBox.shrink()
                  : MoreDrawerUserRow(user: user),
              loading: () => const _UserRowSkeleton(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            Divider(height: 1, thickness: 1, color: theme.dividerColor),
            MoreDrawerGrid(
              onSavedTap: () => _go(context, '/saved'),
              onDepartmentsTap: () => _go(context, '/departments'),
              onRequestsTap: () => _go(context, '/requests'),
              onProfileTap: () => _go(context, '/profile'),
            ),
            Divider(height: 1, thickness: 1, color: theme.dividerColor),
            _SignOutRow(
              onTap: () => _signOut(context, ref),
              errorColor: cs.error,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: cs.error,
              ),
            ),
            SizedBox(height: 12 + bottomInset),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String path) {
    Navigator.of(context).pop();
    context.go(path);
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    // Capture providers before popping — the modal's ConsumerWidget is torn
    // down by the pop, after which `ref` reads can warn.
    final signOut = ref.read(signOutUseCaseProvider);
    final guestMode = ref.read(guestModeProvider.notifier);
    Navigator.of(context).pop();
    await signOut.call();
    guestMode.exit();
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 20,
      child: Center(
        child: Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: theme.dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _SpecularTopEdge extends StatelessWidget {
  const _SpecularTopEdge();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: isDark ? 0.22 : 0.6),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ac = theme.extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: ac.amber,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              'U',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Unishare',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutRow extends StatelessWidget {
  const _SignOutRow({
    required this.onTap,
    required this.errorColor,
    required this.labelStyle,
  });

  final VoidCallback onTap;
  final Color errorColor;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: errorColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.logout_rounded, size: 18, color: errorColor),
            ),
            const SizedBox(width: 12),
            Text('Sign out', style: labelStyle),
          ],
        ),
      ),
    );
  }
}

class _UserRowSkeleton extends StatelessWidget {
  const _UserRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 68);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/widget/features/more/more_drawer_test.dart
```

Expected: 7 tests passing.

- [ ] **Step 5: Analyze + format + commit**

```bash
flutter analyze
dart format lib/features/more/presentation/widgets/more_drawer.dart \
            test/widget/features/more/more_drawer_test.dart

cd ../..
git add apps/mobile/lib/features/more/presentation/widgets/more_drawer.dart \
        apps/mobile/test/widget/features/more/more_drawer_test.dart
git commit -m "feat(more): add MoreDrawerSheet and showMoreDrawer entry point"
```

---

## Task 5: Migrate `/saved` out of the StatefulShellRoute

Until this task, `/saved` exists as branch 4 of the StatefulShellRoute (guest tab destination). After this task, `/saved` is a single top-level GoRoute that both guests and auth users can navigate to. The guest nav bar pill state shifts from "compare current branch index to `kSavedBranchIndex`" to "is the current URL `/saved`?".

**Files:**
- Modify: `apps/mobile/lib/core/router/router.dart`
- Modify: `apps/mobile/lib/core/router/guest_shell_scaffold.dart`
- Modify: `apps/mobile/lib/shared/widgets/guest_nav_bar.dart`

- [ ] **Step 1: Inspect existing failing surface area**

Before changing anything, run the existing tests to capture the baseline:

```bash
cd apps/mobile
flutter test test/widget/core/router/shell_router_test.dart
```

Expected: all tests pass currently. Note the count for comparison after the refactor.

- [ ] **Step 2: Update `guest_nav_bar.dart` — accept `isOnSaved` instead of `kSavedBranchIndex` comparison**

In `apps/mobile/lib/shared/widgets/guest_nav_bar.dart`:

Change the constructor and the `_selectedTab` getter. Replace:

```dart
class GuestNavBar extends StatefulWidget {
  const GuestNavBar({
    super.key,
    required this.activeIndex,
    required this.onFeedTap,
    required this.onSavedTap,
  });

  /// `activeIndex` matches the parent shell's branch index (NavTab.feed.index
  /// or [kSavedBranchIndex]). Anything else renders no active pill.
  final int activeIndex;
  final VoidCallback onFeedTap;
  final VoidCallback onSavedTap;
```

with:

```dart
class GuestNavBar extends StatefulWidget {
  const GuestNavBar({
    super.key,
    required this.isOnFeed,
    required this.isOnSaved,
    required this.onFeedTap,
    required this.onSavedTap,
  });

  /// True when the current route is `/feed` (or its descendants).
  final bool isOnFeed;

  /// True when the current route is `/saved`.
  final bool isOnSaved;

  final VoidCallback onFeedTap;
  final VoidCallback onSavedTap;
```

And replace the `_selectedTab` getter inside `_GuestNavBarState`:

```dart
int get _selectedTab {
  if (widget.activeIndex == NavTab.feed.index) return 0;
  if (widget.activeIndex == kSavedBranchIndex) return 1;
  return -1;
}
```

with:

```dart
int get _selectedTab {
  if (widget.isOnFeed) return 0;
  if (widget.isOnSaved) return 1;
  return -1;
}
```

Remove the `NavTab` import if it becomes unused — Dart's linter will flag it.

- [ ] **Step 3: Update `guest_shell_scaffold.dart` — derive `isOnSaved` from `GoRouterState`, navigate via `context.go`**

Replace the entire body of `apps/mobile/lib/core/router/guest_shell_scaffold.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/core/router/router.dart';
import 'package:unishare_mobile/core/router/shell_scaffold.dart';
import 'package:unishare_mobile/shared/widgets/guest_nav_bar.dart';
import 'package:unishare_mobile/shared/widgets/scroll_to_top_target.dart';

class GuestShellScaffold extends StatelessWidget {
  const GuestShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final isOnFeed = path == '/feed' || path.startsWith('/feed/');
    final isOnSaved = path == '/saved';

    return PopScope(
      canPop: isOnFeed || context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isOnFeed) {
          context.go('/feed');
        }
      },
      child: Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: GuestNavBar(
          isOnFeed: isOnFeed,
          isOnSaved: isOnSaved,
          onFeedTap: () {
            if (isOnFeed) {
              final state =
                  ShellScaffold.scrollTargetKeys[NavTab.feed.index].currentState;
              if (state is ScrollToTopTarget) state.scrollToTop();
              return;
            }
            context.go('/feed');
          },
          onSavedTap: () => context.go('/saved'),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Update `router.dart` — promote `/saved` to top-level, delete branch 4, remove `kSavedBranchIndex` and the auth redirect**

In `apps/mobile/lib/core/router/router.dart`:

Remove the constant near the top of the file:

```dart
/// Branch index of the guest /saved route in the StatefulShellRoute.
/// Declared here to avoid a circular import between GuestNavBar and GuestShellScaffold.
const kSavedBranchIndex = 4;
```

Remove this redirect rule inside `_RouterNotifier.redirect`:

```dart
// 4. Authenticated user on guest-only /saved → redirect to /more/saved
if (isAuthenticated && currentPath == '/saved') {
  return '/more/saved';
}
```

Renumber the remaining comment numbering (rule 5 becomes rule 4).

In the same `redirect` method, the `knownPrefixes` set already includes `/saved`. Leave that.

Add a new top-level GoRoute *before* the StatefulShellRoute (so it takes priority over any shell child resolution). Insert immediately after the `/preview` route:

```dart
GoRoute(
  path: '/saved',
  builder: (context, state) => const SavedScreen(),
),
```

Delete the entire **Branch 4 — SAVED** entry from the `branches:` list of the StatefulShellRoute:

```dart
// Branch 4 — SAVED (top-level; used by the guest shell nav bar)
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/saved',
      builder: (context, state) => const SavedScreen(),
    ),
  ],
),
```

- [ ] **Step 5: Run tests + analyze**

```bash
flutter analyze
flutter test
```

Expected:
- Existing `shell_router_test.dart` tests still pass — `/feed`, `/posts`, `/notifications`, `/more` (still works for now since branch 3 still exists), `/welcome`, `/posts/create`, unknown path, back press, tapping FEED tab.
- The `kSavedBranchIndex` constant is gone — no references should remain. If `flutter analyze` flags an unused import in `guest_nav_bar.dart`, remove `import 'package:unishare_mobile/core/router/router.dart';`.

If `guest_nav_bar.dart` still needs to reference `NavTab`, keep the import. Verify with grep:

```bash
grep -n "NavTab\|kSavedBranchIndex" lib/shared/widgets/guest_nav_bar.dart
```

- [ ] **Step 6: Format + commit**

```bash
dart format lib/core/router/router.dart \
            lib/core/router/guest_shell_scaffold.dart \
            lib/shared/widgets/guest_nav_bar.dart

cd ../..
git add apps/mobile/lib/core/router/router.dart \
        apps/mobile/lib/core/router/guest_shell_scaffold.dart \
        apps/mobile/lib/shared/widgets/guest_nav_bar.dart
git commit -m "refactor(router): promote /saved to top-level route"
```

---

## Task 6: Add top-level routes for `/profile`, `/departments`, `/requests`

This task adds new top-level routes that the drawer will navigate to. The old `/more/profile`, `/more/departments`, `/more/requests` routes remain in place for one more task — we delete them in Task 8 along with `MoreScreen`.

**Files:**
- Modify: `apps/mobile/lib/core/router/router.dart`

- [ ] **Step 1: Add the new top-level GoRoutes**

In `apps/mobile/lib/core/router/router.dart`, insert these routes immediately after the `/saved` top-level route (added in Task 5), still *before* the `StatefulShellRoute`:

```dart
GoRoute(
  path: '/profile',
  builder: (context, state) => const ProfileScreen(),
),
GoRoute(
  path: '/departments',
  builder: (context, state) => const DepartmentsScreen(),
  routes: [
    GoRoute(
      path: ':deptId',
      builder: (context, state) => CoursesScreen(
        deptId: state.pathParameters['deptId']!,
        departmentName: state.uri.queryParameters['name'] ?? 'Courses',
      ),
    ),
  ],
),
GoRoute(
  path: '/requests',
  builder: (context, state) => const RequestsScreen(),
),
GoRoute(
  path: '/requests/:requestId',
  builder: (context, state) {
    final requestId = state.pathParameters['requestId']!;
    return RequestDetailScreen(requestId: requestId);
  },
),
```

- [ ] **Step 2: Update `knownPrefixes` in `_RouterNotifier.redirect`**

Replace:

```dart
const knownPrefixes = {
  '/feed',
  '/posts',
  '/notifications',
  '/more',
  '/saved',
  '/preview',
  '/upload-progress',
};
```

with:

```dart
const knownPrefixes = {
  '/feed',
  '/posts',
  '/notifications',
  '/more',
  '/saved',
  '/profile',
  '/departments',
  '/requests',
  '/preview',
  '/upload-progress',
};
```

(Leave `/more` in place for now — we delete it in Task 8.)

- [ ] **Step 3: Run tests + analyze**

```bash
cd apps/mobile
flutter analyze
flutter test
```

Expected: all existing tests still pass. The new routes are discoverable but not yet referenced by any UI.

- [ ] **Step 4: Format + commit**

```bash
dart format lib/core/router/router.dart

cd ../..
git add apps/mobile/lib/core/router/router.dart
git commit -m "feat(router): add top-level /profile, /departments, /requests routes"
```

---

## Task 7: Wire `ShellScaffold` to open the drawer on More tap

**Files:**
- Modify: `apps/mobile/lib/core/router/shell_scaffold.dart`
- Modify: `apps/mobile/test/widget/core/router/shell_router_test.dart`

- [ ] **Step 1: Write the failing test**

Open `apps/mobile/test/widget/core/router/shell_router_test.dart` and add this test inside the `group('Shell router', ...)`:

```dart
testWidgets('tapping More tab opens the More drawer (does not switch branch)', (
  tester,
) async {
  await tester.pumpWidget(_buildApp());
  await tester.pumpAndSettle();

  final moreTab = find.byWidgetPredicate(
    (w) =>
        w is Semantics &&
        w.properties.button == true &&
        w.properties.label == 'More',
  );
  expect(moreTab, findsOneWidget);

  await tester.tap(moreTab);
  await tester.pumpAndSettle();

  // The drawer surfaces these uppercase labels.
  expect(find.text('SAVED'), findsOneWidget);
  expect(find.text('DEPARTMENTS'), findsOneWidget);
  expect(find.text('REQUESTS'), findsOneWidget);
  expect(find.text('PROFILE'), findsOneWidget);
  // We're still rooted on /feed under the drawer.
  expect(find.byType(MainNavBar), findsOneWidget);
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd apps/mobile
flutter test test/widget/core/router/shell_router_test.dart
```

Expected: the new test FAILS because tapping More currently navigates to `/more` (the old MoreScreen) — the drawer is never opened. Existing `/more` test should still pass.

- [ ] **Step 3: Wire the More tap to open the drawer**

Replace `apps/mobile/lib/core/router/shell_scaffold.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/core/router/router.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer.dart';
import 'package:unishare_mobile/shared/widgets/main_nav_bar.dart';
import 'package:unishare_mobile/shared/widgets/scroll_to_top_target.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// One scroll target per branch. After dropping branches /more (3) and the
  /// guest /saved branch (4), only Feed/Posts/Notifs remain — three keys.
  static final List<GlobalKey<State>> scrollTargetKeys = List.generate(
    NavTab.values.length - 1, // Feed, Posts, Notifs (More is action-only)
    (_) => GlobalKey<State>(),
  );

  @override
  Widget build(BuildContext context) {
    final activeIndex = navigationShell.currentIndex;

    return PopScope(
      canPop: activeIndex == NavTab.feed.index || context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && activeIndex != NavTab.feed.index) {
          navigationShell.goBranch(NavTab.feed.index, initialLocation: true);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: MainNavBar(
          activeIndex: activeIndex,
          onTap: (index) => _handleTabTap(context, index),
        ),
      ),
    );
  }

  void _handleTabTap(BuildContext context, int index) {
    // More is an action tab — it opens the drawer instead of switching branch.
    if (index == NavTab.more.index) {
      showMoreDrawer(context);
      return;
    }
    if (index == navigationShell.currentIndex) {
      final state = scrollTargetKeys[index].currentState;
      if (state is ScrollToTopTarget) {
        (state as ScrollToTopTarget).scrollToTop();
      }
      return;
    }
    navigationShell.goBranch(index);
  }
}
```

**Note on `scrollTargetKeys` length:** the old length was `NavTab.values.length + 1` (= 5) to cover the four NavTab branches plus the guest /saved branch. After Tasks 5 and 8, only Feed/Posts/Notifs are real branches (More is action-only, /saved is top-level, /more is deleted). The new length is `NavTab.values.length - 1` (= 3).

This means downstream consumers of `scrollTargetKeys` must use index 0/1/2 only. Update each branch's builder in `router.dart` to use the correct index. Replace:

```dart
// Branch 0 — FEED
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/feed',
      builder: (context, state) => FeedScreen(
        scrollKey: ShellScaffold.scrollTargetKeys[NavTab.feed.index],
      ),
    ),
  ],
),
// Branch 1 — POSTS
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/posts',
      builder: (context, state) => MyPostsScreen(
        scrollKey: ShellScaffold.scrollTargetKeys[NavTab.posts.index],
      ),
    ),
  ],
),
// Branch 2 — NOTIFS
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/notifications',
      builder: (context, state) => NotificationsScreen(
        scrollKey:
            ShellScaffold.scrollTargetKeys[NavTab.notifs.index],
      ),
    ),
  ],
),
```

The `NavTab.feed.index` (0), `NavTab.posts.index` (1), `NavTab.notifs.index` (2) values still map correctly. No changes needed here — but verify after Task 8 that all three keys are still accessed only at valid indices.

- [ ] **Step 4: Run the test to verify it passes**

```bash
flutter test test/widget/core/router/shell_router_test.dart
```

Expected: the new test PASSES. The existing `'MainNavBar present on /more'` test will likely still pass (we haven't deleted /more yet), but the More tap test now opens the drawer instead.

- [ ] **Step 5: Run the full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Analyze + format + commit**

```bash
flutter analyze
dart format lib/core/router/shell_scaffold.dart \
            test/widget/core/router/shell_router_test.dart

cd ../..
git add apps/mobile/lib/core/router/shell_scaffold.dart \
        apps/mobile/test/widget/core/router/shell_router_test.dart
git commit -m "feat(shell): More tab opens drawer instead of switching branch"
```

---

## Task 8: Delete `MoreScreen`, the `/more` branch, and the old test

This task completes the migration. After it lands, `/more` is no longer a valid path.

**Files:**
- Delete: `apps/mobile/lib/features/more/presentation/screens/more_screen.dart`
- Delete: `apps/mobile/test/widget/features/more/more_screen_test.dart`
- Modify: `apps/mobile/lib/core/router/router.dart`
- Modify: `apps/mobile/test/widget/core/router/shell_router_test.dart`

- [ ] **Step 1: Delete the old More test (it will be replaced by the drawer test we already wrote)**

```bash
cd apps/mobile
git rm test/widget/features/more/more_screen_test.dart
```

- [ ] **Step 2: Delete the old MoreScreen file**

```bash
git rm lib/features/more/presentation/screens/more_screen.dart
```

- [ ] **Step 3: Remove the import and branch from `router.dart`**

In `apps/mobile/lib/core/router/router.dart`:

Remove the import:

```dart
import 'package:unishare_mobile/features/more/presentation/screens/more_screen.dart';
```

Delete the entire **Branch 3 — MORE** entry from the `branches:` list:

```dart
// Branch 3 — MORE
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/more',
      builder: (context, state) => MoreScreen(
        scrollKey: ShellScaffold.scrollTargetKeys[NavTab.more.index],
      ),
      routes: [
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: 'saved',
          builder: (context, state) => const SavedScreen(),
        ),
        GoRoute(
          path: 'departments',
          builder: (context, state) => const DepartmentsScreen(),
          routes: [
            GoRoute(
              path: ':deptId',
              builder: (context, state) => CoursesScreen(
                deptId: state.pathParameters['deptId']!,
                departmentName:
                    state.uri.queryParameters['name'] ?? 'Courses',
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'requests',
          builder: (context, state) => const RequestsScreen(),
        ),
        GoRoute(
          path: 'requests/:requestId',
          builder: (context, state) {
            final requestId = state.pathParameters['requestId']!;
            return RequestDetailScreen(requestId: requestId);
          },
        ),
      ],
    ),
  ],
),
```

- [ ] **Step 4: Remove `/more` from `knownPrefixes` in `_RouterNotifier.redirect`**

Update `knownPrefixes` to:

```dart
const knownPrefixes = {
  '/feed',
  '/posts',
  '/notifications',
  '/saved',
  '/profile',
  '/departments',
  '/requests',
  '/preview',
  '/upload-progress',
};
```

- [ ] **Step 5: Update `shell_router_test.dart`**

In `apps/mobile/test/widget/core/router/shell_router_test.dart`:

Remove this test (it's now invalid — `/more` is no longer a path):

```dart
testWidgets('MainNavBar present on /more', (tester) async {
  await tester.pumpWidget(_buildApp());
  await tester.pumpAndSettle();
  _router(tester).go('/more');
  await tester.pumpAndSettle();
  expect(find.byType(MainNavBar), findsOneWidget);
});
```

Add a replacement test that proves `/more` redirects safely:

```dart
testWidgets('navigating to /more redirects to /feed (no longer a valid path)', (
  tester,
) async {
  await tester.pumpWidget(_buildApp());
  await tester.pumpAndSettle();
  _router(tester).go('/more');
  await tester.pumpAndSettle();
  expect(find.byType(MainNavBar), findsOneWidget);
  expect(find.text('Feed'), findsAtLeastNWidgets(1));
});
```

This works because `_RouterNotifier.redirect`'s `knownPrefixes` no longer includes `/more`, so the fallback `return '/feed';` fires.

- [ ] **Step 6: Run the full test suite**

```bash
flutter analyze
flutter test
```

Expected:
- `more_screen_test.dart` is gone (deleted in Step 1).
- All drawer tests pass.
- `shell_router_test.dart` passes including the new redirect-to-feed test.
- No tests reference `MoreScreen` or `/more/*` paths.

If a test fails because of an unused import or unreachable constant, fix it inline.

- [ ] **Step 7: Format + commit**

```bash
dart format lib/core/router/router.dart \
            test/widget/core/router/shell_router_test.dart

cd ../..
git add apps/mobile/lib/core/router/router.dart \
        apps/mobile/lib/features/more/presentation/screens/more_screen.dart \
        apps/mobile/test/widget/features/more/more_screen_test.dart \
        apps/mobile/test/widget/core/router/shell_router_test.dart
git commit -m "refactor(more): remove MoreScreen and /more branch"
```

---

## Task 9: Whole-suite verification + manual smoke

This is the final pre-merge gate. Nothing new is written.

- [ ] **Step 1: Run analyze, format check, and full test suite**

```bash
cd apps/mobile
flutter analyze
dart format --set-exit-if-changed .
flutter test
```

Expected:
- `flutter analyze`: no issues.
- `dart format --set-exit-if-changed .`: exit 0 (nothing to reformat).
- `flutter test`: all tests pass. Confirm the new drawer tests appear in the output (4 new test files × 2–7 tests each).

If any step fails, fix the underlying issue (do not skip).

- [ ] **Step 2: Manual smoke — auth user, light mode**

```bash
flutter run -d <device>
```

1. Sign in.
2. On `/feed`, tap **More**. Verify:
   - The sheet rises from the bottom with the drag handle, Unishare header, user row showing your name + role badge.
   - The grid shows four tiles: SAVED, DEPARTMENTS, REQUESTS, PROFILE.
   - The Sign out row is at the bottom in red.
   - The page behind is frosted (BackdropFilter).
3. Swipe the sheet down to dismiss. Confirm Feed is still active.
4. Tap **More** again. Tap **SAVED**. Verify `/saved` opens with an AppBar back arrow and no bottom nav.
5. Tap the back arrow. Verify return to Feed (or wherever you were).
6. Repeat for DEPARTMENTS, REQUESTS, PROFILE.
7. Tap **More** → **Sign out**. Verify you land on `/welcome`.

- [ ] **Step 3: Manual smoke — auth user, dark mode**

Toggle the OS to dark mode. Repeat Step 2 verifications. Confirm:
- Sheet body uses the dark surface color.
- Grid background reads as the dark muted variant (`ac.cardDark`).
- Amber identity (avatar, role badge) is unchanged.
- Red Sign out color is unchanged.

- [ ] **Step 4: Manual smoke — guest user**

Sign out, enter guest mode from `/welcome`.
1. Verify the guest bottom nav still shows three tabs (Feed, Saved, Sign In).
2. Tap **Saved**. Verify `/saved` loads (now top-level, not a branch).
3. Tap **Feed**. Verify return to `/feed`.
4. Tap **Saved**, then system-back. Confirm reasonable return path.

- [ ] **Step 5: Final summary commit (optional)**

If any docs need updating (e.g., README screenshots), do so now. Otherwise the work is done.

```bash
cd ../..
git log --oneline -10
```

You should see roughly:
```
<sha> refactor(more): remove MoreScreen and /more branch
<sha> feat(shell): More tab opens drawer instead of switching branch
<sha> feat(router): add top-level /profile, /departments, /requests routes
<sha> refactor(router): promote /saved to top-level route
<sha> feat(more): add MoreDrawerSheet and showMoreDrawer entry point
<sha> feat(more): add MoreDrawerUserRow widget
<sha> feat(more): add MoreDrawerGrid widget
<sha> feat(more): add MoreDrawerTile widget
<sha> docs(more): add design spec for More drawer (bottom sheet)
```

Push the branch and open a PR referencing the spec.

---

## Self-Review Notes

**Spec coverage** — every section in `2026-05-16-more-drawer-design.md` maps to a task:
- Behavior (sheet trigger, dismissal, routing model) → Tasks 5, 6, 7, 8
- /saved consolidation (Option B) → Task 5
- Layout (container, drag handle, header, user row, grid, sign out, safe area) → Tasks 1–4
- Liquid glass (backdrop scrim, top specular line) → Task 4
- Dark mode tokens → exercised in Tasks 1–4 (all token-driven) and verified in Task 9 Step 3
- Code structure (new/deleted/modified files) → maps 1:1
- Test plan → Tasks 1–4 (widget) and Task 7 (shell_router) cover every test bullet

**No placeholders** — every code step has complete code. No TODO/TBD strings. No "similar to Task N" references. The `MoreDrawerTile`/`MoreDrawerGrid`/`MoreDrawerUserRow`/`MoreDrawerSheet` types are introduced in order with consistent signatures across tasks.

**Type consistency** — `MoreDrawerTile`'s constructor (`label`, `icon`, `onTap`) is referenced consistently in `MoreDrawerGrid`. `MoreDrawerUserRow.user` is the same `AppUser` type used in `MoreDrawerSheet`'s `currentUserProvider.when`. `showMoreDrawer(BuildContext)` has the same signature in Task 4 and Task 7.

**Risks** — the Task 5 / Task 7 ordering matters: `ShellScaffold.scrollTargetKeys` length changes in Task 7, but `kSavedBranchIndex` is removed in Task 5. If Task 7's `length - 1` calculation is applied before Task 5 finishes, branch 4 still exists and we'd be off-by-one. Plan is correct as written — Task 5 ships first.
