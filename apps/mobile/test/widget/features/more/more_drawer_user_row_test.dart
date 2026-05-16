import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_user_row.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/profile_card.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.build(AppThemes.unishare),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders name, uppercase role badge, and initials', (
    tester,
  ) async {
    const user = AppUser(
      id: 'u1',
      name: 'Pyae Sone Shin Thant',
      email: 'p@example.com',
      role: 'admin',
    );

    await tester.pumpWidget(_wrap(const MoreDrawerUserRow(user: user)));

    expect(find.text('Pyae Sone Shin Thant'), findsOneWidget);
    expect(find.byType(ProfileBadge), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);
    // Avatar initials: first letter of first two words.
    expect(find.text('PS'), findsOneWidget);
  });

  testWidgets('single-word name falls back to first two characters', (
    tester,
  ) async {
    const user = AppUser(id: 'u1', name: 'Alex', email: 'a@example.com');

    await tester.pumpWidget(_wrap(const MoreDrawerUserRow(user: user)));

    expect(find.text('AL'), findsOneWidget);
  });

  testWidgets('empty name renders "?" placeholder', (tester) async {
    const user = AppUser(id: 'u1', name: '', email: 'a@example.com');

    await tester.pumpWidget(_wrap(const MoreDrawerUserRow(user: user)));

    expect(find.text('?'), findsOneWidget);
  });
}
