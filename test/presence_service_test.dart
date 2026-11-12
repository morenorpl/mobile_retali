import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_retali/services/presence_service.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'token': 'mock-token-xyz',
      'user_id': 'user-1234-uuid',
      'email': 'tourleader@retali.com',
    });
  });

  tearDown(() async {
    await PresenceService.setOfflineNow();
  });

  group('PresenceService Tests', () {
    test('PresenceService can be initialized and handles lifecycle changes', () async {
      PresenceService.init();

      // Start online
      PresenceService.start();

      // Simulate app going to background (paused)
      final service = PresenceService();
      service.didChangeAppLifecycleState(AppLifecycleState.paused);

      // Simulate app resuming
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // Simulate user logout / offline
      await PresenceService.setOfflineNow();
    });

    test('PresenceService does not crash when no user is logged in', () async {
      SharedPreferences.setMockInitialValues({});
      await PresenceService.checkAndStart();
      await PresenceService.setOfflineNow();
    });
  });
}
