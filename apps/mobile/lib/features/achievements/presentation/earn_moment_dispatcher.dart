import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/new_badge_alert_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/earn_moment_modal.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/earn_moment_toast.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';

const _restPrefixes = <String>{
  '/feed',
  '/profile',
  '/notifications',
  '/saved',
  '/achievements',
  '/posts',
};

bool _isRestRoute(String location) {
  if (location == '/' || location.isEmpty) return false;
  for (final p in _restPrefixes) {
    if (location == p || location.startsWith('$p/')) return true;
  }
  return false;
}

class EarnMomentDispatcher extends ConsumerStatefulWidget {
  const EarnMomentDispatcher({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<EarnMomentDispatcher> createState() =>
      _EarnMomentDispatcherState();
}

class _EarnMomentDispatcherState extends ConsumerState<EarnMomentDispatcher> {
  bool _draining = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) return widget.child;
    final uid = user.id;

    final queue = ref.watch(newBadgeAlertProvider(uid));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeDrain(uid, queue);
    });
    return widget.child;
  }

  Future<void> _maybeDrain(String uid, List<EarnedBadge> queue) async {
    if (_draining || queue.isEmpty || !mounted) return;
    final location = GoRouterState.of(context).uri.path;
    if (!_isRestRoute(location)) return;

    _draining = true;
    try {
      final catalog = ref.read(badgeCatalogProvider).asData?.value ?? const [];
      final byId = <String, AchievementBadge>{for (final b in catalog) b.id: b};
      for (final earned in List<EarnedBadge>.of(queue)) {
        if (!mounted) break;
        final badge = byId[earned.badgeId];
        if (badge != null) {
          await _showOne(badge, earned);
        }
        await ref
            .read(newBadgeAlertProvider(uid).notifier)
            .markSeen(earned);
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _showOne(AchievementBadge badge, EarnedBadge earned) async {
    final useModal = badge.tier == BadgeTier.onboarding ||
        badge.tier == BadgeTier.prestige;
    if (useModal) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => EarnMomentModal(
          badge: badge,
          points: earned.pointsAwarded,
        ),
      );
    } else {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.showSnackBar(
          buildEarnMomentToast(context, badge, earned.pointsAwarded),
        );
        await Future.delayed(const Duration(milliseconds: 3200));
      }
    }
  }
}
