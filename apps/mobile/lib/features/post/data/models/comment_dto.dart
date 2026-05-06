// TODO(flutter-engineer): implement per SPEC-0006
// Run: dart run build_runner build --delete-conflicting-outputs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/converters/timestamp_converter.dart';
import '../../domain/entities/comment.dart';

part 'comment_dto.freezed.dart';
part 'comment_dto.g.dart';

@freezed
abstract class CommentDto with _$CommentDto {
  const CommentDto._();

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

  Comment toEntity() => Comment(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorAvatar: authorAvatar,
        body: body,
        createdAt: createdAt,
      );
}
