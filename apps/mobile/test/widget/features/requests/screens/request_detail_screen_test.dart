import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/domain/entities/suggestion.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/request_repository_provider.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/suggestions_provider.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/upvote_provider.dart';
import 'package:unishare_mobile/features/requests/presentation/screens/request_detail_screen.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

ContentRequest _request() {
  final now = DateTime(2026, 5, 9);
  return ContentRequest(
    id: 'req-1',
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

Suggestion _suggestion() => Suggestion(
  id: 'sug-1',
  postId: 'post-1',
  postTitle: 'DS midterm notes',
  postType: 'lectureNote',
  suggestedByUserId: 'user-2',
  suggestedByName: 'Bob',
  createdAt: DateTime(2026, 5, 9),
);

Widget _wrap(
  Widget child,
  ContentRequest request, {
  List<Suggestion> suggestions = const [],
}) {
  return ProviderScope(
    overrides: [
      requestDetailProvider.overrideWith(
        (ref, requestId) => Stream.value(request),
      ),
      suggestionsProvider.overrideWith(
        (ref, requestId) => Stream.value(suggestions),
      ),
      hasUpvotedProvider.overrideWith((ref, requestId) async => false),
      currentUserIdProvider.overrideWithValue(null),
    ],
    child: MaterialApp(theme: AppTheme.build(AppThemes.unishare), home: child),
  );
}

void main() {
  group('RequestDetailScreen', () {
    testWidgets('renders AppBar with "Request" title', (tester) async {
      final request = _request();
      await tester.pumpWidget(
        _wrap(const RequestDetailScreen(requestId: 'req-1'), request),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request'), findsOneWidget);
    });

    testWidgets('renders request title in card', (tester) async {
      final request = _request();
      await tester.pumpWidget(
        _wrap(const RequestDetailScreen(requestId: 'req-1'), request),
      );
      await tester.pumpAndSettle();

      expect(find.text(request.title), findsOneWidget);
    });

    testWidgets('shows empty suggestions text when no suggestions', (
      tester,
    ) async {
      final request = _request();
      await tester.pumpWidget(
        _wrap(
          const RequestDetailScreen(requestId: 'req-1'),
          request,
          suggestions: [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No suggestions yet'), findsOneWidget);
    });

    testWidgets('renders suggestion cards when suggestions exist', (
      tester,
    ) async {
      final request = _request();
      final suggestion = _suggestion();
      await tester.pumpWidget(
        _wrap(
          const RequestDetailScreen(requestId: 'req-1'),
          request,
          suggestions: [suggestion],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(suggestion.postTitle), findsOneWidget);
    });

    testWidgets('shows SUGGEST button', (tester) async {
      final request = _request();
      await tester.pumpWidget(
        _wrap(const RequestDetailScreen(requestId: 'req-1'), request),
      );
      await tester.pumpAndSettle();

      expect(find.text('SUGGEST'), findsOneWidget);
    });

    testWidgets('SUGGEST button opens SuggestFulfillmentDialog on tap', (
      tester,
    ) async {
      final request = _request();
      await tester.pumpWidget(
        _wrap(const RequestDetailScreen(requestId: 'req-1'), request),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUGGEST'));
      await tester.pumpAndSettle();

      expect(find.text('Suggest a Fulfillment'), findsOneWidget);
    });
  });
}
