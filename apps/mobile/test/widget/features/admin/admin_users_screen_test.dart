import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/admin/domain/entities/admin_user.dart';
import 'package:unishare_mobile/features/admin/presentation/providers/admin_providers.dart';
import 'package:unishare_mobile/features/admin/presentation/screens/admin_users_screen.dart';

const _fakeUsers = [
  AdminUser(id: 'u1', name: 'Alice', email: 'alice@uni.edu', role: 'student'),
  AdminUser(id: 'u2', name: 'Bob', email: 'bob@uni.edu', role: 'moderator'),
];

void main() {
  group('AdminUsersScreen', () {
    testWidgets('shows loading indicator while users load', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminUsersProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: const MaterialApp(home: AdminUsersScreen()),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders user rows with name, email and role', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminUsersProvider.overrideWith((ref) => Stream.value(_fakeUsers)),
          ],
          child: const MaterialApp(home: AdminUsersScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('bob@uni.edu'), findsOneWidget);
      expect(find.text('moderator'), findsOneWidget);
    });

    testWidgets('shows empty state when there are no users', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminUsersProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: const MaterialApp(home: AdminUsersScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('No users'), findsOneWidget);
    });

    // TODO(template): add interaction tests — tapping the role menu calls
    // AdminUserActions.setRole; the ban button surfaces the not-implemented
    // message until the backend lands.
  });
}
