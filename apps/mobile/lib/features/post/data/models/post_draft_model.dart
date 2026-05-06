import 'package:hive_flutter/hive_flutter.dart';

import 'package:unishare_mobile/features/post/domain/entities/code_snippet.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

// typeId: 1 — verified no other model claims this ID in this codebase.
class PostDraftModel extends HiveObject {
  PostDraftModel({
    required this.id,
    required this.postTypeIndex,
    required this.year,
    required this.courseId,
    required this.title,
    required this.description,
    required this.postingIdentityIndex,
    required this.semester,
    required this.moduleNumber,
    required this.tags,
    required this.localMediaPaths,
    required this.uploadedUrls,
    required this.createdAt,
    required this.statusIndex,
    this.externalUrl,
    this.errorMessage,
    this.codeSnippetLanguage,
    this.codeSnippetFilename,
    this.codeSnippetContent,
  });

  // field 0
  String id;
  // field 1
  int postTypeIndex;
  // field 2
  int year;
  // field 3
  String courseId;
  // field 4
  String title;
  // field 5
  String description;
  // field 6
  int postingIdentityIndex;
  // field 7
  int semester;
  // field 8
  String moduleNumber;
  // field 9
  String? externalUrl;
  // field 10
  List<String> tags;
  // field 11
  List<String> localMediaPaths;
  // field 12
  Map<String, String> uploadedUrls;
  // field 13
  DateTime createdAt;
  // field 14
  int statusIndex;
  // field 15
  String? errorMessage;
  // field 16
  String? codeSnippetLanguage;
  // field 17
  String? codeSnippetFilename;
  // field 18
  String? codeSnippetContent;

  PostDraft toEntity() {
    CodeSnippet? snippet;
    if (codeSnippetLanguage != null &&
        codeSnippetFilename != null &&
        codeSnippetContent != null) {
      snippet = CodeSnippet(
        language: codeSnippetLanguage!,
        filename: codeSnippetFilename!,
        content: codeSnippetContent!,
      );
    }
    return PostDraft(
      id: id,
      postType: PostType.values[postTypeIndex],
      year: year,
      courseId: courseId,
      title: title,
      description: description,
      postingIdentity: PostingIdentity.values[postingIdentityIndex],
      semester: semester,
      moduleNumber: moduleNumber,
      externalUrl: externalUrl,
      tags: List<String>.from(tags),
      localMediaPaths: List<String>.from(localMediaPaths),
      uploadedUrls: Map<String, String>.from(uploadedUrls),
      createdAt: createdAt,
      status: DraftStatus.values[statusIndex],
      errorMessage: errorMessage,
      codeSnippet: snippet,
    );
  }

  static PostDraftModel fromEntity(PostDraft draft) {
    return PostDraftModel(
      id: draft.id,
      postTypeIndex: draft.postType.index,
      year: draft.year,
      courseId: draft.courseId,
      title: draft.title,
      description: draft.description,
      postingIdentityIndex: draft.postingIdentity.index,
      semester: draft.semester,
      moduleNumber: draft.moduleNumber,
      externalUrl: draft.externalUrl,
      tags: List<String>.from(draft.tags),
      localMediaPaths: List<String>.from(draft.localMediaPaths),
      uploadedUrls: Map<String, String>.from(draft.uploadedUrls),
      createdAt: draft.createdAt,
      statusIndex: draft.status.index,
      errorMessage: draft.errorMessage,
      codeSnippetLanguage: draft.codeSnippet?.language,
      codeSnippetFilename: draft.codeSnippet?.filename,
      codeSnippetContent: draft.codeSnippet?.content,
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
      postTypeIndex: fields[1] as int? ?? 0,
      year: fields[2] as int? ?? 1,
      courseId: fields[3] as String? ?? '',
      title: fields[4] as String? ?? '',
      description: fields[5] as String? ?? '',
      postingIdentityIndex: fields[6] as int? ?? 0,
      semester: fields[7] as int? ?? 1,
      moduleNumber: fields[8] as String? ?? '',
      externalUrl: fields[9] as String?,
      tags: (fields[10] as List?)?.cast<String>() ?? [],
      localMediaPaths: (fields[11] as List?)?.cast<String>() ?? [],
      uploadedUrls: (fields[12] as Map?)?.cast<String, String>() ?? {},
      createdAt: fields[13] as DateTime? ?? DateTime(2026),
      statusIndex: fields[14] as int? ?? 0,
      errorMessage: fields[15] as String?,
      codeSnippetLanguage: fields[16] as String?,
      codeSnippetFilename: fields[17] as String?,
      codeSnippetContent: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PostDraftModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.postTypeIndex)
      ..writeByte(2)
      ..write(obj.year)
      ..writeByte(3)
      ..write(obj.courseId)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.postingIdentityIndex)
      ..writeByte(7)
      ..write(obj.semester)
      ..writeByte(8)
      ..write(obj.moduleNumber)
      ..writeByte(9)
      ..write(obj.externalUrl)
      ..writeByte(10)
      ..write(obj.tags)
      ..writeByte(11)
      ..write(obj.localMediaPaths)
      ..writeByte(12)
      ..write(obj.uploadedUrls)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.statusIndex)
      ..writeByte(15)
      ..write(obj.errorMessage)
      ..writeByte(16)
      ..write(obj.codeSnippetLanguage)
      ..writeByte(17)
      ..write(obj.codeSnippetFilename)
      ..writeByte(18)
      ..write(obj.codeSnippetContent);
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
