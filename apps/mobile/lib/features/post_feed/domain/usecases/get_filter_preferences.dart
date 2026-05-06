import '../entities/post_filter_preferences.dart';
import '../repositories/preferences_repository.dart';

class GetFilterPreferences {
  const GetFilterPreferences(this._repository);

  final PreferencesRepository _repository;

  Future<PostFilterPreferences> call(String uid) =>
      _repository.getFilterPreferences(uid);
}
