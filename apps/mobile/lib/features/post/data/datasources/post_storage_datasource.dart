import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'upload_file_stub.dart'
    if (dart.library.io) 'upload_file_io.dart';

class PostStorageDatasource {
  final _storage = FirebaseStorage.instance;

  /// Uploads a local file (mobile) to `posts/{uid}/{uuid}-{filename}`.
  Future<String> upload(
    String localPath,
    String uid, {
    void Function(double progress)? onProgress,
  }) async {
    final filename = localPath.split('/').last;
    final ref = _storage.ref('posts/$uid/${_newId()}-$filename');
    final task = buildUploadTask(ref, localPath);
    return _trackAndReturn(task, ref, onProgress);
  }

  /// Uploads in-memory [bytes] (web) to `posts/{uid}/{uuid}-{filename}`.
  Future<String> uploadBytes(
    Uint8List bytes,
    String filename,
    String uid, {
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref('posts/$uid/${_newId()}-$filename');
    final task = ref.putData(bytes);
    return _trackAndReturn(task, ref, onProgress);
  }

  /// Uploads [content] as `text/plain`. Used for code snippets.
  Future<String> uploadText(String content, String uid, String filename) async {
    final ref = _storage.ref('posts/$uid/${_newId()}-$filename');
    await ref.putString(content, metadata: SettableMetadata(contentType: 'text/plain'));
    return ref.getDownloadURL();
  }

  Future<String> _trackAndReturn(
    UploadTask task,
    Reference ref,
    void Function(double)? onProgress,
  ) async {
    StreamSubscription? sub;
    if (onProgress != null) {
      sub = task.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) onProgress(snap.bytesTransferred / snap.totalBytes);
      });
    }
    try {
      await task;
    } finally {
      await sub?.cancel();
    }
    return ref.getDownloadURL();
  }

  String _newId() => FirebaseFirestore.instance.collection('_').doc().id;
}
