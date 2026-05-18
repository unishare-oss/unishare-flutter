import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/user_gamification.dart';

part 'user_gamification_dto.freezed.dart';
part 'user_gamification_dto.g.dart';

@freezed
abstract class UserGamificationDto with _$UserGamificationDto {
  const UserGamificationDto._();

  const factory UserGamificationDto({
    @Default(0) int totalPoints,
    @Default(1) int level,
    String? selectedTitle,
    @Default(<String>[]) List<String> displayedBadges,
  }) = _UserGamificationDto;

  factory UserGamificationDto.fromJson(Map<String, dynamic> json) =>
      _$UserGamificationDtoFromJson(json);

  UserGamification toEntity() => UserGamification(
    totalPoints: totalPoints,
    level: level,
    selectedTitle: selectedTitle,
    displayedBadges: displayedBadges,
  );
}
