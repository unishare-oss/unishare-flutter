import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    if (isLoading) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: appColors.amber,
        ),
      );
    }
    final iconColor = isSaved ? appColors.amber : appColors.textMuted;
    return Tooltip(
      message: isSaved ? 'Unsave' : 'Save',
      child: Semantics(
        label: isSaved ? 'Unsave post' : 'Save post',
        button: true,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(
            isSaved ? Icons.bookmark : Icons.bookmark_border,
            size: size,
          ),
          color: iconColor,
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(4),
            minimumSize: Size(size + 8, size + 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            highlightColor: appColors.amber.withValues(alpha: 0.15),
            foregroundColor: iconColor,
          ),
        ),
      ),
    );
  }
}
