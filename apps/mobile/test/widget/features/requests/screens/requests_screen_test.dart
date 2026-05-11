import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/request_repository_provider.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/requests_provider.dart';
import 'package:unishare_mobile/features/requests/presentation/screens/requests_screen.dart';
import 'package:unishare_mobile/features/post/data/datasources/course_firestore_datasource.dart';
import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

// Inline factory to avoid cross-directory import issues.
ContentRequest _fakeRequest({String id = 'req-1'}) {
  final now = DateTime(2026, 5, 9);
  return ContentRequest(
    id: id,
    requesterId: 'user-1',
    requesterName: 'Alice',
    departmentId: 'dept-1',
    departmentName: 'Computer Science',
    year: '2',
    courseId: 'CSC234',
    courseName: 'CSC234',
    title: 'Data Structures notes',
    status: RequestStatus.open,
    upvoteCount: 0,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeCourseDatasource implements CourseFirestoreDatasource {
  @override
  Future<List<({String id, String name})>> getDepartments(
    String universityId,
  ) async => [];

  @override
  Future<List<({String id, String name})>> getCourses(
    String deptId,
    int year,
  ) async => [];
}

void main() {
  group('RequestsScreen', () {
    testWidgets('shows CircularProgressIndicator while loading', (
      tester,
    ) async {
      final controller = StreamController<List<ContentRequest>>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courseFirestoreDatasourceProvider.overrideWithValue(
              _FakeCourseDatasource(),
            ),
            currentUserIdProvider.overrideWithValue(null),
            requestsProvider.overrideWith((ref, filter) => controller.stream),
          ],
          child: MaterialApp(
            theme: AppTheme.build(AppThemes.unishare),
            home: const RequestsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when list is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courseFirestoreDatasourceProvider.overrideWithValue(
              _FakeCourseDatasource(),
            ),
            currentUserIdProvider.overrideWithValue(null),
            requestsProvider.overrideWith((ref, filter) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.build(AppThemes.unishare),
            home: const RequestsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No requests yet.'), findsOneWidget);
    });

    testWidgets('renders request cards from stream', (tester) async {
      final request = _fakeRequest();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courseFirestoreDatasourceProvider.overrideWithValue(
              _FakeCourseDatasource(),
            ),
            currentUserIdProvider.overrideWithValue(null),
            requestsProvider.overrideWith(
              (ref, filter) => Stream.value([request]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.build(AppThemes.unishare),
            home: const RequestsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(request.title), findsOneWidget);
    });

    testWidgets('opens NewRequestDialog when "New Request" button tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courseFirestoreDatasourceProvider.overrideWithValue(
              _FakeCourseDatasource(),
            ),
            currentUserIdProvider.overrideWithValue(null),
            requestsProvider.overrideWith((ref, filter) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.build(AppThemes.unishare),
            home: const RequestsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Request'));
      await tester.pumpAndSettle();

      expect(find.text('New Resource Request'), findsOneWidget);
    });
  });
}
