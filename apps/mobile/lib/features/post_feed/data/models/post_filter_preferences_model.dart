import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:unishare_mobile/features/post_feed/domain/entities/post_filter_preferences.dart';

part 'post_filter_preferences_model.freezed.dart';
part 'post_filter_preferences_model.g.dart';

@freezed
abstract class PostFilterPreferencesModel with _$PostFilterPreferencesModel {
  const PostFilterPreferencesModel._();

  const factory PostFilterPreferencesModel({
    required List<String> selectedTags,
    required DateTime updatedAt,
  }) = _PostFilterPreferencesModel;

  factory PostFilterPreferencesModel.fromJson(Map<String, dynamic> json) =>
      _$PostFilterPreferencesModelFromJson(json);

  // TODO: add fromFirestore factory reading DocumentSnapshot
  PostFilterPreferences toEntity() =>
      PostFilterPreferences(selectedTags: selectedTags, updatedAt: updatedAt);
}
