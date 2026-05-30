import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

typedef TokenProvider = Future<String?> Function({bool forceRefresh});

const _workerBaseUrl = String.fromEnvironment('WORKER_URL');

/// POST /ai/reindex — re-upserts the post's search-blob embedding to
/// Vectorize after a title or description edit. Fire-and-forget from the
/// caller's perspective: a 4xx/5xx returns `false` and the caller logs it;
/// the edit itself already succeeded in Firestore so we never block the UI.
///
/// On 401, we force-refresh the ID token and retry exactly once. Two
/// consecutive 401s mean a real auth problem — give up.
class AiReindexDatasource {
  AiReindexDatasource({http.Client? client, TokenProvider? tokenProvider})
    : _client = client ?? http.Client(),
      _tokenProvider = tokenProvider ?? _defaultTokenProvider;

  final http.Client _client;
  final TokenProvider _tokenProvider;

  static Future<String?> _defaultTokenProvider({bool forceRefresh = false}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Future.value(null);
    return user.getIdToken(forceRefresh);
  }

  Future<bool> call({
    required String postId,
    required String title,
    required String description,
  }) async {
    final token = await _tokenProvider();
    if (token == null) return false;

    final body = jsonEncode({
      'postId': postId,
      'title': title,
      'description': description,
    });

    var response = await _post(token, body);
    if (response.statusCode == 401) {
      final fresh = await _tokenProvider(forceRefresh: true);
      if (fresh == null) return false;
      response = await _post(fresh, body);
    }
    return response.statusCode == 200;
  }

  Future<http.Response> _post(String token, String body) => _client.post(
    Uri.parse('$_workerBaseUrl/ai/reindex'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: body,
  );
}
