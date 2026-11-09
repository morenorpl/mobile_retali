import 'dart:async';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

final GlobalKey<_RunningNotificationBarState> _runningNotifKey =
    GlobalKey<_RunningNotificationBarState>();

class RunningNotificationBar extends StatefulWidget {
  const RunningNotificationBar({super.key});

  static void refreshGlobal() {
    _runningNotifKey.currentState?._fetchLatest();
  }

  @override
  State<RunningNotificationBar> createState() => _RunningNotificationBarState();
}

class _RunningNotificationBarState extends State<RunningNotificationBar> {
  String _currentText = "Memuat notifikasi...";
  RealtimeChannel? _realtimeChannel;
  Timer? _autoRefreshTimer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchLatest();

    // 🔁 auto refresh tiap 10 detik
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchLatest();
    });

    // 🔔 Realtime listener dari Supabase
    _setupSupabaseRealtime();
  }

  void _setupSupabaseRealtime() {
    final client = SupabaseService.client;
    if (client == null) return;

    try {
      _realtimeChannel = client
          .channel('public:running_notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              final newRecord = payload.newRecord;
              final body = (newRecord['body'] ??
                      newRecord['message'] ??
                      newRecord['content'] ??
                      newRecord['text'] ??
                      '')
                  .toString()
                  .trim();

              if (body.isNotEmpty && mounted) {
                setState(() => _currentText = body);
                debugPrint("⚡ Supabase Realtime notif: $body");
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint("⚠️ Gagal setup Supabase Realtime di running bar: $e");
    }
  }

  Future<void> _fetchLatest() async {
    if (_loading) return;
    _loading = true;
    try {
      final list = await ApiService.getNotifications();
      debugPrint("📦 Total notif: ${list.length}");
      if (list.isNotEmpty) {
        // ambil notifikasi terbaru
        final notif = list.first ?? list.last;
        String body = '';
        // cari field yang berisi teks isi
        body = (notif['body'] ??
                notif['message'] ??
                notif['content'] ??
                notif['text'] ??
                '')
            .toString()
            .trim();

        // kalau body kosong, coba ambil dari notif['data']
        if (body.isEmpty && notif['data'] != null) {
          final data = notif['data'];
          if (data is Map) {
            body = (data['body'] ??
                    data['message'] ??
                    data['content'] ??
                    data['text'] ??
                    '')
                .toString()
                .trim();
          }
        }

        debugPrint("🧾 Body terdeteksi: '$body'");

        if (body.isNotEmpty && body != _currentText && mounted) {
          setState(() => _currentText = body);
        } else if (body.isEmpty && mounted) {
          setState(() => _currentText = "Belum ada isi notifikasi");
        }
      } else if (mounted) {
        setState(() => _currentText = "Belum ada notifikasi");
      }
    } catch (e) {
      debugPrint("⚠️ Gagal ambil notifikasi: $e");
      if (mounted) {
        setState(() => _currentText = "Gagal memuat notifikasi");
      }
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _runningNotifKey,
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Marquee(
              text: _currentText,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              velocity: 40,
              blankSpace: 50,
              pauseAfterRound: const Duration(seconds: 2),
              startPadding: 10,
            ),
          ),
        ],
      ),
    );
  }
}
