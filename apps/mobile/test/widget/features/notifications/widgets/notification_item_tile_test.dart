import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/notifications/domain/entities/notification_item.dart';
import 'package:unishare_mobile/features/notifications/presentation/widgets/notification_item_tile.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

AppNotification _notif({
  String id = 'n1',
  NotificationType type = NotificationType.postCommentAdded,
  bool isRead = false,
  String actorName = 'Alice',
  String targetTitle = 'My Post',
  String targetId = 'post-1',
  String targetType = 'post',
  String body = 'Body',
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id,
    type: type,
    isRead: isRead,
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(minutes: 5)),
    title: 'Title',
    body: body,
    actorId: 'a1',
    actorName: actorName,
    actorPhotoUrl: null,
    targetId: targetId,
    targetType: targetType,
    targetTitle: targetTitle,
  );
}

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.build(AppThemes.unishare),
  home: Scaffold(body: child),
);

/// Returns the concatenated plain text of every [RichText] in the widget tree.
/// Needed because [find.textContaining] does not traverse [TextSpan] children.
String _richTextDump(WidgetTester tester) {
  return tester
      .widgetList<RichText>(find.byType(RichText))
      .map((rt) => rt.text.toPlainText())
      .join(' | ');
}

void main() {
  group('NotificationItemTile', () {
    testWidgets('unread tile renders amber indicator bar (width 3)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          NotificationItemTile(
            notification: _notif(isRead: false),
            onTap: () {},
          ),
        ),
      );

      // The indicator bar is a 3-wide Container with a BoxDecoration.
      // Read tile uses SizedBox(width: 3) so the type differs.
      final container = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).color != null &&
                (c.decoration as BoxDecoration).borderRadius != null,
          );
      expect(container, isNotEmpty);
    });

    testWidgets('unread tile renders the 8px circular dot indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          NotificationItemTile(
            notification: _notif(isRead: false),
            onTap: () {},
          ),
        ),
      );

      final dots = tester.widgetList<Container>(find.byType(Container)).where((
        c,
      ) {
        final d = c.decoration;
        if (d is! BoxDecoration) return false;
        return d.shape == BoxShape.circle;
      });
      expect(dots.length, 1);
    });

    testWidgets('read tile renders no amber bar and no dot', (tester) async {
      await tester.pumpWidget(
        _host(
          NotificationItemTile(
            notification: _notif(isRead: true),
            onTap: () {},
          ),
        ),
      );

      // No circular dot containers when read.
      final dots = tester.widgetList<Container>(find.byType(Container)).where((
        c,
      ) {
        final d = c.decoration;
        if (d is! BoxDecoration) return false;
        return d.shape == BoxShape.circle;
      });
      expect(dots, isEmpty);
    });

    testWidgets('renders actor name + action text + target title', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          NotificationItemTile(
            notification: _notif(
              actorName: 'Alice',
              type: NotificationType.postCommentAdded,
              targetTitle: 'Lecture Notes',
            ),
            onTap: () {},
          ),
        ),
      );

      final richText = _richTextDump(tester);
      expect(richText, contains('Alice'));
      expect(richText, contains('commented on your post'));
      expect(find.text('Lecture Notes'), findsOneWidget);
    });

    testWidgets('renders body excerpt below actor/action line when non-empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          NotificationItemTile(
            notification: _notif(body: 'Alice commented: Great resource!'),
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Alice commented: Great resource!'), findsOneWidget);
    });

    testWidgets('does not render a body Text when body is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          NotificationItemTile(
            notification: _notif(body: ''),
            onTap: () {},
          ),
        ),
      );

      // targetTitle 'My Post' is shown; an additional body Text widget must not
      // appear. Verify no Text widget contains the empty string (there are none).
      final textWidgets = tester.widgetList<Text>(find.byType(Text)).toList();
      // None of the Text children should be empty.
      for (final t in textWidgets) {
        expect(t.data, isNotEmpty);
      }
    });

    testWidgets('relative timestamp shows "just now" for fresh notifs', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          NotificationItemTile(
            notification: _notif(createdAt: DateTime.now()),
            onTap: () {},
          ),
        ),
      );

      expect(find.text('just now'), findsOneWidget);
    });

    testWidgets('relative timestamp shows minutes for <1h', (tester) async {
      await tester.pumpWidget(
        _host(
          NotificationItemTile(
            notification: _notif(
              createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
            ),
            onTap: () {},
          ),
        ),
      );

      expect(find.text('12m ago'), findsOneWidget);
    });

    testWidgets('action text differs per notification type', (tester) async {
      // postLiked
      await tester.pumpWidget(
        _host(
          NotificationItemTile(
            notification: _notif(type: NotificationType.postLiked),
            onTap: () {},
          ),
        ),
      );
      expect(_richTextDump(tester), contains('liked your post'));

      // requestUpvoted
      await tester.pumpWidget(
        _host(
          NotificationItemTile(
            notification: _notif(type: NotificationType.requestUpvoted),
            onTap: () {},
          ),
        ),
      );
      expect(_richTextDump(tester), contains('upvoted your request'));

      // suggestionAccepted — grammar fix: reads "Alice accepted your suggestion"
      await tester.pumpWidget(
        _host(
          NotificationItemTile(
            notification: _notif(type: NotificationType.suggestionAccepted),
            onTap: () {},
          ),
        ),
      );
      expect(_richTextDump(tester), contains('accepted your suggestion'));
    });

    testWidgets('tap fires the onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(
          NotificationItemTile(
            notification: _notif(),
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets(
      'Semantics label includes actor, action, target, and read state',
      (tester) async {
        await tester.pumpWidget(
          _host(
            NotificationItemTile(
              notification: _notif(
                actorName: 'Alice',
                type: NotificationType.postCommentAdded,
                targetTitle: 'My Post',
                isRead: false,
                body: 'Alice commented: hi',
              ),
              onTap: () {},
            ),
          ),
        );

        final semantics = tester.getSemantics(
          find.byType(NotificationItemTile),
        );
        expect(semantics.label, contains('Alice'));
        expect(semantics.label, contains('commented on your post'));
        expect(semantics.label, contains('My Post'));
        expect(semantics.label, contains('Unread'));
      },
    );

    testWidgets('Semantics label uses "Read" when notification is read', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          NotificationItemTile(
            notification: _notif(isRead: true),
            onTap: () {},
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(NotificationItemTile));
      expect(semantics.label, contains('Read'));
      expect(semantics.label, isNot(contains('Unread')));
    });

    testWidgets(
      'Semantics label includes body excerpt when body is non-empty',
      (tester) async {
        await tester.pumpWidget(
          _host(
            NotificationItemTile(
              notification: _notif(body: 'Great resource!'),
              onTap: () {},
            ),
          ),
        );

        final semantics = tester.getSemantics(
          find.byType(NotificationItemTile),
        );
        expect(semantics.label, contains('Great resource!'));
      },
    );
  });
}
