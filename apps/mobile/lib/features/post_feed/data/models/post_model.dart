import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/post.dart';

part 'post_model.freezed.dart';
part 'post_model.g.dart';

@freezed
class PostModel with _$PostModel {
  const PostModel._();

  const factory PostModel({
    required String id,
    required String authorId,
    required String authorName,
    required String authorAvatar,
    required String title,
    required String body,
    @Default([]) List<String> mediaUrls,
    @Default([]) List<String> tags,
    @Default(0) int likesCount,
    @Default(false) bool isLikedByCurrentUser,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PostModel;

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);

  factory PostModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    bool isLiked,
  ) {
    final data = doc.data()!;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
      authorAvatar: data['authorAvatar'] as String? ?? '',
      title: data['title'] as String,
      body: data['body'] as String,
      mediaUrls: (data['mediaUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      likesCount: data['likesCount'] as int? ?? 0,
      isLikedByCurrentUser: isLiked,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Post toEntity() => Post(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorAvatar: authorAvatar,
        title: title,
        body: body,
        mediaUrls: mediaUrls,
        tags: tags,
        likesCount: likesCount,
        isLikedByCurrentUser: isLikedByCurrentUser,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
