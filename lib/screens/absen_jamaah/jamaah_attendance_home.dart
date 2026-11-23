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
  // Theme Color Palette (Retali-Sistem Umrah Theme)
  static const Color kPrimaryDark = Color(0xFF0D1523);
  static const Color kPrimaryNavy = Color(0xFF1B3167);
  static const Color kSecondaryNavy = Color(0xFF263754);
  static const Color kAccentGold = Color(0xFFEAB308);
  static const Color kSurface = Colors.white;
  static const Color kBackground = Color(0xFFF8FAFC);
  static const Color kTextPrimary = Color(0xFF0F172A);
  static const Color kTextSecondary = Color(0xFF64748B);
  static const Color kTextMuted = Color(0xFF94A3B8);
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kSuccess = Color(0xFF10B981);
  static const Color kError = Color(0xFFEF4444);
  static const Color kWarning = Color(0xFFF59E0B);

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
            debugPrint('📝 Data berubah, refresh UI...');
            setState(() {
              _cachedData = newData;
              _futureAbsenList = Future.value(newData);
            });
          } else {
            debugPrint('⏱️ Tidak ada perubahan data');
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
  // 🛡️ SAFE GETTERS & UTILITIES
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
        if (current is Map) {
          current = current[key];
        } else {
          return fallback;
        }
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

    if (s.contains('bus') || s.contains('bis')) return Icons.directions_bus_rounded;
    if (s.contains('hotel') || s.contains('kamar') || s.contains('check in') || s.contains('check-in')) return Icons.hotel_rounded;
    if (s.contains('pesawat') || s.contains('flight') || s.contains('bandara') || s.contains('airport')) return Icons.flight_takeoff_rounded;
    if (s.contains('ziarah') || s.contains('tour') || s.contains('city tour')) return Icons.explore_rounded;
    if (s.contains('masjid') || s.contains('umrah') || s.contains('tawaf') || s.contains('sa\'i') || s.contains('sai') || s.contains('miqat') || s.contains('ibadah') || s.contains('kajian')) {
      return Icons.mosque_rounded;
    }
    if (s.contains('makan') || s.contains('resto') || s.contains('sarapan') || s.contains('dinner') || s.contains('lunch')) return Icons.restaurant_rounded;
    if (s.contains('koper') || s.contains('bagasi') || s.contains('luggage')) return Icons.luggage_rounded;

    return Icons.event_available_rounded;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
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
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      if (dateStr.contains('T') || dateStr.contains(':')) {
        return '${date.day} ${months[date.month - 1]} ${date.year} • $hour:$minute';
      }
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  double _getCompletionRate(Map<String, dynamic> item) {
    if (item['is_done'] == true) return 1.0;
    final dynamic users = item['attendance_user'] ?? item['jamaah'] ?? item['users'];
    if (users is List && users.isNotEmpty) {
      final int total = users.length;
      final int attended = users.where((u) {
        if (u is Map) {
          final status = (u['attendance_status'] ?? u['status'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          return status == 'hadir' || status == 'present' || status == 'sudah';
        }
        return false;
      }).length;
      if (total > 0) {
        return attended / total;
      }
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimaryDark,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: 'Kembali',
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kAccentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fact_check_rounded,
                color: kAccentGold,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Absen Jamaah',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Segarkan data',
            onPressed: _refresh,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryDark, kPrimaryNavy],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureAbsenList,
        builder: (context, snapshot) {
          // Loading pertama kali
          if (snapshot.connectionState == ConnectionState.waiting && _isFirstLoad) {
            return _buildLoadingState();
          }

          if (snapshot.hasError && _cachedData.isEmpty) {
            return _buildErrorState(snapshot.error.toString());
          }

          final list = snapshot.data ?? _cachedData;

          return RefreshIndicator(
            color: kPrimaryNavy,
            backgroundColor: kSurface,
            onRefresh: () async {
              _refresh();
              await _futureAbsenList;
            },
            child: list.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 32,
                    ),
                    child: Column(
                      children: [
                        _buildHeaderBanner([]),
                        const SizedBox(height: 16),
                        _buildEmptyState(),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 32,
                    ),
                    itemCount: list.length + 1,
                    itemBuilder: (_, index) {
                      if (index == 0) {
                        return _buildHeaderBanner(list);
                      }

                      final a = Map<String, dynamic>.from(list[index - 1]);
                      final int absenId = _getInt(a, 'id');
                      final bool isDone = a['is_done'] ?? false;
                      final double completionRate = _getCompletionRate(a);

                      // Judul kartu adalah nama kloter, bukan nama sesi
                      String judul = _getNestedString(a, ['kloter', 'nama']);
                      if (judul == '-' || judul.isEmpty) {
                        judul = _getString(a, 'kloter_name');
                      }
                      if (judul == '-' || judul.isEmpty) {
                        judul = _getString(a, 'kloter');
                      }
                      if (judul == '-' || judul.isEmpty) {
                        judul = _getString(a, 'judul_absen');
                      }

                      final String periode = _getString(
                        a,
                        'periode_kloter',
                        fallback: 'Periode Umrah 2026',
                      );
                      final String tanggalRaw = _getString(a, 'tanggal_operasional');
                      final String tanggalDisplay = (tanggalRaw != '-' && tanggalRaw.isNotEmpty)
                          ? _formatDate(tanggalRaw)
                          : 'Sesuai Jadwal';

                      final String sesi = _getString(
                        a,
                        'sesi_lengkap',
                        fallback: 'Sesi Absen',
                      );
                      final int jumlah = _getInt(a, 'jamaah_count');

                      return _buildAttendanceCard(
                        absenId: absenId,
                        judul: judul,
                        periode: periode,
                        sesi: sesi,
                        tanggalDisplay: tanggalDisplay,
                        jumlah: jumlah,
                        isDone: isDone,
                        completionRate: completionRate,
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  // ============================================
  // 🏷️ HEADER BANNER (NAVY GRADIENT & LIVE SYNC)
  // ============================================
  Widget _buildHeaderBanner(List<dynamic> list) {
    final int totalSesi = list.length;
    final int totalSelesai = list.where((item) {
      if (item is Map) {
        return item['is_done'] == true;
      }
      return false;
    }).length;
    final int totalBelum = totalSesi - totalSelesai;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimaryDark, kPrimaryNavy, kSecondaryNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: kPrimaryDark.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle decorative background circles
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAccentGold.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kAccentGold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: kAccentGold.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: kAccentGold,
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Muthawif & Tour Leader',
                            style: TextStyle(
                              color: kAccentGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Live auto-refresh indicator chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: kSuccess,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Live Auto-Sync',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Presensi Kehadiran Jamaah',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pantau dan pastikan seluruh jamaah lengkap di setiap titik sesi perjalanan Umrah.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                // Metric Stats Pills
                Row(
                  children: [
                    Expanded(
                      child: _buildHeaderStat(
                        label: 'Total Sesi',
                        value: '$totalSesi',
                        icon: Icons.layers_rounded,
                        color: Colors.white,
                        bgColor: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHeaderStat(
                        label: 'Selesai',
                        value: '$totalSelesai',
                        icon: Icons.check_circle_rounded,
                        color: kSuccess,
                        bgColor: kSuccess.withValues(alpha: 0.18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHeaderStat(
                        label: 'Menunggu',
                        value: '$totalBelum',
                        icon: Icons.pending_actions_rounded,
                        color: kAccentGold,
                        bgColor: kAccentGold.withValues(alpha: 0.18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // 📋 ATTENDANCE SESSION CARD
  // ============================================
  Widget _buildAttendanceCard({
    required int absenId,
    required String judul,
    required String periode,
    required String sesi,
    required String tanggalDisplay,
    required int jumlah,
    required bool isDone,
    required double completionRate,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: kPrimaryDark.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Kloter Name & Jamaah Count Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: kPrimaryNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.flight_class_rounded,
                              size: 14,
                              color: kPrimaryNavy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              judul,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: kTextPrimary,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const SizedBox(width: 27),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: kTextSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              periode,
                              style: const TextStyle(
                                fontSize: 12,
                                color: kTextSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimaryNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: kPrimaryNavy.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.groups_rounded,
                        size: 14,
                        color: kPrimaryNavy,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$jumlah Jamaah',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kPrimaryNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Middle Box: Sesi & Schedule Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDone
                          ? kSuccess.withValues(alpha: 0.1)
                          : kPrimaryNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDone
                            ? kSuccess.withValues(alpha: 0.25)
                            : kPrimaryNavy.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Icon(
                      _getSessionIcon(sesi),
                      size: 22,
                      color: isDone ? kSuccess : kPrimaryNavy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'SESI ABSENSI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: kTextMuted,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: kTextSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tanggalDisplay,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          sesi,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kTextPrimary,
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
            const SizedBox(height: 14),

            // Progress Bar & Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDone ? Icons.task_alt_rounded : Icons.timelapse_rounded,
                      size: 14,
                      color: isDone ? kSuccess : kWarning,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isDone ? 'Progres Presensi (Selesai)' : 'Progres Presensi',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  isDone
                      ? '100%'
                      : (completionRate > 0
                          ? '${(completionRate * 100).toInt()}%'
                          : 'Belum'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDone
                        ? kSuccess
                        : (completionRate > 0 ? kWarning : kTextMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: isDone
                    ? 1.0
                    : (completionRate > 0 ? completionRate : 0.0),
                minHeight: 6,
                backgroundColor: kBorder,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDone ? kSuccess : kAccentGold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bottom Section: Status Chip & Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Refined Status Badge Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isDone
                        ? kSuccess.withValues(alpha: 0.1)
                        : kWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDone
                          ? kSuccess.withValues(alpha: 0.3)
                          : kWarning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        size: 13,
                        color: isDone ? kSuccess : kWarning,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isDone ? 'Selesai' : 'Belum Selesai',
                        style: TextStyle(
                          color: isDone
                              ? const Color(0xFF047857)
                              : const Color(0xFFB45309),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sleek Action Button
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
                    backgroundColor: kPrimaryNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.checklist_rtl_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDone ? 'Lihat Jamaah' : 'Isi Presensi',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: kAccentGold,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ⏳ LOADING STATE (SKELETON CARDS)
  // ============================================
  Widget _buildLoadingState() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderBanner([]),
        const SizedBox(height: 16),
        _buildSkeletonCard(),
        const SizedBox(height: 16),
        _buildSkeletonCard(),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 150,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: 75,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 190,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 100,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              Container(
                width: 120,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // 📭 EMPTY STATE
  // ============================================
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: kPrimaryDark.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: kPrimaryNavy.withValues(alpha: 0.07),
              shape: BoxShape.circle,
              border: Border.all(
                color: kAccentGold.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              size: 40,
              color: kPrimaryNavy,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Belum Ada Sesi Absen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jadwal absensi jamaah untuk kloter Anda belum tersedia atau belum dijadwalkan oleh admin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: kTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Perbarui Data',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ⚠️ ERROR STATE
  // ============================================
  Widget _buildErrorState(String error) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 32,
      ),
      child: Column(
        children: [
          _buildHeaderBanner([]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kError.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryDark.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: kError.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 38,
                    color: kError,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gagal Memuat Data',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Terjadi kendala saat mengambil data absensi jamaah. Silakan periksa koneksi internet Anda dan coba lagi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: kTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Coba Lagi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
