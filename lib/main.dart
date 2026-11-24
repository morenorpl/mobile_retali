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
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16.5, color: Color(0xFF0F172A)),
          bodyMedium: TextStyle(fontSize: 14.5, color: Color(0xFF334155)),
          bodySmall: TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
          titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          titleMedium: TextStyle(fontSize: 17.0, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          titleSmall: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          labelLarge: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1523),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 19.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Meningkatkan skala teks secocoknya agar terlihat lebih besar & lebih terbaca di seluruh aplikasi
        final currentScale = mediaQuery.textScaler.scale(1.0);
        final effectiveScaler = TextScaler.linear((currentScale * 1.10).clamp(1.10, 1.30));

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: effectiveScaler,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
