// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/saved/domain/entities/saved_post_snapshot.dart';

class SavedPost {
  const SavedPost({
    required this.postId,
    required this.savedAt,
    required this.snapshot,
  });

  final String postId;
  final DateTime savedAt;
  final SavedPostSnapshot snapshot;
}
