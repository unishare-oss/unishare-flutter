import 'dart:typed_data';

Future<Uint8List> readFileBytes(String localPath) => throw UnsupportedError(
  'File-path reads are not supported on web — pass bytes directly.',
);
