import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

/// Service untuk memantau keberadaan (presence) akun petugas di aplikasi mobile.
///
/// Aturan sesuai sistem dashboard:
/// - Saat membuka aplikasi: `is_active = true` dan `updated_at` di-refresh (heartbeat setiap 45 detik).
/// - Saat keluar/meminimalkan aplikasi: diberi toleransi 3 menit. Jika dalam 3 menit
///   tidak kembali membuka aplikasi, `is_active` akan otomatis diubah menjadi `false`.
/// - Saat logout: `is_active` seketika diubah menjadi `false`.
class PresenceService with WidgetsBindingObserver {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  static Timer? _heartbeatTimer;
  static Timer? _inactiveTimer;
  static bool _isInitialized = false;

  /// Interval pengiriman heartbeat saat user aktif di aplikasi (45 detik)
  static const Duration _heartbeatInterval = Duration(seconds: 45);

  /// Batas toleransi keluar aplikasi sebelum status dinyatakan offline (3 menit)
  static const Duration _offlineDelay = Duration(minutes: 3);

  /// Inisialisasi lifecycle observer saat aplikasi pertama kali berjalan
  static void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(_instance);
    debugPrint('🟢 [PresenceService] Lifecycle observer initialized');

    // Jika user sudah login sebelumnya, langsung mulai heartbeat
    checkAndStart();
  }

  /// Cek apakah user sedang login; jika iya, langsung mulai heartbeat online
  static Future<void> checkAndStart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('user_id') ?? prefs.getString('id');
    final email = prefs.getString('email');

    final hasUser = (userId != null && userId.isNotEmpty && userId != '-') ||
        (email != null && email.isNotEmpty);

    if (token != null && token.isNotEmpty && hasUser) {
      start();
    }
  }

  /// Mulai status online dan aktifkan pengiriman heartbeat berkala
  static void start() {
    _inactiveTimer?.cancel();
    _inactiveTimer = null;

    // Kirim sinyal online seketika
    _updatePresence(isActive: true);

    // Jalankan heartbeat periodik setiap 45 detik
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _updatePresence(isActive: true);
    });

    debugPrint('🟢 [PresenceService] Started online presence heartbeat');
  }

  /// Saat aplikasi diminimalkan/background, hentikan heartbeat dan hitung mundur 3 menit
  static void pause() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    _inactiveTimer?.cancel();
    debugPrint('🟡 [PresenceService] App in background, 3-minute offline timer started...');

    _inactiveTimer = Timer(_offlineDelay, () {
      debugPrint('🔴 [PresenceService] 3 minutes in background elapsed, marking is_active = false');
      _updatePresence(isActive: false);
    });
  }

  /// Hentikan semua timer presence tanpa update ke server (misal untuk testing / cleanup)
  static void stop() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _inactiveTimer?.cancel();
    _inactiveTimer = null;
  }

  /// Set user offline seketika (digunakan saat logout)
  static Future<void> setOfflineNow() async {
    stop();
    await _updatePresence(isActive: false);
    debugPrint('🔴 [PresenceService] User explicitly set to offline');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 [PresenceService] AppLifecycleState: $state');
    switch (state) {
      case AppLifecycleState.resumed:
        // User membuka atau kembali ke aplikasi
        checkAndStart();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // User meminimalkan atau beralih dari aplikasi
        pause();
        break;
      case AppLifecycleState.detached:
        // Aplikasi ditutup total
        pause();
        break;
    }
  }

  /// Mengirim update status is_active & updated_at ke tabel `profiles` di Supabase
  static Future<void> _updatePresence({required bool isActive}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("user_id") ?? prefs.getString("id");
      final email = prefs.getString("email");

      final supaUser = SupabaseService.client?.auth.currentUser;
      if ((userId == null || userId.isEmpty || userId == '-') && supaUser != null) {
        userId = supaUser.id;
      }

      final hasId = userId != null && userId.isNotEmpty && userId != '-';
      final hasEmail = email != null && email.isNotEmpty;

      if (!hasId && !hasEmail) {
        return;
      }

      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final updateData = {
        'is_active': isActive,
        'updated_at': nowUtc,
      };

      // 1. Coba melalui Supabase Client
      final client = SupabaseService.client;
      if (client != null) {
        try {
          if (hasId) {
            await client.from('profiles').update(updateData).eq('id', userId);
            debugPrint('✅ [PresenceService] Updated profiles ($userId) via client: is_active=$isActive');
            return;
          } else if (hasEmail) {
            await client.from('profiles').update(updateData).eq('email', email);
            debugPrint('✅ [PresenceService] Updated profiles ($email) via client: is_active=$isActive');
            return;
          }
        } catch (e) {
          debugPrint('⚠️ [PresenceService] Client update failed: $e, falling back to REST');
        }
      }

      // 2. Fallback melalui Supabase REST Direct
      try {
        final queryParam = hasId ? 'id=eq.$userId' : 'email=eq.$email';
        final uri = Uri.parse('${SupabaseConfig.supabaseUrl}/rest/v1/profiles?$queryParam');

        final sessionToken = prefs.getString('session_token') ?? prefs.getString('token');
        final headers = Map<String, String>.from(SupabaseConfig.restHeaders);
        if (sessionToken != null && sessionToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $sessionToken';
        }

        final res = await http.patch(
          uri,
          headers: headers,
          body: jsonEncode(updateData),
        );
        debugPrint('✅ [PresenceService] Updated profiles via REST ($queryParam) [status ${res.statusCode}]: is_active=$isActive');
      } catch (e) {
        debugPrint('⚠️ [PresenceService] REST update failed: $e');
      }
    } catch (e) {
      debugPrint('⚠️ [PresenceService] Error in _updatePresence: $e');
    }
  }
}
