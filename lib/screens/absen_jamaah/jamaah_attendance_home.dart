import 'package:flutter/material.dart';
import '../../services/jamaah_attendance_service.dart';
import 'jamaah_attendance_page.dart';
import 'dart:async';

class JamaahAttendanceHome extends StatefulWidget {
  const JamaahAttendanceHome({super.key});

  @override
  State<JamaahAttendanceHome> createState() => _JamaahAttendanceHomeState();
}

class _JamaahAttendanceHomeState extends State<JamaahAttendanceHome> {
  late Future<List<dynamic>> _futureAbsenList;
  late List<dynamic> _cachedData = [];

  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _futureAbsenList = _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================
  // 🔄 AUTO REFRESH (SETIAP 5 DETIK)
  // ============================================
  Timer? _timer;

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (mounted) {
        try {
          final newData = await JamaahAttendanceService.fetchAbsenList();

          // Cek apakah ada perubahan data
          if (_hasDataChanged(newData)) {
            print('📝 Data berubah, refresh UI...');
            setState(() {
              _cachedData = newData;
              _futureAbsenList = Future.value(newData);
            });
          } else {
            print('⏱️ Tidak ada perubahan data');
          }
        } catch (e) {
          debugPrint('❌ Auto refresh error: $e');
        }
      }
    });
  }

  bool _hasDataChanged(List<dynamic> newData) {
    if (_cachedData.length != newData.length) return true;

    // Bandingkan setiap item (simple comparison berdasarkan id dan is_done)
    for (int i = 0; i < newData.length; i++) {
      if (i >= _cachedData.length) return true;

      final newItem = newData[i];
      final oldItem = _cachedData[i];

      final newId = _getInt(newItem, 'id');
      final oldId = _getInt(oldItem, 'id');

      final newIsDone = newItem['is_done'] ?? false;
      final oldIsDone = oldItem['is_done'] ?? false;

      if (newId != oldId || newIsDone != oldIsDone) {
        return true;
      }
    }

    return false;
  }

  Future<List<dynamic>> _loadData() async {
    try {
      final data = await JamaahAttendanceService.fetchAbsenList();

      if (!mounted) return [];

      setState(() {
        _cachedData = data;
        _isFirstLoad = false;
      });

      return data;
    } catch (e) {
      if (!mounted) return [];

      debugPrint('❌ ERR LOAD ABSEN LIST: $e');
      setState(() {
        _isFirstLoad = false;
      });
      return _cachedData.isEmpty ? [] : _cachedData;
    }
  }

  void _refresh() {
    setState(() {
      _futureAbsenList = _loadData();
    });
  }

  // ============================================
  // 🛡️ SAFE GETTERS
  // ============================================
  String _getString(dynamic obj, String key, {String fallback = '-'}) {
    if (obj is Map && obj[key] != null) return obj[key].toString();
    return fallback;
  }

  int _getInt(dynamic obj, String key, {int fallback = 0}) {
    if (obj is Map && obj[key] != null) {
      if (obj[key] is int) return obj[key];
      return int.tryParse(obj[key].toString()) ?? fallback;
    }
    return fallback;
  }

  String _getNestedString(
    dynamic obj,
    List<String> keys, {
    String fallback = '-',
  }) {
    try {
      dynamic current = obj;
      for (final key in keys) {
        if (current is Map)
          current = current[key];
        else
          return fallback;
      }
      return (current == null || current == 'null')
          ? fallback
          : current.toString();
    } catch (e) {
      return fallback;
    }
  }

  IconData _getSessionIcon(String sesi) {
    final s = sesi.toLowerCase();

    if (s.contains('bus')) return Icons.directions_bus;
    if (s.contains('hotel')) return Icons.hotel;
    if (s.contains('pesawat')) return Icons.flight_takeoff;

    return Icons.event;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF842D62),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Absen Jamaah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureAbsenList,
        builder: (context, snapshot) {
          // Tampilkan loading hanya saat pertama kali
          if (snapshot.connectionState == ConnectionState.waiting &&
              _isFirstLoad) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF842D62)),
            );
          }

          final list = snapshot.data ?? _cachedData;

          if (list.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada data absen',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final a = Map<String, dynamic>.from(list[i]);
              final int absenId = _getInt(a, 'id');
              final bool isDone = a['is_done'] ?? false;

              String judul = _getString(a, 'judul_absen');
              if (judul == '-') judul = _getNestedString(a, ['kloter', 'nama']);

              final String periode = _getString(
                a,
                'periode_kloter',
                fallback: '22 Februari - 2 Maret 2026',
              );
              final String tanggalRaw = _getString(a, 'tanggal_operasional');
              final String tanggalDisplay = tanggalRaw != '-'
                  ? _formatDate(tanggalRaw)
                  : '15 Feb 2026';

              final String sesi = _getString(
                a,
                'sesi_lengkap',
                fallback: 'Sesi Absen',
              );
              final int jumlah = _getInt(a, 'jamaah_count');

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Judul & Periode
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  judul,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF842D62),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  periode,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1E6ED),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$jumlah Jamaah',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF842D62),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Tanggal Operasional
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tanggalDisplay,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Box Sesi Absen
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF0F0F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFEEEEEE),
                                ),
                              ),
                              child: Icon(
                                _getSessionIcon(sesi),
                                size: 20,
                                color: const Color(0xFF842D62),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sesi Absen',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sesi,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Footer: Status & Tombol
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isDone ? "Sudah dikerjakan" : "Belum dikerjakan",
                              style: TextStyle(
                                color: isDone
                                    ? Colors.green[700]
                                    : Colors.orange[800],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Tombol Lihat Jamaah
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JamaahAttendancePage(
                                    absenId: absenId,
                                    judul: judul,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _refresh();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF842D62),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Lihat Jamaah',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
