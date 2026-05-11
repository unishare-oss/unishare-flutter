import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/requests/presentation/widgets/suggest_fulfillment_dialog.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

// The dialog fetches user posts from Firestore directly using FutureBuilder.
// We test the empty-state and the disabled-until-selection behavior by wrapping
// in a minimal ProviderScope.

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('SuggestFulfillmentDialog', () {
    testWidgets('renders dialog title', (tester) async {
      await tester.pumpWidget(
        _wrap(const SuggestFulfillmentDialog(requestId: 'req-1')),
      );
      await tester.pump();

      expect(find.text('Suggest a Fulfillment'), findsOneWidget);
    });

    testWidgets('Submit button is disabled until a post is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const SuggestFulfillmentDialog(requestId: 'req-1')),
      );
      // Wait for FutureBuilder to complete (will fail with FirebaseException in
      // test environment — the FutureBuilder returns empty list on error path).
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Submit is disabled when no post is selected.
      final submitButtons = tester.widgetList<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit'),
      );
      for (final btn in submitButtons) {
        expect(btn.onPressed, isNull);
      }
    });

    testWidgets('Cancel button is rendered', (tester) async {
      await tester.pumpWidget(
        _wrap(const SuggestFulfillmentDialog(requestId: 'req-1')),
      );
      await tester.pump();

      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
