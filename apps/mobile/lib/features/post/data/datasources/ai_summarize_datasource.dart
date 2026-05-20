import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const _workerBaseUrl = String.fromEnvironment('WORKER_URL');

class AiSummarizeDatasource {
  AiSummarizeDatasource({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Calls the Worker `/ai/summarize` endpoint.
  /// Returns `{summaryStatus, summary, extractedText?, extractedTextTruncated?, aiTags?}`
  /// from the Worker response.
  ///
  /// [existingTags] is the Phase A vocabulary control whitelist (PROP-0011).
  /// When non-empty, the worker injects it into the summarize prompt so the
  /// model prefers reusing tags already in heavy use across the corpus.
  /// Advisory only — the model can still invent new tags for novel topics.
  Future<Map<String, dynamic>> call({
    required String fileUrl,
    required String filename,
    List<String> existingTags = const [],
    String? postId,
    String? title,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw Exception('not_authenticated');

    final response = await _client.post(
      Uri.parse('$_workerBaseUrl/ai/summarize'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fileUrl': fileUrl,
        'filename': filename,
        if (existingTags.isNotEmpty) 'existingTags': existingTags,
        // PROP-0011 Phase 4a — postId + title let the worker upsert this post
        // into the Vectorize index for semantic search. Optional for back-compat
        // with older worker versions that ignore unknown fields.
        'postId': ?postId,
        if (title != null && title.isNotEmpty) 'title': title,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Worker error ${response.statusCode}: ${response.body}');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }
}
