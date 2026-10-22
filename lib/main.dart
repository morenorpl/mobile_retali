import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'splash_screen.dart';

final _flnp = FlutterLocalNotificationsPlugin();
const _androidChannelId = 'default_channel';
const _androidChannelName = 'General';

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final flnp = FlutterLocalNotificationsPlugin();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flnp.initialize(initSettings);

  // 🔴 WAJIB: buat channel DI BACKGROUND
  const channel = AndroidNotificationChannel(
    'default_channel',
    'General',
    importance: Importance.max,
    description: 'Default channel for general notifications',
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
          'default_channel',
          'General',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}

Future<void> _setupLocalNotifications() async {
  const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initIOS = DarwinInitializationSettings();
  await _flnp.initialize(const InitializationSettings(
    android: initAndroid,
    iOS: initIOS,
  ));

  final androidImpl =
    _flnp.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
    _androidChannelId,
    _androidChannelName,
    importance: Importance.max,
    description: 'Default channel for general notifications',
  ));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Tambahkan ini supaya format tanggal Indonesia aktif
  await initializeDateFormatting('id_ID', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Daftarkan background handler
  FirebaseMessaging.onBackgroundMessage(_bgHandler);

  // Android 13+ permission
  await FirebaseMessaging.instance.requestPermission();

  if (!kIsWeb) {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _setupLocalNotifications();
    await FirebaseMessaging.instance.subscribeToTopic('all');

    FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      FirebaseMessaging.instance.subscribeToTopic('all');
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage m) async {
  String? title;
  String? body;

  if (m.notification != null) {
    title = m.notification!.title;
    body  = m.notification!.body;
  }

  title ??= m.data['title'];
  body  ??= m.data['body'];

  if (title != null || body != null) {
    await _flnp.show(
      DateTime.now().millisecondsSinceEpoch, // 🔥 JANGAN dibagi 1000
      title ?? 'Notifikasi',
      body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'General',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
});


    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      // TODO: navigate berdasarkan m.data jika perlu
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // TODO: navigate berdasarkan initial.data jika perlu
    }
  } else {
    // WEB
    // final token = await FirebaseMessaging.instance.getToken(vapidKey: 'YOUR_PUBLIC_VAPID_KEY');
  }

  runApp(const MyApp());
}

// Cari class MyApp di main.dart Anda dan ubah menjadi seperti ini:

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Retali Mustajab Travel',
      theme: ThemeData(
        useMaterial3: true, // Pastikan ini true untuk konsistensi UI
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF842D62), // Gunakan warna ungu aplikasi Anda
          primary: const Color(0xFF842D62),
        ),
        // 🔴 TAMBAHKAN INI: Kunci tema AppBar secara Global
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF842D62),
          foregroundColor: Colors.white, // Ini akan memaksa Icon dan Teks menjadi putih
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

