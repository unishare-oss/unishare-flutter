import 'package:flutter/material.dart';

/// A stateless like button widget.
///
/// - [isLiked] true → filled heart icon (red)
/// - [isLiked] false → outline heart icon
/// - [enabled] false → greyed out, tap is a no-op
class LikeButton extends StatelessWidget {
  const LikeButton({
    super.key,
    required this.isLiked,
    required this.count,
    required this.onTap,
    this.enabled = true,
  });

  final bool isLiked;
  final int count;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? Colors.grey
        : isLiked
        ? Colors.red
        : const Color(0xFF8a837e);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
