import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/curriculum_materi.dart';
import '../services/curriculum_service.dart';

class CurriculumTourLeaderScreen extends StatefulWidget {
  const CurriculumTourLeaderScreen({super.key});

  @override
  State<CurriculumTourLeaderScreen> createState() =>
      _CurriculumTourLeaderScreenState();
}

class _CurriculumTourLeaderScreenState extends State<CurriculumTourLeaderScreen> {
  // Retali-Sistem Navy & Gold Design Palette
  static const Color primaryDark = Color(0xFF0D1523);
  static const Color primaryNavy = Color(0xFF1B3167);
  static const Color secondaryNavy = Color(0xFF263754);
  static const Color accentGold = Color(0xFFEAB308);
  static const Color surfaceWhite = Colors.white;
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);

  late Future<List<CurriculumMateri>> _future;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _future = CurriculumService.getCurriculums();
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
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  String _estimateReadingTime(String text) {
    final words = text.trim().split(RegExp(r'\s+')).length;
    final minutes = (words / 150).ceil();
    if (minutes <= 1) return '1 mnt baca';
    return '$minutes mnt baca';
  }

  Future<void> _launchAttachment(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan lampiran tidak valid.'),
          backgroundColor: errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka tautan lampiran.'),
            backgroundColor: errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat membuka tautan: $e'),
            backgroundColor: errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _shareMateri(CurriculumMateri item, String cleanDesc, String cleanContent) async {
    final shareBuffer = StringBuffer();
    shareBuffer.writeln('📚 KURIKULUM TOUR LEADER - RETALI');
    shareBuffer.writeln(item.title);
    if (item.subTitle != null && item.subTitle!.trim().isNotEmpty) {
      shareBuffer.writeln(item.subTitle!.trim());
    }
    shareBuffer.writeln('-----------------------------------');
    if (cleanDesc.isNotEmpty) {
      shareBuffer.writeln('\n[Ringkasan]:\n$cleanDesc');
    }
    if (cleanContent.isNotEmpty) {
      shareBuffer.writeln('\n[Materi Lengkap]:\n$cleanContent');
    }
    if (item.attachmentUrl != null && item.attachmentUrl!.trim().isNotEmpty) {
      shareBuffer.writeln('\n[Lampiran]:\n${item.attachmentUrl!.trim()}');
    }
    shareBuffer.writeln('\nRetali Sistem Zero Complaint');

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareBuffer.toString(),
          subject: 'Kurikulum TL: ${item.title}',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing curriculum: $e');
    }
  }

  Future<void> _copyMateri(BuildContext context, CurriculumMateri item, String cleanDesc, String cleanContent) async {
    final copyBuffer = StringBuffer();
    copyBuffer.writeln(item.title);
    if (item.subTitle != null && item.subTitle!.trim().isNotEmpty) {
      copyBuffer.writeln(item.subTitle!.trim());
    }
    copyBuffer.writeln('');
    if (cleanDesc.isNotEmpty) {
      copyBuffer.writeln(cleanDesc);
      copyBuffer.writeln('');
    }
    if (cleanContent.isNotEmpty) {
      copyBuffer.writeln(cleanContent);
    }
    if (item.attachmentUrl != null && item.attachmentUrl!.trim().isNotEmpty) {
      copyBuffer.writeln('\nLampiran: ${item.attachmentUrl!.trim()}');
    }

    await Clipboard.setData(ClipboardData(text: copyBuffer.toString().trim()));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Materi kurikulum berhasil disalin ke clipboard.',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDetailDialog(BuildContext context, CurriculumMateri item) {
    final cleanDesc = _stripHtml(item.description);
    final cleanContent = _stripHtml(item.content);
    final readTime = _estimateReadingTime('$cleanDesc $cleanContent');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 🟡 TOP DRAG HANDLE & ACTIONS BAR
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: surfaceWhite,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: borderLight.withValues(alpha: 0.7),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Drag Indicator Pill
                        Center(
                          child: Container(
                            width: 44,
                            height: 4.5,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: borderLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        // Bar with Badges and Close button
                        Row(
                          children: [
                            // Category / Module Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: primaryNavy.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: primaryNavy.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.school_rounded,
                                    size: 14,
                                    color: primaryNavy,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.category.toUpperCase(),
                                    style: const TextStyle(
                                      color: primaryNavy,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Read time badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: backgroundSlate,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: borderLight,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    readTime,
                                    style: const TextStyle(
                                      color: textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Copy Action
                            IconButton(
                              onPressed: () => _copyMateri(sheetContext, item, cleanDesc, cleanContent),
                              tooltip: 'Salin Materi',
                              icon: const Icon(
                                Icons.copy_rounded,
                                size: 19,
                                color: primaryNavy,
                              ),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(7),
                              style: IconButton.styleFrom(
                                backgroundColor: primaryNavy.withValues(alpha: 0.06),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Share Action
                            IconButton(
                              onPressed: () => _shareMateri(item, cleanDesc, cleanContent),
                              tooltip: 'Bagikan',
                              icon: const Icon(
                                Icons.share_rounded,
                                size: 19,
                                color: secondaryNavy,
                              ),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(7),
                              style: IconButton.styleFrom(
                                backgroundColor: primaryNavy.withValues(alpha: 0.06),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Close Action
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              tooltip: 'Tutup',
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: textSecondary,
                              ),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(7),
                              style: IconButton.styleFrom(
                                backgroundColor: backgroundSlate,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 📜 MAIN READING CONTENT BODY
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with Accent Bar
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 4.5,
                                height: 26,
                                margin: const EdgeInsets.only(top: 2, right: 10),
                                decoration: BoxDecoration(
                                  color: accentGold,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    height: 1.3,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Subtitle if available
                          if (item.subTitle != null && item.subTitle!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: backgroundSlate,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderLight),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.bookmark_border_rounded,
                                    color: accentGold,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.subTitle!.trim(),
                                      style: const TextStyle(
                                        color: primaryNavy,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          // Status indicator chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: item.isPublished
                                  ? successGreen.withValues(alpha: 0.08)
                                  : warningAmber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: item.isPublished
                                    ? successGreen.withValues(alpha: 0.25)
                                    : warningAmber.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.isPublished
                                      ? Icons.verified_rounded
                                      : Icons.schedule_rounded,
                                  color: item.isPublished ? successGreen : warningAmber,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.isPublished
                                      ? 'Standar Operasional Resmi Tour Leader Retali'
                                      : 'Draf Modul (Dalam Peninjauan)',
                                  style: TextStyle(
                                    color: item.isPublished ? successGreen : warningAmber,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 📌 SECTION 1: Ringkasan / Deskripsi Modul
                          if (cleanDesc.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: primaryNavy.withValues(alpha: 0.035),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: primaryNavy.withValues(alpha: 0.12),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: primaryNavy,
                                        size: 17,
                                      ),
                                      SizedBox(width: 7),
                                      Text(
                                        'Ringkasan & Tujuan Materi',
                                        style: TextStyle(
                                          color: primaryNavy,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SelectableText(
                                    cleanDesc,
                                    style: const TextStyle(
                                      color: textPrimary,
                                      fontSize: 14,
                                      height: 1.6,
                                      letterSpacing: 0.15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // 📖 SECTION 2: Isi Lengkap Materi
                          if (cleanContent.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: accentGold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.article_outlined,
                                    color: accentGold,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Panduan & Prosedur Lengkap',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderLight),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryDark.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: SelectableText(
                                cleanContent,
                                style: const TextStyle(
                                  color: textPrimary,
                                  fontSize: 14.5,
                                  height: 1.68,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // If both desc and content are empty
                          if (cleanDesc.isEmpty && cleanContent.isEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 24,
                              ),
                              decoration: BoxDecoration(
                                color: backgroundSlate,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderLight),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.menu_book_outlined,
                                    size: 38,
                                    color: textMuted,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tidak ada rincian deskripsi tambahan untuk materi ini.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // 📎 SECTION 3: Lampiran / Dokumen Pendukung (jika ada)
                          if (item.attachmentUrl != null &&
                              item.attachmentUrl!.trim().isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: accentGold.withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentGold.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: accentGold.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.attachment_rounded,
                                      color: primaryDark,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Dokumen Pendukung / Lampiran',
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.attachmentUrl!.trim(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: textSecondary,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _launchAttachment(
                                      sheetContext,
                                      item.attachmentUrl!,
                                    ),
                                    icon: const Icon(
                                      Icons.open_in_new_rounded,
                                      size: 15,
                                    ),
                                    label: const Text('Buka'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryNavy,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Bottom Close Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textSecondary,
                                side: const BorderSide(color: borderLight),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Tutup Materi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
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
      },
    );
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
        backgroundColor: backgroundSlate,
        body: Column(
          children: [
            // 🕌 HERO APP BAR WITH NAVY GRADIENT & SEARCH
            _buildHeroHeader(context),

            // 📋 MAIN CURRICULUM LIST
            Expanded(
              child: RefreshIndicator(
                color: primaryNavy,
                backgroundColor: surfaceWhite,
                onRefresh: _refresh,
                child: FutureBuilder<List<CurriculumMateri>>(
                  future: _future,
                  builder: (context, snapshot) {
                    // 1. Loading State
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    // 2. Error State
                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }

                    final allList = snapshot.data ?? [];

                    // Filter list by search query if any
                    final query = _searchQuery.toLowerCase().trim();
                    final filteredList = allList.where((item) {
                      if (query.isEmpty) return true;
                      final title = item.title.toLowerCase();
                      final sub = (item.subTitle ?? '').toLowerCase();
                      final desc = (item.description ?? '').toLowerCase();
                      final content = (item.content ?? '').toLowerCase();
                      final cat = item.category.toLowerCase();
                      return title.contains(query) ||
                          sub.contains(query) ||
                          desc.contains(query) ||
                          content.contains(query) ||
                          cat.contains(query);
                    }).toList();

                    // 3. Empty Data State (No data in DB)
                    if (allList.isEmpty) {
                      return _buildEmptyState();
                    }

                    // 4. No Search Results State
                    if (filteredList.isEmpty) {
                      return _buildNoSearchResultsState();
                    }

                    // 5. Success Content List
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        // Results summary / subheader counter
                        _buildSectionSummary(filteredList.length, allList.length),

                        const SizedBox(height: 12),

                        // Materi Cards List
                        ...filteredList.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildCurriculumCard(context, item, index),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =======================================================
  // 🕌 HERO HEADER WITH NAVY GRADIENT & ISLAMIC ARABESQUE
  // =======================================================
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
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Islamic Geometric Pattern Overlay
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
                // Top Navigation Bar
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

                    // Title & App Subtitle
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
                                'Curriculum Tour Leader',
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

                    // Quick Refresh Button
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _refresh,
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Introduction Banner Inside Header
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentGold.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: accentGold,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Standar Operasional Tour Leader',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Panduan resmi pelaksanaan tugas, handling jamaah, & SOP di Tanah Suci',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 🔍 Modern Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: surfaceWhite,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari materi atau SOP tour leader...',
                      hintStyle: const TextStyle(
                        color: textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: primaryNavy,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: textSecondary,
                                size: 18,
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
                        horizontal: 14,
                        vertical: 12,
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

  // =======================================================
  // 🏷️ SUMMARY BAR / RESULT COUNTER
  // =======================================================
  Widget _buildSectionSummary(int filteredCount, int totalCount) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 14,
          decoration: BoxDecoration(
            color: accentGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _searchQuery.isEmpty
              ? 'Daftar Modul Pembelajaran'
              : 'Hasil Pencarian ($filteredCount)',
          style: const TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: primaryNavy.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$filteredCount dari $totalCount Modul',
            style: const TextStyle(
              color: primaryNavy,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // =======================================================
  // 📚 CURRICULUM MATERI CARD (Modern 18px Radius & Gold touches)
  // =======================================================
  Widget _buildCurriculumCard(
    BuildContext context,
    CurriculumMateri item,
    int index,
  ) {
    final moduleNumber = (index + 1).toString().padLeft(2, '0');
    final cleanDesc = _stripHtml(item.description);
    final cleanContent = _stripHtml(item.content);
    final excerpt = cleanDesc.isNotEmpty
        ? cleanDesc
        : (cleanContent.isNotEmpty ? cleanContent : 'Tidak ada ringkasan materi.');
    final readTime = _estimateReadingTime('$cleanDesc $cleanContent');

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderLight,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDetailDialog(context, item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta Row: Module Badge + Category + Read time
                Row(
                  children: [
                    // Module Number Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryNavy,
                            secondaryNavy,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: primaryNavy.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'MODUL $moduleNumber',
                        style: const TextStyle(
                          color: accentGold,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Category Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: backgroundSlate,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderLight),
                      ),
                      child: Text(
                        item.category.toUpperCase(),
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Read Time Chip
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          readTime,
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    height: 1.32,
                    letterSpacing: -0.2,
                  ),
                ),

                // Subtitle if available
                if (item.subTitle != null && item.subTitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.subTitle!.trim(),
                    style: const TextStyle(
                      color: primaryNavy,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Clean Excerpt
                Text(
                  excerpt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 14),

                // Card Footer: Attachment icon + "Baca Materi" Button
                Row(
                  children: [
                    // Attachment badge if present
                    if (item.attachmentUrl != null &&
                        item.attachmentUrl!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: accentGold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.attachment_rounded,
                              size: 13,
                              color: primaryDark,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Lampiran PDF/File',
                              style: TextStyle(
                                color: primaryDark,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(),

                    // Read More Call-To-Action Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryNavy.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryNavy.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Pelajari Modul',
                            style: TextStyle(
                              color: primaryNavy,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: primaryNavy,
                          ),
                        ],
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

  // =======================================================
  // ⌛ LOADING STATE
  // =======================================================
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryDark.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: primaryNavy,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Memuat Kurikulum Tour Leader...',
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sinkronisasi standar operasional retali',
              style: TextStyle(
                color: textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =======================================================
  // ⚠️ ERROR STATE
  // =======================================================
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderLight),
            boxShadow: [
              BoxShadow(
                color: primaryDark.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: errorRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 42,
                  color: errorRed,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal Memuat Kurikulum',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Terjadi kendala saat menyinkronkan data materi kurikulum tour leader:\n$errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Coba Lagi',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =======================================================
  // 📭 EMPTY DATABASE STATE
  // =======================================================
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: primaryNavy.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryNavy.withValues(alpha: 0.12),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 54,
                color: primaryNavy,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum Ada Materi Kurikulum',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Materi standar operasional & kurikulum tour leader akan ditampilkan di sini setelah dipublikasikan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryNavy,
                side: const BorderSide(color: primaryNavy, width: 1.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Perbarui Data',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =======================================================
  // 🔍 NO SEARCH RESULTS STATE
  // =======================================================
  Widget _buildNoSearchResultsState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: backgroundSlate,
                shape: BoxShape.circle,
                border: Border.all(color: borderLight),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 46,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Modul Tidak Ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ada modul kurikulum yang cocok dengan "$_searchQuery". Silakan gunakan kata kunci lain.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.clear_rounded, size: 17),
              label: const Text(
                'Reset Pencarian',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: primaryNavy,
              ),
            ),
          ],
        ),
      ),
    );
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
