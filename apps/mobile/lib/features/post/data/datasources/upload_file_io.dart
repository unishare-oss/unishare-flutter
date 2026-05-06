import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> readFileBytes(String localPath) =>
    File(localPath).readAsBytes();
