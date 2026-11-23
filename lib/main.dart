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
      title: 'retali sistem Zero Complaint',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B3167),
          primary: const Color(0xFF1B3167),
          secondary: const Color(0xFFEAB308),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1523),
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
