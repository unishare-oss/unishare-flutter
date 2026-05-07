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
      await tester.pumpWidget(_makeStep(datasource: _NeverCourseDatasource()));
      // One pump — future hasn't resolved yet.
      await tester.pump();
      expect(find.text('Loading…'), findsWidgets);
    });

    testWidgets('shows failed-to-load hint when departments error', (
      tester,
    ) async {
      await tester.pumpWidget(_makeStep(datasource: _ErrorCourseDatasource()));
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
