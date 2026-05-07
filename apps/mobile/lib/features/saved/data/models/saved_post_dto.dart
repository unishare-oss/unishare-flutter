import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:unishare_mobile/features/saved/domain/entities/saved_post.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post_snapshot.dart';

part 'saved_post_dto.freezed.dart';
part 'saved_post_dto.g.dart';

@freezed
abstract class SavedPostDto with _$SavedPostDto {
  const factory SavedPostDto({
    required String postId,
    // Timestamp → DateTime conversion is done at the datasource level before
    // fromJson is called, so the DTO stores DateTime directly.
    required DateTime savedAt,
    required String title,
    required String authorName,
    required String authorAvatar,
    required String courseId,
    required String postType,
    required List<String> tags,
    @Default(0) int commentsCount,
  }) = _SavedPostDto;

  factory SavedPostDto.fromJson(Map<String, dynamic> json) =>
      _$SavedPostDtoFromJson(json);
}

extension SavedPostDtoMapper on SavedPostDto {
  SavedPost toEntity() => SavedPost(
    postId: postId,
    savedAt: savedAt,
    snapshot: SavedPostSnapshot(
      title: title,
      authorName: authorName,
      authorAvatar: authorAvatar,
      courseId: courseId,
      postType: postType,
      tags: List.unmodifiable(tags),
      commentsCount: commentsCount,
    ),
  );
}
