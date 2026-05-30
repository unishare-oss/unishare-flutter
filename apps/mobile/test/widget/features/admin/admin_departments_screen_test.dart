import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/admin/presentation/providers/admin_providers.dart';
import 'package:unishare_mobile/features/admin/presentation/screens/admin_departments_screen.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

const _fakeDepts = <({String id, String name})>[
  (id: 'cs', name: 'Computer Science'),
  (id: 'cpe', name: 'Computer Engineering'),
];

Widget _pump(Stream<List<({String id, String name})>> depts) => ProviderScope(
  overrides: [adminDepartmentsProvider.overrideWith((ref) => depts)],
  child: MaterialApp(
    theme: AppTheme.build(AppThemes.unishare),
    home: const AdminDepartmentsScreen(),
  ),
);

void main() {
  group('AdminDepartmentsScreen', () {
    testWidgets('shows loading indicator while departments load', (
      tester,
    ) async {
      await tester.pumpWidget(_pump(const Stream.empty()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('lists departments with id and name', (tester) async {
      await tester.pumpWidget(_pump(Stream.value(_fakeDepts)));
      await tester.pump();
      expect(find.text('Computer Science'), findsOneWidget);
      expect(find.text('cpe'), findsOneWidget);
    });

    testWidgets('shows empty state when there are no departments', (
      tester,
    ) async {
      await tester.pumpWidget(_pump(Stream.value(const [])));
      await tester.pump();
      expect(find.text('No departments yet'), findsOneWidget);
    });

    // TODO(template): add a test that the FAB opens the create-department
    // dialog and that submitting calls AdminCatalogActions.createDepartment.
  });
}
