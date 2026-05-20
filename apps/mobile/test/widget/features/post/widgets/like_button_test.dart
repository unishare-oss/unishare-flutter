import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/like_button.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

void main() {
  group('LikeButton', () {
    testWidgets('isLiked: true → filled heart icon (Icons.favorite)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: Scaffold(
            body: LikeButton(isLiked: true, count: 5, onTap: () {}),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('isLiked: false → outline heart icon (Icons.favorite_border)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: Scaffold(
            body: LikeButton(isLiked: false, count: 3, onTap: () {}),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('enabled: false disables tap — onTap not fired', (
      tester,
    ) async {
      var tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: Scaffold(
            body: LikeButton(
              isLiked: false,
              count: 0,
              onTap: () => tapCount++,
              enabled: false,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(LikeButton));
      await tester.pump();

      expect(tapCount, 0);
    });

    testWidgets('onTap fires when enabled is true', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: Scaffold(
            body: LikeButton(isLiked: false, count: 0, onTap: () => tapCount++),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(LikeButton));
      await tester.pump();

      expect(tapCount, 1);
    });

    testWidgets('count is displayed as text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: Scaffold(
            body: LikeButton(isLiked: false, count: 42, onTap: () {}),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('42'), findsOneWidget);
    });
  });
}
