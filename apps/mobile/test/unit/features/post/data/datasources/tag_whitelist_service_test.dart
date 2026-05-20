import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:unishare_mobile/features/post/data/datasources/tag_whitelist_service.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tag_whitelist_test');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    box = await Hive.openBox<dynamic>(
      'tag_whitelist_test_${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await box.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('TagWhitelistService — cache layer', () {
    test('cold cache calls compute, writes result, returns it', () async {
      var calls = 0;
      final service = TagWhitelistService(
        cacheBox: box,
        computeOverride: () async {
          calls++;
          return ['krebs-cycle', 'atp-synthesis'];
        },
      );

      final result = await service.topTags();

      expect(result, equals(['krebs-cycle', 'atp-synthesis']));
      expect(calls, 1);
    });

    test('warm cache (within TTL) skips compute, returns cached', () async {
      var calls = 0;
      Future<List<String>> compute() async {
        calls++;
        return ['first-fetch'];
      }

      final service = TagWhitelistService(
        cacheBox: box,
        computeOverride: compute,
      );
      await service.topTags(); // primes cache
      expect(calls, 1);

      // Second call should hit cache, not compute.
      final cached = await service.topTags();
      expect(cached, equals(['first-fetch']));
      expect(calls, 1, reason: 'compute should not run on cache hit');
    });

    test('compute failure returns empty list and does not throw', () async {
      final service = TagWhitelistService(
        cacheBox: box,
        computeOverride: () async => throw Exception('firestore down'),
      );

      final result = await service.topTags();

      expect(result, isEmpty);
    });

    test('expired cache triggers fresh compute', () async {
      // Pre-populate with a stale entry (25 hours old > 24h TTL).
      final stale = DateTime.now().subtract(const Duration(hours: 25));
      await box.put('top_tags', {
        'topics': ['stale-tag'],
        'updatedAt': stale.millisecondsSinceEpoch,
      });

      var calls = 0;
      final service = TagWhitelistService(
        cacheBox: box,
        computeOverride: () async {
          calls++;
          return ['fresh-tag'];
        },
      );

      final result = await service.topTags();

      expect(result, equals(['fresh-tag']));
      expect(calls, 1, reason: 'expired cache must re-compute');
    });
  });
}
