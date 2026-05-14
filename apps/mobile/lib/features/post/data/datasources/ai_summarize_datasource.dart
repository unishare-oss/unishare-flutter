import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const _workerBaseUrl = String.fromEnvironment(
  'WORKER_BASE_URL',
  defaultValue: 'https://unishare-upload.workers.dev',
);

class AiSummarizeDatasource {
  AiSummarizeDatasource({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Calls the Worker `/ai/summarize` endpoint.
  /// Returns `{summaryStatus, summary}` from the Worker response.
  Future<Map<String, dynamic>> call({
    required String fileUrl,
    required String filename,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw Exception('not_authenticated');

    final response = await _client.post(
      Uri.parse('$_workerBaseUrl/ai/summarize'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'fileUrl': fileUrl, 'filename': filename}),
    );

    if (response.statusCode != 200) {
      throw Exception('Worker error ${response.statusCode}: ${response.body}');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }
}
