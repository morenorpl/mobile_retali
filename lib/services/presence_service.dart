import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

/// Service untuk memantau keberadaan (presence) akun petugas di aplikasi mobile.
///
/// Aturan:
/// - Saat membuka aplikasi / login: `is_active = true` dan `updated_at` di-refresh (heartbeat setiap 25 detik).
/// - Dashboard memeriksa status aktif melalui kolom `is_active` dan waktu `updated_at` (dalam batas toleransi 1 menit).
/// - Saat keluar/meminimalkan aplikasi: jika dalam 1 menit tidak kembali membuka aplikasi, `is_active` otomatis diubah menjadi `false`.
/// - Saat logout: `is_active` seketika diubah menjadi `false` dan `updated_at` dimundurkan 5 menit lalu.
/// - Saat login: aplikasi otomatis memastikan status `is_active = true` sehingga tidak ada kendala "Akun sedang tidak aktif".
class PresenceService with WidgetsBindingObserver {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  static Timer? _heartbeatTimer;
  static Timer? _inactiveTimer;
  static bool _isInitialized = false;

  /// Interval pengiriman heartbeat saat user aktif di aplikasi (25 detik)
  static const Duration _heartbeatInterval = Duration(seconds: 25);

  /// Batas toleransi keluar aplikasi sebelum status dinyatakan offline (1 menit)
  static const Duration _offlineDelay = Duration(minutes: 1);

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

    // Kirim sinyal online seketika (refresh updated_at)
    _updatePresence(isOnline: true);

    // Jalankan heartbeat periodik setiap 45 detik
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _updatePresence(isOnline: true);
    });

    debugPrint('🟢 [PresenceService] Started online presence heartbeat');
  }

  /// Saat aplikasi diminimalkan/background, hentikan heartbeat dan hitung mundur 1 menit
  static void pause() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    _inactiveTimer?.cancel();
    debugPrint('🟡 [PresenceService] App in background, 1-minute offline timer started...');

    _inactiveTimer = Timer(_offlineDelay, () {
      debugPrint('🔴 [PresenceService] 1 minute in background elapsed, marking offline (is_active = false)');
      _updatePresence(isOnline: false);
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
    await _updatePresence(isOnline: false);
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

  /// Mengirim update status kehadiran via updated_at ke tabel `profiles` di Supabase.
  ///
  /// CATATAN PENTING: Hanya memperbarui `updated_at`, TIDAK PERNAH mengubah `is_active`!
  /// Dashboard membaca (now - updated_at) <= 3 menit sebagai indikator Online (Aktif).
  /// Saat offline, `updated_at` dimundurkan 5 menit lalu agar dashboard seketika membaca offline.
  static Future<void> _updatePresence({required bool isOnline}) async {
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

      // Online: waktu sekarang (heartbeat baru).
      // Offline: waktu 5 menit lalu sehingga dashboard langsung mendeteksi diffMinutes > 3.
      final timestamp = isOnline
          ? DateTime.now().toUtc()
          : DateTime.now().toUtc().subtract(const Duration(minutes: 5));

      final updateData = {
        'is_active': isOnline,
        'updated_at': timestamp.toIso8601String(),
      };

      // 1. Coba melalui Supabase Client
      final client = SupabaseService.client;
      if (client != null) {
        try {
          if (hasId) {
            await client.from('profiles').update(updateData).eq('id', userId).timeout(const Duration(seconds: 3));
            debugPrint('✅ [PresenceService] Updated profiles ($userId) via client: is_active=$isOnline');
            return;
          } else if (hasEmail) {
            await client.from('profiles').update(updateData).eq('email', email).timeout(const Duration(seconds: 3));
            debugPrint('✅ [PresenceService] Updated profiles ($email) via client: is_active=$isOnline');
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
        ).timeout(const Duration(seconds: 3));
        debugPrint('✅ [PresenceService] Updated profiles via REST ($queryParam) [status ${res.statusCode}]: is_active=$isOnline');
      } catch (e) {
        debugPrint('⚠️ [PresenceService] REST update failed: $e');
      }
    } catch (e) {
      debugPrint('⚠️ [PresenceService] Error in _updatePresence: $e');
    }
  }
}
