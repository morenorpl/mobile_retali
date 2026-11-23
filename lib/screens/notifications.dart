import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Retali-Sistem Theme - Navy & Gold Palette
  static const Color primaryDark = Color(0xFF0D1523);
  static const Color primaryNavy = Color(0xFF1B3167);
  static const Color secondaryNavy = Color(0xFF263754);
  static const Color accentGold = Color(0xFFEAB308);
  static const Color surfaceColor = Colors.white;
  static const Color pageBg = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);

  bool _loading = true;
  String? _error;
  List<NotificationItem> _items = [];
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetch();
    NotificationService.addListener(_fetch);
  }

  @override
  void dispose() {
    NotificationService.removeListener(_fetch);
    super.dispose();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await ApiService.getNotificationItems();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.isNegative || d.inSeconds < 60) return 'Baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} mnt lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    if (d.inDays < 7) return '${d.inDays} hr lalu';
    final weeks = (d.inDays / 7).floor();
    return '$weeks mgg lalu';
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    try {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return dt.toString().substring(0, 16);
    }
  }

  String _getCountdownText(NotificationItem item) {
    if (item.startDate == null) return 'Jadwal belum ditentukan';
    final diff = item.diffHours;
    if (diff == null) return 'Jadwal belum ditentukan';
    if (diff <= 0) {
      final pastHours = (-diff).toStringAsFixed(1);
      return 'Telah dimulai ($pastHours jam lalu)';
    } else if (diff < 1) {
      final mins = (diff * 60).round();
      return '$mins menit lagi';
    } else if (diff < 24) {
      final hours = diff.toStringAsFixed(1);
      return '$hours jam lagi';
    } else {
      final days = (diff / 24).toStringAsFixed(1);
      return '$days hari lagi';
    }
  }

  Future<void> _handleMarkAllAsRead() async {
    try {
      await ApiService.markAllNotificationsAsRead();
      setState(() {
        _items = _items.map((it) => it.copyWith(isRead: true)).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: accentGold, size: 18),
                SizedBox(width: 10),
                Text(
                  'Semua notifikasi ditandai sudah dibaca',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            backgroundColor: primaryNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal markAll: $e");
    }
  }

  Future<void> _showDetail(NotificationItem item) async {
    // Jika belum dibaca, langsung tandai dibaca di server & update tampilan
    if (!item.isRead) {
      try {
        await ApiService.markNotificationAsRead(item.id);
        setState(() {
          final idx = _items.indexWhere((e) => e.id == item.id);
          if (idx != -1) {
            _items[idx] = _items[idx].copyWith(isRead: true, readAt: DateTime.now());
          }
        });
      } catch (e) {
        debugPrint("Gagal mark notif as read: $e");
      }
    }

    if (!mounted) return;

    // Modal slide-up detail
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: const BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag handle indicator
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Sheet header bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryNavy.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: primaryNavy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Detail Pemberitahuan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: textSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: borderColor),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge & Relative Time Tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(item, isRead: false),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _timeAgo(item.createdAt),
                                  style: const TextStyle(
                                    color: textSecondary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Notification Title
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Countdown / Dynamic Urgency Status Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: item.statusBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: item.statusBorderColor, width: 1.2),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: item.statusColor.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(item.statusIcon, color: item.statusColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.dynamicReminderText,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: item.statusColor,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.statusDescription,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: item.statusColor.withOpacity(0.9),
                                      height: 1.3,
                                    ),
                                  ),
                                  if (item.startDate != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: surfaceColor.withOpacity(0.85),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: item.statusBorderColor,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.timer_outlined,
                                            size: 13,
                                            color: item.statusColor,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _getCountdownText(item),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: item.statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Full Message Section
                      const Text(
                        'Isi Pesan Lengkap',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: pageBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          item.message.isNotEmpty
                              ? item.message
                              : '(Tidak ada isi pesan tambahan)',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Schedule Section (if present)
                      if (item.startDate != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: textPrimary.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryNavy.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 20,
                                  color: primaryNavy,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Jadwal Kegiatan',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Mulai: ${_formatDateTime(item.startDate)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    if (item.endDate != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Selesai: ${_formatDateTime(item.endDate)}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Timestamp info footer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: textMuted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Dibuat: ${_formatDateTime(item.createdAt)}${item.readAt != null ? ' • Dibaca: ${_formatDateTime(item.readAt)}' : ''}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Button (Tutup)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: const Text(
                            'Tutup',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryNavy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGuideDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryDark, primaryNavy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info_outline_rounded, color: accentGold, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panduan Status Warna',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sistem Pengingat Bertahap',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _guideItem(
                color: errorRed,
                title: 'Merah (Saat Kegiatan)',
                desc: 'Waktu pelaksanaan kegiatan telah tiba atau sedang berlangsung saat ini. Memerlukan aksi segera oleh petugas.',
              ),
              const SizedBox(height: 10),
              _guideItem(
                color: warningAmber,
                title: 'Kuning (Peringatan 12 Jam)',
                desc: 'Jadwal kegiatan sudah mendesak (< 12 jam lagi). Mengingatkan "12 jam lagi harus dilaksanakan".',
              ),
              const SizedBox(height: 10),
              _guideItem(
                color: successGreen,
                title: 'Hijau (Peringatan 24 Jam)',
                desc: 'Jadwal kegiatan mendekati rentang 12 hingga 24 jam lagi. Mengingatkan "24 jam lagi harus dilaksanakan".',
              ),
              const SizedBox(height: 10),
              _guideItem(
                color: textMuted,
                title: 'Abu-Abu (Belum Ada Peringatan)',
                desc: 'Notifikasi telah dibuat oleh admin, jadwal kegiatan masih > 24 jam. Belum masuk masa pengingat petugas.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Mengerti',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _guideItem({
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(NotificationItem item, {bool isRead = false}) {
    final bgColor = isRead ? const Color(0xFFF1F5F9) : item.statusBgColor;
    final borderColor = isRead ? const Color(0xFFCBD5E1) : item.statusBorderColor;
    final dotColor = isRead ? textMuted : item.statusColor;
    final textColor = isRead ? textSecondary : item.statusColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            item.statusLabel,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required int total,
    required int unread,
    required int redCount,
    required int yellowCount,
    required int greenCount,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryNavy, secondaryNavy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: accentGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Pengingat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unread > 0
                          ? '$unread notifikasi belum dibaca'
                          : 'Semua notifikasi sudah dibaca',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: unread > 0 ? const Color(0xFFD97706) : textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: errorRed.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '$unread Baru',
                    style: const TextStyle(
                      color: errorRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: pageBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  label: 'Saat Kegiatan',
                  count: redCount,
                  color: errorRed,
                  dotColor: errorRed,
                ),
                Container(width: 1, height: 24, color: borderColor),
                _buildMiniStat(
                  label: '12 Jam',
                  count: yellowCount,
                  color: warningAmber,
                  dotColor: warningAmber,
                ),
                Container(width: 1, height: 24, color: borderColor),
                _buildMiniStat(
                  label: '24 Jam',
                  count: greenCount,
                  color: successGreen,
                  dotColor: successGreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required int count,
    required Color color,
    required Color dotColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips({
    required int totalCount,
    required int count24h,
    required int count12h,
    required int countActive,
  }) {
    final filters = [
      {'label': 'Semua', 'count': totalCount, 'color': primaryNavy},
      {'label': 'Saat Kegiatan', 'count': countActive, 'color': errorRed},
      {'label': '12 Jam', 'count': count12h, 'color': warningAmber},
      {'label': '24 Jam', 'count': count24h, 'color': successGreen},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((f) {
          final label = f['label'] as String;
          final count = f['count'] as int;
          final color = f['color'] as Color;
          final isSelected = _selectedFilter == label;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = label;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                decoration: BoxDecoration(
                  color: isSelected ? primaryNavy : surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? primaryNavy : borderColor,
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryNavy.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (label != 'Semua') ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isSelected ? accentGold : color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? accentGold : textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem it) {
    final isRead = it.isRead;

    // Distinctive urgency indicator color on the left edge
    final Color urgencyColor = () {
      switch (it.status) {
        case NotificationStatus.merah:
          return errorRed;
        case NotificationStatus.kuning:
          return warningAmber;
        case NotificationStatus.hijau:
          return successGreen;
        case NotificationStatus.abuAbu:
          return textMuted;
      }
    }();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFFF8FAFC) : surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? borderColor : const Color(0xFFCBD5E1),
          width: 1,
        ),
        boxShadow: isRead
            ? []
            : [
                BoxShadow(
                  color: primaryDark.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Distinctive colored indicator on the left for urgency
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: isRead ? urgencyColor.withOpacity(0.4) : urgencyColor,
                ),
              ),

              // Main content
              Expanded(
                child: InkWell(
                  onTap: () => _showDetail(it),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header bar: Status Badge + Relative Time Tag + Unread Indicator
                        Row(
                          children: [
                            _buildStatusBadge(it, isRead: isRead),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 11,
                                    color: isRead ? textMuted : textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _timeAgo(it.createdAt),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                                      color: isRead ? textMuted : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isRead) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: accentGold,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x66EAB308),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Notification Title
                        Text(
                          it.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                            color: isRead ? textSecondary : textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Kotak Pengingat Dinamis (Dynamic Reminder)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: isRead ? const Color(0xFFF1F5F9) : it.statusBgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isRead ? borderColor : it.statusBorderColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                it.statusIcon,
                                size: 14,
                                color: isRead ? textMuted : it.statusColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  it.dynamicReminderText,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                    color: isRead ? textSecondary : it.statusColor,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Message snippet (if any)
                        if (it.message.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            it.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              color: isRead ? textMuted : const Color(0xFF475569),
                              height: 1.4,
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),
                        Divider(
                          height: 1,
                          thickness: 0.8,
                          color: isRead ? borderColor : const Color(0xFFF1F5F9),
                        ),
                        const SizedBox(height: 8),

                        // Bottom info: Date & Detail link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event_note_rounded,
                                  size: 13,
                                  color: isRead ? textMuted : primaryNavy,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  it.startDate != null
                                      ? 'Jadwal: ${_formatDateTime(it.startDate)}'
                                      : 'Dibuat: ${_formatDateTime(it.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isRead ? textMuted : textSecondary,
                                    fontWeight: isRead ? FontWeight.w400 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Detail',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isRead ? textMuted : primaryNavy,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 14,
                                  color: isRead ? textMuted : primaryNavy,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: errorRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, size: 36, color: errorRed),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Gagal Memuat Notifikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _error ?? 'Terjadi kesalahan saat memuat data notifikasi.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAllView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryNavy.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 40,
              color: primaryNavy,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            'Belum Ada Notifikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              'Belum ada notifikasi atau jadwal kegiatan yang ditujukan untuk Anda saat ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterEmptyView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.filter_list_off_rounded,
                size: 32,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Tidak ada notifikasi dengan status "$_selectedFilter"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'Semua';
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryNavy,
                side: const BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Tampilkan Semua',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _items.where((e) => !e.isRead).length;
    final totalCount = _items.length;
    final redCount = _items.where((e) => e.status == NotificationStatus.merah).length;
    final yellowCount = _items.where((e) => e.status == NotificationStatus.kuning).length;
    final greenCount = _items.where((e) => e.status == NotificationStatus.hijau).length;

    List<NotificationItem> filteredItems = _items;
    if (_selectedFilter == '24 Jam') {
      filteredItems = _items.where((e) => e.status == NotificationStatus.hijau).toList();
    } else if (_selectedFilter == '12 Jam') {
      filteredItems = _items.where((e) => e.status == NotificationStatus.kuning).toList();
    } else if (_selectedFilter == 'Saat Kegiatan') {
      filteredItems = _items.where((e) => e.status == NotificationStatus.merah).toList();
    }

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryDark,
                primaryNavy,
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notifikasi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Pemberitahuan & Pengingat Umrah',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // "Tandai Semua Dibaca" button with gold/white accent
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: unreadCount > 0 ? _handleMarkAllAsRead : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: unreadCount > 0
                            ? accentGold.withOpacity(0.18)
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: unreadCount > 0
                              ? accentGold.withOpacity(0.5)
                              : Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.done_all_rounded,
                            size: 14,
                            color: unreadCount > 0 ? accentGold : Colors.white.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tandai Baca',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: unreadCount > 0 ? accentGold : Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Guide button with modern glass styling
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showGuideDialog,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: primaryNavy,
        backgroundColor: Colors.white,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: primaryNavy,
                ),
              )
            : (_error != null)
                ? _buildErrorView()
                : (_items.isEmpty)
                    ? _buildEmptyAllView()
                    : CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // 1. Summary Counter Card
                          SliverToBoxAdapter(
                            child: _buildSummaryCard(
                              total: totalCount,
                              unread: unreadCount,
                              redCount: redCount,
                              yellowCount: yellowCount,
                              greenCount: greenCount,
                            ),
                          ),

                          // 2. Status Filter Chips (Semua, 24 Jam, 12 Jam, Saat Kegiatan)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildFilterChips(
                                totalCount: totalCount,
                                count24h: greenCount,
                                count12h: yellowCount,
                                countActive: redCount,
                              ),
                            ),
                          ),

                          // 3. Notification List or Filter Empty State
                          if (filteredItems.isEmpty)
                            SliverToBoxAdapter(
                              child: _buildFilterEmptyView(),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.only(bottom: 28),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final it = filteredItems[index];
                                    return _buildNotificationCard(it);
                                  },
                                  childCount: filteredItems.length,
                                ),
                              ),
                            ),
                        ],
                      ),
      ),
    );
  }
}
