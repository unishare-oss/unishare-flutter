import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/shared/widgets/scroll_to_top_target.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({required GlobalKey<State> scrollKey})
    : super(key: scrollKey);

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> with ScrollToTopTarget {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _destinations.length,
        itemBuilder: (context, index) {
          final dest = _destinations[index];
          return ListTile(
            leading: Icon(dest.icon),
            title: Text(dest.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(dest.route),
          );
        },
      ),
    );
  }
}
