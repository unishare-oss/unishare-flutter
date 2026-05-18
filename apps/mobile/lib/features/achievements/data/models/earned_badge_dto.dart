import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';

part 'earned_badge_dto.freezed.dart';

@freezed
abstract class EarnedBadgeDto with _$EarnedBadgeDto {
  const EarnedBadgeDto._();

  const factory EarnedBadgeDto({
    required String badgeId,
    required Timestamp earnedAt,
    required int pointsAwarded,
  }) = _EarnedBadgeDto;

  factory EarnedBadgeDto.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? const <String, dynamic>{};
    return EarnedBadgeDto(
      badgeId: data['badgeId'] as String? ?? snap.id,
      earnedAt: data['earnedAt'] as Timestamp? ?? Timestamp.now(),
      pointsAwarded: (data['pointsAwarded'] as num?)?.toInt() ?? 0,
    );
  }

  EarnedBadge toEntity() => EarnedBadge(
    badgeId: badgeId,
    earnedAt: earnedAt.toDate(),
    pointsAwarded: pointsAwarded,
  );
}
