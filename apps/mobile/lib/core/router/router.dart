import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/auth/presentation/providers/guest_mode_provider.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/widgets/academic_profile_bottom_sheet.dart';

part 'router.g.dart';

// ---------------------------------------------------------------------------
// Session-level dismissal state (resets on cold start)
// ---------------------------------------------------------------------------

// Simple in-memory flag — not a Riverpod provider to keep it out of codegen.
bool _academicProfileSessionDismissed = false;

// ---------------------------------------------------------------------------
// Notifier — watches auth + guest state, calls notifyListeners on change
// ---------------------------------------------------------------------------

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<Object?>>(
      authStateProvider,
      (prev, next) => notifyListeners(),
    );
    _ref.listen<bool>(guestModeProvider, (prev, next) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(authStateProvider);
    final isGuest = _ref.read(guestModeProvider);

    // hasValue is true only when the stream has emitted a data event.
    // .value returns null for loading/error, and the actual value (which may
    // itself be null = signed-out) for AsyncData.
    final isAuthenticated = authAsync.hasValue && authAsync.value != null;

    const authRoutes = {'/welcome', '/sign-in', '/sign-up'};
    final currentPath = state.uri.path;

    // 1. No session + not guest → force /welcome
    if (!isAuthenticated && !isGuest) {
      if (!authRoutes.contains(currentPath)) {
        return '/welcome';
      }
      return null;
    }

    // 2. Authenticated → redirect away from auth routes to /
    if (isAuthenticated && authRoutes.contains(currentPath)) {
      return '/';
    }

    return null;
  }
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

@riverpod
GoRouter router(Ref ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const _HomeScreen()),
    ],
  );
}

// ---------------------------------------------------------------------------
// Home screen — shows feed placeholder + triggers academic profile overlay
// ---------------------------------------------------------------------------

class _HomeScreen extends ConsumerStatefulWidget {
  const _HomeScreen();

  @override
  ConsumerState<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<_HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowProfile());
  }

  void _maybeShowProfile() {
    if (!mounted) return;

    final authAsync = ref.read(authStateProvider);
    final user = authAsync.hasValue ? authAsync.value : null;

    if (user != null &&
        user.departmentId == null &&
        !_academicProfileSessionDismissed) {
      _academicProfileSessionDismissed = true;
      showAcademicProfileBottomSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unishare')),
      body: const Center(child: Text('Unishare')),
    );
  }
}
