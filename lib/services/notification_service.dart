import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'api_service.dart';
import 'supabase_service.dart';

class NotificationService {
  static const String channelId = 'retali_notifications_channel';
  static const String channelName = 'Retali Notifications';

  static final FlutterLocalNotificationsPlugin _flnp =
      FlutterLocalNotificationsPlugin();
  static RealtimeChannel? _supabaseRealtimeChannel;
  static Timer? _checkScheduleTimer;
  static final List<VoidCallback> _listeners = [];

  static void addListener(VoidCallback cb) {
    if (!_listeners.contains(cb)) _listeners.add(cb);
  }

  static void removeListener(VoidCallback cb) {
    _listeners.remove(cb);
  }

  static void notifyAppListeners() {
    for (final cb in List<VoidCallback>.from(_listeners)) {
      try {
        cb();
      } catch (e) {
        debugPrint("⚠️ Error calling notification listener: $e");
      }
    }
  }

  /// Inisialisasi local notification & background scheduler
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _flnp.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      channelId,
      channelName,
      importance: Importance.max,
      description: 'Saluran notifikasi pengingat kegiatan Retali Mustajab Travel',
    );

    final androidImpl = _flnp.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(channel);

    // Jalankan pengecekan pengingat pertama kali
    await checkAndTriggerPendingNotifications();

    // Timer berkala tiap 60 detik untuk mendeteksi perubahan status waktu (Abu-Abu -> Merah -> Kuning -> Hijau)
    _checkScheduleTimer?.cancel();
    _checkScheduleTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      checkAndTriggerPendingNotifications();
    });

    // Otomatis pasang realtime listener jika Supabase client sudah siap
    setupSupabaseRealtime();
  }

  /// Menampilkan notifikasi popup lokal
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _flnp.show(id, title, body, notificationDetails, payload: payload);
  }

  /// Memeriksa status notifikasi yang ditujukan untuk user yang sedang login,
  /// dan memunculkan pop-up pemberitahuan sesuai status waktunya:
  /// - Merah (24 Jam sebelum): "24 jam lagi [nama notif] harus dilaksanakan"
  /// - Kuning (12 Jam sebelum): "12 jam lagi [nama notif] harus dilaksanakan"
  /// - Hijau (Saat kegiatan): "Saat ini [nama notif] harus dilaksanakan"
  /// - Abu-Abu (> 24 Jam): Belum terkirim ke petugas
  static Future<void> checkAndTriggerPendingNotifications() async {
    try {
      final items = await ApiService.getNotificationItems();
      if (items.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();

      for (final item in items) {
        final title = item.title.trim().isNotEmpty ? item.title.trim() : 'kegiatan';

        switch (item.status) {
          case NotificationStatus.merah:
            final key = 'notif_alert_${item.id}_merah';
            final alreadySent = prefs.getBool(key) ?? false;
            if (!alreadySent) {
              await showNotification(
                title: 'Peringatan 24 Jam: $title',
                body: '24 jam lagi $title harus dilaksanakan',
                payload: item.id,
              );
              await prefs.setBool(key, true);
              debugPrint('🔔 [Triggered 24 Jam] Notifikasi merah terkirim untuk: $title');
            }
            break;

          case NotificationStatus.kuning:
            final key = 'notif_alert_${item.id}_kuning';
            final alreadySent = prefs.getBool(key) ?? false;
            if (!alreadySent) {
              await showNotification(
                title: 'Peringatan 12 Jam: $title',
                body: '12 jam lagi $title harus dilaksanakan',
                payload: item.id,
              );
              await prefs.setBool(key, true);
              debugPrint('🔔 [Triggered 12 Jam] Notifikasi kuning terkirim untuk: $title');
            }
            break;

          case NotificationStatus.hijau:
            final key = 'notif_alert_${item.id}_hijau';
            final alreadySent = prefs.getBool(key) ?? false;
            if (!alreadySent) {
              await showNotification(
                title: 'Saat Kegiatan: $title',
                body: 'Saat ini jadwal $title harus dilaksanakan',
                payload: item.id,
              );
              await prefs.setBool(key, true);
              debugPrint('🔔 [Triggered Saat Kegiatan] Notifikasi hijau terkirim untuk: $title');
            }
            break;

          case NotificationStatus.abuAbu:
            // Abu-abu: notif telah dibikin admin tapi belum terkirim ke petugas (> 24 jam)
            break;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [checkAndTriggerPendingNotifications] Error: $e');
    }
  }

  /// Mengaktifkan Realtime listener notifikasi dari Supabase
  static void setupSupabaseRealtime({
    Function(Map<String, dynamic> payload)? onNewNotification,
  }) {
    final client = SupabaseService.client;
    if (client == null) {
      debugPrint('ℹ️ [NotificationService] Supabase belum aktif, listener realtime ditunda.');
      return;
    }

    try {
      _supabaseRealtimeChannel?.unsubscribe();

      _supabaseRealtimeChannel = client
          .channel('public:notifications_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            callback: (payload) async {
              debugPrint('🔔 [Supabase Realtime Notifications] Event: ${payload.eventType}');
              await checkAndTriggerPendingNotifications();
              notifyAppListeners();
              if (payload.newRecord.isNotEmpty) {
                onNewNotification?.call(payload.newRecord);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notification_recipients',
            callback: (payload) async {
              debugPrint('🔔 [Supabase Realtime Recipients] Event: ${payload.eventType}');
              await checkAndTriggerPendingNotifications();
              notifyAppListeners();
              if (payload.newRecord.isNotEmpty) {
                onNewNotification?.call(payload.newRecord);
              }
            },
          )
          .subscribe();

      debugPrint('✅ [NotificationService] Realtime notifications channel tersambung.');
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Error realtime Supabase: $e');
    }
  }

  /// Hentikan realtime listener dan timer
  static void dispose() {
    _supabaseRealtimeChannel?.unsubscribe();
    _supabaseRealtimeChannel = null;
    _checkScheduleTimer?.cancel();
    _checkScheduleTimer = null;
    _listeners.clear();
  }
}
