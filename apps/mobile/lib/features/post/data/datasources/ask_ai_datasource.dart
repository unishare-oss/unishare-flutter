import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const _workerBaseUrl = String.fromEnvironment('WORKER_URL');

class AskAiDatasource {
  AskAiDatasource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> call({
    required String summary,
    required String question,
    required List<Map<String, String>> history,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw Exception('not_authenticated');

    final response = await _client.post(
      Uri.parse('$_workerBaseUrl/ai/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'summary': summary,
        'question': question,
        'history': history,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Worker error ${response.statusCode}: ${response.body}');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }
}
