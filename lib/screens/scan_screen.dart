import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mobile_retali/helpers/permission_helper.dart';
import 'package:mobile_retali/services/scan_service.dart';
import 'riwayat_scan/history_screen.dart';

enum ScanMode { koper, paspor }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  ScanMode _mode = ScanMode.koper;

  bool _scanLocked = false;
  bool _isTorchOn = false;
  String? _statusMessage;
  Color _statusColor = Colors.transparent;

  late final MobileScannerController _cameraController;
  late final AudioPlayer _playerOk;
  late final ScanService _scanService;

  @override
  void initState() {
    super.initState();

    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      autoStart: true,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _playerOk = AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop)
      ..setVolume(1.0);

    _scanService = ScanService();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _playerOk.dispose();
    super.dispose();
  }

  Future<void> _playSuccess() async {
    try {
      await _playerOk.play(
        AssetSource('sound/Barcode scan.mp3'),
      );
    } catch (_) {}
  }

  String _firstField(String raw) => raw.split('|').first.trim();

  bool _isPassportQR(String raw) {
    final first = _firstField(raw);
    return RegExp(r'^[A-Z]{1,2}[0-9]{6,9}$', caseSensitive: false).hasMatch(first);
  }

  bool _isJsonPassport(String raw) {
    try {
      final j = jsonDecode(raw);
      return j is Map &&
          (j.containsKey('passport') ||
              j.containsKey('passport_number') ||
              j.containsKey('passportNumber'));
    } catch (_) {
      return false;
    }
  }

  bool _isJsonKoper(String raw) {
    try {
      final j = jsonDecode(raw);
      return j is Map &&
          (j.containsKey('kode_koper') ||
              j.containsKey('koper_code') ||
              j.containsKey('koper'));
    } catch (_) {
      return false;
    }
  }

  bool _isKoperQR(String raw) {
    if (_isJsonKoper(raw)) return true;
    if (_isPassportQR(raw) || _isJsonPassport(raw)) return false;
    final parts = raw.split('|').map((e) => e.trim()).toList();
    if (parts.length >= 2) return true;
    if (parts.length == 1 && parts.first.isNotEmpty && parts.first.length <= 15) return true;
    return true;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanLocked) return;

    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    final cleaned = raw.trim();
    _scanLocked = true;

    if (_statusMessage != null) {
      setState(() => _statusMessage = null);
    }

    if (_mode == ScanMode.koper) {
      if (_isPassportQR(cleaned) || _isJsonPassport(cleaned)) {
        _showStatus("❌ QR PASPOR TERDETEKSI\n(Ganti mode ke Scan Paspor)", Colors.red);
        await Future.delayed(const Duration(milliseconds: 1000));
        _unlockScan();
        return;
      }
      if (!_isKoperQR(cleaned)) {
        _showStatus("❌ FORMAT QR KOPER TIDAK VALID", Colors.red);
        await Future.delayed(const Duration(milliseconds: 1000));
        _unlockScan();
        return;
      }
    }

    if (_mode == ScanMode.paspor) {
      if (_isJsonKoper(cleaned)) {
        _showStatus("❌ QR KOPER TERDETEKSI\n(Ganti mode ke Scan Koper)", Colors.red);
        await Future.delayed(const Duration(milliseconds: 1000));
        _unlockScan();
        return;
      }
    }

    try {
      if (_mode == ScanMode.koper) {
        await _handleScanKoper(cleaned);
      } else {
        await _handleScanPaspor(cleaned);
      }
    } catch (e) {
      _showStatus("❌ GAGAL MEMPROSES QR: $e", Colors.red);
    }

    await Future.delayed(const Duration(milliseconds: 1800));
    _unlockScan();
  }

  void _unlockScan() {
    _scanLocked = false;
  }

  Future<void> _toggleTorch() async {
    try {
      await _cameraController.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final capture = await _cameraController.analyzeImage(file.path);
        if (capture != null && capture.barcodes.isNotEmpty) {
          await _onDetect(capture);
        } else {
          _showStatus("⚠️ Tidak ada QR code valid yang terdeteksi dari file", Colors.orange);
        }
      }
    } catch (e) {
      _showStatus("❌ Gagal membaca file: $e", Colors.red);
    }
  }

  Future<void> _handleScanKoper(String raw) async {
    try {
      final result = await _scanService.scanKoper(qrRaw: raw);
      if (result.success) {
        await _playSuccess();
        final display = result.ownerName != null && result.ownerName != '-'
            ? "${result.code} - ${result.ownerName}"
            : result.code;
        _showStatus("✅ SCAN KOPER BERHASIL\n$display", Colors.green);
      } else {
        final msg = result.message ?? 'Koper sudah pernah discan';
        _showStatus("⚠️ $msg\n(${result.code})", Colors.orange);
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').trim();
      _showStatus("❌ $msg", Colors.red);
    }
  }

  Future<void> _handleScanPaspor(String raw) async {
    try {
      final result = await _scanService.scanPassport(qrRaw: raw);
      if (result.success) {
        await _playSuccess();
        final display = result.ownerName != null && result.ownerName != '-'
            ? "${result.code} - ${result.ownerName}"
            : result.code;
        _showStatus("✅ SCAN PASPOR BERHASIL\n$display", Colors.green);
      } else {
        final msg = result.message ?? 'Paspor sudah pernah discan';
        _showStatus("⚠️ $msg\n(${result.code})", Colors.orange);
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').trim();
      _showStatus("❌ $msg", Colors.red);
    }
  }

  void _showStatus(String message, Color color) {
    if (!mounted) return;
    setState(() {
      _statusMessage = message;
      _statusColor = color.withValues(alpha: 0.85);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PermissionHelper.requestCameraPermission(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == false) {
          return Scaffold(
            backgroundColor: const Color(0xFF1E293B),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text("Scan Kamera", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.no_photography_rounded, size: 72, color: Colors.amber),
                    const SizedBox(height: 16),
                    const Text(
                      "Izin Kamera Diperlukan",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Aplikasi membutuhkan izin kamera untuk memindai kode QR secara real-time.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF842D62),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text("Minta Izin Kamera", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              MobileScanner(
                controller: _cameraController,
                fit: BoxFit.cover,
                onDetect: _onDetect,
              ),

              // Header bar
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _mode == ScanMode.koper
                                  ? "📦 SCAN KOPER"
                                  : "📘 SCAN PASPOR",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: IconButton(
                            icon: Icon(
                              _isTorchOn ? Icons.flash_on : Icons.flash_off,
                              color: _isTorchOn ? Colors.amber : Colors.white,
                            ),
                            tooltip: "Senter Kamera",
                            onPressed: _toggleTorch,
                          ),
                        ),
                        const SizedBox(width: 6),
                        CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: IconButton(
                            icon: const Icon(Icons.photo_library, color: Colors.white),
                            tooltip: "Scan dari Galeri / File",
                            onPressed: _pickFromGallery,
                          ),
                        ),
                        const SizedBox(width: 6),
                        CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: IconButton(
                            icon: const Icon(Icons.history, color: Colors.white),
                            tooltip: "Riwayat Scan",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const HistoryScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_statusMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Box scanner
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _mode == ScanMode.koper
                              ? const Color(0xFF842D62)
                              : Colors.blueAccent,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Arahkan kamera ke QR ${_mode == ScanMode.koper ? 'Koper' : 'Paspor'}",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Actions
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'btnHistory',
                      backgroundColor: Colors.black54,
                      icon: const Icon(Icons.history, color: Colors.white),
                      label: const Text(
                        "History",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryScreen(),
                          ),
                        );
                      },
                    ),
                    FloatingActionButton.extended(
                      heroTag: 'btnToggleMode',
                      backgroundColor: _mode == ScanMode.koper
                          ? Colors.blueAccent
                          : const Color(0xFF842D62),
                      icon: Icon(
                        _mode == ScanMode.koper
                            ? Icons.document_scanner
                            : Icons.inventory_2,
                        color: Colors.white,
                      ),
                      label: Text(
                        _mode == ScanMode.koper
                            ? "Ke Scan Paspor"
                            : "Ke Scan Koper",
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        setState(() {
                          _mode = _mode == ScanMode.koper
                              ? ScanMode.paspor
                              : ScanMode.koper;
                          _statusMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
