import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_frame.dart';

IconData _resolveGlyph(String name) {
  switch (name) {
    case 'user-circle':
      return PhosphorIconsThin.userCircle;
    case 'paper-plane-tilt':
      return PhosphorIconsThin.paperPlaneTilt;
    case 'bookmark-simple':
      return PhosphorIconsThin.bookmarkSimple;
    case 'chat-circle-dots':
      return PhosphorIconsThin.chatCircleDots;
    case 'hand-waving':
      return PhosphorIconsThin.handWaving;
    case 'sparkle':
      return PhosphorIconsThin.sparkle;
    case 'stack':
      return PhosphorIconsThin.stack;
    case 'lightbulb':
      return PhosphorIconsThin.lightbulb;
    case 'notebook':
      return PhosphorIconsThin.notebook;
    case 'chats':
      return PhosphorIconsThin.chats;
    case 'hand-heart':
      return PhosphorIconsThin.handHeart;
    case 'compass':
      return PhosphorIconsThin.compass;
    case 'books':
      return PhosphorIconsThin.books;
    case 'ear':
      return PhosphorIconsThin.ear;
    case 'anchor':
      return PhosphorIconsThin.anchor;
    case 'crown-simple':
      return PhosphorIconsThin.crownSimple;
    case 'tree':
      return PhosphorIconsThin.tree;
    case 'seal-check':
      return PhosphorIconsThin.sealCheck;
    case 'globe':
      return PhosphorIconsThin.globe;
    case 'medal':
      return PhosphorIconsThin.medal;
    default:
      return PhosphorIconsThin.question;
  }
}

class BadgeIcon extends StatelessWidget {
  const BadgeIcon({
    super.key,
    required this.badge,
    required this.locked,
    this.size = 48,
  });

  final AchievementBadge badge;
  final bool locked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return BadgeFrame(
      tier: badge.tier,
      locked: locked,
      size: size,
      child: Icon(locked ? PhosphorIconsThin.lock : _resolveGlyph(badge.glyph)),
    );
  }
}
