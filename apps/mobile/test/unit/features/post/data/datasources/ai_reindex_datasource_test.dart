import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unishare_mobile/features/post/data/datasources/ai_reindex_datasource.dart';

void main() {
  group('AiReindexDatasource', () {
    test('POSTs postId, title, description with bearer token', () async {
      late http.BaseRequest captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode({'reindexed': true}), 200);
      });
      final ds = AiReindexDatasource(
        client: client,
        tokenProvider: ({bool forceRefresh = false}) async => 'fake-token',
      );

      final result = await ds.call(
        postId: 'p1',
        title: 'New title',
        description: 'New description',
      );

      expect(result, isTrue);
      expect(captured.method, 'POST');
      expect(captured.url.path, endsWith('/ai/reindex'));
      expect(captured.headers['Authorization'], 'Bearer fake-token');
      // ignore: avoid_dynamic_calls
      final body =
          jsonDecode((captured as http.Request).body) as Map<String, dynamic>;
      expect(body['postId'], 'p1');
      expect(body['title'], 'New title');
      expect(body['description'], 'New description');
    });

    test('returns false on 4xx without retrying', () async {
      var callCount = 0;
      final client = MockClient((req) async {
        callCount++;
        return http.Response('{"error":"Forbidden"}', 403);
      });
      final ds = AiReindexDatasource(
        client: client,
        tokenProvider: ({bool forceRefresh = false}) async => 'fake-token',
      );

      final result = await ds.call(postId: 'p1', title: 't', description: 'd');

      expect(result, isFalse);
      expect(callCount, 1);
    });

    test('retries once on 401 after forcing token refresh', () async {
      var callCount = 0;
      var refreshCount = 0;
      final client = MockClient((req) async {
        callCount++;
        final auth = req.headers['Authorization'];
        if (auth == 'Bearer stale-token') {
          return http.Response('{"error":"Unauthorized"}', 401);
        }
        return http.Response('{"reindexed":true}', 200);
      });
      final ds = AiReindexDatasource(
        client: client,
        tokenProvider: ({bool forceRefresh = false}) async {
          if (forceRefresh) {
            refreshCount++;
            return 'fresh-token';
          }
          return 'stale-token';
        },
      );

      final result = await ds.call(postId: 'p1', title: 't', description: 'd');

      expect(result, isTrue);
      expect(callCount, 2);
      expect(refreshCount, 1);
    });

    test('gives up after a second 401', () async {
      var callCount = 0;
      final client = MockClient((req) async {
        callCount++;
        return http.Response('{"error":"Unauthorized"}', 401);
      });
      final ds = AiReindexDatasource(
        client: client,
        tokenProvider: ({bool forceRefresh = false}) async =>
            forceRefresh ? 'fresh-token' : 'stale-token',
      );

      final result = await ds.call(postId: 'p1', title: 't', description: 'd');

      expect(result, isFalse);
      expect(callCount, 2); // initial + 1 retry, no further attempts
    });
  });
}
