import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:unishare_mobile/features/post/domain/entities/comment.dart';

part 'comment_dto.freezed.dart';
part 'comment_dto.g.dart';

/// Custom JSON converter that handles Firestore [Timestamp] ↔ [DateTime].
class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp ts) => ts.toDate();

  @override
  Timestamp toJson(DateTime dt) => Timestamp.fromDate(dt);
}

@freezed
abstract class CommentDto with _$CommentDto {
  const factory CommentDto({
    required String id,
    required String authorId,
    required String authorName,
    required String authorAvatar,
    required String body,
    @TimestampConverter() required DateTime createdAt,
  }) = _CommentDto;

  factory CommentDto.fromJson(Map<String, dynamic> json) =>
      _$CommentDtoFromJson(json);
}

extension CommentDtoMapper on CommentDto {
  Comment toEntity() => Comment(
    id: id,
    authorId: authorId,
    authorName: authorName,
    authorAvatar: authorAvatar,
    body: body,
    createdAt: createdAt,
  );
}
