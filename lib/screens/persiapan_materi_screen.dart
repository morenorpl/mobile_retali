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

  Widget _buildCoverImage(String url) {
    if (url.startsWith('data:image/')) {
      try {
        final commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          final base64Str = url.substring(commaIdx + 1).trim();
          final bytes = base64Decode(base64Str);
          return Image.memory(
            bytes,
            fit: BoxFit.contain,
            width: double.infinity,
          );
        }
      } catch (e) {
        debugPrint("Error decoding base64 image: $e");
      }
      return Container(
        height: 120,
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 36),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 180,
          color: Colors.grey.shade100,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF842D62),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        height: 120,
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 36),
            const SizedBox(height: 6),
            Text(
              "Gagal memuat gambar",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, PersiapanMateri item) {
    final cleanDesc = _stripHtml(item.description);
    final cleanContent = _stripHtml(item.content);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.title,
              style: const TextStyle(
                color: Color(0xFF842D62),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (item.subTitle != null && item.subTitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.subTitle!.trim(),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(dialogCtx).size.width,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogCtx).size.height * 0.65,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🖼️ Tampilkan gambar cover utuh di atas teks jika tersedia
                  if (item.displayCover != null && item.displayCover!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: _buildCoverImage(item.displayCover!),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                if (cleanDesc.isNotEmpty) ...[
                  Text(
                    cleanDesc,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  if (cleanContent.isNotEmpty) const Divider(height: 24),
                ],
                if (cleanContent.isNotEmpty)
                  Text(
                    cleanContent,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                if (cleanDesc.isEmpty && cleanContent.isEmpty && (item.displayCover == null || item.displayCover!.isEmpty))
                  Text(
                    "Tidak ada deskripsi tambahan.",
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
          // 📥 Tombol Download Gambar (hanya tampil jika materi memiliki cover foto)
          if (item.displayCover != null && item.displayCover!.isNotEmpty)
            TextButton.icon(
              onPressed: () => _downloadImage(dialogCtx, item),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text(
                "Unduh Gambar",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
              ),
            ),
          // 📋 Tombol Salin Teks
          TextButton.icon(
            onPressed: () async {
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
              if (dialogCtx.mounted) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  SnackBar(
                    content: const Text('Materi berhasil disalin ke clipboard.'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text(
              "Salin",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF842D62),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
            child: const Text(
              "Tutup",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Mengunduh / menyimpan foto cover materi ke penyimpanan perangkat
  Future<void> _downloadImage(BuildContext context, PersiapanMateri item) async {
    final coverUrl = item.displayCover;
    if (coverUrl == null || coverUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materi ini tidak memiliki gambar untuk diunduh.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sedang mengunduh gambar...'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
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
          throw Exception("Gagal mengunduh gambar dari server (Kode: ${response.statusCode})");
        }
        bytes = response.bodyBytes;
      }

      final isPng = coverUrl.contains('image/png') || coverUrl.toLowerCase().endsWith('.png');
      final ext = isPng ? 'png' : 'jpg';
      final cleanTitle = item.title
          .replaceAll(RegExp(r'[^\w\s\-]'), '')
          .trim()
          .replaceAll(' ', '_');
      final fileName = '${cleanTitle}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      // Download atau simpan file (otomatis bekerja di Web, Android, iOS)
      await downloadOrSaveFile(bytes, fileName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gambar berhasil diunduh: $fileName',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal mengunduh gambar: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Gagal mengunduh gambar: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5C1C3B), Color(0xFF7B1F48)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          _pageTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF842D62),
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🏷️ Container Header atas: "Materi Persiapan Diniyah" / "Materi Persiapan Teknis"
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5C1C3B), Color(0xFF7B1F48)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _headerText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Image.asset(
                      _headerImage,
                      height: 55,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.menu_book,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ],
                ),
              ),

              // 📦 Grid 2 Kolom Materi dari Database
              FutureBuilder<List<PersiapanMateri>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF842D62),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                            const SizedBox(height: 12),
                            Text(
                              "Gagal memuat materi: ${snapshot.error}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF842D62),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _loadData,
                              child: const Text("Coba Lagi"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final list = snapshot.data ?? [];

                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Belum Ada Materi",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Data materi belum tersedia di database.\nTarik ke bawah untuk memuat ulang.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return _buildCard(item);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(PersiapanMateri item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF7B1F48).withOpacity(0.3),
        onTap: () => _showDetailDialog(context, item),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B1F48), Color(0xFF5C1C3B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item.displayCover != null && item.displayCover!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 52,
                    width: 52,
                    color: Colors.white.withOpacity(0.1),
                    child: _buildCoverImage(item.displayCover!),
                  ),
                )
              else
                Image.asset(
                  "assets/LogoRetali.png",
                  height: 52,
                  color: Colors.white,
                  fit: BoxFit.contain,
                ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
