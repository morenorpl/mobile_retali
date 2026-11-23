import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/tugas_service.dart';
import '../../models/checklist_models.dart';
import 'checklist_detail_screen.dart';
import 'dart:async';

class ChecklistListScreen extends StatefulWidget {
  const ChecklistListScreen({super.key});

  @override
  State<ChecklistListScreen> createState() => _ChecklistListScreenState();
}

class _ChecklistListScreenState extends State<ChecklistListScreen> {
  late Future<List<ChecklistSummary>> _future;
  List<ChecklistSummary> _items = [];
  Timer? _timer;
  bool _isFirstLoad = true;
  int _selectedFilter = 0; // 0: Semua, 1: Belum Selesai, 2: Selesai

  // Retali-Sistem Palette (Navy & Gold)
  static const Color primaryDark = Color(0xFF0D1523);
  static const Color primaryNavy = Color(0xFF1B3167);
  static const Color secondaryNavy = Color(0xFF263754);
  static const Color accentGold = Color(0xFFEAB308);
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================
  // 🔄 SILENT AUTO REFRESH (REALTIME)
  // ============================================
  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) return;

      try {
        final newData = await TugasService.getChecklistList();

        // Hanya update UI jika ada data yang beneran berubah
        if (_hasDataChanged(newData)) {
          debugPrint('📝 Data checklist berubah, mengupdate UI...');
          setState(() {
            _items = newData;
            // Penting: Pake Future.value biar FutureBuilder nggak loading lagi
            _future = Future.value(newData);
          });
        }
      } catch (e) {
        debugPrint('⏱️ Auto-refresh error (checklist): $e');
      }
    });
  }

  bool _hasDataChanged(List<ChecklistSummary> newData) {
    if (_items.isEmpty && newData.isEmpty) return false;
    if (_items.length != newData.length) return true;

    for (int i = 0; i < newData.length; i++) {
      final newItem = newData[i];
      // Cari item lama berdasarkan ID
      final oldItem = _items.firstWhere(
        (t) => t.id == newItem.id,
        orElse: () => _items[i],
      );

      if (newItem.status != oldItem.status) return true;
      if (newItem.submitted != oldItem.submitted) return true;

      // Cek perubahan waktu selesai secara presisi
      if (newItem.doneAt?.millisecondsSinceEpoch !=
          oldItem.doneAt?.millisecondsSinceEpoch) {
        return true;
      }
    }
    return false;
  }

  Future<List<ChecklistSummary>> _loadData() async {
    try {
      final data = await TugasService.getChecklistList();
      _items = data;
      _isFirstLoad = false;
      return data;
    } catch (e) {
      _isFirstLoad = false;
      debugPrint('❌ ERR LOAD CHECKLIST: $e');
      return _items;
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = _loadData();
    });
  }

  Future<void> _openDetail(ChecklistSummary item) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChecklistDetailScreen(
          checklistId: item.id,
          title: item.title,
          summary: item,
        ),
      ),
    );

    if (changed == true) {
      // OPTIMISTIC UI: Langsung update status selesai
      setState(() {
        final idx = _items.indexWhere((t) => t.id == item.id);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(
            doneAt: DateTime.now(),
          );
        }
        _future = Future.value(_items);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Checklist berhasil diselesaikan 🎉',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Trigger refresh data asli dari server
      _loadData();
    }
  }

  List<ChecklistSummary> get _filteredItems {
    switch (_selectedFilter) {
      case 1:
        return _items.where((t) => !t.submitted).toList();
      case 2:
        return _items.where((t) => t.submitted).toList();
      case 0:
      default:
        return _items;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar Checklist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Monitoring Ibadah Zero Complaint',
              style: TextStyle(
                color: textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat Ulang',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
            ),
            onPressed: _reload,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<ChecklistSummary>>(
        future: _future,
        builder: (context, snapshot) {
          // Loading pertama kali
          if (snapshot.connectionState == ConnectionState.waiting && _isFirstLoad) {
            return _buildLoadingState();
          }

          // Error dan tidak ada cache data
          if (snapshot.hasError && _items.isEmpty) {
            return _buildErrorState();
          }

          final totalCount = _items.length;
          final completedCount = _items.where((t) => t.submitted).length;
          final pendingCount = totalCount - completedCount;
          final displayList = _filteredItems;

          return RefreshIndicator(
            color: primaryNavy,
            backgroundColor: surface,
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Overview Progress Header Card
                SliverToBoxAdapter(
                  child: _buildHeaderProgress(totalCount, completedCount, pendingCount),
                ),

                // 2. Filter Tabs
                SliverToBoxAdapter(
                  child: _buildFilterTabs(totalCount, pendingCount, completedCount),
                ),

                // 3. Content List or Empty State
                if (displayList.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(totalCount == 0),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = displayList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ChecklistCard(
                              data: item,
                              onTap: () => _openDetail(item),
                              onKerjakan: item.canWork ? () => _openDetail(item) : null,
                            ),
                          );
                        },
                        childCount: displayList.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 🌟 OVERVIEW PROGRESS HEADER
  // ===========================================================================
  Widget _buildHeaderProgress(int total, int completed, int pending) {
    final double progress = total > 0 ? (completed / total) : 0.0;
    final int percent = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryDark,
            primaryNavy,
            secondaryNavy,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient circles for luxury touch
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentGold.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag & Realtime badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentGold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accentGold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: accentGold,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'ZERO COMPLAINT CHECKLIST',
                            style: TextStyle(
                              color: accentGold,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Live Sync',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Progress Stats
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Progres Penyelesaian',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            total == 0
                                ? 'Belum ada data checklist'
                                : percent == 100
                                    ? 'Alhamdulillah, semua checklist tuntas! 🎉'
                                    : '$completed dari $total tugas telah diselesaikan',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: total > 0 ? progress : 0,
                              minHeight: 6,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percent == 100 ? success : accentGold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),

                    // Circular Progress Dial
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: total > 0 ? progress : 0,
                            strokeWidth: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              percent == 100 ? success : accentGold,
                            ),
                          ),
                        ),
                        if (percent == 100 && total > 0)
                          const Icon(
                            Icons.check_rounded,
                            color: success,
                            size: 26,
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$percent',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                '%',
                                style: TextStyle(
                                  color: accentGold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bottom Counters Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderMiniStat('Total', '$total', Icons.fact_check_outlined, Colors.white),
                      Container(width: 1, height: 22, color: Colors.white.withValues(alpha: 0.15)),
                      _buildHeaderMiniStat('Belum Selesai', '$pending', Icons.hourglass_empty_rounded, accentGold),
                      Container(width: 1, height: 22, color: Colors.white.withValues(alpha: 0.15)),
                      _buildHeaderMiniStat('Selesai', '$completed', Icons.check_circle_rounded, success),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMiniStat(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 🏷️ FILTER TABS (Semua, Belum Selesai, Selesai)
  // ===========================================================================
  Widget _buildFilterTabs(int total, int pending, int completed) {
    final tabs = [
      {'title': 'Semua', 'count': total},
      {'title': 'Belum Selesai', 'count': pending},
      {'title': 'Selesai', 'count': completed},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: textPrimary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedFilter == index;
          final tab = tabs[index];
          final title = tab['title'] as String;
          final count = tab['count'] as int;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedFilter != index) {
                  setState(() {
                    _selectedFilter = index;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? primaryNavy : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryNavy.withValues(alpha: 0.22),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.white : textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? accentGold : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? primaryDark : textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // ⏳ LOADING STATE
  // ===========================================================================
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: primaryNavy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryNavy),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Memuat Checklist...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sinkronisasi tugas & pemantauan ibadah jamaah',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ⚠️ ERROR STATE
  // ===========================================================================
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: errorRed,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Gagal Memuat Checklist',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Terjadi kendala saat mengambil data checklist. Silakan periksa koneksi internet Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 📭 EMPTY STATE
  // ===========================================================================
  Widget _buildEmptyState(bool isTotalEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: isTotalEmpty
                    ? primaryNavy.withValues(alpha: 0.08)
                    : success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTotalEmpty
                    ? Icons.checklist_rtl_rounded
                    : Icons.task_alt_rounded,
                size: 38,
                color: isTotalEmpty ? primaryNavy : success,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isTotalEmpty
                  ? 'Belum Ada Checklist'
                  : _selectedFilter == 1
                      ? 'Semua Checklist Selesai! 🎉'
                      : 'Belum Ada Checklist Selesai',
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isTotalEmpty
                  ? 'Saat ini belum ada tugas checklist yang dijadwalkan.'
                  : _selectedFilter == 1
                      ? 'MasyaAllah, seluruh checklist telah dikerjakan dengan tuntas.'
                      : 'Belum ada checklist yang selesai dikerjakan pada tab ini.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            if (!isTotalEmpty)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedFilter = 0;
                  });
                },
                icon: const Icon(Icons.list_alt_rounded, size: 18),
                label: const Text('Tampilkan Semua'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryNavy,
                  side: const BorderSide(color: primaryNavy),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Segarkan Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 🗂️ CHECKLIST CARD COMPONENT
// =============================================================================
class _ChecklistCard extends StatelessWidget {
  final ChecklistSummary data;
  final VoidCallback? onKerjakan;
  final VoidCallback? onTap;

  const _ChecklistCard({
    required this.data,
    this.onKerjakan,
    this.onTap,
  });

  // Retali-Sistem Palette
  static const Color primaryNavy = Color(0xFF1B3167);
  static const Color secondaryNavy = Color(0xFF263754);
  static const Color accentGold = Color(0xFFEAB308);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  String _formatDate(DateTime date) {
    try {
      return DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('d MMM yyyy, HH:mm').format(date);
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    try {
      final startDay = DateFormat('d MMM yyyy', 'id_ID').format(start);
      final endDay = DateFormat('d MMM yyyy', 'id_ID').format(end);
      final startTime = DateFormat('HH:mm', 'id_ID').format(start);
      final endTime = DateFormat('HH:mm', 'id_ID').format(end);

      if (startDay == endDay) {
        return '$startDay • $startTime - $endTime WIB';
      } else {
        return '$startDay $startTime - $endDay $endTime WIB';
      }
    } catch (_) {
      return '${DateFormat('d MMM, HH:mm').format(start)} - ${DateFormat('d MMM, HH:mm').format(end)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Status Waktu
    String waktuLabel;
    Color waktuColor;
    Color waktuBg;
    Color waktuBorder;
    IconData waktuIcon;

    if (data.status == 'belum_dibuka') {
      waktuLabel = 'Belum Dibuka';
      waktuColor = warning;
      waktuBg = const Color(0xFFFFFBEB);
      waktuBorder = const Color(0xFFFDE68A);
      waktuIcon = Icons.schedule_rounded;
    } else if (data.status == 'ditutup') {
      waktuLabel = 'Sudah Ditutup';
      waktuColor = errorRed;
      waktuBg = const Color(0xFFFEF2F2);
      waktuBorder = const Color(0xFFFECACA);
      waktuIcon = Icons.lock_clock_rounded;
    } else {
      waktuLabel = 'Sedang Dibuka';
      waktuColor = const Color(0xFF059669);
      waktuBg = const Color(0xFFECFDF5);
      waktuBorder = const Color(0xFFA7F3D0);
      waktuIcon = Icons.lock_open_rounded;
    }

    // 2. Status Kerja
    final bool isSubmitted = data.submitted;
    final String kerjaLabel = isSubmitted ? 'Selesai' : 'Belum Selesai';
    final Color kerjaColor = isSubmitted ? success : textSecondary;
    final Color kerjaBg = isSubmitted ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9);
    final Color kerjaBorder = isSubmitted ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0);
    final IconData kerjaIcon = isSubmitted ? Icons.check_circle_rounded : Icons.pending_actions_rounded;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSubmitted ? success.withValues(alpha: 0.25) : border,
          width: isSubmitted ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: textPrimary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Badges and Completion Checkbox/Icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Badges
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildBadge(waktuLabel, waktuColor, waktuBg, waktuBorder, waktuIcon),
                          _buildBadge(kerjaLabel, kerjaColor, kerjaBg, kerjaBorder, kerjaIcon),
                        ],
                      ),
                    ),

                    // Completion Checkbox with animated touch
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSubmitted
                            ? success
                            : data.canWork
                                ? accentGold.withValues(alpha: 0.12)
                                : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSubmitted
                              ? success
                              : data.canWork
                                  ? accentGold
                                  : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                        boxShadow: isSubmitted
                            ? [
                                BoxShadow(
                                  color: success.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isSubmitted
                            ? Icons.check_rounded
                            : data.canWork
                                ? Icons.edit_note_rounded
                                : Icons.lock_outline_rounded,
                        color: isSubmitted
                            ? Colors.white
                            : data.canWork
                                ? accentGold
                                : const Color(0xFF94A3B8),
                        size: isSubmitted ? 18 : 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSubmitted ? success : primaryNavy,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          height: 1.35,
                          letterSpacing: -0.2,
                          decoration: isSubmitted ? TextDecoration.none : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Schedule and Completion Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              size: 14,
                              color: primaryNavy,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Jadwal Pengisian',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _formatDateRange(data.opensAt, data.closesAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (data.doneAt != null) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: border),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.task_alt_rounded,
                                size: 14,
                                color: success,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Diselesaikan Pada',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: success,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    _formatDate(data.doneAt!),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Button or Result Row
                if (data.canWork && onKerjakan != null)
                  Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [primaryNavy, secondaryNavy],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryNavy.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: onKerjakan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note_rounded, size: 20, color: accentGold),
                          SizedBox(width: 8),
                          Text(
                            'Kerjakan Checklist',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white70),
                        ],
                      ),
                    ),
                  )
                else if (isSubmitted)
                  Container(
                    width: double.infinity,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: onTap,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility_outlined, size: 17, color: primaryNavy),
                            SizedBox(width: 8),
                            Text(
                              'Lihat Detail Jawaban',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryNavy,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded, size: 18, color: primaryNavy),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (data.status == 'belum_dibuka')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_clock_rounded, size: 15, color: Color(0xFFD97706)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Belum dapat diisi (menunggu jadwal dibuka)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (data.status == 'ditutup')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cancel_outlined, size: 15, color: errorRed),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Waktu pengisian checklist telah ditutup',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color textColor, Color bgColor, Color borderColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: textColor),
          const SizedBox(width: 4.5),
          Text(
            text,
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
}
