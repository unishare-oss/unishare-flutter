import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

void main() {
  testWidgets('ProfileScreen renders Profile title in app bar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override to a fixed AppUser so the screen doesn't reach Firebase.
          currentUserProvider.overrideWith(
            (ref) async => const AppUser(
              id: 'u1',
              name: 'Alex Tester',
              email: 'alex@example.com',
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: const ProfileScreen(),
        ),
      ),
    );
    // One pump for first frame, one for the async user resolve.
    await tester.pump();
    await tester.pump();

    // App-bar title is present regardless of body state.
    expect(find.text('Profile'), findsOneWidget);
  });
}
