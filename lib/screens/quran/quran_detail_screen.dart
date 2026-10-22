import 'package:flutter/material.dart';
import 'package:mobile_retali/services/quran_service.dart';

class QuranDetailScreen extends StatefulWidget {
  final int nomor;
  const QuranDetailScreen({super.key, required this.nomor});

  @override
  State<QuranDetailScreen> createState() => _QuranDetailScreenState();
}

class _QuranDetailScreenState extends State<QuranDetailScreen> {
  Map<String, dynamic>? _surah;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      final data = await QuranService.getSurahDetail(widget.nomor);
      setState(() => _surah = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _surah;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF842D62),
        // === TAMBAHKAN INI UNTUK WARNA PUTIH ===
        foregroundColor: Colors.white, // Warna untuk icon dan teks
        titleTextStyle: const TextStyle(
          color: Colors.white, // Warna khusus untuk judul
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Warna khusus untuk icon
        ),
        title: Text(s == null ? 'Surat' : '${s['namaLatin']} (${s['nama']})'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : s == null
              ? const Center(child: Text('Gagal memuat surat'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      // Header info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF842D62).withOpacity(.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${s['namaLatin']} • ${s['jumlahAyat']} ayat',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(
                              (s['arti'] ?? '').toString(),
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              (s['deskripsi'] ?? '')
                                  .toString()
                                  .replaceAll(RegExp(r'<[^>]*>'), ''), // bersihkan HTML
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Bismillah (sebagian API include di ayat pertama; biarkan apa adanya)
                      // Daftar ayat
                      ...((s['ayat'] as List?) ?? [])
                          .cast<Map<String, dynamic>>()
                          .map((a) {
                        final no = a['nomorAyat'] ?? a['nomor'] ?? '';
                        final arab = a['teksArab'] ?? a['arab'] ?? '';
                        final latin = a['teksLatin'] ?? a['latin'] ?? '';
                        final indo = a['teksIndonesia'] ?? a['indonesia'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        const Color(0xFF842D62).withOpacity(.1),
                                    child: Text(
                                      '$no',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF842D62),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Ayat $no',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Arabic
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  arab.toString(),
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    height: 1.6,
                                    fontFamily: 'NotoNaskhArabic', // kalau tersedia
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Latin
                              Text(
                                latin.toString(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Terjemahan
                              Text(
                                indo.toString(),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
    );
  }
}