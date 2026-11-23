// lib/screens/faq_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/faq_model.dart';
import '../services/faq_service.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  // Retali-Sistem Navy & Gold Design Palette
  static const Color primaryDark = Color(0xFF0D1523);
  static const Color primaryNavy = Color(0xFF1B3167);
  static const Color secondaryNavy = Color(0xFF263754);
  static const Color accentGold = Color(0xFFEAB308);
  static const Color pageBg = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color errorRed = Color(0xFFEF4444);

  final TextEditingController _searchController = TextEditingController();
  List<FaqItem> _allFaqs = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFaqs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await FaqService.fetchFaqs();
      if (!mounted) return;
      setState(() {
        _allFaqs = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat FAQ: $e';
        _isLoading = false;
      });
    }
  }

  List<String> get _categories {
    final Set<String> cats = {'Semua'};
    for (final faq in _allFaqs) {
      if (faq.category.isNotEmpty) {
        cats.add(faq.category);
      }
    }
    return cats.toList();
  }

  List<FaqItem> get _filteredFaqs {
    return _allFaqs.where((item) {
      final matchesCategory =
          _selectedCategory == 'Semua' ||
          item.category.toLowerCase() == _selectedCategory.toLowerCase();
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          item.question.toLowerCase().contains(q) ||
          item.answer.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('tour leader') || cat.contains('leader')) {
      return primaryNavy;
    } else if (cat.contains('muthawif')) {
      return const Color(0xFF0D9488);
    } else if (cat.contains('teknis')) {
      return const Color(0xFF2563EB);
    } else if (cat.contains('kloter') || cat.contains('jamaah')) {
      return const Color(0xFFD97706);
    } else if (cat.contains('fiqih') || cat.contains('ibadah')) {
      return const Color(0xFF7C3AED);
    }
    return textSecondary;
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('tour leader') || cat.contains('leader')) {
      return Icons.badge_outlined;
    } else if (cat.contains('muthawif')) {
      return Icons.menu_book_rounded;
    } else if (cat.contains('teknis')) {
      return Icons.qr_code_scanner_rounded;
    } else if (cat.contains('kloter') || cat.contains('jamaah')) {
      return Icons.groups_rounded;
    } else if (cat.contains('fiqih') || cat.contains('ibadah')) {
      return Icons.mosque_rounded;
    }
    return Icons.help_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: pageBg,
        body: Column(
          children: [
            // 🕌 HERO HEADER WITH SEARCH BAR & ISLAMIC ARABESQUE PATTERN
            _buildHeroHeader(context),

            // 🏷️ CATEGORY SELECTION CHIPS
            if (!_isLoading && _allFaqs.isNotEmpty) _buildCategoryChips(),

            // 📊 RESULTS SUMMARY COUNTER
            if (!_isLoading && _errorMessage == null && _allFaqs.isNotEmpty)
              _buildResultsSummary(),

            // 📖 MAIN FAQ LIST & CONTENT
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================
  // 🕌 HERO HEADER
  // ==============================
  Widget _buildHeroHeader(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primaryDark,
            primaryNavy,
            secondaryNavy,
          ],
          stops: [0.0, 0.65, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Geometric Arabesque Overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
              child: const CustomPaint(
                painter: _IslamicGeometricPatternPainter(),
              ),
            ),
          ),

          // Header Content
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation & Title Bar
                Row(
                  children: [
                    // Back Action Button with Glassmorphism
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Tagline
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: accentGold,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Pusat Bantuan (FAQ)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Retali Sistem Zero Complaint',
                            style: TextStyle(
                              color: accentGold.withValues(alpha: 0.95),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick Count Pill Badge
                    if (!_isLoading && _allFaqs.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentGold.withValues(alpha: 0.25),
                              accentGold.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accentGold.withValues(alpha: 0.65),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentGold.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.quiz_rounded,
                              color: accentGold,
                              size: 12,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${_allFaqs.length} Topik',
                              style: const TextStyle(
                                color: accentGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Greeting & Subtitle
                const Text(
                  'Ada yang bisa kami bantu?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Temukan jawaban cepat seputar operasional ibadah & tugas lapangan.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 14),

                // 🔍 Subtle Rounded Search Bar (16px shape)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _searchQuery.isNotEmpty
                          ? accentGold
                          : Colors.white.withValues(alpha: 0.9),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryDark.withValues(alpha: 0.20),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari pertanyaan, panduan, atau kata kunci...',
                      hintStyle: const TextStyle(
                        color: textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: primaryNavy,
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: textSecondary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: textSecondary,
                                  size: 15,
                                ),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================
  // 🏷️ CATEGORY CHIPS
  // ==============================
  Widget _buildCategoryChips() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 12, bottom: 2),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat.toLowerCase() == _selectedCategory.toLowerCase();
          final count = cat == 'Semua'
              ? _allFaqs.length
              : _allFaqs
                  .where((f) => f.category.toLowerCase() == cat.toLowerCase())
                  .length;
          final catColor = _getCategoryColor(cat);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [primaryNavy, secondaryNavy],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? accentGold : borderLight,
                    width: isSelected ? 1.4 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryNavy.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cat != 'Semua') ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isSelected ? accentGold : catColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                    ] else ...[
                      Icon(
                        Icons.grid_view_rounded,
                        size: 13,
                        color: isSelected ? accentGold : textSecondary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : textPrimary,
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentGold.withValues(alpha: 0.22)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected ? accentGold : textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==============================
  // 📊 RESULTS SUMMARY ROW
  // ==============================
  Widget _buildResultsSummary() {
    final list = _filteredFaqs;
    final bool hasFilter = _selectedCategory != 'Semua' || _searchQuery.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: accentGold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Menampilkan ${list.length} dari ${_allFaqs.length} pertanyaan',
            style: const TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hasFilter) ...[
            const Spacer(),
            InkWell(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'Semua';
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 12, color: primaryNavy),
                    SizedBox(width: 4),
                    Text(
                      'Reset Filter',
                      style: TextStyle(
                        color: primaryNavy,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==============================
  // 📖 BODY LIST / EMPTY / ERROR
  // ==============================
  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                strokeWidth: 3.2,
                valueColor: const AlwaysStoppedAnimation<Color>(accentGold),
                backgroundColor: primaryNavy.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Memuat Pusat Bantuan...',
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: errorRed.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: errorRed.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: errorRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: errorRed,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Gagal Memuat FAQ',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Coba Lagi',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  onPressed: _loadFaqs,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final list = _filteredFaqs;

    // EMPTY SEARCH RESULTS OR CATEGORY STATE
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFaqs,
        color: primaryNavy,
        backgroundColor: Colors.white,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryNavy.withValues(alpha: 0.08),
                      accentGold.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentGold.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.search_off_rounded,
                    color: primaryNavy,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Pertanyaan Tidak Ditemukan'
                  : 'Belum Ada Pertanyaan',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ada pertanyaan atau panduan yang cocok dengan kata kunci "$_searchQuery".'
                  : 'Belum ada data FAQ untuk kategori "$_selectedCategory".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Silakan periksa ejaan kata kunci atau ganti filter kategori.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = 'Semua';
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                label: const Text(
                  'Reset Pencarian',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  elevation: 3,
                  shadowColor: primaryNavy.withValues(alpha: 0.35),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // LIST VIEW OF ACCORDION ITEMS
    return RefreshIndicator(
      onRefresh: _loadFaqs,
      color: primaryNavy,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          final catColor = _getCategoryColor(item.category);
          final catIcon = _getCategoryIcon(item.category);

          return _FaqAccordionCard(
            key: ValueKey(item.id),
            item: item,
            index: index,
            searchQuery: _searchQuery,
            categoryColor: catColor,
            categoryIcon: catIcon,
          );
        },
      ),
    );
  }
}

// ==========================================
// 📌 FAQ ITEM ACCORDION CARD WITH ANIMATION
// ==========================================
class _FaqAccordionCard extends StatefulWidget {
  final FaqItem item;
  final int index;
  final String searchQuery;
  final Color categoryColor;
  final IconData categoryIcon;

  const _FaqAccordionCard({
    super.key,
    required this.item,
    required this.index,
    required this.searchQuery,
    required this.categoryColor,
    required this.categoryIcon,
  });

  @override
  State<_FaqAccordionCard> createState() => _FaqAccordionCardState();
}

class _FaqAccordionCardState extends State<_FaqAccordionCard> {
  static const Color primaryDark = Color(0xFF0D1523);
  static const Color primaryNavy = Color(0xFF1B3167);
  static const Color accentGold = Color(0xFFEAB308);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);

  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded
              ? accentGold.withValues(alpha: 0.65)
              : borderLight,
          width: _isExpanded ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isExpanded
                ? primaryNavy.withValues(alpha: 0.08)
                : const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: _isExpanded ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TAPPABLE HEADER SECTION
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number Badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _isExpanded
                            ? primaryNavy
                            : widget.categoryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.index + 1}'.padLeft(2, '0'),
                          style: TextStyle(
                            color: _isExpanded ? accentGold : widget.categoryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Category Pill & Question Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: widget.categoryColor.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: widget.categoryColor.withValues(alpha: 0.22),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.categoryIcon,
                                  size: 10,
                                  color: widget.categoryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.item.category.toUpperCase(),
                                  style: TextStyle(
                                    color: widget.categoryColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Question with Search Highlight
                          _buildHighlightedText(
                            text: widget.item.question,
                            query: widget.searchQuery,
                            baseStyle: const TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                            highlightStyle: TextStyle(
                              color: primaryDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              backgroundColor: accentGold.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Rotating Smooth Chevron Icon
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeInOut,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _isExpanded
                              ? accentGold.withValues(alpha: 0.16)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _isExpanded ? const Color(0xFFB45309) : textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ANIMATED EXPANDED CONTENT BODY
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderLight),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Accent Stripe in Gold
                        Container(
                          width: 4,
                          color: accentGold,
                        ),

                        // Answer Text & Action Toolbar
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Subtitle Header
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.lightbulb_outline_rounded,
                                      size: 14,
                                      color: accentGold,
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'PANDUAN OPERASIONAL',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: primaryNavy,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Highlighted Answer Content
                                _buildHighlightedText(
                                  text: widget.item.answer,
                                  query: widget.searchQuery,
                                  baseStyle: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 13,
                                    height: 1.65,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  highlightStyle: TextStyle(
                                    color: primaryDark,
                                    fontSize: 13,
                                    height: 1.65,
                                    fontWeight: FontWeight.w700,
                                    backgroundColor: accentGold.withValues(alpha: 0.32),
                                  ),
                                  isSelectable: true,
                                ),

                                const SizedBox(height: 12),
                                const Divider(color: borderLight, height: 1),
                                const SizedBox(height: 10),

                                // Action Buttons (Copy Answer)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(
                                            text: '${widget.item.question}\n\n${widget.item.answer}',
                                          ));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Row(
                                                children: [
                                                  Icon(
                                                    Icons.check_circle_rounded,
                                                    color: accentGold,
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      'Jawaban FAQ disalin ke clipboard',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: primaryDark,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: borderLight),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.02),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.copy_rounded,
                                                size: 13,
                                                color: primaryNavy,
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                'Salin Jawaban',
                                                style: TextStyle(
                                                  color: primaryNavy,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 240),
          ),
        ],
      ),
    );
  }

  // Text highlighting utility
  Widget _buildHighlightedText({
    required String text,
    required String query,
    required TextStyle baseStyle,
    required TextStyle highlightStyle,
    bool isSelectable = false,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty || !text.toLowerCase().contains(cleanQuery)) {
      if (isSelectable) {
        return SelectableText(text, style: baseStyle);
      }
      return Text(text, style: baseStyle);
    }

    final List<TextSpan> spans = [];
    int start = 0;
    final lowerText = text.toLowerCase();

    while (start < text.length) {
      final matchIndex = lowerText.indexOf(cleanQuery, start);
      if (matchIndex == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }

      if (matchIndex > start) {
        spans.add(TextSpan(text: text.substring(start, matchIndex), style: baseStyle));
      }

      final matchEnd = matchIndex + cleanQuery.length;
      spans.add(TextSpan(
        text: text.substring(matchIndex, matchEnd),
        style: highlightStyle,
      ));

      start = matchEnd;
    }

    if (isSelectable) {
      return SelectableText.rich(TextSpan(children: spans));
    }
    return Text.rich(TextSpan(children: spans));
  }
}

// =======================================================
// 📐 SUBTLE GEOMETRIC ISLAMIC ARABESQUE PATTERN PAINTER
// =======================================================
class _IslamicGeometricPatternPainter extends CustomPainter {
  const _IslamicGeometricPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFFEAB308).withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..style = PaintingStyle.fill;

    const double spacing = 64.0;
    final int cols = (size.width / spacing).ceil() + 2;
    final int rows = (size.height / spacing).ceil() + 2;

    for (int i = -1; i < cols; i++) {
      for (int j = -1; j < rows; j++) {
        final cx = i * spacing + (j % 2 == 0 ? 0 : spacing / 2);
        final cy = j * spacing;

        canvas.save();
        canvas.translate(cx, cy);

        // 8-Pointed Star (Rub el Hizb) using two intersecting 45-degree squares
        const double halfSide = 12.0;
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: halfSide * 2,
          height: halfSide * 2,
        );

        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, strokePaint);

        canvas.rotate(0.785398); // 45 degrees in radians
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, strokePaint);

        // Inner decorative circle
        canvas.drawCircle(Offset.zero, 5.0, strokePaint);

        canvas.restore();

        // Small inter-star connector dot
        canvas.drawCircle(
          Offset(cx + spacing / 2, cy + spacing / 2),
          1.5,
          strokePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
