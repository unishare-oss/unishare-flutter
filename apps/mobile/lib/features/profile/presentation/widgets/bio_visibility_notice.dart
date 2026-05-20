import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

/// One-time banner shown to users with a non-empty bio after the
/// SPEC-0011 rollout, since their bio is now mirrored into
/// `users_public/{uid}` and visible to any signed-in student.
///
/// Hides itself permanently once the user taps "Got it" by setting
/// [_dismissedKey] in the existing `settings` Hive box.
class BioVisibilityNotice extends StatefulWidget {
  const BioVisibilityNotice({super.key, required this.user});
  final AppUser user;

  @override
  State<BioVisibilityNotice> createState() => _BioVisibilityNoticeState();
}

const _settingsBox = 'settings';
const _dismissedKey = 'bio_visibility_notice_dismissed';

class _BioVisibilityNoticeState extends State<BioVisibilityNotice> {
  bool _dismissed = false;

  bool get _hasBio => (widget.user.bio ?? '').trim().isNotEmpty;

  bool _readDismissed() {
    if (!Hive.isBoxOpen(_settingsBox)) return false;
    return Hive.box(_settingsBox).get(_dismissedKey) == true;
  }

  Future<void> _dismiss() async {
    if (Hive.isBoxOpen(_settingsBox)) {
      await Hive.box(_settingsBox).put(_dismissedKey, true);
    }
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || !_hasBio || _readDismissed()) {
      return const SizedBox.shrink();
    }
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: ac.amberSubtle,
        border: Border.all(color: ac.amber, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: ac.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your bio is now visible to other students.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ac.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              'Take a moment to review or edit it below.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: ac.mutedForeground,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _dismiss,
              style: TextButton.styleFrom(foregroundColor: ac.amber),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}
