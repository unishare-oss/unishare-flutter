# Departments → Courses → Feed Filter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire DepartmentsScreen tiles to a new CoursesScreen, let course taps switch to the Feed tab with the course pre-selected, and replace the tag-based FilterPickerWidget with a new FeedFilterDrawer (sort toggle + Year/Module/Course dropdowns).

**Architecture:** A new `FeedFilterState` / `FeedFilterNotifier` is the single source of truth for all feed filter state — it replaces `activeTagFiltersProvider`. `CoursesScreen` writes to this notifier before navigating to `/feed`. `FeedFilterDrawer` is a `ConsumerStatefulWidget` bottom sheet that holds local draft state and commits it on Apply.

**Tech Stack:** Flutter, Riverpod (riverpod_annotation / build_runner), GoRouter, `coursesProvider` (existing family provider in `course_reference_provider.dart`), `authStateProvider`.

**Spec:** `docs/superpowers/specs/2026-05-13-departments-courses-feed-filter-design.md`

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| CREATE | `lib/features/feed/presentation/providers/feed_filter_provider.dart` | `FeedFilterState` value class + `FeedFilterNotifier` |
| CREATE | `lib/features/departments/presentation/screens/courses_screen.dart` | CoursesScreen with year tabs |
| CREATE | `lib/features/feed/presentation/widgets/feed_filter_drawer.dart` | New filter bottom sheet |
| MODIFY | `lib/features/departments/presentation/screens/departments_screen.dart` | Add tap handler on tiles |
| MODIFY | `lib/core/router/router.dart` | Nest `:deptId` route under `departments` |
| MODIFY | `lib/features/feed/presentation/screens/feed_screen.dart` | Swap to `feedFilterProvider`, rewire drawer |
| MODIFY | `lib/features/feed/presentation/widgets/feed_empty_state_widget.dart` | Update copy to not mention tags |
| DELETE | `lib/features/feed/presentation/providers/active_tag_filters_provider.dart` | Replaced by `feedFilterProvider` |
| DELETE | `lib/features/feed/presentation/widgets/filter_picker_widget.dart` | Replaced by `FeedFilterDrawer` |
| CREATE | `test/unit/features/feed/providers/feed_filter_provider_test.dart` | Unit tests for state + notifier |
| MODIFY | `test/widget/features/departments/screens/departments_screen_test.dart` | Fix stale test + add tile rendering |
| CREATE | `test/widget/features/departments/screens/courses_screen_test.dart` | Widget tests for CoursesScreen |
| CREATE | `test/widget/features/feed/feed_filter_drawer_test.dart` | Widget tests for FeedFilterDrawer |
| MODIFY | `test/widget/feed/feed_screen_test.dart` | Update filter-related tests |

All Flutter commands run from `apps/mobile/`. Prefix every command below with `cd apps/mobile &&`.

---

## Task 1: FeedFilterState + FeedFilterNotifier

**Files:**
- Create: `lib/features/feed/presentation/providers/feed_filter_provider.dart`
- Create: `test/unit/features/feed/providers/feed_filter_provider_test.dart`

- [ ] **Step 1.1: Create the test file**

```dart
// test/unit/features/feed/providers/feed_filter_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/feed/presentation/providers/feed_filter_provider.dart';

ProviderContainer _container() => ProviderContainer();

void main() {
  group('FeedFilterState.activeCount', () {
    test('is 0 when no filters set', () {
      expect(const FeedFilterState().activeCount, 0);
    });

    test('counts year, courseId, moduleNumber independently', () {
      const state = FeedFilterState(year: 2, courseId: 'CSC101', moduleNumber: 'M3');
      expect(state.activeCount, 3);
    });

    test('sortOrder does not contribute to activeCount', () {
      const state = FeedFilterState(sortOrder: FeedSortOrder.recent);
      expect(state.activeCount, 0);
    });

    test('courseName does not contribute to activeCount', () {
      const state = FeedFilterState(courseId: 'CSC101', courseName: 'Calculus I');
      expect(state.activeCount, 1);
    });
  });

  group('FeedFilterNotifier', () {
    test('builds with empty FeedFilterState', () {
      final c = _container();
      addTearDown(c.dispose);
      expect(c.read(feedFilterProvider), const FeedFilterState());
    });

    test('setCourse sets courseId and courseName', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(feedFilterProvider.notifier).setCourse('CSC101', 'Calculus');
      final state = c.read(feedFilterProvider);
      expect(state.courseId, 'CSC101');
      expect(state.courseName, 'Calculus');
    });

    test('setCourse with null clears course fields', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(feedFilterProvider.notifier).setCourse('CSC101', 'Calculus');
      c.read(feedFilterProvider.notifier).setCourse(null, null);
      final state = c.read(feedFilterProvider);
      expect(state.courseId, isNull);
      expect(state.courseName, isNull);
    });

    test('setYear sets year', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(feedFilterProvider.notifier).setYear(3);
      expect(c.read(feedFilterProvider).year, 3);
    });

    test('setModule sets moduleNumber', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(feedFilterProvider.notifier).setModule('M2');
      expect(c.read(feedFilterProvider).moduleNumber, 'M2');
    });

    test('clear resets to default FeedFilterState', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(feedFilterProvider.notifier).setCourse('CSC101', 'Calculus');
      c.read(feedFilterProvider.notifier).setYear(2);
      c.read(feedFilterProvider.notifier).clear();
      expect(c.read(feedFilterProvider), const FeedFilterState());
    });
  });
}
```

- [ ] **Step 1.2: Run tests — expect them to fail (file doesn't exist yet)**

```bash
cd apps/mobile && flutter test test/unit/features/feed/providers/feed_filter_provider_test.dart
```
Expected: compile error — `feed_filter_provider.dart` not found.

- [ ] **Step 1.3: Create the provider file**

```dart
// lib/features/feed/presentation/providers/feed_filter_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_filter_provider.g.dart';

enum FeedSortOrder { recent }

class FeedFilterState {
  const FeedFilterState({
    this.sortOrder = FeedSortOrder.recent,
    this.year,
    this.courseId,
    this.courseName,
    this.moduleNumber,
  });

  final FeedSortOrder sortOrder;
  final int? year;
  final String? courseId;
  final String? courseName;
  final String? moduleNumber;

  int get activeCount =>
      (year != null ? 1 : 0) +
      (courseId != null ? 1 : 0) +
      (moduleNumber != null ? 1 : 0);

  @override
  bool operator ==(Object other) =>
      other is FeedFilterState &&
      other.sortOrder == sortOrder &&
      other.year == year &&
      other.courseId == courseId &&
      other.courseName == courseName &&
      other.moduleNumber == moduleNumber;

  @override
  int get hashCode =>
      Object.hash(sortOrder, year, courseId, courseName, moduleNumber);
}

@riverpod
class FeedFilter extends _$FeedFilter {
  @override
  FeedFilterState build() => const FeedFilterState();

  void setCourse(String? courseId, String? courseName) {
    state = FeedFilterState(
      sortOrder: state.sortOrder,
      year: state.year,
      courseId: courseId,
      courseName: courseName,
      moduleNumber: state.moduleNumber,
    );
  }

  void setYear(int? year) {
    state = FeedFilterState(
      sortOrder: state.sortOrder,
      year: year,
      courseId: state.courseId,
      courseName: state.courseName,
      moduleNumber: state.moduleNumber,
    );
  }

  void setModule(String? moduleNumber) {
    state = FeedFilterState(
      sortOrder: state.sortOrder,
      year: state.year,
      courseId: state.courseId,
      courseName: state.courseName,
      moduleNumber: moduleNumber,
    );
  }

  void setSortOrder(FeedSortOrder order) {
    state = FeedFilterState(
      sortOrder: order,
      year: state.year,
      courseId: state.courseId,
      courseName: state.courseName,
      moduleNumber: state.moduleNumber,
    );
  }

  void clear() => state = const FeedFilterState();
}
```

- [ ] **Step 1.4: Run codegen**

```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```
Expected: generates `lib/features/feed/presentation/providers/feed_filter_provider.g.dart` with no errors.

- [ ] **Step 1.5: Run tests — expect them to pass**

```bash
cd apps/mobile && flutter test test/unit/features/feed/providers/feed_filter_provider_test.dart
```
Expected: All 9 tests pass.

- [ ] **Step 1.6: Commit**

```bash
git add lib/features/feed/presentation/providers/feed_filter_provider.dart \
        lib/features/feed/presentation/providers/feed_filter_provider.g.dart \
        test/unit/features/feed/providers/feed_filter_provider_test.dart
git commit -m "feat(feed): add FeedFilterState and FeedFilterNotifier"
```

---

## Task 2: Wire DepartmentsScreen tile taps

**Files:**
- Modify: `lib/features/departments/presentation/screens/departments_screen.dart`
- Modify: `test/widget/features/departments/screens/departments_screen_test.dart`

- [ ] **Step 2.1: Update the test file**

Replace the entire contents of `test/widget/features/departments/screens/departments_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/departments_provider.dart';
import 'package:unishare_mobile/features/departments/presentation/screens/departments_screen.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

Widget _buildSubject({
  List<({String id, String name})> departments = const [],
}) {
  return ProviderScope(
    overrides: [
      departmentsProvider.overrideWith((_) => Stream.value(departments)),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: const DepartmentsScreen(),
    ),
  );
}

void main() {
  testWidgets('renders "Departments" title', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('Departments'), findsOneWidget);
  });

  testWidgets('shows empty state when no departments', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('No departments found.'), findsOneWidget);
  });

  testWidgets('renders department names', (tester) async {
    await tester.pumpWidget(_buildSubject(departments: [
      (id: 'eng', name: 'Engineering'),
      (id: 'sci', name: 'Science'),
    ]));
    await tester.pump();
    expect(find.text('Engineering'), findsOneWidget);
    expect(find.text('Science'), findsOneWidget);
  });

  testWidgets('department tiles are tappable (GestureDetector present)', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject(departments: [
      (id: 'eng', name: 'Engineering'),
    ]));
    await tester.pump();
    expect(find.byType(GestureDetector), findsWidgets);
  });
}
```

- [ ] **Step 2.2: Run new tests — 3 pass, 1 fails (no GestureDetector yet)**

```bash
cd apps/mobile && flutter test test/widget/features/departments/screens/departments_screen_test.dart
```
Expected: "department tiles are tappable" fails.

- [ ] **Step 2.3: Update DepartmentsScreen to add tap handlers**

Replace the `itemBuilder` lambda in `departments_screen.dart`. The list builder currently is:
```dart
itemBuilder: (context, index) =>
    _DepartmentTile(name: departments[index].name),
```

Replace with:
```dart
itemBuilder: (context, index) {
  final dept = departments[index];
  return GestureDetector(
    onTap: () => context.push(
      '/more/departments/${dept.id}'
      '?name=${Uri.encodeComponent(dept.name)}',
    ),
    child: _DepartmentTile(name: dept.name),
  );
},
```

Also add the GoRouter import at the top of `departments_screen.dart`:
```dart
import 'package:go_router/go_router.dart';
```

- [ ] **Step 2.4: Run tests — expect all 4 to pass**

```bash
cd apps/mobile && flutter test test/widget/features/departments/screens/departments_screen_test.dart
```
Expected: All 4 tests pass.

- [ ] **Step 2.5: Commit**

```bash
git add lib/features/departments/presentation/screens/departments_screen.dart \
        test/widget/features/departments/screens/departments_screen_test.dart
git commit -m "feat(departments): wire department tile taps to courses route"
```

---

## Task 3: Router — add `:deptId` nested route

**Files:**
- Modify: `lib/core/router/router.dart`

- [ ] **Step 3.1: Add the import for CoursesScreen at the top of router.dart**

Find the block of import statements near the top of `lib/core/router/router.dart` and add:
```dart
import 'package:unishare_mobile/features/departments/presentation/screens/courses_screen.dart';
```

- [ ] **Step 3.2: Nest the `:deptId` GoRoute under `departments`**

In `router.dart`, find this block:
```dart
GoRoute(
  path: 'departments',
  builder: (context, state) => const DepartmentsScreen(),
),
```

Replace it with:
```dart
GoRoute(
  path: 'departments',
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
```

- [ ] **Step 3.3: Analyze — expect no errors (CoursesScreen doesn't exist yet, so this will fail)**

```bash
cd apps/mobile && flutter analyze
```
Expected: error about `CoursesScreen` not found. That's fine — it will be created in Task 4.

- [ ] **Step 3.4: Commit the router change (stash-free — just the router)**

```bash
git add lib/core/router/router.dart
git commit -m "feat(router): add :deptId nested route under departments"
```

---

## Task 4: CoursesScreen

**Files:**
- Create: `lib/features/departments/presentation/screens/courses_screen.dart`
- Create: `test/widget/features/departments/screens/courses_screen_test.dart`

- [ ] **Step 4.1: Create the test file**

```dart
// test/widget/features/departments/screens/courses_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/departments/presentation/screens/courses_screen.dart';
import 'package:unishare_mobile/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

Widget _buildSubject({
  List<({String id, String name})> year1Courses = const [],
}) {
  return ProviderScope(
    overrides: [
      coursesProvider('dept1', 1).overrideWith((_) async => year1Courses),
      coursesProvider('dept1', 2).overrideWith((_) async => const []),
      coursesProvider('dept1', 3).overrideWith((_) async => const []),
      coursesProvider('dept1', 4).overrideWith((_) async => const []),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: const CoursesScreen(
        deptId: 'dept1',
        departmentName: 'Engineering',
      ),
    ),
  );
}

void main() {
  testWidgets('shows department name in AppBar', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('Engineering'), findsOneWidget);
  });

  testWidgets('shows four year tabs', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    for (final label in ['Year 1', 'Year 2', 'Year 3', 'Year 4']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('shows course names when courses exist', (tester) async {
    await tester.pumpWidget(_buildSubject(year1Courses: [
      (id: 'c1', name: 'Calculus I'),
      (id: 'c2', name: 'Programming I'),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('Calculus I'), findsOneWidget);
    expect(find.text('Programming I'), findsOneWidget);
  });

  testWidgets('shows empty state when no courses for year', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();
    expect(find.text('No courses for Year 1.'), findsOneWidget);
  });

  testWidgets('course tiles are tappable', (tester) async {
    await tester.pumpWidget(_buildSubject(year1Courses: [
      (id: 'c1', name: 'Calculus I'),
    ]));
    await tester.pumpAndSettle();
    expect(find.byType(GestureDetector), findsWidgets);
  });
}
```

- [ ] **Step 4.2: Run tests — expect compile failure (screen not created yet)**

```bash
cd apps/mobile && flutter test test/widget/features/departments/screens/courses_screen_test.dart
```
Expected: compile error — `courses_screen.dart` not found.

- [ ] **Step 4.3: Create CoursesScreen**

```dart
// lib/features/departments/presentation/screens/courses_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({
    super.key,
    required this.deptId,
    required this.departmentName,
  });

  final String deptId;
  final String departmentName;

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedYear = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedYear = _tabController.index + 1);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final cs = theme.colorScheme;
    final coursesAsync = ref.watch(
      coursesProvider(widget.deptId, _selectedYear),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.departmentName),
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ac.amber,
          labelColor: ac.amber,
          unselectedLabelColor: ac.textMuted,
          labelStyle: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Year 1'),
            Tab(text: 'Year 2'),
            Tab(text: 'Year 3'),
            Tab(text: 'Year 4'),
          ],
        ),
      ),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load courses.',
            style: theme.textTheme.bodyMedium?.copyWith(color: ac.textMuted),
          ),
        ),
        data: (courses) {
          if (courses.isEmpty) {
            return Center(
              child: Text(
                'No courses for Year $_selectedYear.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ac.textMuted,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final course = courses[index];
              return GestureDetector(
                onTap: () {
                  ref
                      .read(feedFilterProvider.notifier)
                      .setCourse(course.id, course.name);
                  context.go('/feed');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ac.muted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.book_outlined,
                          size: 20,
                          color: ac.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          course.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: ac.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4.4: Run analyze — should pass now that CoursesScreen exists**

```bash
cd apps/mobile && flutter analyze
```
Expected: no errors.

- [ ] **Step 4.5: Run tests — expect all 5 to pass**

```bash
cd apps/mobile && flutter test test/widget/features/departments/screens/courses_screen_test.dart
```
Expected: All 5 tests pass.

- [ ] **Step 4.6: Commit**

```bash
git add lib/features/departments/presentation/screens/courses_screen.dart \
        test/widget/features/departments/screens/courses_screen_test.dart
git commit -m "feat(departments): add CoursesScreen with year tabs"
```

---

## Task 5: FeedFilterDrawer

**Files:**
- Create: `lib/features/feed/presentation/widgets/feed_filter_drawer.dart`
- Create: `test/widget/features/feed/feed_filter_drawer_test.dart`

- [ ] **Step 5.1: Create the test file**

```dart
// test/widget/features/feed/feed_filter_drawer_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:unishare_mobile/features/feed/presentation/widgets/feed_filter_drawer.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> get authStateChanges => Stream.value(null);
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
  Future<void> signOut() async {}
  @override
  Future<AppUser?> getCurrentUser() async => null;
  @override
  Future<void> updateAcademicProfile({
    required String uid,
    required String departmentId,
    int? enrollmentYear,
  }) async {}
}

Post _post({required String id, required String courseId, int year = 1, String moduleNumber = ''}) =>
    Post(
      id: id,
      authorId: 'uid',
      authorName: 'Test',
      authorAvatar: '',
      postType: PostType.lectureNote,
      year: year,
      courseId: courseId,
      title: 'Title',
      description: '',
      postingIdentity: PostingIdentity.named,
      semester: 1,
      moduleNumber: moduleNumber,
      mediaUrls: const [],
      tags: const [],
      likesCount: 0,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Widget _buildSubject({List<Post> posts = const []}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: Scaffold(
        body: FeedFilterDrawer(loadedPosts: posts),
      ),
    ),
  );
}

void main() {
  testWidgets('renders "Filter posts" title', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('Filter posts'), findsOneWidget);
  });

  testWidgets('renders RECENT and TRENDING sort buttons', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('RECENT'), findsOneWidget);
    expect(find.text('TRENDING'), findsOneWidget);
  });

  testWidgets('renders Clear and Apply action buttons', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
  });

  testWidgets('tapping Clear calls feedFilterProvider.clear()', (tester) async {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    ]);
    addTearDown(container.dispose);

    container.read(feedFilterProvider.notifier).setYear(2);
    expect(container.read(feedFilterProvider).year, 2);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: Scaffold(
            body: FeedFilterDrawer(loadedPosts: const []),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Clear'));
    await tester.pump();

    expect(container.read(feedFilterProvider), const FeedFilterState());
  });
}
```

- [ ] **Step 5.2: Run tests — expect compile failure**

```bash
cd apps/mobile && flutter test test/widget/features/feed/feed_filter_drawer_test.dart
```
Expected: compile error — `feed_filter_drawer.dart` not found.

- [ ] **Step 5.3: Create FeedFilterDrawer**

```dart
// lib/features/feed/presentation/widgets/feed_filter_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class FeedFilterDrawer extends ConsumerStatefulWidget {
  const FeedFilterDrawer({super.key, required this.loadedPosts});

  final List<Post> loadedPosts;

  static Future<void> show(BuildContext context, List<Post> loadedPosts) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FeedFilterDrawer(loadedPosts: loadedPosts),
    );
  }

  @override
  ConsumerState<FeedFilterDrawer> createState() => _FeedFilterDrawerState();
}

class _FeedFilterDrawerState extends ConsumerState<FeedFilterDrawer> {
  late FeedSortOrder _sortOrder;
  int? _year;
  String? _courseId;
  String? _courseName;
  String? _moduleNumber;

  @override
  void initState() {
    super.initState();
    final current = ref.read(feedFilterProvider);
    _sortOrder = current.sortOrder;
    _year = current.year;
    _courseId = current.courseId;
    _courseName = current.courseName;
    _moduleNumber = current.moduleNumber;
  }

  List<String> _moduleOptions() {
    var posts = widget.loadedPosts;
    if (_year != null) posts = posts.where((p) => p.year == _year).toList();
    if (_courseId != null) {
      posts = posts.where((p) => p.courseId == _courseId).toList();
    }
    return posts
        .map((p) => p.moduleNumber)
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  void _apply() {
    final notifier = ref.read(feedFilterProvider.notifier);
    notifier.setSortOrder(_sortOrder);
    notifier.setYear(_year);
    notifier.setCourse(_courseId, _courseName);
    notifier.setModule(_moduleNumber);
    Navigator.of(context).pop();
  }

  void _clear() {
    ref.read(feedFilterProvider.notifier).clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final cs = theme.colorScheme;
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    final user = ref.watch(authStateProvider).valueOrNull;
    final deptId = user?.departmentId;
    final coursesAsync = deptId != null
        ? ref.watch(coursesProvider(deptId, _year ?? 1))
        : const AsyncData<List<({String id, String name})>>([]);

    final moduleOptions = _moduleOptions();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Filter posts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          // Sort toggle
          Row(
            children: [
              Expanded(
                child: _SortButton(
                  label: 'RECENT',
                  icon: Icons.access_time_outlined,
                  selected: _sortOrder == FeedSortOrder.recent,
                  onTap: () => setState(
                    () => _sortOrder = FeedSortOrder.recent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: _SortButton(
                  label: 'TRENDING',
                  icon: Icons.trending_up,
                  selected: false,
                  enabled: false,
                  onTap: null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Year + Module row
          Row(
            children: [
              Expanded(
                child: _DropdownField<int?>(
                  value: _year,
                  hint: 'All years',
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All years'),
                    ),
                    for (int y = 1; y <= 4; y++)
                      DropdownMenuItem(value: y, child: Text('Year $y')),
                  ],
                  onChanged: (v) => setState(() {
                    _year = v;
                    _moduleNumber = null;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownField<String?>(
                  value: _moduleNumber,
                  hint: 'All modules',
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All modules'),
                    ),
                    for (final m in moduleOptions)
                      DropdownMenuItem(value: m, child: Text(m)),
                  ],
                  onChanged: moduleOptions.isEmpty
                      ? null
                      : (v) => setState(() => _moduleNumber = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Course dropdown
          coursesAsync.when(
            loading: () => const _DropdownField<String?>(
              value: null,
              hint: 'Loading...',
              items: [],
              onChanged: null,
            ),
            error: (_, __) => const _DropdownField<String?>(
              value: null,
              hint: 'All courses',
              items: [
                DropdownMenuItem(value: null, child: Text('All courses')),
              ],
              onChanged: null,
            ),
            data: (courses) => _DropdownField<String?>(
              value: _courseId,
              hint: 'All courses',
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All courses'),
                ),
                for (final c in courses)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() {
                _courseId = v;
                _courseName = v == null
                    ? null
                    : courses.firstWhere((c) => c.id == v).name;
                _moduleNumber = null;
              }),
            ),
          ),
          const SizedBox(height: 24),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ac.mutedForeground,
                    side: BorderSide(color: theme.dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Clear',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ac.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Apply',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.label,
    required this.icon,
    required this.selected,
    this.enabled = true,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final effectiveColor = selected
        ? ac.amber
        : enabled
        ? ac.textMuted
        : ac.textMuted.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? ac.amber : theme.dividerColor,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: selected
              ? ac.amber.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(10),
        color: cs.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(color: ac.textMuted),
          ),
          dropdownColor: cs.surface,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: ac.textMuted,
          ),
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }
}
```

- [ ] **Step 5.4: Run tests — expect all 4 to pass**

```bash
cd apps/mobile && flutter test test/widget/features/feed/feed_filter_drawer_test.dart
```
Expected: All 4 tests pass.

- [ ] **Step 5.5: Commit**

```bash
git add lib/features/feed/presentation/widgets/feed_filter_drawer.dart \
        test/widget/features/feed/feed_filter_drawer_test.dart
git commit -m "feat(feed): add FeedFilterDrawer with sort/year/module/course filters"
```

---

## Task 6: FeedScreen rewire + cleanup

**Files:**
- Modify: `lib/features/feed/presentation/screens/feed_screen.dart`
- Modify: `lib/features/feed/presentation/widgets/feed_empty_state_widget.dart`
- Delete: `lib/features/feed/presentation/providers/active_tag_filters_provider.dart`
- Delete: `lib/features/feed/presentation/widgets/filter_picker_widget.dart`
- Modify: `test/widget/feed/feed_screen_test.dart`

- [ ] **Step 6.1: Update FeedEmptyStateWidget copy**

In `lib/features/feed/presentation/widgets/feed_empty_state_widget.dart`, replace the subtitle text:
```
'Try selecting different tags or clear the filter to see all posts.'
```
with:
```
'Try adjusting your filters or clear them to see all posts.'
```

- [ ] **Step 6.2: Update feed_screen.dart — imports**

In `lib/features/feed/presentation/screens/feed_screen.dart`, replace:
```dart
import 'package:unishare_mobile/features/feed/presentation/providers/active_tag_filters_provider.dart';
```
with:
```dart
import 'package:unishare_mobile/features/feed/presentation/providers/feed_filter_provider.dart';
```

And replace:
```dart
import 'package:unishare_mobile/features/feed/presentation/widgets/filter_picker_widget.dart';
```
with:
```dart
import 'package:unishare_mobile/features/feed/presentation/widgets/feed_filter_drawer.dart';
```

- [ ] **Step 6.3: Update _FeedScreenState — replace activeTagFiltersProvider usage**

In `_FeedScreenState.build`, find:
```dart
final activeTagFilters = ref.watch(activeTagFiltersProvider);
```
Replace with:
```dart
final filter = ref.watch(feedFilterProvider);
```

- [ ] **Step 6.4: Update _filterPosts signature and body**

Replace the entire `_filterPosts` method:
```dart
List<Post> _filterPosts(List<Post> all, FeedFilterState filter) {
  var posts = switch (_tabController.index) {
    1 => all.where((p) => p.postType == PostType.lectureNote).toList(),
    2 => all.where((p) => p.postType == PostType.exercise).toList(),
    _ => all,
  };
  if (filter.year != null) {
    posts = posts.where((p) => p.year == filter.year).toList();
  }
  if (filter.courseId != null) {
    posts = posts.where((p) => p.courseId == filter.courseId).toList();
  }
  if (filter.moduleNumber != null) {
    posts = posts.where((p) => p.moduleNumber == filter.moduleNumber).toList();
  }
  if (_searchQuery.isEmpty) return posts;
  if (_searchQuery.startsWith('#')) {
    final q = _searchQuery.substring(1).toLowerCase();
    return q.isEmpty
        ? posts
        : posts
              .where((p) => p.tags.any((t) => t.toLowerCase().contains(q)))
              .toList();
  }
  final q = _searchQuery.toLowerCase();
  return posts.where((p) {
    return p.title.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q);
  }).toList();
}
```

- [ ] **Step 6.5: Update _openFilterPicker → _openFilterDrawer**

Remove the `_openFilterPicker` method and replace with:
```dart
void _openFilterDrawer(List<Post> allPosts) {
  FeedFilterDrawer.show(context, allPosts);
}
```

- [ ] **Step 6.6: Update all call sites in build()**

In `build()`, find:
```dart
final activeTagFilters = ref.watch(activeTagFiltersProvider);
```
(should already be replaced in Step 6.3)

Find:
```dart
activeFilterCount: activeTagFilters.length,
onFiltersPressed: () =>
    _openFilterPicker(feedAsync.value ?? [], activeTagFilters),
```
Replace with:
```dart
activeFilterCount: filter.activeCount,
onFiltersPressed: () => _openFilterDrawer(feedAsync.value ?? []),
```

Find:
```dart
final posts = _filterPosts(allPosts, activeTagFilters);
```
Replace with:
```dart
final posts = _filterPosts(allPosts, filter);
```

Find:
```dart
return FeedEmptyStateWidget(
  onClear: () =>
      ref.read(activeTagFiltersProvider.notifier).clear(),
);
```
Replace with:
```dart
return FeedEmptyStateWidget(
  onClear: () => ref.read(feedFilterProvider.notifier).clear(),
);
```

Also remove the `_buildSuggestions` call parameter that previously used `activeTagFilters` if present — check the full method doesn't still reference it.

- [ ] **Step 6.7: Delete the old files**

```bash
rm apps/mobile/lib/features/feed/presentation/providers/active_tag_filters_provider.dart
rm apps/mobile/lib/features/feed/presentation/providers/active_tag_filters_provider.g.dart
rm apps/mobile/lib/features/feed/presentation/widgets/filter_picker_widget.dart
```

- [ ] **Step 6.8: Update feed_screen_test.dart — fix broken filter tests**

Add these imports to `test/widget/feed/feed_screen_test.dart` (near the existing imports):
```dart
import 'package:unishare_mobile/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:unishare_mobile/features/feed/presentation/widgets/feed_filter_drawer.dart';
```

Add this helper class near the top of the test file (alongside `_GuestModeOn`):
```dart
class _PresetFeedFilter extends FeedFilter {
  _PresetFeedFilter(this._initial);
  final FeedFilterState _initial;
  @override
  FeedFilterState build() => _initial;
}
```

Update `_buildSubject` to accept an optional feed filter override:
```dart
Widget _buildSubject({
  bool guestMode = false,
  FeedFilterState feedFilter = const FeedFilterState(),
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      if (guestMode) guestModeProvider.overrideWith(() => _GuestModeOn()),
      feedProvider.overrideWith((_) => Stream.value(_mockFeed)),
      feedFilterProvider.overrideWith(() => _PresetFeedFilter(feedFilter)),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: FeedScreen(scrollKey: GlobalKey()),
    ),
  );
}
```

Replace the three stale filter tests (the ones that reference "Filter by tags", "Confirm", `InkWell` with tag name) with:
```dart
testWidgets('tapping Filters button opens filter drawer', (tester) async {
  await tester.pumpWidget(_buildSubject());
  await tester.pump();

  await tester.tap(find.text('Filters'));
  await tester.pumpAndSettle();

  expect(find.text('Filter posts'), findsOneWidget);
});

testWidgets('filter drawer shows Clear and Apply buttons', (tester) async {
  await tester.pumpWidget(_buildSubject());
  await tester.pump();

  await tester.tap(find.text('Filters'));
  await tester.pumpAndSettle();

  expect(find.text('Clear'), findsOneWidget);
  expect(find.text('Apply'), findsOneWidget);
});

testWidgets('courseId filter shows only matching posts', (tester) async {
  // CSC233 has 2 posts: 'LR Parsing' (note) + 'Assignment 9' (exercise)
  await tester.pumpWidget(_buildSubject(
    feedFilter: const FeedFilterState(courseId: 'CSC233', courseName: 'CS'),
  ));
  await tester.pump();

  expect(find.byType(PostCard), findsNWidgets(2));
  expect(find.text('LR Parsing'), findsOneWidget);
});

testWidgets('no-match courseId filter shows empty state widget', (tester) async {
  await tester.pumpWidget(_buildSubject(
    feedFilter: const FeedFilterState(courseId: 'NO_MATCH', courseName: 'x'),
  ));
  await tester.pump();

  expect(find.byType(FeedEmptyStateWidget), findsOneWidget);
});
```

- [ ] **Step 6.9: Run analyze — expect no errors**

```bash
cd apps/mobile && flutter analyze
```
Expected: no errors or warnings referencing deleted files.

- [ ] **Step 6.10: Run the full test suite**

```bash
cd apps/mobile && flutter test
```
Expected: All tests pass. If any test fails due to `active_tag_filters_provider` references in other test files, grep for them and fix:
```bash
grep -r "activeTagFiltersProvider\|FilterPickerWidget\|filter_picker_widget" apps/mobile/test --include="*.dart"
```

- [ ] **Step 6.11: Final commit**

```bash
git add lib/features/feed/presentation/screens/feed_screen.dart \
        lib/features/feed/presentation/widgets/feed_empty_state_widget.dart \
        test/widget/feed/feed_screen_test.dart
git commit -m "feat(feed): replace tag filter with FeedFilterDrawer and FeedFilterNotifier"
```

---

## Done

All six tasks deliver working software independently. After Task 6, run the full suite one more time and verify the acceptance criteria from the spec:

```bash
cd apps/mobile && flutter test && flutter analyze
```

Check:
- [ ] Department tile → CoursesScreen with year tabs
- [ ] Course tap → Feed tab with Filters badge showing 1
- [ ] Filters drawer → RECENT/TRENDING + Year/Module/Course dropdowns
- [ ] Clear immediately resets filter + dismisses sheet
- [ ] Apply commits selections
- [ ] No references to `activeTagFiltersProvider` or `FilterPickerWidget` anywhere
