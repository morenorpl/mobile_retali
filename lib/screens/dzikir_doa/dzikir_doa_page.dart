import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'doa_model.dart';
import 'doa_data.dart';

class DzikirDoaPage extends StatefulWidget {
  const DzikirDoaPage({super.key});

  @override
  State<DzikirDoaPage> createState() => _DzikirDoaPageState();
}

class _DzikirDoaPageState extends State<DzikirDoaPage> {
  final _kategori = const ['Semua', 'Safar', 'Makkah', 'Masjid', 'Thawaf', 'Sa\'i', 'Umum'];
  String _selected = 'Semua';
  String _q = '';
  Set<int> _favorit = {};

  @override
  void initState() {
    super.initState();
    _loadFav();
  }

  Future<void> _loadFav() async {
    final sp = await SharedPreferences.getInstance();
    _favorit = (sp.getStringList('fav_doa') ?? []).map(int.parse).toSet();
    if (mounted) setState(() {});
  }

  Future<void> _toggleFav(int id) async {
    final sp = await SharedPreferences.getInstance();
    if (_favorit.contains(id)) {
      _favorit.remove(id);
    } else {
      _favorit.add(id);
    }
    await sp.setStringList('fav_doa', _favorit.map((e) => e.toString()).toList());
    if (mounted) setState(() {});
  }

  List<Doa> _filtered() {
    List<Doa> items = List<Doa>.from(doaList);

    if (_selected != 'Semua') {
      items = items.where((d) => d.kategori == _selected).toList();
    }
    if (_q.isNotEmpty) {
      final q = _q.toLowerCase();
      items = items
          .where((d) =>
              d.judul.toLowerCase().contains(q) ||
              d.latin.toLowerCase().contains(q) ||
              d.arti.toLowerCase().contains(q))
          .toList();
    }

    items.sort((a, b) {
      final af = _favorit.contains(a.id) ? 1 : 0;
      final bf = _favorit.contains(b.id) ? 1 : 0;
      return bf.compareTo(af);
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dzikir & Doa',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF842D62),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F4F7),
              Color(0xFFF0E8EF),
            ],
          ),
        ),
        child: Column(
          children: [
            // Search Box
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari doa/dzikir...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(
                    Icons.search,
                    color: const Color(0xFF842D62).withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),

            // Kategori Chips
            SizedBox(
              height: 50,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final k = _kategori[i];
                  final active = _selected == k;
                  return FilterChip(
                    label: Text(
                      k,
                      style: TextStyle(
                        color: active ? Colors.white : const Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: active,
                    onSelected: (_) => setState(() => _selected = k),
                    selectedColor: const Color(0xFF842D62),
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: active ? const Color(0xFF842D62) : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.1),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _kategori.length,
              ),
            ),

            // Info jumlah
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      color: const Color(0xFF842D62).withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${items.length} doa/dzikir ditemukan',
                      style: TextStyle(
                        color: const Color(0xFF842D62).withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (_favorit.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.bookmark,
                            color: const Color(0xFF842D62).withOpacity(0.7),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_favorit.length} favorit',
                            style: TextStyle(
                              color: const Color(0xFF842D62).withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            // Daftar Doa
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada doa/dzikir ditemukan',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Coba kata kunci atau kategori lain',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, i) => _DoaCard(
                        doa: items[i],
                        isFav: _favorit.contains(items[i].id),
                        onToggleFav: () => _toggleFav(items[i].id),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoaCard extends StatelessWidget {
  final Doa doa;
  final bool isFav;
  final VoidCallback onToggleFav;

  const _DoaCard({
    required this.doa,
    required this.isFav,
    required this.onToggleFav,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan judul dan action buttons
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doa.judul,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xFF333333),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF842D62).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            doa.kategori,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF842D62),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bookmark Button
                      Container(
                        decoration: BoxDecoration(
                          color: isFav ? const Color(0xFF842D62) : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          tooltip: isFav ? 'Hapus favorit' : 'Tambah ke favorit',
                          onPressed: onToggleFav,
                          icon: Icon(
                            isFav ? Icons.bookmark : Icons.bookmark_outline,
                            color: isFav ? Colors.white : Colors.grey,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Copy Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          tooltip: 'Salin teks',
                          onPressed: () async {
                            final text = '${doa.judul}\n\n${doa.arab}\n\n${doa.latin}\n\nArtinya: ${doa.arti}';
                            await Clipboard.setData(ClipboardData(text: text));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Teks doa disalin'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.copy_all_outlined,
                            color: Colors.grey,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Teks Arab
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F4F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF842D62).withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  doa.arab,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.8,
                    fontFamily: 'NotoNaskhArabic',
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Teks Latin
              Text(
                doa.latin,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF555555),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),

              // Terjemahan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF842D62).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF842D62).withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Artinya:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF842D62).withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      doa.arti,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF444444),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}