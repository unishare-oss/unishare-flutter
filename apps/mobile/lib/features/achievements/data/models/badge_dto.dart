import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';

part 'badge_dto.freezed.dart';
part 'badge_dto.g.dart';

@freezed
abstract class BadgeConditionDto with _$BadgeConditionDto {
  const factory BadgeConditionDto({
    required String type,
    required int threshold,
  }) = _BadgeConditionDto;

  factory BadgeConditionDto.fromJson(Map<String, dynamic> json) =>
      _$BadgeConditionDtoFromJson(json);
}

@freezed
abstract class BadgeDto with _$BadgeDto {
  const BadgeDto._();

  const factory BadgeDto({
    required String id,
    required String name,
    required String description,
    required String glyph,
    required int points,
    required String tier,
    required String category,
    required BadgeConditionDto condition,
    required int order,
    required bool active,
  }) = _BadgeDto;

  factory BadgeDto.fromJson(Map<String, dynamic> json) =>
      _$BadgeDtoFromJson(json);

  factory BadgeDto.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) =>
      BadgeDto.fromJson({...snap.data() ?? const {}, 'id': snap.id});

  AchievementBadge toEntity() => AchievementBadge(
    id: id,
    name: name,
    description: description,
    glyph: glyph,
    points: points,
    tier: BadgeTier.values.firstWhere(
      (t) => t.name == tier,
      orElse: () => BadgeTier.progression,
    ),
    category: BadgeCategory.values.firstWhere(
      (c) => c.name == category,
      orElse: () => BadgeCategory.content,
    ),
    condition: BadgeCondition(
      statKey: condition.type,
      threshold: condition.threshold,
    ),
    order: order,
    active: active,
  );
}
