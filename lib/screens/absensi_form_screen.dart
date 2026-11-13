import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/sesi_absensi_model.dart';
import '../services/absensi_service.dart';

class AbsensiFormScreen extends StatefulWidget {
  final SesiAbsensi sesi;
  final String userId;
  final String userName;
  final String kloter;
  final String role;

  const AbsensiFormScreen({
    super.key,
    required this.sesi,
    required this.userId,
    required this.userName,
    required this.kloter,
    required this.role,
  });

  @override
  State<AbsensiFormScreen> createState() => _AbsensiFormScreenState();
}

class _AbsensiFormScreenState extends State<AbsensiFormScreen> {
  XFile? _pickedFile;
  bool _loading = false;
  double? _lat, _lng;
  bool _locationLoading = false;
  String _selectedType = 'masuk'; // 'masuk', 'tugas', 'izin', 'sakit'
  String? _selectedBagian;
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.sesi.bagianSesi.isNotEmpty) {
      _selectedBagian = widget.sesi.bagianSesi.first.namaBagian;
    }
    _prepareLocation();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _prepareLocation() async {
    try {
      setState(() => _locationLoading = true);

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi ditolak permanen. Aktifkan di pengaturan HP.'),
            ),
          );
        }
        return;
      }

      if (await Geolocator.isLocationServiceEnabled()) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (mounted) {
          setState(() {
            _lat = pos.latitude;
            _lng = pos.longitude;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS tidak aktif, mohon aktifkan lokasi GPS.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil lokasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        imageQuality: 65,
        maxWidth: 1024,
      );
      if (file != null && mounted) {
        setState(() => _pickedFile = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka kamera: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!widget.sesi.isSudahMasukWaktu) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Belum bisa absen. Sesi ini baru dibuka mulai pukul ${widget.sesi.formattedJamMulai} WIB.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    if (_pickedFile == null && (_selectedType == 'masuk' || _selectedType == 'tugas')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan ambil foto bukti kehadiran terlebih dahulu'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await AbsensiService.submitAttendanceGuide(
        userId: widget.userId,
        sesiId: widget.sesi.id,
        sesiTitle: widget.sesi.judul,
        bagianSesi: _selectedBagian,
        targetJamMulai: widget.sesi.targetJamMulai,
        targetJamSelesai: widget.sesi.targetJamSelesai,
        kloter: widget.kloter,
        type: _selectedType,
        note: _noteCtrl.text.trim(),
        lat: _lat,
        lng: _lng,
        pickedFile: _pickedFile,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (res['success'] == true) {
        final statusWaktu = res['status_waktu'] == 'terlambat'
            ? ' (Status: Terlambat)'
            : ' (Status: Tepat Waktu)';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Absensi berhasil disimpan!$statusWaktu'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context, true); // Return true agar list me-refresh data
      } else {
        final msg = res['message'] ?? 'Gagal mengirim absensi';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $msg'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Terjadi kesalahan: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F8),
      appBar: AppBar(
        title: const Text(
          'Isi Absensi Petugas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF842D62),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ⚠️ BANNER PERINGATAN: Jika belum masuk waktu target absensi
            if (!widget.sesi.isSudahMasukWaktu) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_clock_rounded, color: Colors.amber.shade800, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Target jam sesi ini belum dimulai. Anda baru bisa mengirim absensi mulai pukul ${widget.sesi.formattedJamMulai} WIB.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 🏷️ KARTU DETAIL SESI ABSENSI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5C1C3B), Color(0xFF842D62)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Sesi #${widget.sesi.urutan}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            widget.sesi.formattedTargetTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.sesi.judul,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  if (widget.sesi.keterangan != null &&
                      widget.sesi.keterangan!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.sesi.keterangan!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 📌 BAGIAN SESI DROPDOWN (Jika ada bagian_sesi_absensi)
            if (widget.sesi.bagianSesi.isNotEmpty) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Bagian / Lokasi Sesi:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F5F8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedBagian,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF842D62)),
                            items: widget.sesi.bagianSesi.map((b) {
                              return DropdownMenuItem<String>(
                                value: b.namaBagian,
                                child: Text(
                                  b.namaBagian,
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedBagian = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 🔘 TIPE STATUS KEHADIRAN (Masuk / Tugas / Izin / Sakit)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jenis Kehadiran:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTypeChip('masuk', 'Hadir / Masuk', Icons.check_circle_outline),
                        const SizedBox(width: 8),
                        _buildTypeChip('tugas', 'Tugas Lapangan', Icons.assignment_outlined),
                        const SizedBox(width: 8),
                        _buildTypeChip('izin', 'Izin', Icons.info_outline),
                        const SizedBox(width: 8),
                        _buildTypeChip('sakit', 'Sakit', Icons.healing_outlined),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📷 FOTO BUKTI KEHADIRAN
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.camera_alt_rounded, color: Color(0xFF842D62), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Foto Bukti Kehadiran',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _pickPhoto(ImageSource.camera),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _pickedFile == null ? const Color(0xFFF8F4F7) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _pickedFile == null
                                ? const Color(0xFF842D62).withOpacity(0.3)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: _pickedFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF842D62).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_a_photo_rounded,
                                      size: 28,
                                      color: Color(0xFF842D62),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Ketuk untuk membuka kamera',
                                    style: TextStyle(
                                      color: Color(0xFF444444),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ambil foto selfie atau foto kegiatan di lokasi',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: kIsWeb
                                        ? Image.network(
                                            _pickedFile!.path,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          )
                                        : Image.file(
                                            File(_pickedFile!.path),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.65),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.refresh, color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'Ganti Foto',
                                            style: TextStyle(color: Colors.white, fontSize: 11),
                                          ),
                                        ],
                                      ),
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
            const SizedBox(height: 16),

            // 📍 LOKASI GPS & KOORDINAT
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFF842D62), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Koordinat GPS Lokasi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: _prepareLocation,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.refresh_rounded,
                              color: const Color(0xFF842D62),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_locationLoading)
                      Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: const Color(0xFF842D62),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Mendeteksi koordinat GPS...',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      )
                    else if (_lat != null && _lng != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F9F4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lat: ${_lat!.toStringAsFixed(6)}, Lng: ${_lng!.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontFamily: 'Monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'GPS belum terdeteksi. Ketuk ikon refresh.',
                            style: TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📝 CATATAN TAMBAHAN (OPSIONAL)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan Petugas (Opsional):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Rombongan bus 1 lengkap, kondisi lancar...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF8F5F8),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 🚀 TOMBOL SIMPAN / KIRIM ABSENSI
            ElevatedButton(
              onPressed: (_loading || !widget.sesi.isSudahMasukWaktu) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.sesi.isSudahMasukWaktu
                    ? const Color(0xFF842D62)
                    : Colors.grey.shade300,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: widget.sesi.isSudahMasukWaktu ? 3 : 0,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.sesi.isSudahMasukWaktu
                              ? Icons.cloud_upload_rounded
                              : Icons.lock_clock_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.sesi.isSudahMasukWaktu
                              ? 'Kirim & Simpan Absensi'
                              : 'Belum Bisa Absen (Mulai ${widget.sesi.formattedJamMulai} WIB)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF842D62) : const Color(0xFFF4EFF3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF842D62) : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.black87),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
