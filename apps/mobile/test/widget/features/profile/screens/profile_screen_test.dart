import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/profile/presentation/screens/profile_screen.dart';

void main() {
  testWidgets('ProfileScreen renders title and coming soon', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfileScreen())),
    );
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
  });
}
