import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'services/notification_service.dart';
import 'services/presence_service.dart';
import 'services/supabase_service.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Format tanggal Indonesia aktif
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Supabase
  await SupabaseService.initialize();

  // Inisialisasi Notification Service (Local Notification + Supabase Realtime)
  await NotificationService.init();

  // Inisialisasi Presence Service (Aktif / Non-aktif status monitoring)
  PresenceService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Retali Mustajab Travel',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF842D62),
          primary: const Color(0xFF842D62),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF842D62),
          foregroundColor: Colors.white,
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
