# CourseStep Department Selector — Design Spec

**Date:** 2026-05-07  
**Feature branch:** feature/upload-progress  
**Status:** Approved

---

## Problem

Step 2 of the create-post wizard (`CourseStep`) uses a hardcoded in-memory course map. Real department and course data is seeded in Firestore. The widget needs to load live data, add a department selector, and persist the selected department alongside the course in `PostDraft`.

---

## Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Where does Firestore query code live? | New `CourseFirestoreDatasource` in `post/data/datasources/` | Keeps post feature self-contained; mirrors existing `PostFirestoreDatasource` pattern |
| Reuse auth `FirestoreUserDatasource`? | No | Cross-feature coupling; auth datasource serves a different purpose |
| Filter departments by university? | Yes, using `universityId` | Future-proofs multi-tenant; only one uni today so no practical difference yet |
| Add `departmentId` to `PostDraft`? | Yes, required `String` field | Enables future department-scoped queries on posts |
| Offline support? | Firestore SDK disk cache | Free, no Hive needed; graceful degradation on first-time offline |
| `courseId` format? | Document ID only (e.g. `csc201`) | `(departmentId, courseId)` together are globally unique across departments |

---

## Architecture

### New files

```
apps/mobile/lib/features/post/
  data/datasources/course_firestore_datasource.dart
  presentation/providers/course_reference_provider.dart     (+ .g.dart generated)

apps/mobile/test/widget/features/post/widgets/
  course_step_test.dart
```

### Modified files

```
post/domain/entities/post_draft.dart                   — add departmentId field
post/presentation/widgets/course_step.dart             — rewrite as ConsumerWidget
post/presentation/screens/create_post_screen.dart      — add _departmentId state
post/data/datasources/post_firestore_datasource.dart   — write departmentId
test/widget/features/post/screens/create_post_screen_test.dart  — update step-2 flow
test/unit/features/post/fakes/post_factories.dart      — add departmentId to factory
```

---

## Data Layer

### `CourseFirestoreDatasource`

```
getDepartments(universityId: String) → Future<List<({String id, String name})>>
  - If universityId is empty, fetches all departments (graceful fallback)
  - Queries: collection('departments').where('universityId', isEqualTo: universityId)

getCourses(deptId: String, year: int) → Future<List<({String id, String name})>>
  - Queries: departments/{deptId}/courses where yearLevel == year
```

Return type `({String id, String name})` matches the existing auth datasource pattern.

---

## Providers

File: `course_reference_provider.dart`

| Provider | Type | keepAlive | Notes |
|----------|------|-----------|-------|
| `courseFirestoreDatasourceProvider` | Provider | true | Singleton datasource |
| `departmentsForUniversityProvider(universityId)` | FutureProvider family | false (auto-dispose) | Re-fetches when universityId changes |
| `coursesProvider(deptId, year)` | FutureProvider family | false (auto-dispose) | Re-fetches on selection change |

---

## Domain Changes

`PostDraft` gains:
```dart
required this.departmentId,   // String, after courseId
```

`copyWith` gains:
```dart
String? departmentId,
// ...
departmentId: departmentId ?? this.departmentId,
```

`PostFirestoreDatasource.createPost` writes `'departmentId': draft.departmentId`.  
`Post` entity is **not** changed (out of scope).

---

## CourseStep Widget

```
CourseStep (ConsumerWidget)
  Props: universityId, selectedDepartmentId, selectedYear, selectedCourseId,
         onDepartmentChanged, onYearChanged, onCourseChanged

  DEPARTMENT dropdown
    source: departmentsForUniversityProvider(universityId)
    loading → disabled, hint = "Loading…"
    error   → disabled, hint = "Failed to load"
    data    → selectable list

  YEAR dropdown
    source: static [1, 2, 3, 4]
    always enabled

  COURSE dropdown
    source: coursesProvider(deptId, year)   [only watched when both are non-null]
    dept not selected → disabled, hint = "Select a department first"
    year not selected → disabled, hint = "Select a year first"
    loading           → disabled, hint = "Loading…"
    error             → disabled, hint = "Failed to load"
    empty data        → disabled, hint = "No courses found"
    data              → selectable list

  Cascade reset:
    dept changed → year = null, course = null
    year changed → course = null
```

---

## CreatePostScreen Changes

```dart
String? _departmentId;   // new state field

// In build:
final universityId = ref.watch(currentUserProvider).valueOrNull?.universityId ?? '';

// _nextEnabled step 1:
1 => _year != null && _courseId != null && _departmentId != null,

// CourseStep call gains:
universityId: universityId,
selectedDepartmentId: _departmentId,
onDepartmentChanged: (d) => setState(() { _departmentId = d; _year = null; _courseId = null; }),
// onYearChanged updated to also reset _courseId

// PostDraft at submit gains:
departmentId: _departmentId ?? '',
```

---

## Tests

### `create_post_screen_test.dart`
- Add `_StubCourseDatasource` implementing `CourseFirestoreDatasource` with deterministic fake data
- Add `courseFirestoreDatasourceProvider` and `currentUserProvider` overrides to `_makeScreen()`
- Update step-2 interaction in all tests: select department → year → course

### `course_step_test.dart` (new)
Covers: loading state, error state, dept selection enables year, dept+year loads courses, dept change resets year+course, year change resets course, empty-courses state.

---

## Build & Verify

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
flutter analyze
dart format .
flutter test
```
