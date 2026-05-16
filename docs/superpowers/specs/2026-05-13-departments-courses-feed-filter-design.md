# Departments → Courses → Feed Filter Flow

**Date:** 2026-05-13
**Status:** Approved

---

## Overview

Wire up the existing DepartmentsScreen so department tiles navigate to a new CoursesScreen, and course taps switch to the Feed tab with the selected course pre-set in a new unified feed filter. Replace the tag-based FilterPickerWidget with a new FeedFilterDrawer that supports sort order, year, module, and course filtering.

---

## Architecture

### New files

| File | Purpose |
|---|---|
| `features/departments/presentation/screens/courses_screen.dart` | New CoursesScreen widget |
| `features/feed/presentation/providers/feed_filter_provider.dart` | FeedFilterState + FeedFilterNotifier |
| `features/feed/presentation/widgets/feed_filter_drawer.dart` | New filter bottom sheet |

### Modified files

| File | Change |
|---|---|
| `features/departments/presentation/screens/departments_screen.dart` | Pass `id` to `_DepartmentTile`; add tap → push courses route |
| `core/router/router.dart` | Nest `GoRoute(path: ':deptId')` under `departments` |
| `features/feed/presentation/screens/feed_screen.dart` | Swap `activeTagFiltersProvider` → `feedFilterProvider`; rewire filter drawer |

### Deleted files

| File | Reason |
|---|---|
| `features/feed/presentation/providers/active_tag_filters_provider.dart` | Replaced by `feedFilterProvider` |
| `features/feed/presentation/widgets/filter_picker_widget.dart` | Replaced by `FeedFilterDrawer` |

---

## Data Model

### FeedFilterState

Plain Dart class (no Freezed — no serialisation needed):

```dart
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
  final int? year;          // null = all years
  final String? courseId;   // null = all courses
  final String? courseName; // display name only — for drawer selected state
  final String? moduleNumber; // null = all modules

  int get activeCount =>
      (year != null ? 1 : 0) +
      (courseId != null ? 1 : 0) +
      (moduleNumber != null ? 1 : 0);

  // Nullable copyWith uses a private sentinel so callers can explicitly pass null
  // to clear a field (e.g. copyWith(courseId: null)) vs. omitting the arg.
  FeedFilterState copyWith({
    FeedSortOrder? sortOrder,
    Object? year = _sentinel,       // pass null to clear
    Object? courseId = _sentinel,
    Object? courseName = _sentinel,
    Object? moduleNumber = _sentinel,
  });
}

const Object _sentinel = Object();
```

### FeedFilterNotifier

`@riverpod` class in `feed_filter_provider.dart`:

```dart
@riverpod
class FeedFilter extends _$FeedFilter {
  @override
  FeedFilterState build() => const FeedFilterState();

  void setCourse(String? courseId, String? courseName) => ...
  void setYear(int? year) => ...
  void setModule(String? moduleNumber) => ...
  void setSortOrder(FeedSortOrder order) => ...
  void clear() => state = const FeedFilterState();
}
```

---

## CoursesScreen

**Route:** `/more/departments/:deptId?name=<encoded dept name>`

**Constructor:** `CoursesScreen({required String deptId, required String departmentName})`

**Structure:**
- `Scaffold` with `AppBar(title: Text(departmentName))`
- `DefaultTabController(length: 4)` wrapping a `TabBar` with tabs "Year 1" … "Year 4" (pinned, `indicatorColor: ac.amber`)
- `TabBarView` — each tab watches `coursesProvider(deptId, tabIndex + 1)`
- Each tab body: `AsyncValue.when` — loading spinner, error text, data list
- List: `ListView.builder` of course tiles (same visual style as `_DepartmentTile` — surface card, `Icons.book_outlined` icon, course name, trailing `Icons.chevron_right`)
- Empty state: `"No courses for Year X."` in `ac.textMuted`
- Course tile tap:
  ```dart
  ref.read(feedFilterProvider.notifier).setCourse(course.id, course.name);
  context.go('/feed');
  ```

---

## Router

Nest a `:deptId` child route under the existing `departments` route:

```dart
GoRoute(
  path: 'departments',
  builder: (_, __) => const DepartmentsScreen(),
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

---

## DepartmentsScreen

`_DepartmentTile` gains an `id` parameter. Tile is wrapped in `GestureDetector`:

```dart
onTap: () => context.push(
  '/more/departments/${dept.id}?name=${Uri.encodeComponent(dept.name)}',
),
```

The `departmentsProvider` already returns `({String id, String name})` records — no data-layer change needed.

---

## Feed Filtering

### FeedScreen changes

- Replace `ref.watch(activeTagFiltersProvider)` → `ref.watch(feedFilterProvider)`
- `activeFilterCount` → `filter.activeCount`
- `_openFilterPicker(allPosts, activeTagFilters)` → `_openFilterDrawer(allPosts, filter)`
- `FeedEmptyStateWidget.onClear` → `ref.read(feedFilterProvider.notifier).clear()`

### Client-side filter chain (order matters)

1. **Tab** — ALL / NOTES / EXERCISES (existing logic, unchanged)
2. **Year** — `filter.year != null` → `p.year == filter.year`
3. **Course** — `filter.courseId != null` → `p.courseId == filter.courseId`
4. **Module** — `filter.moduleNumber != null` → `p.moduleNumber == filter.moduleNumber`
5. **Search query** — existing title/description/#tag search (unchanged)

No Firestore index changes — all filtering is client-side.

---

## FeedFilterDrawer

**Shown via:** `showModalBottomSheet(isScrollControlled: true, ...)`

**Layout (top to bottom):**

1. **Sort toggle** — two equal-width outlined buttons: RECENT (amber border + amber-tinted bg when selected) and TRENDING (grayed out, 40% opacity, non-tappable)
2. **Year + Module row** — two equal-width dropdowns side by side
   - Year: options "All years", "Year 1" … "Year 4"
   - Module: options "All modules" + unique `moduleNumber` values collected from loaded posts (filtered by active year + course selections)
3. **Course row** — full-width dropdown
   - Options: "All courses" + courses from `coursesProvider(user.departmentId, filter.year ?? 1)`
   - The user's `departmentId` is read from `authStateProvider`
   - If `departmentId` is null (no academic profile), shows "All courses" only
   - When arriving from Departments → CoursesScreen tap, this field is pre-selected with the tapped course
4. **Action row** — two equal-width buttons
   - **Clear** — outlined; immediately calls `feedFilterProvider.notifier.clear()` and dismisses the sheet (no Apply needed)
   - **Apply** — amber fill, black text; commits drawer local selections to `feedFilterProvider` and dismisses the sheet

**Dropdown implementation:** `showModalBottomSheet` sub-sheets or `DropdownButton` — use `showModalBottomSheet` for the sub-pickers to stay consistent with the existing sheet pattern.

---

## Filters Badge

The `_FiltersButton` in `FeedScreen` currently shows `activeTagFilters.length`. Replace with `filter.activeCount` (counts non-null year + courseId + moduleNumber).

---

## Acceptance Criteria

- [ ] Tapping a department tile navigates to `/more/departments/:deptId` showing courses grouped by year tabs
- [ ] Year tabs default to Year 1; switching tabs reloads courses for that year
- [ ] Tapping a course switches to the Feed tab with `feedFilterProvider.courseId` set; Filters badge shows 1
- [ ] Opening the filter drawer shows RECENT/TRENDING sort, Year/Module/Course dropdowns
- [ ] Course dropdown always pre-populates from `user.departmentId + selected year`; pre-selects the course when arriving from departments flow
- [ ] Apply commits selections; Clear resets all; badge reflects `activeCount`
- [ ] TRENDING button is visible but non-interactive
- [ ] `activeTagFiltersProvider` and `FilterPickerWidget` are deleted with no remaining references
- [ ] `flutter analyze` passes; all existing tests pass
