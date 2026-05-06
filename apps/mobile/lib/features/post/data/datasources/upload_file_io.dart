import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

UploadTask buildUploadTask(Reference ref, String localPath) =>
    ref.putFile(File(localPath));
