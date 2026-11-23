import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sesi_absensi_model.dart';
import '../services/absensi_service.dart';
import '../services/api_service.dart';
import 'absensi_form_screen.dart';

class AbsensiScreen extends StatefulWidget {
  const AbsensiScreen({super.key});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  bool _loading = true;
  String _role = 'tour_leader';
  String _name = 'Petugas';
  String _kloter = '-';
  String _userId = '';

  List<SesiAbsensi> _sesiList = [];
  Map<String, AttendanceGuideRecord> _todayRecords = {};

  // Retali-Sistem Theme - Navy & Gold Color Palette
  static const Color primaryDark = Color(0xFF0D1523);
  static const Color primaryNavy = Color(0xFF1B3167);
  static const Color secondaryNavy = Color(0xFF263754);
  static const Color accentGold = Color(0xFFEAB308);
  static const Color surfaceColor = Colors.white;
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);

  String get _roleDisplay {
    final clean = _role.toLowerCase().replaceAll('_', ' ').trim();
    if (clean == 'muthawif') {
      return 'Muthawif';
    } else if (clean == 'tour leader' || clean == 'tourleader') {
      return 'Tour Leader';
    } else if (clean.isNotEmpty) {
      return clean
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');
    }
    return 'Tour Leader';
  }

  @override
  void initState() {
    super.initState();
    _loadProfileAndData();
  }

  Future<void> _loadProfileAndData() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name') ?? prefs.getString('username') ?? 'Petugas';
    final kloter = prefs.getString('kloter') ?? '-';
    final rawRole = prefs.getString('role') ?? 'tour_leader';
    final normalizedRole = rawRole.toLowerCase().replaceAll(' ', '_');

    final userId = await ApiService.getCurrentUserId() ?? '';

    setState(() {
      _name = name;
      _kloter = kloter;
      _role = normalizedRole;
      _userId = userId;
    });

    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final sesiFuture = _userId.isNotEmpty
          ? AbsensiService.fetchAssignedSesiList(
              userId: _userId,
              role: _role,
              kloter: _kloter,
            )
          : Future.value(<SesiAbsensi>[]);
      final recordsFuture = _userId.isNotEmpty
          ? AbsensiService.fetchTodayAttendanceRecords(userId: _userId)
          : Future.value(<String, AttendanceGuideRecord>{});

      final results = await Future.wait([sesiFuture, recordsFuture]);

      if (mounted) {
        setState(() {
          _sesiList = results[0] as List<SesiAbsensi>;
          _todayRecords = results[1] as Map<String, AttendanceGuideRecord>;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [AbsensiScreen] Error loading data: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _fetchData();
  }

  AttendanceGuideRecord? _findRecordForSesi(SesiAbsensi sesi) {
    if (_todayRecords.containsKey(sesi.id)) {
      return _todayRecords[sesi.id];
    }
    if (_todayRecords.containsKey(sesi.judul)) {
      return _todayRecords[sesi.judul];
    }
    return null;
  }

  String _formatTodayDate() {
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
    } catch (_) {
      try {
        return DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
      } catch (_) {
        final now = DateTime.now();
        return '${now.day}/${now.month}/${now.year}';
      }
    }
  }

  Widget _buildPhotoWidget(
    String? photoUrl, {
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    double borderRadius = 12,
  }) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor),
        ),
        child: const Icon(Icons.image_not_supported_outlined, color: textMuted, size: 24),
      );
    }

    Widget imageContent;
    try {
      if (photoUrl.startsWith('data:image')) {
        final base64String = photoUrl.contains(',') ? photoUrl.split(',').last : photoUrl;
        final bytes = base64Decode(base64String.trim());
        imageContent = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildImageError(width, height, borderRadius),
        );
      } else {
        imageContent = Image.network(
          photoUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildImageError(width, height, borderRadius),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height,
              color: const Color(0xFFF1F5F9),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: primaryNavy),
              ),
            );
          },
        );
      }
    } catch (_) {
      imageContent = _buildImageError(width, height, borderRadius);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageContent,
    );
  }

  Widget _buildImageError(double width, double height, double borderRadius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, color: textMuted, size: 22),
    );
  }

  void _showDetailDialog(SesiAbsensi sesi, AttendanceGuideRecord record) {
    final isTepatWaktu = record.statusWaktu == 'tepat_waktu';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 12,
        backgroundColor: surfaceColor,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dialog Header with Navy Gradient
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryDark, primaryNavy],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: successGreen.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: successGreen.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(Icons.verified_rounded, color: successGreen, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sesi.judul,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sesi Ke-${sesi.urutan} • ${sesi.formattedTargetTime}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                        visualDensity: VisualDensity.compact,
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),

                // Dialog Content Body
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Photo Preview
                      if (record.photoUrl != null && record.photoUrl!.isNotEmpty) ...[
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: primaryDark.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                _buildPhotoWidget(
                                  record.photoUrl,
                                  width: double.infinity,
                                  height: 220,
                                  fit: BoxFit.cover,
                                  borderRadius: 16,
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryDark.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.camera_alt_rounded, color: accentGold, size: 14),
                                        SizedBox(width: 6),
                                        Text(
                                          'Bukti Foto Petugas',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Status Ketepatan Waktu Badge
                      if (record.statusWaktu != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isTepatWaktu
                                ? successGreen.withValues(alpha: 0.1)
                                : warningOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isTepatWaktu
                                  ? successGreen.withValues(alpha: 0.3)
                                  : warningOrange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isTepatWaktu ? Icons.alarm_on_rounded : Icons.alarm_off_rounded,
                                color: isTepatWaktu ? successGreen : warningOrange,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isTepatWaktu ? 'Kehadiran Tepat Waktu' : 'Kehadiran Terlambat',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isTepatWaktu ? const Color(0xFF047857) : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Information Grid
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            _buildInfoTile(
                              icon: Icons.access_time_filled_rounded,
                              iconColor: primaryNavy,
                              label: 'Waktu Tercatat',
                              value: record.formattedCreatedTime,
                            ),
                            if (record.bagianSesi != null && record.bagianSesi!.isNotEmpty) ...[
                              const Divider(height: 18, color: borderColor),
                              _buildInfoTile(
                                icon: Icons.folder_open_rounded,
                                iconColor: secondaryNavy,
                                label: 'Bagian Sesi',
                                value: record.bagianSesi!,
                              ),
                            ],
                            if (record.latitude != null && record.longitude != null) ...[
                              const Divider(height: 18, color: borderColor),
                              _buildInfoTile(
                                icon: Icons.location_on_rounded,
                                iconColor: errorRed,
                                label: 'Koordinat GPS',
                                value:
                                    '${record.latitude!.toStringAsFixed(6)}, ${record.longitude!.toStringAsFixed(6)}',
                              ),
                            ],
                            if (record.note != null && record.note!.isNotEmpty) ...[
                              const Divider(height: 18, color: borderColor),
                              _buildInfoTile(
                                icon: Icons.sticky_note_2_rounded,
                                iconColor: accentGold,
                                label: 'Catatan',
                                value: record.note!,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Button Tutup
                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryNavy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Tutup',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTourLeader = _role.contains('tour') || _role.contains('leader');
    final todayFormatted = _formatTodayDate();

    int sudahCount = 0;
    for (final s in _sesiList) {
      final rec = _findRecordForSesi(s);
      if (rec != null && rec.isSudahAbsen) sudahCount++;
    }
    final belumCount = _sesiList.length - sudahCount;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        color: primaryNavy,
        backgroundColor: surfaceColor,
        onRefresh: _refreshData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 🌟 SLEEK NAVY & GOLD HEADER BANNER
            SliverToBoxAdapter(
              child: _buildHeaderBanner(
                context,
                isTourLeader: isTourLeader,
                todayFormatted: todayFormatted,
                sudahCount: sudahCount,
                belumCount: belumCount,
              ),
            ),

            // 📌 MAIN CONTENT BODY
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 📋 SECTION HEADER DAFTAR SESI
                  _buildSectionHeader(),
                  const SizedBox(height: 14),

                  // 🔄 CONTENT: LOADING / EMPTY / LIST
                  if (_loading)
                    _buildLoadingState()
                  else if (_sesiList.isEmpty)
                    _buildEmptyState()
                  else
                    ..._sesiList.map((sesi) {
                      final record = _findRecordForSesi(sesi);
                      final isSudah = record != null && record.isSudahAbsen;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildSesiCard(sesi, record, isSudah),
                      );
                    }),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🕌 NAVY GRADIENT BANNER HEADER
  Widget _buildHeaderBanner(
    BuildContext context, {
    required bool isTourLeader,
    required String todayFormatted,
    required int sudahCount,
    required int belumCount,
  }) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryDark, primaryNavy, secondaryNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient circles for high-end feel
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentGold.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Header Content
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top App Bar Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (Navigator.canPop(context))
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, color: accentGold, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Retali Zero Complaint',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        // Refresh Button
                        GestureDetector(
                          onTap: _refreshData,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // User Identity Card
                Row(
                  children: [
                    // Avatar with Gold Accent Border
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentGold.withValues(alpha: 0.8),
                            primaryNavy,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: accentGold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: accentGold.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Name and Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Badges Row: Role Badge + Kloter Badge
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              // Role Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      accentGold.withValues(alpha: 0.28),
                                      accentGold.withValues(alpha: 0.12),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: accentGold.withValues(alpha: 0.7),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: accentGold,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _roleDisplay,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: accentGold,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Kloter Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.flight_takeoff_rounded,
                                      color: Colors.white70,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Kloter: $_kloter',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Pill Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_note_rounded, color: accentGold, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          todayFormatted,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: successGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: successGreen.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'Hari Ini',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6EE7B7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 📊 SUMMARY STATS PILLS (3 STATS)
                Row(
                  children: [
                    _buildHeaderStatCard(
                      label: 'Total Sesi',
                      count: '${_sesiList.length}',
                      icon: Icons.list_alt_rounded,
                      color: const Color(0xFF60A5FA),
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderStatCard(
                      label: 'Sudah Selesai',
                      count: '$sudahCount',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF34D399),
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderStatCard(
                      label: 'Belum Diisi',
                      count: '$belumCount',
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFFFBBF24),
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

  Widget _buildHeaderStatCard({
    required String label,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // 📋 SECTION HEADER
  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accentGold,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daftar Sesi Absensi Petugas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Lakukan swafoto dan perekaman lokasi di setiap sesi',
                style: TextStyle(fontSize: 11.5, color: textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: primaryNavy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_sesiList.length} Sesi',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: primaryNavy,
            ),
          ),
        ),
      ],
    );
  }

  // 🔄 LOADING STATE
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryDark.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: primaryNavy,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Memuat Jadwal Absensi...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mengambil data sesi dan verifikasi kehadiran hari ini',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
        ],
      ),
    );
  }

  // 📭 EMPTY STATE
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: const Icon(Icons.event_busy_rounded, size: 36, color: textMuted),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak Ada Sesi Ditugaskan',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Belum ada jadwal sesi absensi aktif yang ditugaskan untuk kloter atau peran Anda pada tanggal ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Muat Ulang', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryNavy,
              side: const BorderSide(color: primaryNavy),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // 🪪 MODERN SESI ABSENSI CARD
  Widget _buildSesiCard(
    SesiAbsensi sesi,
    AttendanceGuideRecord? record,
    bool isSudah,
  ) {
    final canAbsen = !isSudah && sesi.isSudahMasukWaktu;
    final isBelumBisaAbsen = !isSudah && !sesi.isSudahMasukWaktu;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSudah
              ? successGreen.withValues(alpha: 0.35)
              : canAbsen
                  ? accentGold.withValues(alpha: 0.5)
                  : borderColor,
          width: isSudah || canAbsen ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSudah
                ? successGreen.withValues(alpha: 0.05)
                : primaryDark.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Upper Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Number badge + Status Badge
                Row(
                  children: [
                    // Sesi Number Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isSudah
                            ? successGreen.withValues(alpha: 0.12)
                            : canAbsen
                                ? accentGold.withValues(alpha: 0.15)
                                : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSudah
                                ? Icons.check_circle_rounded
                                : canAbsen
                                    ? Icons.pending_rounded
                                    : Icons.lock_clock_rounded,
                            size: 13,
                            color: isSudah
                                ? successGreen
                                : canAbsen
                                    ? const Color(0xFFB45309)
                                    : textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sesi ${sesi.urutan}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSudah
                                  ? const Color(0xFF047857)
                                  : canAbsen
                                      ? const Color(0xFFB45309)
                                      : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Status Badge (Sudah Absen vs Belum Absen)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSudah
                            ? const Color(0xFFECFDF5)
                            : isBelumBisaAbsen
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSudah
                              ? const Color(0xFFA7F3D0)
                              : isBelumBisaAbsen
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSudah
                                  ? successGreen
                                  : isBelumBisaAbsen
                                      ? textMuted
                                      : warningOrange,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isSudah
                                ? 'Sudah Absen'
                                : isBelumBisaAbsen
                                    ? 'Belum Dibuka'
                                    : 'Belum Absen',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSudah
                                  ? const Color(0xFF047857)
                                  : isBelumBisaAbsen
                                      ? textSecondary
                                      : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Judul Sesi
                Text(
                  sesi.judul,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    height: 1.3,
                  ),
                ),

                // Jam Target dengan Icon Clock
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: primaryNavy.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.access_time_rounded, size: 12, color: primaryNavy),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sesi.formattedTargetTime,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),

                // Keterangan Sesi (jika ada)
                if (sesi.keterangan != null && sesi.keterangan!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    sesi.keterangan!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],

                // Bagian Sesi Sub-items (jika ada)
                if (sesi.bagianSesi.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: sesi.bagianSesi.map((b) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, size: 11, color: primaryNavy),
                            const SizedBox(width: 4),
                            Text(
                              b.namaBagian,
                              style: const TextStyle(
                                fontSize: 11,
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: borderColor),

          // 🔘 BOTTOM ACTION AREA
          Padding(
            padding: const EdgeInsets.all(14),
            child: isSudah && record != null
                // 🟢 SUDAH ABSEN: Thumbnail Preview, Jam, & Tombol Lihat Detail
                ? _buildCompletedAttendanceRow(sesi, record)
                // 🟡 BELUM ABSEN: Tombol Ambil Absen Gradient / Disabled
                : _buildPendingAttendanceAction(context, sesi, canAbsen, isBelumBisaAbsen),
          ),
        ],
      ),
    );
  }

  // 🖼️ COMPLETED ATTENDANCE ROW: THUMBNAIL PREVIEW, TIMESTAMP & LIHAT DETAIL
  Widget _buildCompletedAttendanceRow(SesiAbsensi sesi, AttendanceGuideRecord record) {
    final isTepat = record.statusWaktu == 'tepat_waktu';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        children: [
          // Thumbnail Preview with Zoom tap
          GestureDetector(
            onTap: () => _showDetailDialog(sesi, record),
            child: Stack(
              children: [
                _buildPhotoWidget(
                  record.photoUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  borderRadius: 10,
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: primaryDark.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.zoom_in_rounded, size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Waktu & Status Ketepatan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: successGreen, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      record.formattedCreatedTime,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                if (record.statusWaktu != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isTepat
                          ? successGreen.withValues(alpha: 0.15)
                          : warningOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isTepat ? 'Tepat Waktu' : 'Terlambat',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isTepat ? const Color(0xFF047857) : const Color(0xFFB45309),
                      ),
                    ),
                  )
                else
                  const Text(
                    'Telah diverifikasi',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Tombol "Lihat Detail"
          OutlinedButton.icon(
            onPressed: () => _showDetailDialog(sesi, record),
            icon: const Icon(Icons.visibility_outlined, size: 14),
            label: const Text('Detail', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryNavy,
              side: const BorderSide(color: primaryNavy),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // 📷 PENDING ATTENDANCE ACTION: PROMINENT CAMERA GRADIENT BUTTON
  Widget _buildPendingAttendanceAction(
    BuildContext context,
    SesiAbsensi sesi,
    bool canAbsen,
    bool isBelumBisaAbsen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canAbsen)
          Container(
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryDark, primaryNavy],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryNavy.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AbsensiFormScreen(
                        sesi: sesi,
                        userId: _userId,
                        userName: _name,
                        kloter: _kloter,
                        role: _role,
                      ),
                    ),
                  );
                  if (result == true) {
                    _refreshData();
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded, color: accentGold, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Ambil Absen (Foto & Lokasi)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_clock_rounded, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  'Sesi Belum Dibuka',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

        // Keterangan tambahan jika belum masuk jam target
        if (isBelumBisaAbsen) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline_rounded, size: 12, color: textSecondary),
                const SizedBox(width: 5),
                Text(
                  'Absensi baru dibuka mulai pukul ${sesi.formattedJamMulai} WIB',
                  style: const TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
