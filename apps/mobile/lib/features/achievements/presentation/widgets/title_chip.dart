import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';

class TitleChip extends StatelessWidget {
  const TitleChip({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.bodySmall?.copyWith(color: ac.mutedForeground),
    );
  }
}
