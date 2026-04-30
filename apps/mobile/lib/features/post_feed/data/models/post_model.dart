import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/post.dart';
import '../../domain/entities/post_type.dart';

part 'post_model.freezed.dart';
part 'post_model.g.dart';

@freezed
abstract class PostModel with _$PostModel {
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
    @Default('NOTE') String type,
    @Default('') String courseCode,
    @Default('') String courseDepartment,
    @Default(0) int commentCount,
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
      type: data['type'] as String? ?? 'NOTE',
      courseCode: data['courseCode'] as String? ?? '',
      courseDepartment: data['courseDepartment'] as String? ?? '',
      commentCount: data['commentCount'] as int? ?? 0,
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
        type: PostType.fromString(type),
        courseCode: courseCode.isEmpty ? null : courseCode,
        courseDepartment: courseDepartment.isEmpty ? null : courseDepartment,
        commentCount: commentCount,
      );
}

