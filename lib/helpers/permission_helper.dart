import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestCameraPermission() async {
    if (kIsWeb) return true;
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        return true;
      }
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }
      return status.isGranted;
    } catch (_) {
      return true;
    }
  }
}
