import 'package:unishare_mobile/features/post_feed/domain/entities/post_filter_preferences.dart';
import 'package:unishare_mobile/features/post_feed/domain/repositories/preferences_repository.dart';

class SaveFilterPreferences {
  const SaveFilterPreferences(this._repository);

  final PreferencesRepository _repository;

  Future<void> call({required String uid, required List<String> selectedTags}) {
    if (selectedTags.any((t) => t.trim().isEmpty)) {
      throw ArgumentError('tag strings must not be blank');
    }
    final preferences = PostFilterPreferences(
      selectedTags: selectedTags,
      updatedAt: DateTime.now(),
    );
    return _repository.saveFilterPreferences(uid, preferences);
  }
}
