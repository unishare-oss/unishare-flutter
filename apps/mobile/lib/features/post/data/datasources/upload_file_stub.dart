import 'package:firebase_storage/firebase_storage.dart';

UploadTask buildUploadTask(Reference ref, String localPath) =>
    throw UnsupportedError(
      'File-path upload is not supported on web — use uploadBytes() instead.',
    );
