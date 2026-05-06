import 'package:unishare_mobile/features/feed/domain/entities/post_filter_preferences.dart';
import 'package:unishare_mobile/features/feed/domain/repositories/preferences_repository.dart';

class GetFilterPreferences {
  const GetFilterPreferences(this._repository);

  final PreferencesRepository _repository;

  Future<PostFilterPreferences> call(String uid) =>
      _repository.getFilterPreferences(uid);
}
