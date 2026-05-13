import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/departments_provider.dart';
import 'package:unishare_mobile/features/departments/presentation/screens/departments_screen.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

Widget _buildSubject({
  List<({String id, String name})> departments = const [],
}) {
  return ProviderScope(
    overrides: [
      departmentsProvider.overrideWith((_) => Stream.value(departments)),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: const DepartmentsScreen(),
    ),
  );
}

void main() {
  testWidgets('renders "Departments" title', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('Departments'), findsOneWidget);
  });

  testWidgets('shows empty state when no departments', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('No departments found.'), findsOneWidget);
  });

  testWidgets('renders department names', (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        departments: [
          (id: 'eng', name: 'Engineering'),
          (id: 'sci', name: 'Science'),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('Engineering'), findsOneWidget);
    expect(find.text('Science'), findsOneWidget);
  });

  testWidgets('department tiles are tappable (GestureDetector present)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildSubject(departments: [(id: 'eng', name: 'Engineering')]),
    );
    await tester.pump();
    expect(find.byType(GestureDetector), findsWidgets);
  });
}
