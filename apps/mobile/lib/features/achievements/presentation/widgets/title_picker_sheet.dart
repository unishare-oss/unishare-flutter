import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/achievements/domain/usecases/set_displayed_badges.dart';
import 'package:unishare_mobile/features/achievements/domain/usecases/set_selected_title.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/user_gamification_provider.dart';

class TitlePickerSheet extends ConsumerWidget {
  const TitlePickerSheet({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(badgeCatalogProvider).asData?.value ?? const [];
    final earned =
        ref.watch(earnedBadgesProvider(uid)).asData?.value ?? const [];
    final earnedIds = earned.map((e) => e.badgeId).toSet();
    final available = catalog.where((b) => earnedIds.contains(b.id)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    Future<void> select(String? id) async {
      final repo = ref.read(gamificationRepositoryProvider);
      try {
        await SetSelectedTitle(repo)(
          uid: uid,
          badgeId: id,
          earnedIds: earnedIds,
        );
        if (context.mounted) Navigator.of(context).pop();
      } on DisplayedBadgesException catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text('Pick a title to display under your name'),
            ),
          ),
          ListTile(title: const Text('No title'), onTap: () => select(null)),
          ...available.map(
            (b) => ListTile(title: Text(b.name), onTap: () => select(b.id)),
          ),
        ],
      ),
    );
  }
}
