import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/tag_entity.dart';

part 'tag_model.freezed.dart';
part 'tag_model.g.dart';

@freezed
abstract class TagModel with _$TagModel {
  const TagModel._();

  const factory TagModel({
    required String id,
    required String label,
    required String department,
    required String code,
  }) = _TagModel;

  factory TagModel.fromJson(Map<String, dynamic> json) =>
      _$TagModelFromJson(json);

  // TODO: add fromFirestore factory reading DocumentSnapshot
  TagEntity toEntity() =>
      TagEntity(id: id, label: label, department: department, code: code);
}
