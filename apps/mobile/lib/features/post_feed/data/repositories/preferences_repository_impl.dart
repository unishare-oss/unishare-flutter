import 'package:unishare_mobile/features/post_feed/domain/entities/post_filter_preferences.dart';
import 'package:unishare_mobile/features/post_feed/domain/repositories/preferences_repository.dart';

// TODO: inject PreferencesFirestoreDatasource
class PreferencesRepositoryImpl implements PreferencesRepository {
  const PreferencesRepositoryImpl();

  @override
  Future<PostFilterPreferences> getFilterPreferences(String uid) {
    // TODO: delegate to PreferencesFirestoreDatasource
    // Return PostFilterPreferences.empty() when document does not exist
    throw UnimplementedError();
  }

  @override
  Future<void> saveFilterPreferences(
    String uid,
    PostFilterPreferences preferences,
  ) {
    // TODO: delegate to PreferencesFirestoreDatasource using merge-write
    throw UnimplementedError();
  }
}
