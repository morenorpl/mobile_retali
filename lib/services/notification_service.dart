import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const String channelId = 'default_channel';
  static const String channelName = 'General Notifications';

  /// INIT di main isolate
  static Future<void> init() async {
    final flnp = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await flnp.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      channelId,
      channelName,
      importance: Importance.max,
      description: 'Default channel for app notifications',
    );

    final androidImpl =
        flnp.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(channel);

    /// FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.data['title'] ?? message.notification?.title;
      final body  = message.data['body']  ?? message.notification?.body;

      if (title != null || body != null) {
        await flnp.show(
          DateTime.now().millisecondsSinceEpoch,
          title ?? 'Notifikasi',
          body ?? '',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  /// BACKGROUND – ISOLATE TERPISAH
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();

    final flnp = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await flnp.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      channelId,
      channelName,
      importance: Importance.max,
      description: 'Default channel for app notifications',
    );

    final androidImpl =
        flnp.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(channel);

    final title = message.data['title'] ?? message.notification?.title;
    final body  = message.data['body']  ?? message.notification?.body;

    if (title != null || body != null) {
      await flnp.show(
        DateTime.now().millisecondsSinceEpoch,
        title ?? 'Notifikasi',
        body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }
}
