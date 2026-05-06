import '../entities/post_filter_preferences.dart';

abstract interface class PreferencesRepository {
  Future<PostFilterPreferences> getFilterPreferences(String uid);
  Future<void> saveFilterPreferences(
    String uid,
    PostFilterPreferences preferences,
  );
}
