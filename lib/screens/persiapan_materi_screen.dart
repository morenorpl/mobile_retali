import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../helpers/file_saver.dart';
import '../models/persiapan_materi.dart';
import '../services/persiapan_service.dart';

enum PersiapanCategory { diniyah, teknis }

class PersiapanMateriScreen extends StatefulWidget {
  final PersiapanCategory category;
  const PersiapanMateriScreen({super.key, required this.category});

  @override
  State<PersiapanMateriScreen> createState() => _PersiapanMateriScreenState();
}

class _PersiapanMateriScreenState extends State<PersiapanMateriScreen> {
  // Retali-Sistem Design Palette (Navy & Gold)
  static const Color primaryDark = Color(0xFF0D1523);
  static const Color primaryNavy = Color(0xFF1B3167);
  static const Color secondaryNavy = Color(0xFF263754);
  static const Color accentGold = Color(0xFFEAB308);
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);

  late Future<List<PersiapanMateri>> _future;

  bool get _isDiniyah => widget.category == PersiapanCategory.diniyah;

  String get _pageTitle => _isDiniyah ? 'Persiapan Diniyah' : 'Persiapan Teknis';
  String get _headerText => _isDiniyah ? 'Materi Persiapan Diniyah' : 'Materi Persiapan Teknis';
  String get _headerImage => _isDiniyah ? 'assets/diniyah/diniyah.png' : 'assets/diniyah/teknis.png';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _future = _isDiniyah
          ? PersiapanService.getPersiapanDiniyah()
          : PersiapanService.getPersiapanTeknis();
    });
  }

  Future<void> _refresh() async {
    _loadData();
    await _future;
  }

  static String _stripHtml(String? text) {
    if (text == null) return '';
    return text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  /// Membangun widget gambar cover (mendukung base64, assets, dan network URL)
  Widget _buildCoverImage(
    String url, {
    BoxFit fit = BoxFit.contain,
    double? width,
    double? height,
  }) {
    final bool isCompact = height != null && height < 110;

    if (url.startsWith('data:image/')) {
      try {
        final commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          final base64Str = url.substring(commaIdx + 1).trim();
          final bytes = base64Decode(base64Str);
          return Image.memory(
            bytes,
            fit: fit,
            width: width ?? double.infinity,
            height: height,
          );
        }
      } catch (e) {
        debugPrint("Error decoding base64 image: $e");
      }
      return Container(
        height: height ?? 140,
        width: width ?? double.infinity,
        color: const Color(0xFFF1F5F9),
        alignment: Alignment.center,
        child: isCompact
            ? const Icon(Icons.broken_image_outlined, color: textMuted, size: 28)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.broken_image_outlined, color: textMuted, size: 36),
                  SizedBox(height: 6),
                  Text(
                    "Format gambar tidak valid",
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
      );
    }

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        width: width ?? double.infinity,
        height: height,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height ?? 140,
          width: width ?? double.infinity,
          color: const Color(0xFFF1F5F9),
          alignment: Alignment.center,
          child: Icon(Icons.broken_image_outlined, color: textMuted, size: isCompact ? 28 : 36),
        ),
      );
    }

    return Image.network(
      url,
      fit: fit,
      width: width ?? double.infinity,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: height ?? 160,
          width: width ?? double.infinity,
          color: const Color(0xFFF1F5F9),
          alignment: Alignment.center,
          child: SizedBox(
            width: isCompact ? 22 : 28,
            height: isCompact ? 22 : 28,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(primaryNavy),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        height: height ?? 140,
        width: width ?? double.infinity,
        color: const Color(0xFFF1F5F9),
        alignment: Alignment.center,
        child: isCompact
            ? const Icon(Icons.broken_image_outlined, color: textMuted, size: 28)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.broken_image_outlined, color: textMuted, size: 36),
                  SizedBox(height: 6),
                  Text(
                    "Gagal memuat gambar",
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
      ),
    );
  }

  /// Membuka dialog modal preview modern lengkap dengan detail materi
  void _showDetailDialog(BuildContext context, PersiapanMateri item) {
    final cleanDesc = _stripHtml(item.description);
    final cleanContent = _stripHtml(item.content);
    final hasCover = item.displayCover != null && item.displayCover!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: primaryDark.withOpacity(0.65),
      builder: (modalCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(modalCtx).size.height * 0.90,
            maxWidth: 640,
          ),
          margin: EdgeInsets.only(
            left: MediaQuery.of(modalCtx).size.width > 640
                ? (MediaQuery.of(modalCtx).size.width - 640) / 2
                : 0,
            right: MediaQuery.of(modalCtx).size.width > 640
                ? (MediaQuery.of(modalCtx).size.width - 640) / 2
                : 0,
          ),
          decoration: const BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle Indicator
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Modal Top Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentGold.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accentGold.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isDiniyah ? Icons.menu_book_rounded : Icons.handyman_rounded,
                            size: 13,
                            color: const Color(0xFFB45309),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isDiniyah ? "MODUL DINIYAH" : "STANDAR TEKNIS",
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: const Color(0xFFF1F5F9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(modalCtx),
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(
                            Icons.close_rounded,
                            size: 19,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: borderColor, height: 1),

              // Scrollable Document Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul Materi (Besar & Terbaca Jelas)
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          height: 1.3,
                        ),
                      ),
                      if (item.subTitle != null && item.subTitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryNavy.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryNavy.withOpacity(0.15)),
                          ),
                          child: Text(
                            item.subTitle!.trim(),
                            style: const TextStyle(
                              color: primaryNavy,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Section Header Pratinjau Cover Modul
                      Row(
                        children: [
                          const Icon(Icons.image_outlined, size: 20, color: primaryNavy),
                          const SizedBox(width: 8),
                          const Text(
                            "Pratinjau Cover Modul",
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (hasCover)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: successColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "Ada Cover",
                                style: TextStyle(
                                  color: successColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF94A3B8).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "Tanpa Cover",
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Pratinjau Gambar Cover Modul
                      if (hasCover) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: borderColor, width: 1.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 280),
                                  width: double.infinity,
                                  child: _buildCoverImage(item.displayCover!),
                                ),
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Material(
                                    color: primaryDark.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => _openFullScreenImage(context, item),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: accentGold.withOpacity(0.5),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(
                                              Icons.fullscreen_rounded,
                                              color: accentGold,
                                              size: 18,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              "Layar Penuh (Zoom)",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.image_not_supported_outlined,
                                color: textMuted,
                                size: 40,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Modul ini tidak menyertakan berkas gambar cover.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Ringkasan Deskripsi
                      if (cleanDesc.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: primaryNavy,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Deskripsi Materi",
                                    style: TextStyle(
                                      color: primaryNavy,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                cleanDesc,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.55,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Konten Lengkap
                      if (cleanContent.isNotEmpty) ...[
                        const Text(
                          "Uraian / Panduan Lengkap",
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cleanContent,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: secondaryNavy,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (cleanDesc.isEmpty && cleanContent.isEmpty && !hasCover)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Tidak ada uraian teks tambahan pada materi ini.",
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Fixed Bottom Action Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: surface,
                  border: const Border(top: BorderSide(color: borderColor)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Tombol Salin Teks
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: () => _copyMateriText(modalCtx, item),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text(
                            "Salin",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryNavy,
                            side: const BorderSide(color: primaryNavy, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tombol Unduh Cover dengan Gold Accent (Disabled bila !hasCover)
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: hasCover ? () => _downloadImage(modalCtx, item) : null,
                          icon: Icon(
                            Icons.download_rounded,
                            size: 19,
                            color: hasCover ? primaryDark : const Color(0xFF94A3B8),
                          ),
                          label: Text(
                            "Unduh Cover",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: hasCover ? primaryDark : const Color(0xFF94A3B8),
                              letterSpacing: 0.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentGold,
                            disabledBackgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: primaryDark,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: hasCover ? accentGold : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Membuka viewer layar penuh dengan dukungan pinch-to-zoom interaktif
  void _openFullScreenImage(BuildContext context, PersiapanMateri item) {
    final coverUrl = item.displayCover;
    if (coverUrl == null || coverUrl.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (viewerCtx) => Scaffold(
          backgroundColor: primaryDark,
          appBar: AppBar(
            backgroundColor: primaryDark,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(viewerCtx),
            ),
            title: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentGold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.download_rounded, color: accentGold, size: 20),
                ),
                tooltip: "Unduh Cover",
                onPressed: () => _downloadImage(viewerCtx, item),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(24),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: _buildCoverImage(coverUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.pinch_rounded, color: accentGold, size: 16),
                        SizedBox(width: 8),
                        Text(
                          "Cubit layar untuk memperbesar (Zoom)",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Salin isi teks materi ke papan klip
  Future<void> _copyMateriText(BuildContext ctx, PersiapanMateri item) async {
    final cleanDesc = _stripHtml(item.description);
    final cleanContent = _stripHtml(item.content);
    final textToCopy = [
      item.title,
      if (item.subTitle != null && item.subTitle!.trim().isNotEmpty)
        item.subTitle!.trim(),
      if (cleanDesc.isNotEmpty) cleanDesc,
      if (cleanContent.isNotEmpty) cleanContent,
      if (item.displayCover != null && item.displayCover!.startsWith('http'))
        "\n[Foto Cover]: ${item.displayCover!.trim()}",
    ].join('\n\n');

    await Clipboard.setData(ClipboardData(text: textToCopy));
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          backgroundColor: primaryNavy,
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: accentGold, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Materi berhasil disalin ke clipboard.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Mengunduh / menyimpan foto cover materi ke penyimpanan perangkat
  Future<void> _downloadImage(BuildContext context, PersiapanMateri item) async {
    final coverUrl = item.displayCover;
    if (coverUrl == null || coverUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: warningColor,
          content: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Materi ini tidak memiliki file gambar cover untuk diunduh.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: primaryNavy,
        content: Row(
          children: const [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(accentGold),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Sedang mengunduh berkas cover...',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    try {
      Uint8List bytes;
      if (coverUrl.startsWith('data:image/')) {
        final commaIdx = coverUrl.indexOf(',');
        if (commaIdx == -1) throw Exception("Format gambar base64 tidak valid");
        final base64Str = coverUrl.substring(commaIdx + 1).trim();
        bytes = base64Decode(base64Str);
      } else {
        final response = await http.get(Uri.parse(coverUrl));
        if (response.statusCode != 200) {
          throw Exception("Gagal mengunduh cover dari server (Kode: ${response.statusCode})");
        }
        bytes = response.bodyBytes;
      }

      final isPng = coverUrl.contains('image/png') || coverUrl.toLowerCase().endsWith('.png');
      final ext = isPng ? 'png' : 'jpg';
      final cleanTitle = item.title
          .replaceAll(RegExp(r'[^\w\s\-]'), '')
          .trim()
          .replaceAll(' ', '_');
      final fileName = 'Cover_${cleanTitle}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      // Download atau simpan file (otomatis bekerja di Web, Android, iOS)
      await downloadOrSaveFile(bytes, fileName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: successColor,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cover berhasil diunduh: $fileName',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal mengunduh cover: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: errorColor,
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gagal mengunduh cover: $e',
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDark, primaryNavy],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _pageTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 19,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
            ),
            tooltip: "Muat Ulang Data",
            onPressed: _refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: accentGold,
        backgroundColor: primaryDark,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Header Banner
              _buildHeroBanner(),

              // FutureBuilder Konten Data
              FutureBuilder<List<PersiapanMateri>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }

                  final list = snapshot.data ?? [];

                  if (list.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildMateriList(list);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Hero Header Banner dengan ilustrasi kategori dan aksen gold
  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryDark, primaryNavy, secondaryNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Decorative background glowing accents
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentGold.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            // Header Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentGold.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentGold.withOpacity(0.45),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isDiniyah ? Icons.menu_book_rounded : Icons.construction_rounded,
                                color: accentGold,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isDiniyah ? "MODUL IBADAH" : "STANDAR TEKNIS",
                                style: const TextStyle(
                                  color: accentGold,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _headerText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isDiniyah
                              ? "Panduan ibadah dan tata cara umrah sesuai sunnah untuk muthawif & jemaah."
                              : "SOP manasik, handling bandara, hotel, transportasi, dan logistik jemaah.",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Category illustration
                  Container(
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(
                        color: accentGold.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      _headerImage,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.menu_book_rounded,
                        color: accentGold,
                        size: 38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// List Materi dengan header judul section
  Widget _buildMateriList(List<PersiapanMateri> list) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14, left: 2, right: 2),
            child: Row(
              children: [
                const Icon(Icons.library_books_rounded, size: 20, color: primaryNavy),
                const SizedBox(width: 8),
                const Text(
                  "Daftar Modul & Materi",
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryNavy.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${list.length} Materi",
                    style: const TextStyle(
                      color: primaryNavy,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = list[index];
              return _buildMateriCard(item, index);
            },
          ),
        ],
      ),
    );
  }

  /// Card Materi Horizontal: Image di sebelah kiri, Text di sebelah kanan, tombol Detail & Unduh Cover di bawah
  Widget _buildMateriCard(PersiapanMateri item, int index) {
    final cleanDesc = _stripHtml(item.description);
    final hasCover = item.displayCover != null && item.displayCover!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: primaryNavy.withOpacity(0.06),
          highlightColor: primaryNavy.withOpacity(0.03),
          onTap: () => _showDetailDialog(context, item),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row utama: Gambar di sebelah kiri, Text di sebelah kanan
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar / Thumbnail Cover di bagian kiri (Rounded Squircle 88x88)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: hasCover
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildCoverImage(
                                    item.displayCover!,
                                    fit: BoxFit.cover,
                                    width: 88,
                                    height: 88,
                                  ),
                                ],
                              )
                            : Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryDark, primaryNavy],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    _isDiniyah ? Icons.menu_book_rounded : Icons.handyman_rounded,
                                    color: accentGold,
                                    size: 34,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Teks di bagian kanan
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subtitle Badge jika ada
                          if (item.subTitle != null && item.subTitle!.trim().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: primaryNavy.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: primaryNavy.withOpacity(0.12)),
                              ),
                              child: Text(
                                item.subTitle!.trim(),
                                style: const TextStyle(
                                  color: primaryNavy,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],

                          // Judul Modul (Besar & Terbaca Jelas)
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 6),

                          // Ringkasan Deskripsi Teks
                          if (cleanDesc.isNotEmpty)
                            Text(
                              cleanDesc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 13.5,
                                height: 1.4,
                              ),
                            )
                          else
                            const Text(
                              "Ketuk untuk membaca modul lengkap.",
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(color: borderColor, height: 1, thickness: 1),
                const SizedBox(height: 10),

                // Baris Tombol Aksi: "Detail" & "Unduh Cover"
                Row(
                  children: [
                    // Tombol Detail
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _showDetailDialog(context, item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryNavy.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primaryNavy.withOpacity(0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.visibility_outlined, size: 17, color: primaryNavy),
                            SizedBox(width: 6),
                            Text(
                              "Detail",
                              style: TextStyle(
                                color: primaryNavy,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Tombol Unduh Cover (Dinonaktifkan bila saat tidak ada data image)
                    ElevatedButton.icon(
                      onPressed: hasCover ? () => _downloadImage(context, item) : null,
                      icon: Icon(
                        Icons.download_rounded,
                        size: 18,
                        color: hasCover ? primaryDark : const Color(0xFF94A3B8),
                      ),
                      label: Text(
                        "Unduh Cover",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: hasCover ? primaryDark : const Color(0xFF94A3B8),
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGold,
                        disabledBackgroundColor: const Color(0xFFF1F5F9),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: hasCover ? accentGold : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Clean Loading State
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryNavy.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryNavy),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Memuat Materi Persiapan...",
              style: TextStyle(
                color: textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Menyiapkan modul dan panduan umrah",
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Clean Error State
  Widget _buildErrorState(String errorMsg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: primaryDark.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 44,
                  color: errorColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Gagal Memuat Materi",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  "Coba Lagi",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Clean Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: primaryDark.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: primaryNavy.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  size: 46,
                  color: primaryNavy,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Belum Ada Materi",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Materi persiapan untuk kategori ini belum tersedia di database. Tarik ke bawah untuk memuat ulang.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryNavy,
                  side: const BorderSide(color: primaryNavy, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  "Muat Ulang",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
