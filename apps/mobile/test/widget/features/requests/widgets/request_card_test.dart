import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/upvote_provider.dart';
import 'package:unishare_mobile/features/requests/presentation/widgets/request_card.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

ContentRequest _fakeRequest({
  String id = 'req-1',
  RequestStatus status = RequestStatus.open,
  int upvoteCount = 0,
  String? fulfilledByPostId,
  String? fulfilledByPostTitle,
}) {
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
    status: status,
    fulfilledByPostId: fulfilledByPostId,
    fulfilledByPostTitle: fulfilledByPostTitle,
    upvoteCount: upvoteCount,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      hasUpvotedProvider.overrideWith((ref, requestId) async => false),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('RequestCard', () {
    testWidgets('open status shows OPEN badge', (tester) async {
      final request = _fakeRequest(status: RequestStatus.open);
      await tester.pumpWidget(_wrap(RequestCard(request: request)));
      await tester.pumpAndSettle();

      expect(find.text('OPEN'), findsOneWidget);
      expect(find.text('FULFILLED'), findsNothing);
    });

    testWidgets('fulfilled status shows FULFILLED badge', (tester) async {
      final request = _fakeRequest(
        id: 'req-2',
        status: RequestStatus.fulfilled,
        fulfilledByPostId: 'post-1',
        fulfilledByPostTitle: 'DS notes',
      );
      await tester.pumpWidget(_wrap(RequestCard(request: request)));
      await tester.pumpAndSettle();

      expect(find.text('FULFILLED'), findsOneWidget);
      expect(find.text('OPEN'), findsNothing);
    });

    testWidgets('fulfilled request shows "Fulfilled by" link', (tester) async {
      final request = _fakeRequest(
        id: 'req-3',
        status: RequestStatus.fulfilled,
        fulfilledByPostId: 'post-1',
        fulfilledByPostTitle: 'DS midterm notes',
        upvoteCount: 2,
      );
      await tester.pumpWidget(_wrap(RequestCard(request: request)));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Fulfilled by: DS midterm notes'),
        findsOneWidget,
      );
    });

    testWidgets('shows requester name in meta row', (tester) async {
      final request = _fakeRequest();
      await tester.pumpWidget(_wrap(RequestCard(request: request)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Alice'), findsOneWidget);
    });

    testWidgets('shows upvote count', (tester) async {
      final request = _fakeRequest(upvoteCount: 7);
      await tester.pumpWidget(_wrap(RequestCard(request: request)));
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
    });
  });
}
