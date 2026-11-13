import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sesi_absensi_model.dart';
import '../services/absensi_service.dart';
import '../services/api_service.dart';
import 'absen_jamaah/jamaah_attendance_home.dart';
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

  void _showDetailDialog(SesiAbsensi sesi, AttendanceGuideRecord record) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                sesi.judul,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (record.photoUrl != null && record.photoUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: record.photoUrl!.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(record.photoUrl!.split(',').last),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          record.photoUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          ),
                        ),
                ),
                const SizedBox(height: 14),
              ],
              _buildDialogRow('Waktu Absen:', record.formattedCreatedTime),
              if (record.statusWaktu != null)
                _buildDialogRow(
                  'Status Waktu:',
                  record.statusWaktu == 'tepat_waktu' ? 'Tepat Waktu' : 'Terlambat',
                  valueColor: record.statusWaktu == 'tepat_waktu' ? Colors.green : Colors.orange,
                ),
              if (record.bagianSesi != null && record.bagianSesi!.isNotEmpty)
                _buildDialogRow('Bagian Sesi:', record.bagianSesi!),
              if (record.latitude != null && record.longitude != null)
                _buildDialogRow(
                  'Koordinat:',
                  '${record.latitude!.toStringAsFixed(5)}, ${record.longitude!.toStringAsFixed(5)}',
                ),
              if (record.note != null && record.note!.isNotEmpty)
                _buildDialogRow('Catatan:', record.note!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF842D62)),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTourLeader = _role.contains('tour') || _role.contains('leader');
    final todayFormatted = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    int sudahCount = 0;
    for (final s in _sesiList) {
      final rec = _findRecordForSesi(s);
      if (rec != null && rec.isSudahAbsen) sudahCount++;
    }
    final belumCount = _sesiList.length - sudahCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F8),
      appBar: AppBar(
        title: Text(
          _role.contains('muthawif') ? 'Absensi Muthawif' : 'Absensi Tour Leader',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF842D62),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat Ulang',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF842D62),
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔀 SWITCH BUTTON: Absen Tour Leader / Absen Jamaah
              if (isTourLeader) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF842D62),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Absen Petugas',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const JamaahAttendanceHome(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF842D62),
                          side: BorderSide(color: const Color(0xFF842D62).withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Absen Jamaah',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // 👤 KARTU PROFIL & STATUS RINGKASAN
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF842D62).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded, color: Color(0xFF842D62), size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Kloter: $_kloter • ${isTourLeader ? "Tour Leader" : "Muthawif"}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF842D62)),
                        const SizedBox(width: 6),
                        Text(
                          todayFormatted,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Ringkasan 3 Angka
                    Row(
                      children: [
                        _buildStatCard('Total Sesi', '${_sesiList.length}', Colors.blue.shade700),
                        const SizedBox(width: 8),
                        _buildStatCard('Sudah Absen', '$sudahCount', Colors.green.shade700),
                        const SizedBox(width: 8),
                        _buildStatCard('Belum Absen', '$belumCount', Colors.orange.shade800),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 📋 HEADER DAFTAR SESI
              Row(
                children: [
                  const Icon(Icons.playlist_add_check_rounded, color: Color(0xFF842D62), size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Daftar Absen Yang Harus Diisi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih salah satu sesi di bawah ini untuk mengambil foto dan mencatat koordinat kehadiran.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),

              // 🔄 LIST VIEW SESI ABSENSI
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF842D62)),
                  ),
                )
              else if (_sesiList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Tidak Ada Sesi Ditugaskan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Belum ada sesi absensi yang ditugaskan kepada Anda untuk hari ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sesiList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sesi = _sesiList[index];
                    final record = _findRecordForSesi(sesi);
                    final isSudah = record != null && record.isSudahAbsen;

                    return _buildSesiCard(sesi, record, isSudah);
                  },
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSesiCard(
    SesiAbsensi sesi,
    AttendanceGuideRecord? record,
    bool isSudah,
  ) {
    final canAbsen = !isSudah && sesi.isSudahMasukWaktu;
    final isBelumBisaAbsen = !isSudah && !sesi.isSudahMasukWaktu;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSudah
              ? Colors.green.shade300
              : isBelumBisaAbsen
                  ? Colors.grey.shade300
                  : Colors.grey.shade200,
          width: isSudah ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge & Target Jam
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSudah
                        ? Colors.green.shade50
                        : isBelumBisaAbsen
                            ? Colors.grey.shade100
                            : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSudah
                          ? Colors.green.shade300
                          : isBelumBisaAbsen
                              ? Colors.grey.shade400
                              : Colors.orange.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSudah
                            ? Icons.check_circle_rounded
                            : isBelumBisaAbsen
                                ? Icons.lock_clock_rounded
                                : Icons.schedule_rounded,
                        size: 13,
                        color: isSudah
                            ? Colors.green.shade700
                            : isBelumBisaAbsen
                                ? Colors.grey.shade700
                                : Colors.orange.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSudah
                            ? 'Sudah Absen'
                            : isBelumBisaAbsen
                                ? 'Belum Bisa Absen'
                                : 'Belum Absen',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSudah
                              ? Colors.green.shade700
                              : isBelumBisaAbsen
                                  ? Colors.grey.shade700
                                  : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      sesi.formattedTargetTime,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Judul Sesi
            Text(
              '${sesi.urutan}. ${sesi.judul}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),
            if (sesi.keterangan != null && sesi.keterangan!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                sesi.keterangan!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
              ),
            ],

            // Bagian Sesi Sub-items (jika ada)
            if (sesi.bagianSesi.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: sesi.bagianSesi.map((b) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF842D62).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '• ${b.namaBagian}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF842D62),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 14),

            // 🔘 ACTION: Jika sudah absen -> Lihat Detail, Jika belum -> Buka Camera Page
            if (record != null && isSudah)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.done_all, color: Colors.green.shade700, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Jam: ${record.formattedCreatedTime}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                            ),
                          ),
                          if (record.statusWaktu != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(${record.statusWaktu == "tepat_waktu" ? "Tepat Waktu" : "Terlambat"})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: record.statusWaktu == 'tepat_waktu'
                                    ? Colors.green.shade700
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _showDetailDialog(sesi, record),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF842D62),
                      side: const BorderSide(color: Color(0xFF842D62)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Bukti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            else ...[
              ElevatedButton.icon(
                onPressed: canAbsen
                    ? () async {
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
                      }
                    : null,
                icon: Icon(
                  canAbsen ? Icons.camera_alt_rounded : Icons.lock_clock_rounded,
                  size: 16,
                  color: canAbsen ? Colors.white : Colors.grey.shade500,
                ),
                label: Text(
                  'Absen Sekarang (Foto & Lokasi)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: canAbsen ? Colors.white : Colors.grey.shade500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAbsen ? const Color(0xFF842D62) : Colors.grey.shade200,
                  disabledBackgroundColor: Colors.grey.shade200,
                  disabledForegroundColor: Colors.grey.shade500,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
              if (isBelumBisaAbsen) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Absensi baru dibuka mulai pukul ${sesi.formattedJamMulai} WIB',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
