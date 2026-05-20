import 'package:hive_flutter/hive_flutter.dart';

/// Hive box holding the cached AI-tag whitelist for Phase A vocabulary
/// control (PROP-0011). Stored as a single keyed map with two fields:
/// the topics list (a `List<String>`) and the updatedAt epoch-ms timestamp.
///
/// 24-hour TTL is enforced in [TagWhitelistService]; the box itself is just
/// a plain key/value store with no adapter needed.
const tagWhitelistBoxName = 'ai_tag_whitelist';

Future<void> initTagWhitelistBox() async {
  await Hive.openBox<dynamic>(tagWhitelistBoxName);
}
