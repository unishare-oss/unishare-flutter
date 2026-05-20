import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:hive_flutter/hive_flutter.dart';

import 'package:unishare_mobile/core/logging/app_logger.dart';

/// Phase A vocabulary control (PROP-0011 Phase 2): on summarize, the worker
/// is told to *prefer* tags already in heavy use across the corpus so the
/// global tag vocabulary doesn't fragment ("Krebs Cycle" / "krebs cycle" /
/// "TCA cycle" / "citric acid cycle" all becoming separate filter chips).
///
/// Computation strategy: read the [_sampleSize] most recently created posts,
/// flatten their `aiTags`, count frequencies, return the top [_topN]. Cached
/// in Hive for [_ttl] so subsequent post creations within a day don't repeat
/// the Firestore read. A cold cache costs roughly 100 doc reads per user per
/// day — acceptable at expected scale.
///
/// The returned list is *advisory* — the worker prompt asks the model to
/// prefer these tags when applicable but still invent new ones for genuinely
/// novel topics. Phase B (embedding dedup) will collapse near-synonyms.
class TagWhitelistService {
  TagWhitelistService({
    required Box<dynamic> cacheBox,
    FirebaseFirestore? firestore,
    @visibleForTesting Future<List<String>> Function()? computeOverride,
  }) : _box = cacheBox,
       _firestoreOverride = firestore,
       _computeOverride = computeOverride;

  final Box<dynamic> _box;
  // Lazy: we don't touch FirebaseFirestore.instance at construction time so
  // unit tests that supply a [computeOverride] don't need Firebase initialized.
  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  final Future<List<String>> Function()? _computeOverride;

  static const _cacheKey = 'top_tags';
  static const _topicsField = 'topics';
  static const _updatedAtField = 'updatedAt';
  static const _ttl = Duration(hours: 24);
  static const _sampleSize = 100;
  static const _topN = 50;

  /// Top-N tags from recent posts, cached for [_ttl]. Returns an empty list
  /// if the cache is cold AND the Firestore read fails — callers should
  /// treat the whitelist as advisory, not required.
  Future<List<String>> topTags() async {
    final cached = _readCache();
    if (cached != null) return cached;
    try {
      final fresh = await (_computeOverride?.call() ?? _compute());
      await _writeCache(fresh);
      return fresh;
    } catch (e, st) {
      AppLogger.error(
        'TagWhitelistService compute failed',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  Future<List<String>> _compute() async {
    final snapshot = await _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(_sampleSize)
        .get();
    final counts = <String, int>{};
    for (final doc in snapshot.docs) {
      final raw = doc.data()['aiTags'];
      if (raw is! List) continue;
      for (final tag in raw) {
        if (tag is! String || tag.isEmpty) continue;
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(_topN).map((e) => e.key).toList(growable: false);
  }

  List<String>? _readCache() {
    final raw = _box.get(_cacheKey);
    if (raw is! Map) return null;
    final updatedAt = raw[_updatedAtField];
    if (updatedAt is! int) return null;
    final age = DateTime.now().millisecondsSinceEpoch - updatedAt;
    if (age > _ttl.inMilliseconds) return null;
    final topics = raw[_topicsField];
    if (topics is! List) return null;
    return topics.whereType<String>().toList(growable: false);
  }

  Future<void> _writeCache(List<String> topics) async {
    await _box.put(_cacheKey, {
      _topicsField: topics,
      _updatedAtField: DateTime.now().millisecondsSinceEpoch,
    });
  }
}
