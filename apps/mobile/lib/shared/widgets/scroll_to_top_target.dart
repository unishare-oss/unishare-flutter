import 'package:flutter/widgets.dart';

mixin ScrollToTopTarget {
  ScrollController get scrollController;

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
