# CourseStep Department Selector Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hardcoded course list in the create-post wizard's Step 2 with live Firestore data, add a department selector as the first dropdown, and persist `departmentId` in `PostDraft`.

**Architecture:** New `CourseFirestoreDatasource` in the post feature's data layer queries `departments/{deptId}` (filtered by `universityId`) and `departments/{deptId}/courses` (filtered by `yearLevel`). Two auto-dispose family `FutureProvider`s wrap these calls. `CourseStep` is converted to a `ConsumerWidget` with dept→year→course cascade resets. `PostDraft` gains a required `departmentId: String` field.

**Tech Stack:** Flutter, Riverpod (riverpod_annotation codegen), Cloud Firestore, flutter_test / flutter_riverpod ProviderScope overrides.

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/features/post/data/datasources/course_firestore_datasource.dart` | Create | Firestore queries for departments + courses |
| `lib/features/post/presentation/providers/course_reference_provider.dart` | Create | Riverpod providers wrapping the datasource (+ generated `.g.dart`) |
| `lib/features/post/domain/entities/post_draft.dart` | Modify | Add `departmentId: String` field |
| `lib/features/post/presentation/widgets/course_step.dart` | Modify | Rewrite as ConsumerWidget with 3 cascading dropdowns |
| `lib/features/post/presentation/screens/create_post_screen.dart` | Modify | Add `_departmentId` state, pass to CourseStep + PostDraft |
| `lib/features/post/data/datasources/post_firestore_datasource.dart` | Modify | Write `departmentId` when creating a post |
| `test/widget/features/post/widgets/course_step_test.dart` | Create | Widget tests for CourseStep async states + cascade reset |
| `test/widget/features/post/screens/create_post_screen_test.dart` | Modify | Add provider overrides; update step-2 interaction |
| `test/unit/features/post/fakes/post_factories.dart` | Modify | Add `departmentId: ''` to `fakePost` — no, this builds `Post` not `PostDraft` |
| `test/unit/features/post/domain/usecases/create_post_test.dart` | Modify | Add `departmentId: 'dept-cs'` to `_validDraft()` |
| `test/unit/features/post/domain/usecases/sync_draft_queue_test.dart` | Modify | Add `departmentId: 'dept-cs'` to `_draft()` |
| `test/widget/features/post/screens/upload_progress_screen_test.dart` | Modify | Add `departmentId: 'dept-cs'` to inline PostDraft |
| `test/widget/features/post/widgets/draft_queue_indicator_test.dart` | Modify | Add `departmentId: 'dept-cs'` to `_queuedDraft()` |

All paths relative to `apps/mobile/`.

---

## Task 1: Add departmentId to PostDraft and fix all construction sites

**Files:**
- Modify: `apps/mobile/lib/features/post/domain/entities/post_draft.dart`
- Modify: `apps/mobile/test/unit/features/post/domain/usecases/create_post_test.dart:63-76`
- Modify: `apps/mobile/test/unit/features/post/domain/usecases/sync_draft_queue_test.dart:56-71`
- Modify: `apps/mobile/test/widget/features/post/screens/upload_progress_screen_test.dart:66-79`
- Modify: `apps/mobile/test/widget/features/post/widgets/draft_queue_indicator_test.dart:40-54`

- [ ] **Step 1.1: Add `departmentId` to PostDraft**

In `apps/mobile/lib/features/post/domain/entities/post_draft.dart`, add the field after `courseId` in the constructor, the field declaration, and `copyWith`:

```dart
class PostDraft {
  const PostDraft({
    required this.id,
    required this.postType,
    required this.year,
    required this.courseId,
    required this.departmentId,   // ← ADD
    required this.title,
    // ... rest unchanged
  });

  final String id;
  final PostType postType;

  // Step 2
  final int year;
  final String courseId;
  final String departmentId;   // ← ADD

  // ... rest of fields unchanged
```

In `copyWith`, add the parameter and assignment:

```dart
PostDraft copyWith({
  PostType? postType,
  int? year,
  String? courseId,
  String? departmentId,   // ← ADD
  // ... rest unchanged
}) {
  return PostDraft(
    id: id,
    postType: postType ?? this.postType,
    year: year ?? this.year,
    courseId: courseId ?? this.courseId,
    departmentId: departmentId ?? this.departmentId,   // ← ADD
    // ... rest unchanged
  );
}
```

- [ ] **Step 1.2: Fix `create_post_test.dart` — add `departmentId`**

In `apps/mobile/test/unit/features/post/domain/usecases/create_post_test.dart`, update `_validDraft()`:

```dart
PostDraft _validDraft({
  List<String> localMediaPaths = const [],
  String title = 'Test Title',
  String description = 'Test description',
  String moduleNumber = '3',
}) {
  return PostDraft(
    id: 'test-id',
    postType: PostType.lectureNote,
    year: 2,
    courseId: 'csc201',
    departmentId: 'dept-cs',   // ← ADD
    title: title,
    description: description,
    postingIdentity: PostingIdentity.named,
    semester: 1,
    moduleNumber: moduleNumber,
    localMediaPaths: localMediaPaths,
    uploadedUrls: {},
    createdAt: DateTime(2026, 5, 5),
  );
}
```

- [ ] **Step 1.3: Fix `sync_draft_queue_test.dart` — add `departmentId`**

In `apps/mobile/test/unit/features/post/domain/usecases/sync_draft_queue_test.dart`, update `_draft()`:

```dart
PostDraft _draft(String id, {DraftStatus status = DraftStatus.queued}) {
  return PostDraft(
    id: id,
    postType: PostType.lectureNote,
    year: 1,
    courseId: 'csc101',
    departmentId: 'dept-cs',   // ← ADD
    title: 'Title $id',
    description: 'Desc',
    postingIdentity: PostingIdentity.named,
    semester: 1,
    moduleNumber: '1',
    localMediaPaths: [],
    uploadedUrls: {},
    createdAt: DateTime(2026, 5, 5),
    status: status,
  );
}
```

- [ ] **Step 1.4: Fix `upload_progress_screen_test.dart` — add `departmentId`**

In `apps/mobile/test/widget/features/post/screens/upload_progress_screen_test.dart`, find the inline `PostDraft(` and add `departmentId: 'dept-cs',` after `courseId: 'csc101',`.

- [ ] **Step 1.5: Fix `draft_queue_indicator_test.dart` — add `departmentId`**

In `apps/mobile/test/widget/features/post/widgets/draft_queue_indicator_test.dart`, update `_queuedDraft()`:

```dart
PostDraft _queuedDraft(String id) => PostDraft(
  id: id,
  postType: PostType.lectureNote,
  year: 1,
  courseId: 'csc101',
  departmentId: 'dept-cs',   // ← ADD
  title: 'T',
  description: 'D',
  postingIdentity: PostingIdentity.named,
  semester: 1,
  moduleNumber: '1',
  localMediaPaths: [],
  uploadedUrls: {},
  createdAt: DateTime(2026, 5, 5),
  status: DraftStatus.queued,
);
```

- [ ] **Step 1.6: Verify all tests compile and pass**

```bash
cd apps/mobile && flutter test
```

Expected: all existing tests pass (no compilation errors, no new failures).

- [ ] **Step 1.7: Commit**

```bash
git add apps/mobile/lib/features/post/domain/entities/post_draft.dart \
        apps/mobile/test/unit/features/post/domain/usecases/create_post_test.dart \
        apps/mobile/test/unit/features/post/domain/usecases/sync_draft_queue_test.dart \
        apps/mobile/test/widget/features/post/screens/upload_progress_screen_test.dart \
        apps/mobile/test/widget/features/post/widgets/draft_queue_indicator_test.dart
git commit -m "feat(post): add departmentId field to PostDraft"
```

---

## Task 2: Create CourseFirestoreDatasource

**Files:**
- Create: `apps/mobile/lib/features/post/data/datasources/course_firestore_datasource.dart`

- [ ] **Step 2.1: Create the datasource**

Create `apps/mobile/lib/features/post/data/datasources/course_firestore_datasource.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseFirestoreDatasource {
  CourseFirestoreDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<({String id, String name})>> getDepartments(
    String universityId,
  ) async {
    Query<Map<String, dynamic>> query = _firestore.collection('departments');
    if (universityId.isNotEmpty) {
      query = query.where('universityId', isEqualTo: universityId);
    }
    final snap = await query.get();
    return snap.docs
        .map((doc) => (id: doc.id, name: doc.data()['name'] as String? ?? ''))
        .toList();
  }

  Future<List<({String id, String name})>> getCourses(
    String deptId,
    int year,
  ) async {
    final snap = await _firestore
        .collection('departments')
        .doc(deptId)
        .collection('courses')
        .where('yearLevel', isEqualTo: year)
        .get();
    return snap.docs
        .map((doc) => (id: doc.id, name: doc.data()['name'] as String? ?? ''))
        .toList();
  }
}
```

- [ ] **Step 2.2: Commit**

```bash
git add apps/mobile/lib/features/post/data/datasources/course_firestore_datasource.dart
git commit -m "feat(post): add CourseFirestoreDatasource"
```

---

## Task 3: Create course reference providers and run codegen

**Files:**
- Create: `apps/mobile/lib/features/post/presentation/providers/course_reference_provider.dart`
- Generated: `apps/mobile/lib/features/post/presentation/providers/course_reference_provider.g.dart`

- [ ] **Step 3.1: Create the providers file**

Create `apps/mobile/lib/features/post/presentation/providers/course_reference_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/post/data/datasources/course_firestore_datasource.dart';

part 'course_reference_provider.g.dart';

@Riverpod(keepAlive: true)
CourseFirestoreDatasource courseFirestoreDatasource(Ref ref) =>
    CourseFirestoreDatasource();

@riverpod
Future<List<({String id, String name})>> departmentsForUniversity(
  Ref ref,
  String universityId,
) =>
    ref.watch(courseFirestoreDatasourceProvider).getDepartments(universityId);

@riverpod
Future<List<({String id, String name})>> courses(
  Ref ref,
  String deptId,
  int year,
) =>
    ref.watch(courseFirestoreDatasourceProvider).getCourses(deptId, year);
```

- [ ] **Step 3.2: Run build_runner to generate `.g.dart`**

```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```

Expected output: `[INFO] build_runner: Succeeded after ...` — verify that `course_reference_provider.g.dart` is created alongside the source file.

- [ ] **Step 3.3: Verify analyze passes**

```bash
cd apps/mobile && flutter analyze
```

Expected: no errors.

- [ ] **Step 3.4: Commit**

```bash
git add apps/mobile/lib/features/post/presentation/providers/course_reference_provider.dart \
        apps/mobile/lib/features/post/presentation/providers/course_reference_provider.g.dart
git commit -m "feat(post): add course reference providers"
```

---

## Task 4: TDD — CourseStep widget tests then implementation

**Files:**
- Create: `apps/mobile/test/widget/features/post/widgets/course_step_test.dart`
- Modify: `apps/mobile/lib/features/post/presentation/widgets/course_step.dart`

- [ ] **Step 4.1: Write the failing CourseStep tests**

Create `apps/mobile/test/widget/features/post/widgets/course_step_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/post/data/datasources/course_firestore_datasource.dart';
import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/course_step.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

// ---------------------------------------------------------------------------
// Fake datasources
// ---------------------------------------------------------------------------

class _FakeCourseDatasource implements CourseFirestoreDatasource {
  @override
  Future<List<({String id, String name})>> getDepartments(
    String universityId,
  ) async =>
      [
        (id: 'dept-cs', name: 'Computer Science'),
        (id: 'dept-math', name: 'Mathematics'),
      ];

  @override
  Future<List<({String id, String name})>> getCourses(
    String deptId,
    int year,
  ) async {
    if (deptId == 'dept-cs' && year == 1) {
      return [(id: 'csc101', name: 'CSC101 Introduction to Computing')];
    }
    return [];
  }
}

class _ErrorCourseDatasource implements CourseFirestoreDatasource {
  @override
  Future<List<({String id, String name})>> getDepartments(String _) =>
      Future.error(Exception('network error'));

  @override
  Future<List<({String id, String name})>> getCourses(String _, int __) =>
      Future.error(Exception('network error'));
}

class _NeverCourseDatasource implements CourseFirestoreDatasource {
  @override
  Future<List<({String id, String name})>> getDepartments(String _) =>
      Completer<List<({String id, String name})>>().future;

  @override
  Future<List<({String id, String name})>> getCourses(String _, int __) =>
      Completer<List<({String id, String name})>>().future;
}

// ---------------------------------------------------------------------------
// Helper: pump CourseStep with controlled provider override
// ---------------------------------------------------------------------------

Widget _makeStep({
  required CourseFirestoreDatasource datasource,
  String? selectedDepartmentId,
  int? selectedYear,
  String? selectedCourseId,
  ValueChanged<String?>? onDepartmentChanged,
  ValueChanged<int?>? onYearChanged,
  ValueChanged<String?>? onCourseChanged,
}) {
  return ProviderScope(
    overrides: [
      courseFirestoreDatasourceProvider.overrideWithValue(datasource),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: Scaffold(
        body: SingleChildScrollView(
          child: CourseStep(
            universityId: 'uni-1',
            selectedDepartmentId: selectedDepartmentId,
            selectedYear: selectedYear,
            selectedCourseId: selectedCourseId,
            onDepartmentChanged: onDepartmentChanged ?? (_) {},
            onYearChanged: onYearChanged ?? (_) {},
            onCourseChanged: onCourseChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CourseStep', () {
    testWidgets('shows loading hint while departments are pending', (
      tester,
    ) async {
      await tester.pumpWidget(
        _makeStep(datasource: _NeverCourseDatasource()),
      );
      // One pump — future hasn't resolved yet.
      await tester.pump();
      expect(find.text('Loading…'), findsWidgets);
    });

    testWidgets('shows failed-to-load hint when departments error', (
      tester,
    ) async {
      await tester.pumpWidget(
        _makeStep(datasource: _ErrorCourseDatasource()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Failed to load'), findsOneWidget);
    });

    testWidgets('renders department options after load', (tester) async {
      await tester.pumpWidget(_makeStep(datasource: _FakeCourseDatasource()));
      await tester.pumpAndSettle();

      // Open department dropdown.
      await tester.tap(find.text('Select department'));
      await tester.pumpAndSettle();

      expect(find.text('Computer Science'), findsWidgets);
      expect(find.text('Mathematics'), findsWidgets);
    });

    testWidgets('course dropdown shows prompt when department not selected', (
      tester,
    ) async {
      await tester.pumpWidget(_makeStep(datasource: _FakeCourseDatasource()));
      await tester.pumpAndSettle();
      expect(find.text('Select a department first'), findsOneWidget);
    });

    testWidgets('course dropdown shows prompt when year not selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _makeStep(
          datasource: _FakeCourseDatasource(),
          selectedDepartmentId: 'dept-cs',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Select a year first'), findsOneWidget);
    });

    testWidgets('course dropdown lists courses for selected dept + year', (
      tester,
    ) async {
      await tester.pumpWidget(
        _makeStep(
          datasource: _FakeCourseDatasource(),
          selectedDepartmentId: 'dept-cs',
          selectedYear: 1,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select course'));
      await tester.pumpAndSettle();

      expect(find.text('CSC101 Introduction to Computing'), findsWidgets);
    });

    testWidgets('dept+year combo with no courses shows no-courses hint', (
      tester,
    ) async {
      await tester.pumpWidget(
        _makeStep(
          datasource: _FakeCourseDatasource(),
          selectedDepartmentId: 'dept-math',
          selectedYear: 3,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No courses found'), findsOneWidget);
    });

    testWidgets('selecting a department fires all three reset callbacks', (
      tester,
    ) async {
      String? capturedDept;
      int? capturedYear = 99;
      String? capturedCourse = 'old';

      await tester.pumpWidget(
        _makeStep(
          datasource: _FakeCourseDatasource(),
          onDepartmentChanged: (d) => capturedDept = d,
          onYearChanged: (y) => capturedYear = y,
          onCourseChanged: (c) => capturedCourse = c,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select department'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Computer Science').last);
      await tester.pumpAndSettle();

      expect(capturedDept, 'dept-cs');
      expect(capturedYear, isNull);
      expect(capturedCourse, isNull);
    });

    testWidgets('selecting a year fires year + course reset callbacks', (
      tester,
    ) async {
      int? capturedYear;
      String? capturedCourse = 'old';

      await tester.pumpWidget(
        _makeStep(
          datasource: _FakeCourseDatasource(),
          selectedDepartmentId: 'dept-cs',
          onYearChanged: (y) => capturedYear = y,
          onCourseChanged: (c) => capturedCourse = c,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select year'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Year 1').last);
      await tester.pumpAndSettle();

      expect(capturedYear, 1);
      expect(capturedCourse, isNull);
    });
  });
}
```

- [ ] **Step 4.2: Run tests to confirm they fail**

```bash
cd apps/mobile && flutter test test/widget/features/post/widgets/course_step_test.dart
```

Expected: tests fail — CourseStep is still a StatelessWidget with no dept dropdown and no async state.

- [ ] **Step 4.3: Rewrite CourseStep as ConsumerWidget**

Replace the entire contents of `apps/mobile/lib/features/post/presentation/widgets/course_step.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class CourseStep extends ConsumerWidget {
  const CourseStep({
    super.key,
    required this.universityId,
    required this.selectedDepartmentId,
    required this.selectedYear,
    required this.selectedCourseId,
    required this.onDepartmentChanged,
    required this.onYearChanged,
    required this.onCourseChanged,
  });

  final String universityId;
  final String? selectedDepartmentId;
  final int? selectedYear;
  final String? selectedCourseId;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<String?> onCourseChanged;

  static const _years = [1, 2, 3, 4];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final deptsAsync = ref.watch(
      departmentsForUniversityProvider(universityId),
    );

    final coursesAsync =
        (selectedDepartmentId != null && selectedYear != null)
            ? ref.watch(coursesProvider(selectedDepartmentId!, selectedYear!))
            : const AsyncData(<({String id, String name})>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which course is this for?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 24),

        // DEPARTMENT
        _FieldLabel('DEPARTMENT'),
        const SizedBox(height: 6),
        deptsAsync.when(
          loading: () => _DropdownField<String>(
            value: null,
            hint: 'Loading…',
            items: const [],
            onChanged: null,
          ),
          error: (_, __) => _DropdownField<String>(
            value: null,
            hint: 'Failed to load',
            items: const [],
            onChanged: null,
          ),
          data: (depts) => _DropdownField<String>(
            value: selectedDepartmentId,
            hint: 'Select department',
            items: depts
                .map(
                  (d) => DropdownMenuItem(
                    value: d.id,
                    child: Text(
                      d.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              onDepartmentChanged(v);
              onYearChanged(null);
              onCourseChanged(null);
            },
          ),
        ),
        const SizedBox(height: 16),

        // YEAR
        _FieldLabel('YEAR'),
        const SizedBox(height: 6),
        _DropdownField<int>(
          value: selectedYear,
          hint: 'Select year',
          items: _years
              .map(
                (y) => DropdownMenuItem(
                  value: y,
                  child: Text(
                    'Year $y',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            onYearChanged(v);
            onCourseChanged(null);
          },
        ),
        const SizedBox(height: 16),

        // COURSE
        _FieldLabel('COURSE'),
        const SizedBox(height: 6),
        _buildCourseDropdown(context, coursesAsync),
      ],
    );
  }

  Widget _buildCourseDropdown(
    BuildContext context,
    AsyncValue<List<({String id, String name})>> coursesAsync,
  ) {
    final cs = Theme.of(context).colorScheme;

    if (selectedDepartmentId == null) {
      return _DropdownField<String>(
        value: null,
        hint: 'Select a department first',
        items: const [],
        onChanged: null,
      );
    }
    if (selectedYear == null) {
      return _DropdownField<String>(
        value: null,
        hint: 'Select a year first',
        items: const [],
        onChanged: null,
      );
    }
    return coursesAsync.when(
      loading: () => _DropdownField<String>(
        value: null,
        hint: 'Loading…',
        items: const [],
        onChanged: null,
      ),
      error: (_, __) => _DropdownField<String>(
        value: null,
        hint: 'Failed to load',
        items: const [],
        onChanged: null,
      ),
      data: (courses) => _DropdownField<String>(
        value: selectedCourseId,
        hint: courses.isEmpty ? 'No courses found' : 'Select course',
        items: courses
            .map(
              (c) => DropdownMenuItem(
                value: c.id,
                child: Text(
                  c.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: courses.isEmpty ? null : onCourseChanged,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    return Text(
      text,
      style: GoogleFonts.firaCode(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: ac.mutedForeground,
        letterSpacing: 0.55,
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

  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final dividerColor = Theme.of(context).dividerColor;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: ac.mutedForeground,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: ac.mutedForeground,
            size: 18,
          ),
          style: GoogleFonts.spaceGrotesk(fontSize: 14, color: cs.onSurface),
          items: items,
          onChanged: onChanged,
          focusColor: Colors.transparent,
          dropdownColor: cs.surface,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4.4: Run CourseStep tests to confirm they pass**

```bash
cd apps/mobile && flutter test test/widget/features/post/widgets/course_step_test.dart
```

Expected: all 9 tests pass.

- [ ] **Step 4.5: Run full test suite to check for regressions**

```bash
cd apps/mobile && flutter test
```

Expected: existing tests that reference CourseStep (i.e., `create_post_screen_test.dart`) will now fail because `CourseStep`'s constructor changed — that is expected and will be fixed in Task 5.

- [ ] **Step 4.6: Commit**

```bash
git add apps/mobile/lib/features/post/presentation/widgets/course_step.dart \
        apps/mobile/test/widget/features/post/widgets/course_step_test.dart
git commit -m "feat(post): rewrite CourseStep with Firestore-backed dept selector"
```

---

## Task 5: Update CreatePostScreen and fix create_post_screen_test

**Files:**
- Modify: `apps/mobile/test/widget/features/post/screens/create_post_screen_test.dart`
- Modify: `apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart`

- [ ] **Step 5.1: Update `create_post_screen_test.dart`**

Replace the entire file content with:

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/features/post/data/datasources/course_firestore_datasource.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/domain/repositories/post_repository.dart';
import 'package:unishare_mobile/features/post/domain/usecases/create_post.dart';
import 'package:unishare_mobile/features/post/domain/usecases/sync_draft_queue.dart';
import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/draft_queue_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';
import 'package:unishare_mobile/features/post/presentation/screens/create_post_screen.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

class _StubRepo implements PostRepository {
  @override
  Stream<List<Post>> watchFeed({int limit = 20}) => throw UnimplementedError();
  @override
  Future<void> saveDraft(PostDraft draft) async {}
  @override
  Future<void> removeDraft(String draftId) async {}
  @override
  Future<List<PostDraft>> loadDraftQueue() async => [];
  @override
  Stream<Post> watchPost(String postId) => throw UnimplementedError();
  @override
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double)? onProgress,
    void Function(int, double)? onFileProgress,
    Map<String, Uint8List>? fileDataOverride,
    CancellationToken? cancellationToken,
  }) async {}
}

class _FakeDraftQueueNotifier extends DraftQueueNotifier {
  @override
  List<PostDraft> build() => [];
}

class _FakeCourseDatasource implements CourseFirestoreDatasource {
  @override
  Future<List<({String id, String name})>> getDepartments(
    String universityId,
  ) async =>
      [(id: 'dept-cs', name: 'Computer Science')];

  @override
  Future<List<({String id, String name})>> getCourses(
    String deptId,
    int year,
  ) async =>
      [(id: 'csc101', name: 'CSC101 Introduction to Computing')];
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _makeScreen() {
  return ProviderScope(
    overrides: [
      postRepositoryProvider.overrideWithValue(_StubRepo()),
      createPostUseCaseProvider.overrideWithValue(CreatePost(_StubRepo())),
      syncDraftQueueUseCaseProvider.overrideWithValue(
        SyncDraftQueue(_StubRepo()),
      ),
      draftQueueProvider.overrideWith(() => _FakeDraftQueueNotifier()),
      courseFirestoreDatasourceProvider.overrideWithValue(
        _FakeCourseDatasource(),
      ),
      currentUserProvider.overrideWith(
        (_) async => AppUser(
          id: 'user-1',
          name: 'Test User',
          email: 'test@test.com',
          universityId: 'uni-1',
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: const CreatePostScreen(),
    ),
  );
}

// Helper: navigate to step 2 and select dept + year + course
Future<void> _completStep2(WidgetTester tester) async {
  await tester.tap(find.text('Select department'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Computer Science').last);
  await tester.pumpAndSettle();

  await tester.tap(find.text('Select year'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Year 1').last);
  await tester.pumpAndSettle();

  await tester.tap(find.text('Select course'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('CSC101 Introduction to Computing').last);
  await tester.pumpAndSettle();
}

void main() {
  group('CreatePostScreen wizard', () {
    testWidgets('renders step 1 heading and type cards', (tester) async {
      await tester.pumpWidget(_makeScreen());
      await tester.pump();
      expect(find.text('What are you sharing?'), findsOneWidget);
      expect(find.text('Lecture Note'), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Past Exam'), findsOneWidget);
    });

    testWidgets('Next button is disabled on step 1 until a type is selected', (
      tester,
    ) async {
      await tester.pumpWidget(_makeScreen());
      await tester.pump();

      final nextButton = find.widgetWithText(FilledButton, 'Next');
      expect(nextButton, findsOneWidget);

      final button = tester.widget<FilledButton>(nextButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('tapping Lecture Note enables Next and advances to step 2', (
      tester,
    ) async {
      await tester.pumpWidget(_makeScreen());
      await tester.pump();

      await tester.tap(find.text('Lecture Note'));
      await tester.pump();

      final nextButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Next'),
      );
      expect(nextButton.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.text('Which course is this for?'), findsOneWidget);
    });

    testWidgets('Back on step 1 does not crash when no prior route', (
      tester,
    ) async {
      await tester.pumpWidget(_makeScreen());
      await tester.pump();

      final backBtn = find.widgetWithText(TextButton, 'Back');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pump();
    });

    testWidgets(
      'step 2: Next is disabled until department, year, and course are selected',
      (tester) async {
        await tester.pumpWidget(_makeScreen());
        await tester.pump();

        await tester.tap(find.text('Lecture Note'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Next'));
        await tester.pumpAndSettle();

        expect(find.text('Which course is this for?'), findsOneWidget);

        final nextButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Next'),
        );
        expect(nextButton.onPressed, isNull);
      },
    );

    testWidgets(
      'step 3: Next is disabled until title, description, and module are filled',
      (tester) async {
        await tester.pumpWidget(_makeScreen());
        await tester.pump();

        // Step 1
        await tester.tap(find.text('Lecture Note'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Next'));
        await tester.pumpAndSettle();

        // Step 2
        await _completStep2(tester);

        var nextButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Next'),
        );
        expect(nextButton.onPressed, isNotNull);

        await tester.tap(find.widgetWithText(FilledButton, 'Next'));
        await tester.pumpAndSettle();

        expect(find.text('Add details'), findsOneWidget);

        nextButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Next'),
        );
        expect(nextButton.onPressed, isNull);
      },
    );

    testWidgets('step 4: Submit button is always enabled', (tester) async {
      await tester.pumpWidget(_makeScreen());
      await tester.pump();

      // Step 1
      await tester.tap(find.text('Lecture Note'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      // Step 2
      await _completStep2(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      // Step 3 — fill required fields
      await tester.enterText(find.byType(TextField).at(0), 'My Title');
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(1), 'My description');
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(2), '3');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.text('Upload files'), findsOneWidget);

      final submitButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit'),
      );
      expect(submitButton.onPressed, isNotNull);
    });

    testWidgets('Back navigates from step 2 to step 1', (tester) async {
      await tester.pumpWidget(_makeScreen());
      await tester.pump();

      await tester.tap(find.text('Lecture Note'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.text('Which course is this for?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Back'));
      await tester.pumpAndSettle();

      expect(find.text('What are you sharing?'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 5.2: Run the updated test to confirm it fails**

```bash
cd apps/mobile && flutter test test/widget/features/post/screens/create_post_screen_test.dart
```

Expected: compilation errors — `CourseStep` constructor is missing the required `universityId`, `selectedDepartmentId`, `onDepartmentChanged` props from `CreatePostScreen`.

- [ ] **Step 5.3: Update CreatePostScreen**

In `apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart`:

**Add import** at the top (after existing imports):
```dart
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
```

**Add state field** in `_CreatePostScreenState` after `String? _courseId;`:
```dart
String? _departmentId;
```

**Update `_nextEnabled` case 1** (currently `1 => _year != null && _courseId != null`):
```dart
1 => _year != null && _courseId != null && _departmentId != null,
```

**Update `CourseStep(...)` call** in the `build` method's PageView children. Replace the existing `CourseStep(...)` block with:
```dart
CourseStep(
  universityId:
      ref.watch(currentUserProvider).valueOrNull?.universityId ?? '',
  selectedDepartmentId: _departmentId,
  selectedYear: _year,
  selectedCourseId: _courseId,
  onDepartmentChanged: (d) => setState(() {
    _departmentId = d;
    _year = null;
    _courseId = null;
  }),
  onYearChanged: (y) => setState(() {
    _year = y;
    _courseId = null;
  }),
  onCourseChanged: (c) => setState(() => _courseId = c),
),
```

**Update `PostDraft` construction** in `_submit()` — add `departmentId` after `courseId`:
```dart
courseId: _courseId ?? '',
departmentId: _departmentId ?? '',
```

- [ ] **Step 5.4: Run the screen tests to confirm they pass**

```bash
cd apps/mobile && flutter test test/widget/features/post/screens/create_post_screen_test.dart
```

Expected: all tests pass.

- [ ] **Step 5.5: Run the full test suite**

```bash
cd apps/mobile && flutter test
```

Expected: all tests pass.

- [ ] **Step 5.6: Commit**

```bash
git add apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart \
        apps/mobile/test/widget/features/post/screens/create_post_screen_test.dart
git commit -m "feat(post): wire department selector into CreatePostScreen"
```

---

## Task 6: Write departmentId to Firestore

**Files:**
- Modify: `apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart`

- [ ] **Step 6.1: Add departmentId to createPost**

In `apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart`, in the `createPost` method, add `'departmentId': draft.departmentId,` immediately after `'courseId': draft.courseId,`:

```dart
'courseId': draft.courseId,
'departmentId': draft.departmentId,   // ← ADD
```

- [ ] **Step 6.2: Run full test suite**

```bash
cd apps/mobile && flutter test
```

Expected: all tests pass.

- [ ] **Step 6.3: Analyze and format**

```bash
cd apps/mobile && flutter analyze && dart format .
```

Expected: no issues.

- [ ] **Step 6.4: Commit**

```bash
git add apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart
git commit -m "feat(post): persist departmentId in Firestore post document"
```

---

## Self-Review Checklist

- [x] All 6 spec requirements covered (dept selector, Firestore providers, cascade filter, departmentId in PostDraft, replace static map, widget test)
- [x] No TBD/TODO placeholders
- [x] `CourseFirestoreDatasource` method signatures match usage in providers and fakes
- [x] `departmentsForUniversityProvider(universityId)` + `coursesProvider(deptId, year)` match watch calls in CourseStep
- [x] `_FakeCourseDatasource` in tests implements the same interface as production datasource
- [x] All 5 PostDraft construction sites in tests are fixed in Task 1
- [x] `_nextEnabled` updated to require `_departmentId != null`
- [x] `PostDraft` submit includes `departmentId`
