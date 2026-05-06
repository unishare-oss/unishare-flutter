import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/requests/presentation/screens/requests_screen.dart';

void main() {
  testWidgets('RequestsScreen renders title and coming soon', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RequestsScreen())),
    );
    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
  });
}
