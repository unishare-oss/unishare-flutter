import 'package:flutter/material.dart';

import '../../../../shared/widgets/scroll_to_top_target.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({required GlobalKey<State> scrollKey})
    : super(key: scrollKey);

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> with ScrollToTopTarget {
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
      appBar: AppBar(title: const Text('My Posts')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
