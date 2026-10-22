import 'package:flutter/material.dart';
import '../../services/jamaah_attendance_service.dart';
import '../../models/absensi_jamaah_detail.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class JamaahAttendancePage extends StatefulWidget {
  final int absenId;
  final String judul;

  const JamaahAttendancePage({
    super.key,
    required this.absenId,
    required this.judul,
  });

  @override
  State<JamaahAttendancePage> createState() => _JamaahAttendancePageState();
}

class _JamaahAttendancePageState extends State<JamaahAttendancePage> {
  bool _loading = true;
  bool _saving = false;

  String _searchQuery = '';
  String _filterStatus = 'ALL';

  List<AbsensiJamaahDetail> _jamaah = [];
  List<AbsensiJamaahDetail> _filteredJamaah = [];

  final Map<int, TextEditingController> _catatanCtrl = {};
  final Map<int, String> _localStatus = {};
  final Map<int, bool> _showCatatan = {}; // Untuk mengontrol visibility catatan

  int _hadirCount = 0;
  int _tidakHadirCount = 0;
  int _belumAbsenCount = 0;

  String _periode = '';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    for (final c in _catatanCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ==========================================================
  // LOAD DATA
  // ==========================================================

  Future<void> _loadDetail() async {
    setState(() => _loading = true);

    try {
      final res = await JamaahAttendanceService.fetchAbsenDetail(
        widget.absenId,
      );

      _periode = res['absen']?['periode_kloter'] ?? '';

      final list = (res['jamaah'] as List)
          .map((e) => AbsensiJamaahDetail.fromJson(e))
          .toList();

      for (final j in list) {
        _catatanCtrl[j.jamaahId] = TextEditingController(text: j.catatan ?? '');
        _localStatus[j.jamaahId] = j.status.isEmpty ? 'BELUM_ABSEN' : j.status;
        // Tampilkan catatan jika status sudah TIDAK_HADIR atau ada catatan
        _showCatatan[j.jamaahId] =
            j.status == 'TIDAK_HADIR' || (j.catatan?.isNotEmpty ?? false);
      }

      await _loadDraft();
      if (!mounted) return;

      setState(() {
        _jamaah = list;
        _filteredJamaah = list;
        _updateCounters();
      });
    } catch (e) {
      debugPrint("ERROR LOAD DETAIL: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ==========================================================
  // COUNTER
  // ==========================================================

  void _updateCounters() {
    int hadir = 0;
    int tidak = 0;
    int belum = 0;

    for (final s in _localStatus.values) {
      if (s == 'HADIR') {
        hadir++;
      } else if (s == 'TIDAK_HADIR') {
        tidak++;
      } else {
        belum++;
      }
    }

    _hadirCount = hadir;
    _tidakHadirCount = tidak;
    _belumAbsenCount = belum;
  }

  // ==========================================================
  // FILTER + SEARCH
  // ==========================================================

  void _filter() {
    List<AbsensiJamaahDetail> result = _jamaah;

    if (_filterStatus != 'ALL') {
      result = result
          .where((j) => _localStatus[j.jamaahId] == _filterStatus)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (j) =>
                j.nama.toLowerCase().contains(q) ||
                (j.hp ?? '').contains(q) ||
                (j.paspor ?? '').contains(q),
          )
          .toList();
    }

    result.sort((a, b) => a.urutan.compareTo(b.urutan));

    setState(() => _filteredJamaah = result);
  }

  void _updateStatus(int id, String status) {
    setState(() {
      _localStatus[id] = status;
      // Otomatis tampilkan catatan jika memilih TIDAK_HADIR
      if (status == 'TIDAK_HADIR') {
        _showCatatan[id] = true;
      } else if (status == 'HADIR') {
        // Sembunyikan catatan jika memilih HADIR dan catatan kosong
        if (_catatanCtrl[id]?.text.trim().isEmpty ?? true) {
          _showCatatan[id] = false;
        }
      }
      _updateCounters();
      _filter();

      _saveDraft();

    });
  }

  // ==========================================================
  // SUBMIT
  // ==========================================================

  Future<void> _submitAll() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final payload = _jamaah
          .map(
            (j) => {
              "jamaah_id": j.jamaahId,
              "status": _localStatus[j.jamaahId] ?? 'BELUM_ABSEN',
              "catatan": _catatanCtrl[j.jamaahId]?.text.trim(),
            },
          )
          .toList();

      await JamaahAttendanceService.submitBulk(
        absensiJamaahId: widget.absenId,
        data: payload,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('absen_draft_${widget.absenId}');
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Absensi berhasil disimpan"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal simpan: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ==========================================================
  // UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF842D62),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.judul,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _periode.isNotEmpty
                  ? '${_jamaah.length} Jamaah • $_periode'
                  : '${_jamaah.length} Jamaah',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomButton(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearch(),
                _buildStats(),
                _buildFilterTabs(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredJamaah.length,
                    itemBuilder: (context, index) =>
                        _buildCard(_filteredJamaah[index]),
                  ),
                ),
              ],
            ),
    );
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (v) {
            _searchQuery = v;
            _filter();
          },
          decoration: InputDecoration(
            hintText: 'Cari nama, HP, paspor...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[400], size: 18),
                    onPressed: () {
                      _searchQuery = '';
                      _filter();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // STATS
  // ==========================================================

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _statBox('Semua', _jamaah.length, Icons.people, Colors.purple),
          const SizedBox(width: 8),
          _statBox('Belum', _belumAbsenCount, Icons.access_time, Colors.orange),
          const SizedBox(width: 8),
          _statBox('Hadir', _hadirCount, Icons.check_circle, Colors.green),
          const SizedBox(width: 8),
          _statBox('Tidak', _tidakHadirCount, Icons.cancel, Colors.red),
        ],
      ),
    );
  }

  Widget _statBox(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // FILTER TABS
  // ==========================================================

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Semua', 'ALL'),
            const SizedBox(width: 8),
            _filterChip('Belum', 'BELUM_ABSEN'),
            const SizedBox(width: 8),
            _filterChip('Hadir', 'HADIR'),
            const SizedBox(width: 8),
            _filterChip('Tidak', 'TIDAK_HADIR'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filterStatus == value;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? value : 'ALL';
          _filter();
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: const Color(0xFF842D62),
      checkmarkColor: Colors.white,
      shape: const StadiumBorder(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  // ==========================================================
  // CARD
  // ==========================================================

  Widget _buildCard(AbsensiJamaahDetail j) {
    final status = _localStatus[j.jamaahId] ?? 'BELUM_ABSEN';
    final showCatatan = _showCatatan[j.jamaahId] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nomor dan Nama
                Text(
                  '${j.urutan}. ${j.nama}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Info Kloter dan Bus - MEMPERBAIKI ICON DISINI
                Wrap(
                  spacing: 8,
                  children: [
                    _infoChip(
                      icon: Icons
                          .flight_takeoff, // Diperbaiki dari flight_takeout
                      label: 'Kloter ${j.kloter ?? '357'}',
                    ),
                    _infoChip(
                      icon: Icons.directions_bus,
                      label: 'Bus ${j.bus ?? 1}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Nomor HP
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Text(
                      j.hp ?? '-',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Nomor Paspor - MEMPERBAIKI WARNA DISINI
                // Nomor Paspor - MEMPERBAIKI ICON DISINI
                Row(
                  children: [
                    Icon(
                      Icons.card_membership,
                      size: 14,
                      color: Colors.grey[500],
                    ), // Diganti dari Icons.passport
                    const SizedBox(width: 8),
                    Text(
                      j.paspor ?? '-',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

          // Tombol Status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _statusButton(
                        id: j.jamaahId,
                        target: 'HADIR',
                        color: Colors.green,
                        current: status,
                        icon: Icons.check,
                        label: 'Hadir',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statusButton(
                        id: j.jamaahId,
                        target: 'TIDAK_HADIR',
                        color: Colors.red,
                        current: status,
                        icon: Icons.close,
                        label: 'Tidak',
                      ),
                    ),
                  ],
                ),

                // Catatan (muncul otomatis jika status TIDAK_HADIR)
                if (showCatatan) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: _catatanCtrl[j.jamaahId],
                      maxLines: 2,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Opsional: Catatan tambahan',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      onChanged: (value) {
                        _saveDraft();
                        // Jika ada isian catatan, pertahankan tampilan
                        if (value.isNotEmpty && !showCatatan) {
                          setState(() {
                            _showCatatan[j.jamaahId] = true;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusButton({
    required int id,
    required String target,
    required Color color,
    required String current,
    required IconData icon,
    required String label,
  }) {
    final active = current == target;

    return GestureDetector(
      onTap: () => _updateStatus(id, target),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color : color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDraft() async {
  final prefs = await SharedPreferences.getInstance();

  Map<String, dynamic> draft = {};

  for (final j in _jamaah) {
    draft[j.jamaahId.toString()] = {
      "status": _localStatus[j.jamaahId],
      "catatan": _catatanCtrl[j.jamaahId]?.text,
    };
  }

  await prefs.setString(
    'absen_draft_${widget.absenId}',
    jsonEncode(draft),
  );
}

Future<void> _loadDraft() async {
  final prefs = await SharedPreferences.getInstance();
  final saved =
      prefs.getString('absen_draft_${widget.absenId}');

  if (saved == null) return;

  final Map<String, dynamic> draft =
      jsonDecode(saved);

  draft.forEach((key, value) {
    final id = int.parse(key);

    if (_localStatus.containsKey(id)) {
      _localStatus[id] = value['status'] ?? 'BELUM_ABSEN';
    }

    if (_catatanCtrl.containsKey(id)) {
      _catatanCtrl[id]?.text = value['catatan'] ?? '';
    }

    _showCatatan[id] =
        _localStatus[id] == 'TIDAK_HADIR' ||
        (_catatanCtrl[id]?.text.isNotEmpty ?? false);
  });

  _updateCounters();
}

  // ==========================================================
  // BOTTOM BUTTON
  // ==========================================================

  Widget _buildBottomButton() {
    bool isAllCompleted = _belumAbsenCount == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isAllCompleted ? _submitAll : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF842D62),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'SIMPAN ABSENSI',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
