import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/data/datasources/course_firestore_datasource.dart';
import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/features/requests/domain/usecases/create_request.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/request_repository_provider.dart';
import 'package:unishare_mobile/features/requests/presentation/widgets/new_request_dialog.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

class _FakeCourseDatasource implements CourseFirestoreDatasource {
  @override
  Future<List<({String id, String name})>> getDepartments(
    String universityId,
  ) async => [(id: 'dept-1', name: 'Computer Science')];

  @override
  Future<List<({String id, String name})>> getCourses(
    String deptId,
    int year,
  ) async => [(id: 'CSC234', name: 'CSC234 Data Structures')];
}

/// A minimal CreateRequest that captures calls without hitting Firestore.
class _FakeCreateRequest implements CreateRequest {
  _FakeCreateRequest();

  bool called = false;
  String? lastTitle;

  @override
  Future<void> call({
    required String departmentId,
    required String departmentName,
    required String year,
    required String courseId,
    required String courseName,
    required String title,
    String? description,
  }) async {
    called = true;
    lastTitle = title;
  }
}

Widget _wrap(Widget child, {_FakeCreateRequest? fakeCreate}) {
  return ProviderScope(
    overrides: [
      courseFirestoreDatasourceProvider.overrideWithValue(
        _FakeCourseDatasource(),
      ),
      if (fakeCreate != null)
        createRequestUseCaseProvider.overrideWithValue(fakeCreate),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('NewRequestDialog', () {
    testWidgets('renders dialog title', (tester) async {
      await tester.pumpWidget(_wrap(const NewRequestDialog()));
      await tester.pumpAndSettle();

      expect(find.text('New Resource Request'), findsOneWidget);
    });

    testWidgets('"Post Request" button is disabled when title is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const NewRequestDialog()));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Post Request'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('Cancel button closes dialog', (tester) async {
      bool dialogVisible = true;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                await showDialog<void>(
                  context: ctx,
                  builder: (_) => const NewRequestDialog(),
                );
                dialogVisible = false;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('New Resource Request'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('New Resource Request'), findsNothing);
      expect(dialogVisible, isFalse);
    });

    testWidgets('title field accepts input', (tester) async {
      await tester.pumpWidget(_wrap(const NewRequestDialog()));
      await tester.pumpAndSettle();

      final titleField = find.byType(TextField).first;
      await tester.tap(titleField);
      await tester.enterText(titleField, 'Data Structures notes');
      await tester.pump();

      expect(find.text('Data Structures notes'), findsOneWidget);
    });

    testWidgets(
      '"Post Request" button remains disabled without department and year',
      (tester) async {
        await tester.pumpWidget(_wrap(const NewRequestDialog()));
        await tester.pumpAndSettle();

        // Enter title — button should still be disabled because dept/year are missing.
        final titleField = find.byType(TextField).first;
        await tester.tap(titleField);
        await tester.enterText(titleField, 'Some title');
        await tester.pump();

        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Post Request'),
        );
        expect(button.onPressed, isNull);
      },
    );

    testWidgets('submits on valid input — calls CreateRequest use case', (
      tester,
    ) async {
      final fakeCreate = _FakeCreateRequest();

      await tester.pumpWidget(
        _wrap(const NewRequestDialog(), fakeCreate: fakeCreate),
      );
      await tester.pumpAndSettle();

      // Enter a title.
      final titleField = find.byType(TextField).first;
      await tester.tap(titleField);
      await tester.enterText(titleField, 'DS Lecture Notes');
      await tester.pump();

      // Select department — tap the first DropdownButton<String> (Dept).
      // The departments dropdown is the second DropdownButton in the tree.
      // After the title field there are: dept dropdown, year dropdown, course dropdown.
      final deptDropdown = find.byType(DropdownButton<String>).first;
      await tester.tap(deptDropdown);
      await tester.pumpAndSettle();

      // Pick "Computer Science" from the overlay.
      await tester.tap(find.text('Computer Science').last);
      await tester.pumpAndSettle();

      // Select year — tap the year DropdownButton (second String dropdown).
      final yearDropdown = find.byType(DropdownButton<String>).at(1);
      await tester.tap(yearDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Year 1').last);
      await tester.pumpAndSettle();

      // Select course — tap the course DropdownButton (third String dropdown).
      final courseDropdown = find.byType(DropdownButton<String>).at(2);
      await tester.tap(courseDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('CSC234 Data Structures').last);
      await tester.pumpAndSettle();

      // Now Post Request should be enabled.
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Post Request'),
      );
      expect(button.onPressed, isNotNull);

      // Tap submit.
      await tester.tap(find.widgetWithText(FilledButton, 'Post Request'));
      await tester.pumpAndSettle();

      expect(fakeCreate.called, isTrue);
      expect(fakeCreate.lastTitle, 'DS Lecture Notes');
    });
  });
}
