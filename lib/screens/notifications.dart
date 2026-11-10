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
  final Color _accent = const Color(0xFF842D62);
  bool _loading = true;
  String? _error;
  List<NotificationItem> _items = [];

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
    if (d.inSeconds < 60) return 'Baru saja';
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

  Future<void> _handleMarkAllAsRead() async {
    try {
      await ApiService.markAllNotificationsAsRead();
      setState(() {
        _items = _items.map((it) => it.copyWith(isRead: true)).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi ditandai sudah dibaca'),
            backgroundColor: Color(0xFF842D62),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal markAll: $e");
    }
  }

  Future<void> _showDetail(NotificationItem item) async {
    // Jika belum dibaca, langsung tandai dibaca di server & update tampilan (greyed-out)
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Status badge & relative time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge(item, isRead: false),
                  Text(
                    _timeAgo(item.createdAt),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Judul Notifikasi
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),

              // Kotak Pengingat Dinamis (Dynamic Reminder)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: item.statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: item.statusBorderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.statusIcon, color: item.statusColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.dynamicReminderText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: item.statusColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.statusDescription,
                            style: TextStyle(
                              fontSize: 11,
                              color: item.statusColor.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Isi Pesan Lengkap
              const Text(
                'Pesan Lengkap:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  item.message.isNotEmpty ? item.message : '(Tidak ada isi pesan tambahan)',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Jadwal Kegiatan
              if (item.startDate != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF842D62)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mulai: ${_formatDateTime(item.startDate)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            if (item.endDate != null)
                              Text(
                                'Selesai: ${_formatDateTime(item.endDate)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Tombol Tutup
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.help_outline, color: Colors.amber.shade700, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Panduan Status Warna',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              _guideItem(
                color: const Color(0xFF9CA3AF),
                title: 'Abu-Abu (Belum Ada Peringatan)',
                desc: 'Notifikasi telah dibuat oleh admin, jadwal kegiatan masih > 24 jam. Belum dikirimkan ke petugas.',
              ),
              const SizedBox(height: 10),
              _guideItem(
                color: const Color(0xFFEF4444),
                title: 'Merah (Peringatan 24 Jam)',
                desc: 'Jadwal kegiatan mendekati rentang 12 hingga 24 jam lagi. Mengingatkan "24 jam lagi harus dilaksanakan".',
              ),
              const SizedBox(height: 10),
              _guideItem(
                color: const Color(0xFFF59E0B),
                title: 'Kuning (Peringatan 12 Jam)',
                desc: 'Jadwal kegiatan sudah mendesak (< 12 jam lagi). Mengingatkan "12 jam lagi harus dilaksanakan".',
              ),
              const SizedBox(height: 10),
              _guideItem(
                color: const Color(0xFF10B981),
                title: 'Hijau (Saat Kegiatan)',
                desc: 'Waktu pelaksanaan kegiatan telah tiba atau sedang berlangsung saat ini.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF121C2D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Mengerti'),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(NotificationItem item, {bool isRead = false}) {
    final bgColor = isRead ? const Color(0xFFE2E8F0) : item.statusBgColor;
    final borderColor = isRead ? const Color(0xFFCBD5E1) : item.statusBorderColor;
    final dotColor = isRead ? const Color(0xFF94A3B8) : item.statusColor;
    final textColor = isRead ? const Color(0xFF64748B) : item.statusColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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

  @override
  Widget build(BuildContext context) {
    final unreadCount = _items.where((e) => !e.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showGuideDialog,
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'Panduan Status Warna',
          ),
          if (unreadCount > 0)
            IconButton(
              onPressed: _handleMarkAllAsRead,
              icon: const Icon(Icons.done_all, color: Colors.white),
              tooltip: 'Tandai Semua Dibaca',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: _accent,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Gagal memuat notifikasi.\n$_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: _fetch,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi'),
                        ),
                      ),
                    ],
                  )
                : (_items.isEmpty)
                    ? ListView(
                        children: [
                          const SizedBox(height: 140),
                          Icon(Icons.notifications_off_outlined,
                              size: 70, color: Colors.grey.shade400),
                          const SizedBox(height: 14),
                          Center(
                            child: Text(
                              'Belum ada notifikasi yang ditujukan untuk Anda',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final it = _items[i];
                          return _buildNotificationCard(it);
                        },
                      ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem it) {
    final isRead = it.isRead;

    // Konsep warna mirip Gmail:
    // - Belum dibaca: Latar putih bersih, teks lebih tebal & kontras gelap, warna badge/reminder cerah normal
    // - Sudah dibaca: Latar sedikit greyed-out (soft slate/grey), teks normal & muted grey, badge/reminder ikut greyed-out
    final cardBg = isRead ? const Color(0xFFF1F5F9) : Colors.white;
    final cardBorder = isRead ? const Color(0xFFE2E8F0) : _accent.withOpacity(0.22);
    final titleColor = isRead ? const Color(0xFF64748B) : const Color(0xFF0F172A);
    final titleWeight = isRead ? FontWeight.w500 : FontWeight.w700;
    final messageColor = isRead ? const Color(0xFF94A3B8) : const Color(0xFF334155);
    final avatarBg = isRead ? const Color(0xFFE2E8F0) : it.statusBgColor;
    final avatarIconColor = isRead ? const Color(0xFF94A3B8) : it.statusColor;

    final reminderBg = isRead ? const Color(0xFFE2E8F0).withOpacity(0.6) : it.statusBgColor;
    final reminderBorder = isRead ? const Color(0xFFCBD5E1) : it.statusBorderColor;
    final reminderTextColor = isRead ? const Color(0xFF64748B) : it.statusColor;

    return Card(
      elevation: isRead ? 0 : 2,
      color: cardBg,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cardBorder, width: isRead ? 1 : 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(it),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header bar: Avatar Icon + Title + Status Badge + Dot Belum Dibaca
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: avatarBg,
                    child: Icon(it.statusIcon, color: avatarIconColor, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      it.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: titleWeight,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(it, isRead: isRead),
                  if (!isRead) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Kotak Pengingat Dinamis (Dynamic Reminder)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: reminderBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: reminderBorder),
                ),
                child: Text(
                  it.dynamicReminderText,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    color: reminderTextColor,
                  ),
                ),
              ),

              if (it.message.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  it.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isRead ? FontWeight.w400 : FontWeight.w500,
                    color: messageColor,
                    height: 1.35,
                  ),
                ),
              ],

              const SizedBox(height: 8),
              Divider(height: 1, color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
              const SizedBox(height: 6),

              // Bottom Info: Tanggal Jadwal & Relative Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 12,
                        color: isRead ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        it.startDate != null
                            ? 'Jadwal: ${_formatDateTime(it.startDate)}'
                            : 'Dibuat: ${_formatDateTime(it.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isRead ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                          fontWeight: isRead ? FontWeight.w400 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _timeAgo(it.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isRead ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
