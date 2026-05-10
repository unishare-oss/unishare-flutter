import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:unishare_mobile/features/requests/domain/entities/suggestion.dart';

part 'suggestion_dto.freezed.dart';
part 'suggestion_dto.g.dart';

class _TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const _TimestampConverter();

  @override
  DateTime fromJson(Timestamp ts) => ts.toDate();

  @override
  Timestamp toJson(DateTime dt) => Timestamp.fromDate(dt);
}

@freezed
abstract class SuggestionDto with _$SuggestionDto {
  const factory SuggestionDto({
    required String id,
    required String postId,
    required String postTitle,
    required String postType,
    required String suggestedByUserId,
    required String suggestedByName,
    String? suggestedByAvatar,
    @_TimestampConverter() required DateTime createdAt,
  }) = _SuggestionDto;

  factory SuggestionDto.fromJson(Map<String, dynamic> json) =>
      _$SuggestionDtoFromJson(json);
}

extension SuggestionDtoMapper on SuggestionDto {
  Suggestion toDomain() => Suggestion(
    id: id,
    postId: postId,
    postTitle: postTitle,
    postType: postType,
    suggestedByUserId: suggestedByUserId,
    suggestedByName: suggestedByName,
    suggestedByAvatar: suggestedByAvatar,
    createdAt: createdAt,
  );
}
