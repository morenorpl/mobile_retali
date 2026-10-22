import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:mobile_retali/helpers/permission_helper.dart';
import 'package:mobile_retali/services/scan_service.dart';

enum ScanMode { koper, paspor }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  ScanMode _mode = ScanMode.koper;

  bool _scanLocked = false;
  String? _statusMessage;
  Color _statusColor = Colors.transparent;

  late final MobileScannerController _cameraController;
  late final AudioPlayer _playerOk;
  late final ScanService _scanService;

  @override
  void initState() {
    super.initState();

    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal, // ✅ WAJIB
      autoStart: true,
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
    await _playerOk.play(
      AssetSource('sound/Barcode scan.mp3'),
    );
  }

  String _firstField(String raw) => raw.split('|').first.trim();

  bool _isPassportQR(String raw) {
    final first = _firstField(raw);
    return RegExp(r'^[A-Z]{1,2}[0-9]{6,9}$').hasMatch(first);
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

  bool _isKoperQR(String raw) {
    final parts = raw.split('|').map((e) => e.trim()).toList();
    if (parts.length < 3) return false;
    if (_isPassportQR(raw)) return false;
    if (parts.first.length > 10) return false;
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
        _showStatus("❌ QR PASPOR TERDETEKSI", Colors.red);
        _unlockScan();
        return;
      }
      if (!_isKoperQR(cleaned)) {
        _showStatus("❌ FORMAT QR KOPER TIDAK VALID", Colors.red);
        _unlockScan();
        return;
      }
    }

    if (_mode == ScanMode.paspor) {
      if (!_isPassportQR(cleaned) && !_isJsonPassport(cleaned)) {
        _showStatus("❌ QR BUKAN PASPOR", Colors.red);
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
    } catch (_) {
      _showStatus("❌ GAGAL MEMPROSES QR", Colors.red);
    }

    await Future.delayed(const Duration(milliseconds: 350));
    _unlockScan();
  }

  void _unlockScan() {
    _scanLocked = false;
  }

  Future<void> _handleScanKoper(String raw) async {
    final result = await _scanService.scanKoper(qrRaw: raw);
    if (result.success) {
      await _playSuccess();
      _showStatus("✅ SCAN KOPER BERHASIL", Colors.green);
    } else {
      _showStatus("⚠️ KOPER SUDAH DISCAN", Colors.orange);
    }
  }

  Future<void> _handleScanPaspor(String raw) async {
    final result = await _scanService.scanPassport(qrRaw: raw);
    if (result.success) {
      await _playSuccess();
      _showStatus("✅ SCAN PASPOR BERHASIL", Colors.green);
    } else {
      _showStatus("⚠️ PASPOR SUDAH DISCAN", Colors.orange);
    }
  }

  void _showStatus(String message, Color color) {
    setState(() {
      _statusMessage = message;
      _statusColor = color.withOpacity(0.85);
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
          return const Scaffold(
            body: Center(child: Text("⚠️ Izin kamera ditolak")),
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

              Positioned(
                top: 40,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _mode == ScanMode.koper
                            ? "📦 SCAN KOPER – ARAHKAN KE QR"
                            : "📘 SCAN PASPOR – ARAHKAN KE QR",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_statusMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusMessage!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _mode == ScanMode.koper
                          ? Colors.blue
                          : Colors.red,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              Positioned(
                bottom: 40,
                right: 20,
                child: FloatingActionButton.extended(
                  backgroundColor:
                      _mode == ScanMode.koper ? Colors.red : Colors.blue,
                  icon: Icon(
                    _mode == ScanMode.koper
                        ? Icons.document_scanner
                        : Icons.inventory_2,
                  ),
                  label: Text(
                    _mode == ScanMode.koper
                        ? "Scan Paspor"
                        : "Scan Koper",
                  ),
                  onPressed: () {
                    setState(() {
                      _mode = _mode == ScanMode.koper
                          ? ScanMode.paspor
                          : ScanMode.koper;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
