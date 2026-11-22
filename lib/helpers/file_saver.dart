import 'dart:typed_data';
import 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart'
    if (dart.library.html) 'file_saver_web.dart';

Future<String?> downloadOrSaveFile(Uint8List bytes, String fileName) {
  return saveFileBytes(bytes, fileName);
}
