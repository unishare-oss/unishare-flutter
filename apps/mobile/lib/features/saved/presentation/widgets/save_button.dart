import 'package:flutter/material.dart';

class SaveButton extends StatelessWidget {
  const SaveButton({
    super.key,
    required this.isSaved,
    required this.onTap,
    this.isLoading = false,
    this.size = 20,
  });

  final bool isSaved;
  final VoidCallback onTap;
  final bool isLoading;
  final double size;

  static const _amber = Color(0xFFD97706);
  static const _muted = Color(0xFF8a837e);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _amber,
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Icon(
        isSaved ? Icons.bookmark : Icons.bookmark_border,
        size: size,
        color: isSaved ? _amber : _muted,
      ),
    );
  }
}
