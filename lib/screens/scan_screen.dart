import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';

import 'package:mobile_retali/helpers/permission_helper.dart';
import 'package:mobile_retali/services/scan_service.dart';
import 'package:mobile_retali/models/scan_result.dart';
import 'riwayat_scan/history_screen.dart';

enum ScanMode { koper, paspor }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  // Retali-Sistem Color Palette (Navy & Gold Theme)
  static const Color primaryDark = Color(0xFF0D1523);
  static const Color primaryNavy = Color(0xFF1B3167);
  static const Color secondaryNavy = Color(0xFF263754);
  static const Color accentGold = Color(0xFFEAB308);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);

  ScanMode _mode = ScanMode.koper;

  bool _scanLocked = false;
  bool _isTorchOn = false;
  String? _statusMessage;
  Color _statusColor = Colors.transparent;

  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String? _locationStatusText;

  ScanResult? _lastScanResult;

  late final MobileScannerController _cameraController;
  late final AudioPlayer _playerOk;
  late final ScanService _scanService;

  late final AnimationController _scanLineController;
  late final Animation<double> _scanLineAnimation;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scanLineAnimation = CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

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

    // Otomatis deteksi koordinat lokasi saat layar dibuka tanpa perlu input pengguna
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingLocation = true;
          _locationStatusText = "Mencari lokasi GPS...";
        });
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationStatusText = "GPS nonaktif (aktifkan GPS HP)";
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoadingLocation = false;
              _locationStatusText = "Izin lokasi ditolak";
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationStatusText = "Izin lokasi ditolak permanen";
          });
        }
        return;
      }

      // Ambil lokasi cepat terakhir yang diketahui
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() {
          _currentPosition = lastPos;
          _locationStatusText =
              "${lastPos.latitude.toStringAsFixed(4)}, ${lastPos.longitude.toStringAsFixed(4)}";
        });
      }

      // Ambil koordinat akurat terbaru
      final currentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );

      if (mounted) {
        setState(() {
          _currentPosition = currentPos;
          _isLoadingLocation = false;
          _locationStatusText =
              "${currentPos.latitude.toStringAsFixed(4)}, ${currentPos.longitude.toStringAsFixed(4)}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          if (_currentPosition == null) {
            _locationStatusText = "GPS siap otomatis saat scan";
          }
        });
      }
    }
  }

  Future<Position?> _getCoordinates() async {
    if (_currentPosition != null) {
      return _currentPosition;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 2),
      );
      _currentPosition = pos;
      return pos;
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) _currentPosition = last;
        return last;
      } catch (_) {
        return null;
      }
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
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
      setState(() {
        _statusMessage = null;
        _lastScanResult = null;
      });
    }

    if (_mode == ScanMode.koper) {
      if (_isPassportQR(cleaned) || _isJsonPassport(cleaned)) {
        _lastScanResult = null;
        _showStatus("❌ QR PASPOR TERDETEKSI\n(Ganti mode ke Scan Paspor)", Colors.red);
        await Future.delayed(const Duration(milliseconds: 1000));
        _unlockScan();
        return;
      }
      if (!_isKoperQR(cleaned)) {
        _lastScanResult = null;
        _showStatus("❌ FORMAT QR KOPER TIDAK VALID", Colors.red);
        await Future.delayed(const Duration(milliseconds: 1000));
        _unlockScan();
        return;
      }
    }

    if (_mode == ScanMode.paspor) {
      if (_isJsonKoper(cleaned)) {
        _lastScanResult = null;
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
      _lastScanResult = null;
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

  Future<void> _flipCamera() async {
    try {
      await _cameraController.switchCamera();
    } catch (_) {}
  }

  Future<void> _handleScanKoper(String raw) async {
    try {
      final pos = await _getCoordinates();
      final result = await _scanService.scanKoper(
        qrRaw: raw,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );
      _lastScanResult = result;
      if (result.success) {
        await _playSuccess();
        final display = result.ownerName != null && result.ownerName != '-'
            ? "${result.code} - ${result.ownerName}"
            : result.code;
        final locInfo = (pos != null)
            ? "\n📍 ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}"
            : "";
        _showStatus("✅ SCAN KOPER BERHASIL\n$display$locInfo", Colors.green);
      } else {
        final msg = result.message ?? 'Koper sudah pernah discan';
        _showStatus("⚠️ $msg\n(${result.code})", Colors.orange);
      }
    } catch (e) {
      _lastScanResult = null;
      final msg = e.toString().replaceAll('Exception: ', '').trim();
      _showStatus("❌ $msg", Colors.red);
    }
  }

  Future<void> _handleScanPaspor(String raw) async {
    try {
      final pos = await _getCoordinates();
      final result = await _scanService.scanPassport(
        qrRaw: raw,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );
      _lastScanResult = result;
      if (result.success) {
        await _playSuccess();
        final display = result.ownerName != null && result.ownerName != '-'
            ? "${result.code} - ${result.ownerName}"
            : result.code;
        final locInfo = (pos != null)
            ? "\n📍 ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}"
            : "";
        _showStatus("✅ SCAN PASPOR BERHASIL\n$display$locInfo", Colors.green);
      } else {
        final msg = result.message ?? 'Paspor sudah pernah discan';
        _showStatus("⚠️ $msg\n(${result.code})", Colors.orange);
      }
    } catch (e) {
      _lastScanResult = null;
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
            backgroundColor: primaryDark,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentGold),
              ),
            ),
          );
        }

        if (snapshot.data == false) {
          return _buildPermissionDenied(context);
        }

        final size = MediaQuery.of(context).size;
        final double boxWidth = (size.width * 0.74).clamp(250.0, 310.0);
        final double boxHeight = boxWidth;
        final double cutoutTop = (size.height - boxHeight) / 2 - 35;

        return Scaffold(
          backgroundColor: primaryDark,
          body: Stack(
            children: [
              // 1. Camera Live Stream
              Positioned.fill(
                child: MobileScanner(
                  controller: _cameraController,
                  fit: BoxFit.cover,
                  onDetect: _onDetect,
                ),
              ),

              // 2. Cinematic Dark Ambient Scrim with Futuristic Viewport
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_scanLineAnimation, _pulseAnimation]),
                  builder: (context, _) {
                    return CustomPaint(
                      size: size,
                      painter: _ScannerOverlayPainter(
                        cutoutSize: Size(boxWidth, boxHeight),
                        borderRadius: 24.0,
                        bracketColor: _mode == ScanMode.koper
                            ? accentGold
                            : const Color(0xFF60A5FA),
                        scanLineProgress: _scanLineAnimation.value,
                        pulseValue: _pulseAnimation.value,
                      ),
                    );
                  },
                ),
              ),

              // 3. Floating Glassmorphism Top Bar with Mode Switcher
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(context),
              ),

              // 4. Floating Circular Buttons & Guidance Pill beneath the scanner
              Positioned(
                top: cutoutTop + boxHeight + 22,
                left: 20,
                right: 20,
                child: _buildFloatingControlsBar(),
              ),

              // 5. GPS Location Status Banner at bottom (visible when no overlay)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _statusMessage == null ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: _statusMessage != null,
                    child: _buildGpsBanner(),
                  ),
                ),
              ),

              // 6. Scan Result Feedback Overlay / Bottom Sheet
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: _statusMessage != null
                      ? _buildFeedbackOverlay(context)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TOP BAR WITH GLASSMORPHISM & MODE SWITCHER
  // ==========================================
  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      top: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Circular Glass Back Button
            _buildGlassCircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: "Kembali",
              size: 46,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 10),

            // Mode Switcher Styled as Modern Pill Segmented Control
            Expanded(
              child: _buildModeSegmentedControl(),
            ),
            const SizedBox(width: 10),

            // Circular Glass History Button
            _buildGlassCircleButton(
              icon: Icons.history_rounded,
              tooltip: "Riwayat Scan",
              size: 46,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSegmentedControl() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: primaryDark.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSegmentItem(
                  label: "Koper",
                  icon: Icons.luggage_rounded,
                  isSelected: _mode == ScanMode.koper,
                  onTap: () {
                    if (_mode != ScanMode.koper) {
                      setState(() {
                        _mode = ScanMode.koper;
                        _statusMessage = null;
                        _lastScanResult = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildSegmentItem(
                  label: "Paspor",
                  icon: Icons.menu_book_rounded,
                  isSelected: _mode == ScanMode.paspor,
                  onTap: () {
                    if (_mode != ScanMode.paspor) {
                      setState(() {
                        _mode = ScanMode.paspor;
                        _statusMessage = null;
                        _lastScanResult = null;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentItem({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      Color(0xFFFDE047),
                      Color(0xFFEAB308),
                      Color(0xFFCA8A04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentGold.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? primaryDark : Colors.white.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? primaryDark : Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FLOATING CONTROLS BAR (FLASH, HINT, FLIP)
  // ==========================================
  Widget _buildFloatingControlsBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Flash / Torch Button
        _buildGlassCircleButton(
          icon: _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          tooltip: _isTorchOn ? "Matikan Lampu" : "Nyalakan Lampu",
          isActive: _isTorchOn,
          activeColor: accentGold,
          size: 46,
          onTap: _toggleTorch,
        ),
        const SizedBox(width: 12),

        // Centered Translucent Guidance Chip
        Flexible(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: primaryDark.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _mode == ScanMode.koper
                          ? Icons.qr_code_scanner_rounded
                          : Icons.document_scanner_rounded,
                      size: 15,
                      color: _mode == ScanMode.koper
                          ? accentGold
                          : const Color(0xFF60A5FA),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        "Scan QR ${_mode == ScanMode.koper ? 'Koper' : 'Paspor'}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Flip Camera Button
        _buildGlassCircleButton(
          icon: Icons.flip_camera_ios_rounded,
          tooltip: "Ganti Arah Kamera",
          size: 46,
          onTap: _flipCamera,
        ),
      ],
    );
  }

  // ==========================================
  // GPS LOCATION STATUS BANNER AT BOTTOM
  // ==========================================
  Widget _buildGpsBanner() {
    final isReady = _currentPosition != null;
    final dotColor = isReady
        ? successGreen
        : (_isLoadingLocation ? warningAmber : const Color(0xFF94A3B8));

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: primaryDark.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isReady
                  ? successGreen.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.14),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Subtle Animated Glowing Dot
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  final glowScale = _pulseAnimation.value;
                  return Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.65 * glowScale),
                          blurRadius: 8 * glowScale + 2,
                          spreadRadius: 2.5 * glowScale,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),

              Icon(
                Icons.my_location_rounded,
                size: 16,
                color: isReady ? successGreen : accentGold,
              ),
              const SizedBox(width: 10),

              // Clean Typography for Location
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReady
                          ? "GPS AKTIF (OTOMATIS)"
                          : (_isLoadingLocation
                              ? "MENCARI KOORDINAT GPS..."
                              : "STATUS GPS HP"),
                      style: TextStyle(
                        color: isReady
                            ? successGreen
                            : (_isLoadingLocation ? accentGold : textMuted),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isReady
                          ? "${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}"
                          : (_locationStatusText ?? "Mendeteksi koordinat..."),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              if (_isLoadingLocation)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(accentGold),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: "Perbarui GPS",
                  onPressed: _initLocation,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SCAN RESULT FEEDBACK OVERLAY / BOTTOM SHEET
  // ==========================================
  Widget _buildFeedbackOverlay(BuildContext context) {
    final rawMsg = _statusMessage ?? '';
    final isSuccess = rawMsg.startsWith("✅") ||
        _statusColor == Colors.green.withValues(alpha: 0.85) ||
        (_lastScanResult?.success ?? false);
    final isWarning = rawMsg.startsWith("⚠️") ||
        _statusColor == Colors.orange.withValues(alpha: 0.85) ||
        (_lastScanResult?.duplicate ?? false);

    final Color accentColor = isSuccess
        ? successGreen
        : (isWarning ? warningAmber : errorRed);

    final String title = isSuccess
        ? (_mode == ScanMode.koper ? "SCAN KOPER BERHASIL" : "SCAN PASPOR BERHASIL")
        : (isWarning ? "DATA SUDAH PERNAH DISCAN" : "PINDAI QR GAGAL");

    final IconData statusIcon = isSuccess
        ? Icons.check_circle_rounded
        : (isWarning ? Icons.warning_amber_rounded : Icons.cancel_rounded);

    final cleanMessage = rawMsg
        .replaceAll('✅', '')
        .replaceAll('⚠️', '')
        .replaceAll('❌', '')
        .trim();

    final isWrongModePassport = cleanMessage.contains("QR PASPOR TERDETEKSI");
    final isWrongModeKoper = cleanMessage.contains("QR KOPER TERDETEKSI");

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: primaryDark.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.65),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.28),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.18),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(statusIcon, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          isSuccess
                              ? "Data berhasil tercatat ke sistem retali"
                              : (isWarning
                                  ? "Item telah terdaftar sebelumnya"
                                  : "Silakan periksa kembali QR target"),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _statusMessage = null;
                        _lastScanResult = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Metadata presentation card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: secondaryNavy.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_lastScanResult != null) ...[
                      // Code Chip with refined styling
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryNavy.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: accentGold.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _mode == ScanMode.koper
                                      ? Icons.luggage_rounded
                                      : Icons.menu_book_rounded,
                                  size: 13,
                                  color: accentGold,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _mode == ScanMode.koper ? "KOPER" : "PASPOR",
                                  style: const TextStyle(
                                    color: accentGold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lastScanResult!.code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      if (_lastScanResult!.ownerName != null &&
                          _lastScanResult!.ownerName != '-') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _lastScanResult!.ownerName!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (_lastScanResult!.kloter != null ||
                          (_lastScanResult!.ownerPhone != null &&
                              _lastScanResult!.ownerPhone != '-')) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (_lastScanResult!.kloter != null)
                              _buildInfoChip(Icons.group_rounded, "Kloter: ${_lastScanResult!.kloter}"),
                            if (_lastScanResult!.ownerPhone != null &&
                                _lastScanResult!.ownerPhone != '-')
                              _buildInfoChip(Icons.phone_rounded, _lastScanResult!.ownerPhone!),
                          ],
                        ),
                      ],

                      if (_lastScanResult!.latitude != null &&
                          _lastScanResult!.longitude != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.pin_drop_rounded, size: 13, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Text(
                              "${_lastScanResult!.latitude!.toStringAsFixed(5)}, ${_lastScanResult!.longitude!.toStringAsFixed(5)}",
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ] else ...[
                      // Non-structured fallback display (e.g. error / wrong format)
                      Text(
                        cleanMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Action Buttons Row
              Row(
                children: [
                  if (isWrongModePassport || isWrongModeKoper) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentGold,
                          foregroundColor: primaryDark,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: Icon(
                          isWrongModePassport ? Icons.menu_book_rounded : Icons.luggage_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isWrongModePassport
                              ? "Beralih ke Scan Paspor"
                              : "Beralih ke Scan Koper",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          setState(() {
                            _mode = isWrongModePassport ? ScanMode.paspor : ScanMode.koper;
                            _statusMessage = null;
                            _lastScanResult = null;
                          });
                        },
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: const Text("Riwayat", style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HistoryScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSuccess
                              ? successGreen
                              : (isWarning ? accentGold : primaryNavy),
                          foregroundColor:
                              (isSuccess || !isWarning) ? Colors.white : primaryDark,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text(
                          "Lanjut Scan",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          setState(() {
                            _statusMessage = null;
                            _lastScanResult = null;
                          });
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SLEEK CIRCULAR GLASS BUTTON COMPONENT
  // ==========================================
  Widget _buildGlassCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    bool isActive = false,
    Color? activeColor,
    double size = 46,
  }) {
    final tintColor = isActive ? (activeColor ?? accentGold) : Colors.white;

    return Tooltip(
      message: tooltip ?? '',
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? (activeColor ?? accentGold).withValues(alpha: 0.22)
                      : primaryDark.withValues(alpha: 0.55),
                  border: Border.all(
                    color: isActive
                        ? (activeColor ?? accentGold).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.18),
                    width: isActive ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isActive
                          ? (activeColor ?? accentGold).withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: tintColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CAMERA PERMISSION DENIED SCREEN
  // ==========================================
  Widget _buildPermissionDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryDark, primaryNavy],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildGlassCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: "Kembali",
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: secondaryNavy.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentGold.withValues(alpha: 0.15),
                          border: Border.all(
                            color: accentGold.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentGold.withValues(alpha: 0.25),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.no_photography_rounded,
                          size: 38,
                          color: accentGold,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        "Izin Kamera Diperlukan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Aplikasi retali sistem Zero Complaint memerlukan akses kamera untuk memindai kode QR koper dan paspor jamaah secara akurat.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentGold,
                            foregroundColor: primaryDark,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt_rounded, size: 20),
                          label: const Text(
                            "Izinkan Akses Kamera",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =======================================================
// CUSTOM SCANNER OVERLAY PAINTER (CINEMATIC RETICLE & LASER)
// =======================================================
class _ScannerOverlayPainter extends CustomPainter {
  final Size cutoutSize;
  final double borderRadius;
  final Color bracketColor;
  final double scanLineProgress;
  final double pulseValue;

  _ScannerOverlayPainter({
    required this.cutoutSize,
    required this.borderRadius,
    required this.bracketColor,
    required this.scanLineProgress,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double left = (size.width - cutoutSize.width) / 2;
    final double top = (size.height - cutoutSize.height) / 2 - 35;
    final Rect cutoutRect = Rect.fromLTWH(left, top, cutoutSize.width, cutoutSize.height);
    final RRect cutoutRRect = RRect.fromRectAndRadius(cutoutRect, Radius.circular(borderRadius));

    // 1. Dark Cinematic Ambient Scrim
    final Path backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path cutoutPath = Path()..addRRect(cutoutRRect);
    final Path overlayPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

    final Paint scrimPaint = Paint()
      ..color = const Color(0xFF0D1523).withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;
    canvas.drawPath(overlayPath, scrimPaint);

    // 2. Viewport Subtle Border
    final Paint borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(cutoutRRect, borderPaint);

    // 3. Futuristic Corner Brackets (L-Shape on 4 corners)
    final double cornerLength = 32.0;
    final double r = borderRadius;
    final Paint bracketPaint = Paint()
      ..color = bracketColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Top-Left
    final Path tlPath = Path()
      ..moveTo(cutoutRect.left, cutoutRect.top + cornerLength)
      ..lineTo(cutoutRect.left, cutoutRect.top + r)
      ..quadraticBezierTo(cutoutRect.left, cutoutRect.top, cutoutRect.left + r, cutoutRect.top)
      ..lineTo(cutoutRect.left + cornerLength, cutoutRect.top);
    canvas.drawPath(tlPath, bracketPaint);

    // Top-Right
    final Path trPath = Path()
      ..moveTo(cutoutRect.right - cornerLength, cutoutRect.top)
      ..lineTo(cutoutRect.right - r, cutoutRect.top)
      ..quadraticBezierTo(cutoutRect.right, cutoutRect.top, cutoutRect.right, cutoutRect.top + r)
      ..lineTo(cutoutRect.right, cutoutRect.top + cornerLength);
    canvas.drawPath(trPath, bracketPaint);

    // Bottom-Left
    final Path blPath = Path()
      ..moveTo(cutoutRect.left, cutoutRect.bottom - cornerLength)
      ..lineTo(cutoutRect.left, cutoutRect.bottom - r)
      ..quadraticBezierTo(cutoutRect.left, cutoutRect.bottom, cutoutRect.left + r, cutoutRect.bottom)
      ..lineTo(cutoutRect.left + cornerLength, cutoutRect.bottom);
    canvas.drawPath(blPath, bracketPaint);

    // Bottom-Right
    final Path brPath = Path()
      ..moveTo(cutoutRect.right - cornerLength, cutoutRect.bottom)
      ..lineTo(cutoutRect.right - r, cutoutRect.bottom)
      ..quadraticBezierTo(cutoutRect.right, cutoutRect.bottom, cutoutRect.right, cutoutRect.bottom - r)
      ..lineTo(cutoutRect.right, cutoutRect.bottom - cornerLength);
    canvas.drawPath(brPath, bracketPaint);

    // 4. Subtle Center Crosshair Reticle
    final double centerX = cutoutRect.center.dx;
    final double centerY = cutoutRect.center.dy;
    final double crossHairSize = 10.0;
    final Paint crossHairPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(centerX - crossHairSize, centerY),
      Offset(centerX + crossHairSize, centerY),
      crossHairPaint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - crossHairSize),
      Offset(centerX, centerY + crossHairSize),
      crossHairPaint,
    );

    // 5. Animated Laser Scan Line
    final double lineY = cutoutRect.top + (cutoutRect.height * scanLineProgress);
    final Rect lineRect = Rect.fromLTWH(
      cutoutRect.left + 14,
      lineY - 1.5,
      cutoutRect.width - 28,
      3.0,
    );

    // Laser gradient glow
    final Paint lineGlowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          bracketColor.withValues(alpha: 0.0),
          bracketColor.withValues(alpha: 0.85),
          Colors.white,
          bracketColor.withValues(alpha: 0.85),
          bracketColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(lineRect);
    canvas.drawRRect(RRect.fromRectAndRadius(lineRect, const Radius.circular(2)), lineGlowPaint);

    // Soft beam aura
    final Rect auraRect = Rect.fromLTWH(
      cutoutRect.left + 24,
      lineY - 14,
      cutoutRect.width - 48,
      28,
    );
    final Paint auraPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [
          bracketColor.withValues(alpha: 0.22),
          bracketColor.withValues(alpha: 0.0),
        ],
      ).createShader(auraRect);
    canvas.drawRect(auraRect, auraPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanLineProgress != scanLineProgress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.bracketColor != bracketColor ||
        oldDelegate.cutoutSize != cutoutSize;
  }
}
