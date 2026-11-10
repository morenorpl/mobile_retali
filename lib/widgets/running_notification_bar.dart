import 'dart:async';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

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
  int _unreadCount = 0;
  Timer? _autoRefreshTimer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchLatest();

    // Refresh berkala tiap 20 detik
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _fetchLatest();
    });

    // Daftarkan listener ke NotificationService untuk update realtime
    NotificationService.addListener(_fetchLatest);
  }

  Future<void> _fetchLatest() async {
    if (_loading || !mounted) return;
    _loading = true;

    try {
      final items = await ApiService.getNotificationItems();

      if (!mounted) return;

      final unread = items.where((it) => !it.isRead).length;
      final newText = unread > 0
          ? "Ada $unread notif yang belum dibaca"
          : "Tidak ada notif baru";

      if (mounted && (newText != _currentText || unread != _unreadCount)) {
        setState(() {
          _currentText = newText;
          _unreadCount = unread;
        });
      }
    } catch (e) {
      debugPrint("⚠️ Gagal ambil notifikasi running bar: $e");
      if (mounted) {
        setState(() => _currentText = "Tidak ada notif baru");
      }
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    NotificationService.removeListener(_fetchLatest);
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _unreadCount > 0;

    return Container(
      key: _runningNotifKey,
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            hasUnread ? Icons.notifications_active : Icons.notifications_none,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Marquee(
              text: _currentText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              velocity: 35,
              blankSpace: 60,
              pauseAfterRound: const Duration(seconds: 2),
              startPadding: 10,
            ),
          ),
        ],
      ),
    );
  }
}
