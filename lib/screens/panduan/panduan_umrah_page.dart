import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'panduan_models.dart';
import 'panduan_data.dart';

class PanduanUmrahPage extends StatefulWidget {
  const PanduanUmrahPage({super.key});

  @override
  State<PanduanUmrahPage> createState() => _PanduanUmrahPageState();
}

class _PanduanUmrahPageState extends State<PanduanUmrahPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String _q = '';
  Set<String> _favs = {};           // key: sectionId|index
  Map<String, bool> _checks = {};   // checklist item -> done

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: sections.length + 1, vsync: this); // +1 tab Checklist
    _loadState();
  }

  Future<void> _loadState() async {
    final sp = await SharedPreferences.getInstance();
    _favs = (sp.getStringList('umrah_guide_favs') ?? []).toSet();
    final raw = sp.getStringList('umrah_checklist') ?? [];
    _checks = {for (final e in raw) e: true};
    if (mounted) setState(() {});
  }

  Future<void> _toggleFav(String key) async {
    final sp = await SharedPreferences.getInstance();
    if (_favs.contains(key)) {
      _favs.remove(key);
    } else {
      _favs.add(key);
    }
    await sp.setStringList('umrah_guide_favs', _favs.toList());
    if (mounted) setState(() {});
  }

  Future<void> _toggleCheck(String item) async {
    final sp = await SharedPreferences.getInstance();
    final enabled = !(_checks[item] ?? false);
    _checks[item] = enabled;
    final list = _checks.entries.where((e) => e.value).map((e) => e.key).toList();
    await sp.setStringList('umrah_checklist', list);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ...sections.map((s) => Tab(text: s.title)),
      const Tab(text: 'Checklist'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panduan Umrah',
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
            if (_tab.index < sections.length)
              // Search Box untuk panduan
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
                    hintText: 'Cari di "${sections[_tab.index].title}"…',
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
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  ...sections.map((s) => _SectionView(
                        section: s,
                        favorites: _favs,
                        onToggleFav: _toggleFav,
                        query: _q,
                      )),
                  _ChecklistView(
                    checks: _checks,
                    onToggle: _toggleCheck,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  final GuideSection section;
  final Set<String> favorites;
  final void Function(String key) onToggleFav;
  final String query;

  const _SectionView({
    required this.section,
    required this.favorites,
    required this.onToggleFav,
    required this.query,
  });

  List<GuideEntry> _filteredEntries() {
    if (query.trim().isEmpty) return section.entries;
    final q = query.toLowerCase();
    return section.entries.where((e) {
      if (e.title.toLowerCase().contains(q)) return true;
      return e.bullets.any((b) => b.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries();

    if (entries.isEmpty) {
      return Center(
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
              'Tidak ada hasil pencarian',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci lain',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
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
                                ].join('\n');
                                await Clipboard.setData(ClipboardData(text: text));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Teks disalin'),
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

                  // Poin-poin panduan
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: e.bullets.map((b) => _Bullet(text: b)).toList(),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, right: 12),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF842D62),
              shape: BoxShape.circle,
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

class _ChecklistView extends StatelessWidget {
  final Map<String, bool> checks;
  final void Function(String item) onToggle;

  const _ChecklistView({required this.checks, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final items = {
      ...{for (final s in defaultChecklist) s: true},
      ...checks,
    }.keys.toList();

    final completedCount = checks.values.where((done) => done).length;
    final totalCount = items.length;

    return Column(
      children: [
        // Progress Header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          padding: const EdgeInsets.all(20),
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress Checklist',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF842D62),
                    ),
                  ),
                  Text(
                    '$completedCount/$totalCount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF842D62),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: totalCount > 0 ? completedCount / totalCount : 0,
                backgroundColor: Colors.grey[200],
                color: const Color(0xFF842D62),
                borderRadius: BorderRadius.circular(10),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                '${((completedCount / totalCount) * 100).toStringAsFixed(0)}% selesai',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Checklist Items
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.checklist_rtl_outlined,
                        size: 64,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Checklist kosong',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final done = checks[item] ?? false;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        color: Colors.white,
                        child: CheckboxListTile(
                          value: done,
                          onChanged: (_) => onToggle(item),
                          title: Text(
                            item,
                            style: TextStyle(
                              fontSize: 15,
                              color: done ? Colors.grey : const Color(0xFF333333),
                              decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                              fontWeight: done ? FontWeight.normal : FontWeight.w500,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          activeColor: const Color(0xFF842D62),
                          checkColor: Colors.white,
                          tileColor: Colors.white,
                          secondary: done
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: const Color(0xFF842D62),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}