import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class NotificationService {
  static const String channelId = 'default_channel';
  static const String channelName = 'General Notifications';

  static final FlutterLocalNotificationsPlugin _flnp =
      FlutterLocalNotificationsPlugin();
  static RealtimeChannel? _supabaseRealtimeChannel;

  /// Inisialisasi local notification
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
      description: 'Default channel for app notifications',
    );

    final androidImpl = _flnp.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(channel);

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

      // Mendengarkan perubahan atau broadcast pesan pada tabel / channel notifikasi
      _supabaseRealtimeChannel = client
          .channel('public:notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              final newRecord = payload.newRecord;
              debugPrint('🔔 [Supabase Realtime] Notifikasi baru diterima: $newRecord');

              final title = (newRecord['title'] ?? 'Notifikasi Baru').toString();
              final body = (newRecord['body'] ??
                      newRecord['message'] ??
                      newRecord['content'] ??
                      '')
                  .toString();

              if (title.isNotEmpty || body.isNotEmpty) {
                showNotification(title: title, body: body);
              }

              onNewNotification?.call(newRecord);
            },
          )
          .subscribe();

      debugPrint('✅ [NotificationService] Realtime notifications channel tersambung.');
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Error realtime Supabase: $e');
    }
  }

  /// Hentikan realtime listener
  static void dispose() {
    _supabaseRealtimeChannel?.unsubscribe();
    _supabaseRealtimeChannel = null;
  }
}
