import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const _workerBaseUrl = String.fromEnvironment('WORKER_URL');

class AskAiDatasource {
  AskAiDatasource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Streams the worker's `/ai/chat` response.
  ///
  /// [extractedText] is the full document content cached on the post doc
  /// (PROP-0011 Phase 3). When provided, the worker uses it as the grounding
  /// context instead of [summary] — answers can reference details that
  /// don't appear in the bullet summary. [summary] is still required as a
  /// fallback for pre-Phase-1 posts whose extracted text was never cached.
  Stream<Map<String, dynamic>> stream({
    required String summary,
    required String question,
    required List<Map<String, String>> history,
    String? extractedText,
  }) async* {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw Exception('not_authenticated');

    final request = http.Request('POST', Uri.parse('$_workerBaseUrl/ai/chat'))
      ..headers['Content-Type'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token'
      ..body = jsonEncode({
        'summary': summary,
        if (extractedText != null && extractedText.isNotEmpty)
          'extractedText': extractedText,
        'question': question,
        'history': history,
      });

    final response = await _client.send(request);

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Worker error ${response.statusCode}: $body');
    }

    String buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr.isNotEmpty) {
            yield Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);
          }
        }
      }
    }
  }
}
