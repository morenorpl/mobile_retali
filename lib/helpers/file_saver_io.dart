import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<String?> saveFileBytes(Uint8List bytes, String fileName) async {
  // 1. Simpan ke folder Download publik Android jika memungkinkan
  if (Platform.isAndroid) {
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        final f = File('${downloadDir.path}/$fileName');
        await f.writeAsBytes(bytes);
        return f.path;
      }
    } catch (_) {}
  }

  // 2. Coba getExternalStorageDirectory
  try {
    final dir = await getExternalStorageDirectory();
    if (dir != null) {
      final f = File('${dir.path}/$fileName');
      await f.writeAsBytes(bytes);
      return f.path;
    }
  } catch (_) {}

  // 3. Coba getApplicationDocumentsDirectory
  try {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/$fileName');
    await f.writeAsBytes(bytes);
    return f.path;
  } catch (_) {}

  // 4. Fallback system temp
  final f = File('${Directory.systemTemp.path}/$fileName');
  await f.writeAsBytes(bytes);
  return f.path;
}
