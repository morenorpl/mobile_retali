import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _accent = const Color(0xFF842D62);
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
void dispose() {
  // Tandai semua notif sebagai sudah dibaca ketika user keluar dari halaman
  ApiService.markAllNotificationsAsRead().then((_) {
    debugPrint("Semua notifikasi ditandai sudah dibaca");
  }).catchError((e) {
    debugPrint("Gagal markAll: $e");
  });
  super.dispose();
}

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getNotifications();
      final normalized =
          list.map<Map<String, dynamic>>((e) => _normalizeNotif(e)).toList();
      setState(() {
        _items = normalized;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _normalizeNotif(dynamic raw) {
    final map =
        (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

    Map<String, dynamic> data = {};
    final dynamicData = map['data'];
    if (dynamicData is String) {
      try {
        data = Map<String, dynamic>.from(jsonDecode(dynamicData));
      } catch (_) {}
    } else if (dynamicData is Map) {
      data = Map<String, dynamic>.from(dynamicData);
    }

    String pickStr(List keys) {
      for (final k in keys) {
        final v = (k is String) ? (map[k] ?? data[k]) : null;
        if (v is String && v.trim().isNotEmpty) return v;
      }
      return '';
    }

    final String id = (map['id'] ?? data['id'] ?? '').toString();
    String title = pickStr(['title', 'subject', 'heading']);
    String body = pickStr(['body', 'message', 'content', 'text']);
    final createdStr = pickStr(['created_at', 'createdAt', 'time']);

    DateTime createdAt = DateTime.now();
    if (createdStr.isNotEmpty) {
      try {
        createdAt = DateTime.parse(createdStr).toLocal();
      } catch (_) {}
    }

    bool read =
        map['read_at'] != null || map['readAt'] != null || data['read'] == true;

    if (title.isEmpty) {
      title = (map['type']?.toString().split('\\').last ?? 'Notifikasi');
    }
    if (body.isEmpty) {
      body = (map['description'] ?? '').toString();
    }

    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt,
      'read': read,
      'data': data,
      'raw': map,
    };
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} mnt';
    if (d.inHours < 24) return '${d.inHours} jam';
    if (d.inDays < 7) return '${d.inDays} hr';
    final weeks = (d.inDays / 7).floor();
    return '$weeks mgg';
  }

  Future<void> _showDetail(Map<String, dynamic> item) async {
    // kalau belum dibaca → tandai ke server
    if (item['read'] != true) {
      try {
        await ApiService.markNotificationAsRead(item['id']);
        setState(() {
          final idx = _items.indexWhere((e) => e['id'] == item['id']);
          if (idx != -1) _items[idx]['read'] = true;
        });
      } catch (e) {
        debugPrint("Gagal mark notif: $e");
      }
    }

    // tampilkan detail di bottomsheet
    final result = await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['title'] ?? 'Notifikasi',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                _timeAgo(item['createdAt'] as DateTime),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Divider(height: 24),
              Text(
                (item['body'] as String).isNotEmpty
                    ? item['body']
                    : '(tanpa isi)',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true), // balik true
                  icon: const Icon(Icons.check),
                  label: const Text('Tutup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );

    // kalau ditutup & ada perubahan → kembalikan sinyal ke Home
    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Notifikasi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Center(
                        child: Text('Gagal memuat notifikasi.\n$_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14)),
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
                          const SizedBox(height: 120),
                          Icon(Icons.notifications_off,
                              size: 72, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text('Belum ada notifikasi',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(height: 60),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final it = _items[i];
                          final read = it['read'] == true;
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: read
                                    ? Colors.grey.shade200
                                    : accent.withOpacity(0.15),
                                child: Icon(
                                  read
                                      ? Icons.notifications_none
                                      : Icons.notifications_active,
                                  color: read ? Colors.grey.shade600 : accent,
                                ),
                              ),
                              title: Text(
                                it['title'] ?? 'Notifikasi',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: read
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                (it['body'] as String).isNotEmpty
                                    ? it['body']
                                    : '(tanpa isi)',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                _timeAgo(it['createdAt'] as DateTime),
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12),
                              ),
                              onTap: () => _showDetail(it),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
