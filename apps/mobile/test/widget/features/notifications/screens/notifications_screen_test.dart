import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/notifications/domain/entities/notification_item.dart';
import 'package:unishare_mobile/features/notifications/domain/repositories/notification_repository.dart';
import 'package:unishare_mobile/features/notifications/presentation/providers/notification_repository_provider.dart';
import 'package:unishare_mobile/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:unishare_mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:unishare_mobile/features/notifications/presentation/widgets/notification_item_tile.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _RecorderRepo implements NotificationRepository {
  final List<String> markAllCalls = [];
  final List<(String, String)> markOneCalls = [];

  /// When non-null, markAsRead will delay by this duration before completing.
  Duration? markAsReadDelay;

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) =>
      const Stream.empty();

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    if (markAsReadDelay != null) {
      await Future<void>.delayed(markAsReadDelay!);
    }
    markOneCalls.add((userId, notificationId));
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    markAllCalls.add(userId);
  }

  @override
  Future<void> registerFcmToken(
    String userId,
    String token,
    String platform,
  ) async {}

  @override
  Future<void> removeFcmToken(String userId, String token) async {}
}

const _testUser = AppUser(id: 'me-uid', name: 'Me', email: 'me@example.com');

AppNotification _notif({
  String id = 'n1',
  bool isRead = false,
  String targetType = 'post',
  String targetId = 'p1',
  String actorName = 'Alice',
}) {
  return AppNotification(
    id: id,
    type: NotificationType.postCommentAdded,
    isRead: isRead,
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    title: 'New comment on your post',
    body: 'Alice commented: hi',
    actorId: 'a1',
    actorName: actorName,
    actorPhotoUrl: null,
    targetId: targetId,
    targetType: targetType,
    targetTitle: 'My Post',
  );
}

// ---------------------------------------------------------------------------
// Subject builder
// ---------------------------------------------------------------------------

Widget _buildSubject({
  AsyncValue<List<AppNotification>>? notifsState,
  Stream<List<AppNotification>>? notifsStream,
  AppUser? user = _testUser,
  _RecorderRepo? repo,
}) {
  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (_, _) => NotificationsScreen(scrollKey: GlobalKey()),
      ),
      GoRoute(
        path: '/welcome',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('welcome-route'))),
      ),
      GoRoute(
        path: '/posts/:id',
        builder: (_, state) => Scaffold(
          body: Center(child: Text('post-route-${state.pathParameters['id']}')),
        ),
      ),
      GoRoute(
        path: '/requests/:id',
        builder: (_, state) => Scaffold(
          body: Center(
            child: Text('request-route-${state.pathParameters['id']}'),
          ),
        ),
      ),
    ],
  );

  Stream<List<AppNotification>> resolveStream() {
    if (notifsStream != null) return notifsStream;
    if (notifsState == null) return const Stream<List<AppNotification>>.empty();
    return switch (notifsState) {
      AsyncData(:final value) => Stream.value(value),
      AsyncLoading() => _neverStream<List<AppNotification>>(),
      AsyncError(:final error) => Stream<List<AppNotification>>.error(error),
    };
  }

  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((_) => Stream.value(user)),
      watchNotificationsProvider.overrideWith((_) => resolveStream()),
      if (repo != null) notificationRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      theme: AppTheme.build(AppThemes.unishare),
      routerConfig: router,
    ),
  );
}

Stream<T> _neverStream<T>() => StreamController<T>().stream;

/// Concatenates the plain text of every [RichText] in the widget tree.
/// [find.textContaining] does not traverse [TextSpan] children.
String _richTextDump(WidgetTester tester) {
  return tester
      .widgetList<RichText>(find.byType(RichText))
      .map((rt) => rt.text.toPlainText())
      .join(' | ');
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('NotificationsScreen', () {
    testWidgets('renders "Notifications" title in the app bar', (tester) async {
      await tester.pumpWidget(
        _buildSubject(notifsState: const AsyncValue.data([])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('loading state shows a CircularProgressIndicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(notifsState: const AsyncValue.loading()),
      );
      // Single pump — don't settle, otherwise the stream may resolve.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('empty state shows the empty-state copy', (tester) async {
      await tester.pumpWidget(
        _buildSubject(notifsState: const AsyncValue.data([])),
      );
      await tester.pumpAndSettle();

      expect(find.text('No notifications yet'), findsOneWidget);
      expect(
        find.text('Activity on your posts and requests will appear here.'),
        findsOneWidget,
      );
    });

    testWidgets('guest state shows the sign-in prompt', (tester) async {
      await tester.pumpWidget(
        _buildSubject(user: null, notifsState: const AsyncValue.data([])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in to see your notifications'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('populated state renders one tile per notification', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(
          notifsState: AsyncValue.data([
            _notif(id: '1', actorName: 'Alice'),
            _notif(id: '2', actorName: 'Bob'),
            _notif(id: '3', actorName: 'Carol'),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotificationItemTile), findsNWidgets(3));
      final richText = _richTextDump(tester);
      expect(richText, contains('Alice'));
      expect(richText, contains('Bob'));
      expect(richText, contains('Carol'));
    });

    testWidgets('"Mark all read" is hidden when all notifications are read', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(
          notifsState: AsyncValue.data([
            _notif(id: '1', isRead: true),
            _notif(id: '2', isRead: true),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets(
      '"Mark all read" is visible when at least one notification is unread',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            notifsState: AsyncValue.data([
              _notif(id: '1', isRead: true),
              _notif(id: '2', isRead: false),
            ]),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mark all read'), findsOneWidget);
      },
    );

    testWidgets(
      '"Mark all read" is hidden in guest mode even with unread items',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            user: null,
            notifsState: AsyncValue.data([_notif(isRead: false)]),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mark all read'), findsNothing);
      },
    );

    testWidgets('tapping "Mark all read" calls markAllAsRead with caller uid', (
      tester,
    ) async {
      final repo = _RecorderRepo();

      await tester.pumpWidget(
        _buildSubject(
          repo: repo,
          notifsState: AsyncValue.data([_notif(id: '1', isRead: false)]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark all read'));
      await tester.pump();

      expect(repo.markAllCalls, equals(['me-uid']));
    });

    testWidgets(
      'tapping an unread post notification calls markAsRead and navigates to /posts/:id',
      (tester) async {
        final repo = _RecorderRepo();

        await tester.pumpWidget(
          _buildSubject(
            repo: repo,
            notifsState: AsyncValue.data([
              _notif(id: 'n1', targetType: 'post', targetId: 'p42'),
            ]),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(NotificationItemTile));
        await tester.pumpAndSettle();

        expect(repo.markOneCalls, equals([('me-uid', 'n1')]));
        expect(find.text('post-route-p42'), findsOneWidget);
      },
    );

    testWidgets('tapping a request notification navigates to /requests/:id', (
      tester,
    ) async {
      final repo = _RecorderRepo();

      await tester.pumpWidget(
        _buildSubject(
          repo: repo,
          notifsState: AsyncValue.data([
            _notif(
              id: 'n2',
              isRead: true,
              targetType: 'request',
              targetId: 'r99',
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NotificationItemTile));
      await tester.pumpAndSettle();

      expect(find.text('request-route-r99'), findsOneWidget);
    });

    testWidgets(
      'tapping an already-read notification does NOT call markAsRead',
      (tester) async {
        final repo = _RecorderRepo();

        await tester.pumpWidget(
          _buildSubject(
            repo: repo,
            notifsState: AsyncValue.data([
              _notif(
                id: 'n1',
                isRead: true,
                targetType: 'post',
                targetId: 'p1',
              ),
            ]),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(NotificationItemTile));
        await tester.pumpAndSettle();

        expect(repo.markOneCalls, isEmpty);
      },
    );

    testWidgets(
      'navigation happens even when markAsRead is in-flight (fire-and-forget)',
      (tester) async {
        final repo = _RecorderRepo()
          ..markAsReadDelay = const Duration(seconds: 5);

        await tester.pumpWidget(
          _buildSubject(
            repo: repo,
            notifsState: AsyncValue.data([
              _notif(id: 'n1', targetType: 'post', targetId: 'p99'),
            ]),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the tile — markAsRead is delayed 5 s but navigation must be
        // immediate since it is fire-and-forget.
        await tester.tap(find.byType(NotificationItemTile));
        // GoRouter navigation completes within one or two frame pumps.
        // We pump repeatedly but cap at 500 ms — far less than the 5 s delay.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Destination route must already be visible.
        expect(find.text('post-route-p99'), findsOneWidget);

        // Advance timers to let the delayed future complete without leaking.
        await tester.pump(const Duration(seconds: 6));
      },
    );
  });
}
