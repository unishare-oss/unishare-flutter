import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/data/datasources/course_firestore_datasource.dart';
import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/presentation/widgets/request_filter_bar.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

class _FakeCourseDatasource implements CourseFirestoreDatasource {
  @override
  Future<List<({String id, String name})>> getDepartments(
    String universityId,
  ) async => [
    (id: 'dept-1', name: 'Computer Science'),
    (id: 'dept-2', name: 'Engineering'),
  ];

  @override
  Future<List<({String id, String name})>> getCourses(
    String deptId,
    int year,
  ) async => [(id: 'CSC234', name: 'CSC234 Data Structures')];
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      courseFirestoreDatasourceProvider.overrideWithValue(
        _FakeCourseDatasource(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: Scaffold(body: SizedBox(width: 600, child: child)),
    ),
  );
}

void main() {
  group('RequestFilterBar', () {
    testWidgets('renders four DropdownButton widgets', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(
          RequestFilterBar(
            selectedStatus: null,
            selectedDepartmentId: null,
            selectedYear: null,
            selectedCourseId: null,
            onStatusChanged: (_) {},
            onDepartmentChanged: (_) {},
            onYearChanged: (_) {},
            onCourseChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Four DropdownButton widgets should be present.
      expect(find.byType(DropdownButton<RequestStatus>), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsAtLeastNWidgets(3));
    });

    testWidgets('onStatusChanged fires with open when Open selected', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      RequestStatus? captured;

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (ctx, setState) => RequestFilterBar(
              selectedStatus: null,
              selectedDepartmentId: null,
              selectedYear: null,
              selectedCourseId: null,
              onStatusChanged: (v) => setState(() => captured = v),
              onDepartmentChanged: (_) {},
              onYearChanged: (_) {},
              onCourseChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the status dropdown (first DropdownButton).
      await tester.tap(find.byType(DropdownButton<RequestStatus>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open').last);
      await tester.pumpAndSettle();

      expect(captured, RequestStatus.open);
    });

    testWidgets('onStatusChanged fires with null when All selected', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      RequestStatus? captured = RequestStatus.open;

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (ctx, setState) => RequestFilterBar(
              selectedStatus: captured,
              selectedDepartmentId: null,
              selectedYear: null,
              selectedCourseId: null,
              onStatusChanged: (v) => setState(() => captured = v),
              onDepartmentChanged: (_) {},
              onYearChanged: (_) {},
              onCourseChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<RequestStatus>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();

      expect(captured, isNull);
    });

    testWidgets(
      'onStatusChanged fires with fulfilled when Fulfilled selected',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        RequestStatus? captured;

        await tester.pumpWidget(
          _wrap(
            StatefulBuilder(
              builder: (ctx, setState) => RequestFilterBar(
                selectedStatus: null,
                selectedDepartmentId: null,
                selectedYear: null,
                selectedCourseId: null,
                onStatusChanged: (v) => setState(() => captured = v),
                onDepartmentChanged: (_) {},
                onYearChanged: (_) {},
                onCourseChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButton<RequestStatus>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Fulfilled').last);
        await tester.pumpAndSettle();

        expect(captured, RequestStatus.fulfilled);
      },
    );

    testWidgets('onDepartmentChanged fires when a department is selected', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? capturedDept;

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (ctx, setState) => RequestFilterBar(
              selectedStatus: null,
              selectedDepartmentId: capturedDept,
              selectedYear: null,
              selectedCourseId: null,
              onStatusChanged: (_) {},
              onDepartmentChanged: (v) => setState(() => capturedDept = v),
              onYearChanged: (_) {},
              onCourseChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap dept dropdown (first String dropdown).
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Computer Science').last);
      await tester.pumpAndSettle();

      expect(capturedDept, 'dept-1');
    });

    testWidgets('onYearChanged fires when a year is selected', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? capturedYear;

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (ctx, setState) => RequestFilterBar(
              selectedStatus: null,
              selectedDepartmentId: null,
              selectedYear: capturedYear,
              selectedCourseId: null,
              onStatusChanged: (_) {},
              onDepartmentChanged: (_) {},
              onYearChanged: (v) => setState(() => capturedYear = v),
              onCourseChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Year dropdown is the second String dropdown.
      await tester.tap(find.byType(DropdownButton<String>).at(1));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Year 2').last);
      await tester.pumpAndSettle();

      expect(capturedYear, '2');
    });
  });
}
