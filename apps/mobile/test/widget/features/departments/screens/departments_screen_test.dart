import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/departments/presentation/screens/departments_screen.dart';

void main() {
  testWidgets('DepartmentsScreen renders title and coming soon', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DepartmentsScreen()),
      ),
    );
    expect(find.text('Departments'), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
  });
}
