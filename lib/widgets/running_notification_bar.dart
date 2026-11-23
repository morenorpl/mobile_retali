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

class _RunningNotificationBarState extends State<RunningNotificationBar>
    with SingleTickerProviderStateMixin {
  String _currentText = "Memuat notifikasi...";
  int _unreadCount = 0;
  Timer? _autoRefreshTimer;
  bool _loading = false;

  late AnimationController _bellAnimController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Inisialisasi controller animasi goyang halus ikon lonceng
    _bellAnimController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.15)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.15, end: 0.15)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.15, end: -0.10)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.10, end: 0.10)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.10, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 10,
      ),
    ]).animate(_bellAnimController);

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

        if (unread > 0) {
          if (!_bellAnimController.isAnimating) {
            _bellAnimController.repeat();
          }
        } else {
          if (_bellAnimController.isAnimating) {
            _bellAnimController.stop();
            _bellAnimController.reset();
          }
        }
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
    _bellAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _unreadCount > 0;

    return Container(
      key: _runningNotifKey,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasUnread
              ? const Color(0xFFEAB308).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
        boxShadow: [
          if (hasUnread)
            BoxShadow(
              color: const Color(0xFFEAB308).withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              // 🔔 Ikon lonceng dengan animasi shake halus saat ada notifikasi baru
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: hasUnread ? _shakeAnimation.value : 0.0,
                    alignment: Alignment.topCenter,
                    child: child,
                  );
                },
                child: Icon(
                  hasUnread
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: hasUnread
                      ? const Color(0xFFEAB308)
                      : Colors.white.withValues(alpha: 0.85),
                  size: 18,
                ),
              ),

              // 🟡 Badge unread count (lingkaran emas dengan jumlah notifikasi)
              if (hasUnread) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 17,
                    minHeight: 17,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAB308),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEAB308).withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _unreadCount > 99 ? '99+' : '$_unreadCount',
                    style: const TextStyle(
                      color: Color(0xFF0D1523),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(width: 8),

              // Garis pemisah halus (glass separator)
              Container(
                width: 1,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(0.5),
                ),
              ),

              const SizedBox(width: 8),

              // 📜 Running text notifikasi dengan tipografi modern
              Expanded(
                child: Marquee(
                  text: _currentText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  velocity: 32.0,
                  blankSpace: 60.0,
                  pauseAfterRound: const Duration(seconds: 2),
                  startPadding: 4.0,
                  accelerationDuration: const Duration(milliseconds: 300),
                  accelerationCurve: Curves.easeInOut,
                  decelerationDuration: const Duration(milliseconds: 300),
                  decelerationCurve: Curves.easeInOut,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
