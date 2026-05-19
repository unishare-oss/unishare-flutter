import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/user_stats.dart';

part 'user_stats_dto.freezed.dart';
part 'user_stats_dto.g.dart';

@freezed
abstract class UserStatsDto with _$UserStatsDto {
  const UserStatsDto._();

  const factory UserStatsDto({
    @Default(0) int postsCreated,
    @Default(0) int savesReceived,
    @Default(0) int postsWithAtLeastOneSave,
    @Default(0) int uniqueSaversCount,
    @Default(0) int requestsFulfilled,
    @Default(0) int requestsCreated,
    @Default(0) int commentsWritten,
    @Default(0) int savesGiven,
    @Default(<String>[]) List<String> uniqueDepartmentsContributed,
    @Default(false) bool profileCompleted,
  }) = _UserStatsDto;

  factory UserStatsDto.fromJson(Map<String, dynamic> json) =>
      _$UserStatsDtoFromJson(json);

  UserStats toEntity() => UserStats(
    postsCreated: postsCreated,
    savesReceived: savesReceived,
    postsWithAtLeastOneSave: postsWithAtLeastOneSave,
    uniqueSaversCount: uniqueSaversCount,
    requestsFulfilled: requestsFulfilled,
    requestsCreated: requestsCreated,
    commentsWritten: commentsWritten,
    savesGiven: savesGiven,
    uniqueDepartmentsContributed: uniqueDepartmentsContributed,
    profileCompleted: profileCompleted,
  );
}
