import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unishare_mobile/features/post/data/datasources/upload_file_stub.dart'
    if (dart.library.io) 'upload_file_io.dart';

// Set at build time: flutter run --dart-define=WORKER_URL=https://...
const _workerUrl = String.fromEnvironment('WORKER_URL');

class PostStorageDatasource {
  final _dio = Dio();

  Future<String> upload(
    String localPath,
    String uid, {
    void Function(double)? onProgress,
  }) async {
    final filename = localPath.split('/').last;
    final bytes = await readFileBytes(localPath);
    return _put(bytes, filename, onProgress);
  }

  Future<String> uploadBytes(
    Uint8List bytes,
    String filename,
    String uid, {
    void Function(double)? onProgress,
  }) =>
      _put(bytes, filename, onProgress);

  Future<String> uploadText(String content, String uid, String filename) =>
      _put(
        Uint8List.fromList(utf8.encode(content)),
        filename,
        null,
        contentType: 'text/plain',
      );

  Future<String> _put(
    Uint8List bytes,
    String filename,
    void Function(double)? onProgress, {
    String? contentType,
  }) async {
    final ct = contentType ?? _contentTypeFor(filename);
    final idToken = await FirebaseAuth.instance.currentUser!.getIdToken();

    final workerRes = await _dio.post<Map<String, dynamic>>(
      _workerUrl,
      data: {'filename': filename, 'contentType': ct},
      options: Options(
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    final uploadUrl = workerRes.data!['uploadUrl'] as String;
    final publicUrl = workerRes.data!['publicUrl'] as String;

    await _dio.put<void>(
      uploadUrl,
      data: Stream.fromIterable(bytes.map((b) => [b])),
      options: Options(
        headers: {
          'Content-Type': ct,
          'Content-Length': bytes.length,
        },
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 1),
      ),
      onSendProgress: onProgress != null
          ? (sent, total) {
              if (total > 0) onProgress(sent / total);
            }
          : null,
    );

    return publicUrl;
  }

  String _contentTypeFor(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }
}
