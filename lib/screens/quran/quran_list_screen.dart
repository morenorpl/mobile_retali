import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_retali/screens/quran/quran_detail_screen.dart';
import 'package:mobile_retali/services/quran_service.dart';

class QuranListScreen extends StatefulWidget {
  const QuranListScreen({super.key});

  @override
  State<QuranListScreen> createState() => _QuranListScreenState();
}

class _QuranListScreenState extends State<QuranListScreen> {
  // Retali-Sistem Design Palette (Navy & Gold)
  static const Color primaryDark = Color(0xFF0D1523);
  static const Color primaryNavy = Color(0xFF1B3167);
  static const Color secondaryNavy = Color(0xFF263754);
  static const Color accentGold = Color(0xFFEAB308);
  static const Color pageBg = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color errorRed = Color(0xFFEF4444);

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _q = '';
  final TextEditingController _searchController = TextEditingController();

  // Quick filter suggestions for Umrah pilgrims & muthawif
  final List<String> _quickSuggestions = const [
    'Al-Fatihah',
    'Al-Kahf',
    'Ya-Sin',
    'Ar-Rahman',
    'Al-Waqi\'ah',
    'Al-Mulk',
    'Al-Ikhlas',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      final data = await QuranService.getSurahList();
      setState(() {
        _all = data;
        _applyFilter();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_all);
    } else {
      _filtered = _all.where((m) {
        final nama = (m['nama'] ?? '').toString().toLowerCase();
        final latin = (m['namaLatin'] ?? '').toString().toLowerCase();
        final arti = (m['arti'] ?? '').toString().toLowerCase();
        final nomor = (m['nomor'] ?? '').toString();
        return nama.contains(q) || latin.contains(q) || arti.contains(q) || nomor == q;
      }).toList();
    }
  }

  void _onSearchChanged(String v) {
    setState(() {
      _q = v;
      _applyFilter();
    });
  }

  void _setQuickFilter(String name) {
    if (_q.toLowerCase() == name.toLowerCase()) {
      _searchController.clear();
      setState(() {
        _q = '';
        _applyFilter();
      });
    } else {
      _searchController.text = name;
      setState(() {
        _q = name;
        _applyFilter();
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _q = '';
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryDark,
                primaryNavy,
                secondaryNavy,
              ],
            ),
          ),
          child: const Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HeaderPatternPainter(),
                ),
              ),
            ],
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Material(
            color: Colors.white.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.18),
                width: 0.8,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Al-Qur\'an Al-Karim',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentGold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: accentGold.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    '114 SURAH',
                    style: TextStyle(
                      color: accentGold,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Kalamullah • Panduan Ibadah Umrah',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentGold.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentGold.withValues(alpha: 0.35),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: accentGold,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Elegant Header Section with Search Bar & Quick Filters
          _buildSearchAndFilterHeader(),

          // Main Surah List Area
          Expanded(
            child: _loading
                ? _buildLoadingState()
                : RefreshIndicator(
                    color: primaryNavy,
                    backgroundColor: Colors.white,
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? _buildEmptyState()
                        : _buildSurahListView(),
                  ),
          ),
        ],
      ),
    );
  }

  // 🔍 Modern Search and Filter Section
  Widget _buildSearchAndFilterHeader() {
    return Container(
      decoration: BoxDecoration(
        color: pageBg,
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bismillah Card (Shown only when not searching to save space)
          if (_q.isEmpty && !_loading)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryNavy,
                    secondaryNavy,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryDark.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontFamilyFallback: ['Amiri', 'Traditional Arabic', 'Arial'],
                            color: accentGold,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Dengan nama Allah Yang Maha Pengasih lagi Maha Penyayang',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accentGold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: accentGold,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

          // Stylish Rounded 16px Search Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _q.isNotEmpty ? primaryNavy : borderColor,
                width: _q.isNotEmpty ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryDark.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Cari surat, arti, atau nomor (misal: Al-Kahf, 18)...',
                hintStyle: const TextStyle(
                  color: textMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.search_rounded,
                    color: primaryNavy,
                    size: 22,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                suffixIcon: _q.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          color: textMuted,
                          size: 20,
                        ),
                        splashRadius: 18,
                        onPressed: _clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Quick Filter Chips (Popular Surahs)
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildQuickChip(
                  label: 'Semua (114)',
                  isSelected: _q.isEmpty,
                  onTap: _clearSearch,
                ),
                const SizedBox(width: 8),
                ..._quickSuggestions.map((name) {
                  final isSelected = _q.toLowerCase() == name.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildQuickChip(
                      label: name,
                      isSelected: isSelected,
                      onTap: () => _setQuickFilter(name),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Count & Status Summary Row
          if (!_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: accentGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _q.isEmpty
                            ? 'Daftar Surat (${_filtered.length})'
                            : 'Hasil Pencarian (${_filtered.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  if (_q.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: const Row(
                        children: [
                          Icon(Icons.close_rounded, size: 14, color: errorRed),
                          SizedBox(width: 4),
                          Text(
                            'Reset Filter',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: errorRed,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Text(
                      'Al-Qur\'an 30 Juz',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // 🏷️ Quick Filter Chip Widget
  Widget _buildQuickChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? primaryNavy : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? primaryNavy : borderColor,
              width: 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryNavy.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 📜 Main Surah List View
  Widget _buildSurahListView() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = _filtered[i];
        final nomor = s['nomor'];
        final nama = (s['nama'] ?? '').toString();
        final latin = (s['namaLatin'] ?? '').toString();
        final ayat = (s['jumlahAyat'] ?? '-').toString();
        final turun = (s['tempatTurun'] ?? '').toString();
        final arti = (s['arti'] ?? '').toString();

        final turunLower = turun.toLowerCase();
        final isMekah = turunLower.contains('mekah') || turunLower.contains('makkah');
        final isMadinah = turunLower.contains('madin');
        final revelationLabel = isMekah
            ? 'Makkiyah'
            : (isMadinah ? 'Madaniyah' : (turun.isNotEmpty ? turun : 'Surah'));

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: primaryDark.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              splashColor: primaryNavy.withValues(alpha: 0.08),
              highlightColor: accentGold.withValues(alpha: 0.05),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuranDetailScreen(nomor: nomor as int),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Custom 8-Pointed Geometric Star (Rub-el-Hizb) Surah Badge
                    _buildRubElHizbBadge(nomor),
                    const SizedBox(width: 14),

                    // Center Details: Latin Name, Meaning, Revelation & Ayat Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latin,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            arti,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Pill Badges: Revelation Type & Verse Count
                          Row(
                            children: [
                              _buildPillBadge(
                                icon: isMekah
                                    ? Icons.location_on_outlined
                                    : Icons.location_city_outlined,
                                label: revelationLabel,
                                bgColor: isMekah
                                    ? const Color(0xFFFEF9C3)
                                    : const Color(0xFFEFF6FF),
                                textColor: isMekah
                                    ? const Color(0xFF854D0E)
                                    : const Color(0xFF1D4ED8),
                                iconColor: isMekah
                                    ? const Color(0xFF854D0E)
                                    : const Color(0xFF1D4ED8),
                                borderColor: isMekah
                                    ? const Color(0xFFFEF08A)
                                    : const Color(0xFFDBEAFE),
                              ),
                              const SizedBox(width: 6),
                              _buildPillBadge(
                                icon: Icons.format_list_numbered_rounded,
                                label: '$ayat Ayat',
                                bgColor: const Color(0xFFF1F5F9),
                                textColor: const Color(0xFF475569),
                                iconColor: const Color(0xFF64748B),
                                borderColor: const Color(0xFFE2E8F0),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right Side: Arabic Calligraphy Name & Forward Indicator
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nama,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontFamilyFallback: [
                              'Amiri',
                              'Traditional Arabic',
                              'Scheherazade',
                              'Arial',
                            ],
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: primaryNavy,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: pageBg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: borderColor,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: textMuted,
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
      },
    );
  }

  // ۞ Custom 8-Pointed Islamic Geometric Star Badge (Rub-el-Hizb)
  Widget _buildRubElHizbBadge(dynamic nomor) {
    final text = '$nomor';
    final fontSize = text.length > 2 ? 11.0 : 13.0;

    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CustomPaint(
            size: Size(46, 46),
            painter: _RubElHizbPainter(
              strokeColor: accentGold,
              strokeWidth: 1.3,
            ),
          ),
          Text(
            text,
            style: TextStyle(
              color: accentGold,
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // 💊 Refined Pill Badge Widget
  Widget _buildPillBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: iconColor,
          ),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ⏳ Elegant Loading State
  Widget _buildLoadingState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: primaryDark.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryNavy),
                  ),
                ),
                Icon(
                  Icons.auto_stories_rounded,
                  size: 22,
                  color: accentGold,
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Memuat Mushaf Al-Qur\'an...',
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Menyiapkan 114 surat dan terjemahan',
              style: TextStyle(
                color: textSecondary,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔍 Empty Search Results State
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: primaryDark.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primaryNavy.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 36,
                    color: primaryNavy,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Surat Tidak Ditemukan',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tidak ada surat yang cocok dengan kata kunci "$_q". Silakan periksa ejaan atau cari berdasarkan nomor surat.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Reset Pencarian',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

// 📐 Rub-el-Hizb (8-Pointed Islamic Geometric Star) Badge Painter
class _RubElHizbPainter extends CustomPainter {
  final Color strokeColor;
  final double strokeWidth;

  const _RubElHizbPainter({
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - strokeWidth;
    // Exact mathematical ratio of an 8-pointed star formed by 2 overlapping squares:
    // r_inner = outerRadius * 0.7654
    final innerR = outerR * 0.7654;

    final path = Path();
    for (int i = 0; i < 16; i++) {
      final angle = (i * math.pi / 8) - (math.pi / 2);
      final r = (i % 2 == 0) ? outerR : innerR;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Soft drop shadow
    canvas.drawShadow(
      path,
      const Color(0xFF0D1523).withValues(alpha: 0.22),
      2.5,
      false,
    );

    // Deep Navy gradient fill
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF263754),
          Color(0xFF0D1523),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Signature Gold border stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // Inner subtle gold ring
    final ringPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final ringR = innerR * 0.72;
    canvas.drawCircle(center, ringR, ringPaint);

    // 4 Cardinal delicate accent dots
    final dotPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy - ringR), 0.9, dotPaint);
    canvas.drawCircle(Offset(center.dx, center.dy + ringR), 0.9, dotPaint);
    canvas.drawCircle(Offset(center.dx - ringR, center.dy), 0.9, dotPaint);
    canvas.drawCircle(Offset(center.dx + ringR, center.dy), 0.9, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RubElHizbPainter oldDelegate) => false;
}

// 📐 Header Islamic Arabesque Subtle Pattern Painter
class _HeaderPatternPainter extends CustomPainter {
  const _HeaderPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFFEAB308).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double spacing = 48.0;
    final int cols = (size.width / spacing).ceil() + 2;
    final int rows = (size.height / spacing).ceil() + 2;

    for (int i = -1; i < cols; i++) {
      for (int j = -1; j < rows; j++) {
        final cx = i * spacing + (j % 2 == 0 ? 0 : spacing / 2);
        final cy = j * spacing;

        canvas.save();
        canvas.translate(cx, cy);

        // 8-Pointed Rub-el-Hizb Star motif
        const double halfSide = 10.0;
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: halfSide * 2,
          height: halfSide * 2,
        );

        canvas.drawRect(rect, strokePaint);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(rect, strokePaint);
        canvas.drawCircle(Offset.zero, 3.5, strokePaint);

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
