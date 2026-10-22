import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'praktis_models.dart';
import 'praktis_data.dart';

class InfoPraktisPage extends StatefulWidget {
  const InfoPraktisPage({super.key});

  @override
  State<InfoPraktisPage> createState() => _InfoPraktisPageState();
}

class _InfoPraktisPageState extends State<InfoPraktisPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String _q = '';
  Set<String> _favs = {}; // key: sectionId|index

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: praktisSections.length, vsync: this);
    _loadFavs();
  }

  Future<void> _loadFavs() async {
    final sp = await SharedPreferences.getInstance();
    _favs = (sp.getStringList('praktis_favs') ?? []).toSet();
    if (mounted) setState(() {});
  }

  Future<void> _toggleFav(String key) async {
    final sp = await SharedPreferences.getInstance();
    if (_favs.contains(key)) {
      _favs.remove(key);
    } else {
      _favs.add(key);
    }
    await sp.setStringList('praktis_favs', _favs.toList());
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = praktisSections.map((s) => Tab(text: s.title)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Info Praktis'),
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
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: tabs,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari info praktis…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: praktisSections.map((s) {
                return _SectionView(
                  section: s,
                  query: _q,
                  favorites: _favs,
                  onToggleFav: _toggleFav,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  final PraktisSection section;
  final String query;
  final Set<String> favorites;
  final void Function(String key) onToggleFav;

  const _SectionView({
    required this.section,
    required this.query,
    required this.favorites,
    required this.onToggleFav,
  });

  @override
  Widget build(BuildContext context) {
    final entries = query.trim().isEmpty
        ? section.entries
        : section.entries.where((e) =>
            e.title.toLowerCase().contains(query.toLowerCase()) ||
            e.bullets.any((b) => b.toLowerCase().contains(query.toLowerCase())) ||
            e.notes.any((n) => n.toLowerCase().contains(query.toLowerCase()))).toList();

    if (entries.isEmpty) return const Center(child: Text('Tidak ada hasil.'));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final e = entries[i];
        final key = '${section.id}|$i';
        final isFav = favorites.contains(key);
        return Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      tooltip: isFav ? 'Hapus favorit' : 'Tandai favorit',
                      onPressed: () => onToggleFav(key),
                      icon: Icon(
                        isFav ? Icons.bookmark : Icons.bookmark_outline,
                        color: isFav ? const Color(0xFF842D62) : Colors.grey,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Salin',
                      onPressed: () async {
                        final text = [
                          e.title,
                          ...e.bullets.map((b) => '• $b'),
                          if (e.notes.isNotEmpty) '\nCatatan:',
                          ...e.notes.map((n) => '– $n'),
                        ].join('\n');
                        await Clipboard.setData(ClipboardData(text: text));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Disalin')));
                        }
                      },
                      icon: const Icon(Icons.copy_all_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // poin ringkas
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: e.bullets.map((b) => _Bullet(text: b)).toList(),
                ),

                if (e.notes.isNotEmpty) const SizedBox(height: 8),
                if (e.notes.isNotEmpty)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F1F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: e.notes.map((n) => _Dash(text: n)).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(height: 1.4)),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}

class _Dash extends StatelessWidget {
  final String text;
  const _Dash({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('–  ', style: TextStyle(height: 1.4)),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}