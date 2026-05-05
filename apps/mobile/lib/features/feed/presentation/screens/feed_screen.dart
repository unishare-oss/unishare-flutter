import 'package:flutter/material.dart';

import '../../../../shared/widgets/scroll_to_top_target.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({required GlobalKey<State> scrollKey})
    : super(key: scrollKey);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with ScrollToTopTarget {
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
      appBar: AppBar(title: const Text('Feed')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
