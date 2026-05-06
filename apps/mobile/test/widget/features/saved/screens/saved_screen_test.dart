import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/saved/presentation/screens/saved_screen.dart';

void main() {
  testWidgets('SavedScreen renders title and coming soon', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SavedScreen())),
    );
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
  });
}
