import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const _workerBaseUrl = String.fromEnvironment('WORKER_URL');

/// Single result from a semantic search call.
///
/// PROP-0011 Phase 4b — the worker returns post IDs ordered by cosine
/// similarity to the query embedding. The client fetches the actual Post
/// docs from Firestore using these IDs.
class SemanticSearchHit {
  const SemanticSearchHit({required this.postId, required this.score});

  final String postId;
  /// Cosine similarity in [0, 1]. Higher is closer. The worker already
  /// filtered below its similarityFloor before returning.
  final double score;
}

class SemanticSearchDatasource {
  SemanticSearchDatasource({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Calls the worker's `/ai/search` endpoint.
  /// Throws on non-200 responses; callers should treat as "no semantic
  /// results" and fall back to keyword-only matches.
  Future<List<SemanticSearchHit>> search({
    required String query,
    int limit = 10,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw Exception('not_authenticated');

    final response = await _client.post(
      Uri.parse('$_workerBaseUrl/ai/search'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'query': query, 'limit': limit}),
    );

    if (response.statusCode != 200) {
      throw Exception('Worker error ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = body['results'] as List? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((m) => SemanticSearchHit(
              postId: m['postId'] as String,
              score: (m['score'] as num).toDouble(),
            ))
        .toList(growable: false);
  }
}
