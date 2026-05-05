import 'package:flutter/material.dart';

import '../../../../shared/widgets/scroll_to_top_target.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({required GlobalKey<State> scrollKey})
    : super(key: scrollKey);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with ScrollToTopTarget {
  final ScrollController _scrollController = ScrollController();

  @override
  ScrollController get scrollController => _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
