import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/shared/widgets/scroll_to_top_target.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({required GlobalKey<State> scrollKey})
    : super(key: scrollKey);

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen>
    with ScrollToTopTarget {
  final ScrollController _scrollController = ScrollController();

  @override
  ScrollController get scrollController => _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static const _destinations = [
    (label: 'Profile', route: '/more/profile', icon: Icons.person_outline),
    (label: 'Saved', route: '/more/saved', icon: Icons.bookmark_outline),
    (
      label: 'Departments',
      route: '/more/departments',
      icon: Icons.school_outlined,
    ),
    (label: 'Requests', route: '/more/requests', icon: Icons.inbox_outlined),
  ];

  Future<void> _signOut() async {
    await ref.read(signOutUseCaseProvider).call();
    ref.read(guestModeProvider.notifier).exit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        controller: _scrollController,
        children: [
          ..._destinations.map(
            (dest) => ListTile(
              leading: Icon(dest.icon),
              title: Text(dest.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(dest.route),
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text('Sign out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }
}
