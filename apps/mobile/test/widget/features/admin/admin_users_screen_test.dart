import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/admin/domain/entities/admin_user.dart';
import 'package:unishare_mobile/features/admin/presentation/providers/admin_providers.dart';
import 'package:unishare_mobile/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

const _fakeUsers = [
  AdminUser(id: 'u1', name: 'Alice', email: 'alice@uni.edu', role: 'student'),
  AdminUser(id: 'u2', name: 'Bob', email: 'bob@uni.edu', role: 'moderator'),
];

Widget _pump(Stream<List<AdminUser>> users) => ProviderScope(
  overrides: [adminUsersProvider.overrideWith((ref) => users)],
  child: MaterialApp(
    theme: AppTheme.build(AppThemes.unishare),
    home: const AdminUsersScreen(),
  ),
);

void main() {
  group('AdminUsersScreen', () {
    testWidgets('shows loading indicator while users load', (tester) async {
      await tester.pumpWidget(_pump(const Stream.empty()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders user rows with name, email and role', (tester) async {
      await tester.pumpWidget(_pump(Stream.value(_fakeUsers)));
      await tester.pump();
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('bob@uni.edu'), findsOneWidget);
      expect(find.text('moderator'), findsOneWidget);
    });

    testWidgets('shows empty state when there are no users', (tester) async {
      await tester.pumpWidget(_pump(Stream.value(const [])));
      await tester.pump();
      expect(find.text('No users'), findsOneWidget);
    });

    // TODO(template): add interaction tests — tapping the role pill opens the
    // role picker and calls AdminUserActions.setRole; the ban menu item
    // surfaces the not-implemented message until the backend lands.
  });
}
