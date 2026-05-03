import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostStorageDatasource {
  final _storage = FirebaseStorage.instance;

  Future<String> upload(
    String localPath,
    String uid, {
    void Function(double progress)? onProgress,
  }) async {
    final file = File(localPath);
    final filename = localPath.split('/').last;
    final ref = _storage.ref('posts/$uid/${_newId()}-$filename');

    final task = ref.putFile(file);

    StreamSubscription? sub;
    if (onProgress != null) {
      sub = task.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) {
          onProgress(snap.bytesTransferred / snap.totalBytes);
        }
      });
    }

    try {
      await task;
    } finally {
      await sub?.cancel();
    }

    return ref.getDownloadURL();
  }

  // Generates a Firebase-style 20-char random ID without a network call.
  String _newId() {
    // Same approach as Firestore auto-ID: use the Firestore client's doc() generator.
    return FirebaseFirestore.instance.collection('_').doc().id;
  }
}
