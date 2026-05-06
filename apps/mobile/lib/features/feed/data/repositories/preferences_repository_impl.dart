import 'package:unishare_mobile/features/feed/domain/entities/post_filter_preferences.dart';
import 'package:unishare_mobile/features/feed/domain/repositories/preferences_repository.dart';

// Deferred to the data-layer phase. Requires:
//   1. PreferencesFirestoreDatasource injected via constructor
//   2. getFilterPreferences: return PostFilterPreferences.empty() when doc is missing
//   3. saveFilterPreferences: merge-write so unrelated fields are preserved
// Not consumed by any provider yet — FilterPreferencesNotifier is also stubbed.
class PreferencesRepositoryImpl implements PreferencesRepository {
  const PreferencesRepositoryImpl();

  @override
  Future<PostFilterPreferences> getFilterPreferences(String uid) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveFilterPreferences(
    String uid,
    PostFilterPreferences preferences,
  ) {
    throw UnimplementedError();
  }
}
