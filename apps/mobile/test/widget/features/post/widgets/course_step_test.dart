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
// Fake datasource (success path)
// ---------------------------------------------------------------------------

class _FakeCourseDatasource implements CourseFirestoreDatasource {
  @override
  Future<List<({String id, String name})>> getDepartments(
    String universityId,
  ) async => [
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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps CourseStep in a ProviderScope that overrides the datasource.
/// Use for success-path tests (providers resolve normally).
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
      // Override the family provider directly with a never-completing future.
      // This avoids Riverpod retry timers that would prevent pumpAndSettle.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            departmentsForUniversityProvider('uni-1').overrideWith((ref) {
              final c = Completer<List<({String id, String name})>>();
              return c.future;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.build(AppThemes.unishare),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CourseStep(
                  universityId: 'uni-1',
                  selectedDepartmentId: null,
                  selectedYear: null,
                  selectedCourseId: null,
                  onDepartmentChanged: (_) {},
                  onYearChanged: (_) {},
                  onCourseChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Loading…'), findsWidgets);
    });

    testWidgets('shows failed-to-load hint when departments error', (
      tester,
    ) async {
      // Override the family provider with a pre-built AsyncError to avoid
      // Riverpod retry timers that keep the state stuck in AsyncLoading.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            departmentsForUniversityProvider('uni-1').overrideWithValue(
              AsyncError(Exception('network error'), StackTrace.empty),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.build(AppThemes.unishare),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CourseStep(
                  universityId: 'uni-1',
                  selectedDepartmentId: null,
                  selectedYear: null,
                  selectedCourseId: null,
                  onDepartmentChanged: (_) {},
                  onYearChanged: (_) {},
                  onCourseChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Failed to load'), findsOneWidget);
    });

    testWidgets('renders department options after load', (tester) async {
      await tester.pumpWidget(_makeStep(datasource: _FakeCourseDatasource()));
      await tester.pumpAndSettle();

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
