import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fiqih_models.dart';
import 'fiqih_data.dart';

class FiqihUmrahPage extends StatefulWidget {
  const FiqihUmrahPage({super.key});

  @override
  State<FiqihUmrahPage> createState() => _FiqihUmrahPageState();
}

class _FiqihUmrahPageState extends State<FiqihUmrahPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String _q = '';
  Set<String> _favs = {}; // key: sectionId|index

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: fiqhSections.length, vsync: this);
    _loadFavs();
  }

  Future<void> _loadFavs() async {
    final sp = await SharedPreferences.getInstance();
    _favs = (sp.getStringList('fiqih_favs') ?? []).toSet();
    if (mounted) setState(() {});
  }

  Future<void> _toggleFav(String key) async {
    final sp = await SharedPreferences.getInstance();
    if (_favs.contains(key)) {
      _favs.remove(key);
    } else {
      _favs.add(key);
    }
    await sp.setStringList('fiqih_favs', _favs.toList());
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = fiqhSections.map((s) => Tab(text: s.title)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fiqih Umrah',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF842D62),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: tabs,
        ),
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
                  hintText: 'Cari materi fiqih…',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF842D62),
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
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: fiqhSections.map((s) {
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
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  final FiqhSection section;
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
            e.dalil.any((d) => d.toLowerCase().contains(query.toLowerCase()))).toList();

    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Tidak ada hasil pencarian',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) {
        final e = entries[i];
        final key = '${section.id}|$i';
        final isFav = favorites.contains(key);
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
                        child: Text(
                          e.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xFF333333),
                            height: 1.3,
                          ),
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
                              tooltip: isFav ? 'Hapus favorit' : 'Tandai favorit',
                              onPressed: () => onToggleFav(key),
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
                              tooltip: 'Salin',
                              onPressed: () async {
                                final text = [
                                  e.title,
                                  ...e.bullets.map((b) => '• $b'),
                                  if (e.dalil.isNotEmpty) '\nDalil:',
                                  ...e.dalil.map((d) => '– $d'),
                                  if (e.notes.isNotEmpty) '\nCatatan:',
                                  ...e.notes.map((n) => '– $n'),
                                ].join('\n');
                                await Clipboard.setData(ClipboardData(text: text));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                        SnackBar(
                                          content: const Text('Teks disalin ke clipboard'),
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
                  const SizedBox(height: 12),

                  // Poin ringkas
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: e.bullets.map((b) => _Bullet(text: b)).toList(),
                  ),

                  // Dalil & Catatan (expandable)
                  if (e.dalil.isNotEmpty || e.notes.isNotEmpty) const SizedBox(height: 12),
                  if (e.dalil.isNotEmpty || e.notes.isNotEmpty)
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F4F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          title: const Text(
                            'Dalil & Catatan',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF842D62),
                              fontSize: 15,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.expand_more,
                            color: Color(0xFF842D62),
                          ),
                          children: [
                            if (e.dalil.isNotEmpty)
                              const _SubHeading(title: 'Dalil'),
                            if (e.dalil.isNotEmpty)
                              ...e.dalil.map((d) => _Dash(text: d)),
                            if (e.notes.isNotEmpty) const SizedBox(height: 8),
                            if (e.notes.isNotEmpty)
                              const _SubHeading(title: 'Catatan'),
                            if (e.notes.isNotEmpty)
                              ...e.notes.map((n) => _Dash(text: n)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
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
          const Text(
            '•  ',
            style: TextStyle(
              color: Color(0xFF842D62),
              height: 1.5,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                height: 1.5,
                fontSize: 15,
                color: Color(0xFF444444),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubHeading extends StatelessWidget {
  final String title;
  const _SubHeading({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: Color(0xFF333333),
          fontSize: 15,
        ),
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
          const Text(
            '–  ',
            style: TextStyle(
              color: Color(0xFF666666),
              height: 1.5,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                height: 1.5,
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }
}