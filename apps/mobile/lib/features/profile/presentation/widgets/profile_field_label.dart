import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

/// A small mono-spaced uppercase label used above form fields on the profile
/// screen.  Extracted here so it can be shared between [ProfileFormCard] and
/// [ChangePasswordCard] without duplication.
class ProfileFieldLabel extends StatelessWidget {
  const ProfileFieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    return Text(
      text,
      style: AppTypography.mono(
        base: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: ac.textMuted,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
