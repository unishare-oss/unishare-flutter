import 'package:hive_flutter/hive_flutter.dart';

import 'package:unishare_mobile/features/saved/domain/entities/saved_post.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post_snapshot.dart';

// typeId: 2 — verified; PostDraftModelAdapter claims typeId 1.
class SavedPostHiveModel extends HiveObject {
  SavedPostHiveModel({
    required this.postId,
    required this.savedAt,
    required this.title,
    required this.authorName,
    required this.authorAvatar,
    required this.courseId,
    required this.postType,
    required this.tags,
    required this.commentsCount,
  });

  // field 0
  String postId;
  // field 1
  DateTime savedAt;
  // field 2
  String title;
  // field 3
  String authorName;
  // field 4
  String authorAvatar;
  // field 5
  String courseId;
  // field 6
  String postType;
  // field 7
  List<String> tags;
  // field 8
  int commentsCount;

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

  static SavedPostHiveModel fromEntity(SavedPost entity) => SavedPostHiveModel(
    postId: entity.postId,
    savedAt: entity.savedAt,
    title: entity.snapshot.title,
    authorName: entity.snapshot.authorName,
    authorAvatar: entity.snapshot.authorAvatar,
    courseId: entity.snapshot.courseId,
    postType: entity.snapshot.postType,
    tags: List<String>.from(entity.snapshot.tags),
    commentsCount: entity.snapshot.commentsCount,
  );
}

class SavedPostHiveModelAdapter extends TypeAdapter<SavedPostHiveModel> {
  @override
  final int typeId = 2;

  @override
  SavedPostHiveModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return SavedPostHiveModel(
      postId: fields[0] as String,
      savedAt: fields[1] as DateTime,
      title: fields[2] as String? ?? '',
      authorName: fields[3] as String? ?? '',
      authorAvatar: fields[4] as String? ?? '',
      courseId: fields[5] as String? ?? '',
      postType: fields[6] as String? ?? '',
      tags: (fields[7] as List?)?.cast<String>() ?? [],
      commentsCount: fields[8] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, SavedPostHiveModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.postId)
      ..writeByte(1)
      ..write(obj.savedAt)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.authorName)
      ..writeByte(4)
      ..write(obj.authorAvatar)
      ..writeByte(5)
      ..write(obj.courseId)
      ..writeByte(6)
      ..write(obj.postType)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.commentsCount);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedPostHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
