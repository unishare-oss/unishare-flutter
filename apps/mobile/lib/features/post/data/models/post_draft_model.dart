import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/post_draft.dart';

class PostDraftModel {
  PostDraftModel({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.localMediaPaths,
    required this.uploadedUrls,
    required this.createdAt,
    required this.statusIndex,
    this.errorMessage,
  });

  String id;
  String title;
  String body;
  List<String> tags;
  List<String> localMediaPaths;
  Map<String, String> uploadedUrls;
  DateTime createdAt;
  int statusIndex;
  String? errorMessage;

  PostDraft toEntity() {
    return PostDraft(
      id: id,
      title: title,
      body: body,
      tags: List<String>.from(tags),
      localMediaPaths: List<String>.from(localMediaPaths),
      uploadedUrls: Map<String, String>.from(uploadedUrls),
      createdAt: createdAt,
      status: DraftStatus.values[statusIndex],
      errorMessage: errorMessage,
    );
  }

  static PostDraftModel fromEntity(PostDraft draft) {
    return PostDraftModel(
      id: draft.id,
      title: draft.title,
      body: draft.body,
      tags: List<String>.from(draft.tags),
      localMediaPaths: List<String>.from(draft.localMediaPaths),
      uploadedUrls: Map<String, String>.from(draft.uploadedUrls),
      createdAt: draft.createdAt,
      statusIndex: draft.status.index,
      errorMessage: draft.errorMessage,
    );
  }
}

class PostDraftModelAdapter extends TypeAdapter<PostDraftModel> {
  @override
  final int typeId = 1;

  @override
  PostDraftModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return PostDraftModel(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String,
      tags: (fields[3] as List).cast<String>(),
      localMediaPaths: (fields[4] as List).cast<String>(),
      uploadedUrls: (fields[5] as Map).cast<String, String>(),
      createdAt: fields[6] as DateTime,
      statusIndex: fields[7] as int,
      errorMessage: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PostDraftModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.tags)
      ..writeByte(4)
      ..write(obj.localMediaPaths)
      ..writeByte(5)
      ..write(obj.uploadedUrls)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.statusIndex)
      ..writeByte(8)
      ..write(obj.errorMessage);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostDraftModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
