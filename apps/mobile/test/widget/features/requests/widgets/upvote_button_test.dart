import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/upvote_provider.dart';
import 'package:unishare_mobile/features/requests/presentation/widgets/upvote_button.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

Widget _wrap(Widget child, {bool hasUpvoted = false}) {
  return ProviderScope(
    overrides: [
      hasUpvotedProvider.overrideWith((ref, requestId) async => hasUpvoted),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('UpvoteButton', () {
    testWidgets('renders upvote count', (tester) async {
      await tester.pumpWidget(
        _wrap(const UpvoteButton(requestId: 'req-1', upvoteCount: 5)),
      );
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders chevron-up icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const UpvoteButton(requestId: 'req-1', upvoteCount: 3)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
    });

    testWidgets('is tappable and triggers toggle', (tester) async {
      var toggled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hasUpvotedProvider.overrideWith((ref, requestId) async => false),
            toggleUpvoteProvider.overrideWith(
              () => _FakeToggleUpvote(onToggle: () => toggled = true),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.build(AppThemes.unishare),
            home: const Scaffold(
              body: UpvoteButton(requestId: 'req-1', upvoteCount: 0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(toggled, isTrue);
    });

    testWidgets('inactive state — icon uses mutedForeground color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const UpvoteButton(requestId: 'req-1', upvoteCount: 0),
          hasUpvoted: false,
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext ctx = tester.element(find.byType(UpvoteButton));
      final ac = Theme.of(ctx).extension<AppColors>()!;

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.keyboard_arrow_up_rounded),
      );
      expect(icon.color, ac.mutedForeground);
    });

    testWidgets('active state — icon uses amber color when upvoted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const UpvoteButton(requestId: 'req-1', upvoteCount: 4),
          hasUpvoted: true,
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext ctx = tester.element(find.byType(UpvoteButton));
      final ac = Theme.of(ctx).extension<AppColors>()!;

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.keyboard_arrow_up_rounded),
      );
      expect(icon.color, ac.amber);
    });
  });
}

class _FakeToggleUpvote extends ToggleUpvote {
  _FakeToggleUpvote({required this.onToggle});
  final void Function() onToggle;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<void> toggle(String requestId) async {
    onToggle();
  }
}
