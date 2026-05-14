// test/widget/features/feed/feed_filter_drawer_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:unishare_mobile/features/feed/presentation/widgets/feed_filter_drawer.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> get authStateChanges => Stream.value(null);
  @override
  Future<AppUser> signInWithGoogle() => throw UnimplementedError();
  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? universityId,
  }) => throw UnimplementedError();
  @override
  Future<void> signOut() async {}
  @override
  Future<AppUser?> getCurrentUser() async => null;
  @override
  Future<void> updateAcademicProfile({
    required String uid,
    required String departmentId,
    int? enrollmentYear,
  }) async {}
}

Widget _buildSubject({List<Post> posts = const []}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: Scaffold(body: FeedFilterDrawer(loadedPosts: posts)),
    ),
  );
}

void main() {
  testWidgets('renders "Filter posts" title', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('Filter posts'), findsOneWidget);
  });

  testWidgets('renders RECENT and TRENDING sort buttons', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('RECENT'), findsOneWidget);
    expect(find.text('TRENDING'), findsOneWidget);
  });

  testWidgets('renders Clear and Apply action buttons', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
  });

  testWidgets('tapping Clear calls feedFilterProvider.clear()', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    container.read(feedFilterProvider.notifier).setYear(2);
    expect(container.read(feedFilterProvider).year, 2);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(AppThemes.unishare),
          home: Scaffold(body: FeedFilterDrawer(loadedPosts: const [])),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(container.read(feedFilterProvider), const FeedFilterState());
  });
}
