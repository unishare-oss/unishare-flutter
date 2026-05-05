import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../auth/presentation/widgets/academic_profile_dialog.dart';
import '../../../../shared/widgets/scroll_to_top_target.dart';

// Resets on cold start — same session-guard behaviour as the old _HomeScreen.
bool _academicProfileSessionDismissed = false;

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({required GlobalKey<State> scrollKey})
    : super(key: scrollKey);

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with ScrollToTopTarget {
  final ScrollController _scrollController = ScrollController();

  @override
  ScrollController get scrollController => _scrollController;

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
