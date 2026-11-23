import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_retali/models/itinerary_models.dart';
import 'package:mobile_retali/screens/itinerary/itinerary_detail_page.dart';
import 'package:mobile_retali/screens/itinerary/itinerary_widgets.dart';
import 'package:mobile_retali/services/itinerary_service.dart';

class ItineraryListPage extends StatefulWidget {
  const ItineraryListPage({super.key});

  @override
  State<ItineraryListPage> createState() => _ItineraryListPageState();
}

class _ItineraryListPageState extends State<ItineraryListPage> {
  late Future<({List<Itinerary> data, int? nextPage})> _future;
  late ItineraryService _service;
  List<Itinerary> _items = [];
  Timer? _timer;
  bool _isFirstLoad = true;
  int _selectedFilter = 0; // 0: Semua, 1: Aktif, 2: Mendatang, 3: Selesai

  // ============================================
  // 🎨 RETALI-SISTEM THEME (NAVY & GOLD PALETTE)
  // ============================================
  static const Color primaryDark = Color(0xFF0D1523);
  static const Color primaryNavy = AppTheme.brand; // Color(0xFF1B3167)
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
  static const Color warning = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();

    _service = ItineraryService.forTourLeader();
    _loadInitialData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================
  // 🔄 SILENT AUTO REFRESH (REALTIME Tanpa Flicker)
  // ============================================
  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) return;

      try {
        final result = await _service.list();

        // Hanya panggil setState jika data benar-benar berubah
        if (_hasDataChanged(_items, result.data)) {
          setState(() {
            _items = result.data;
            // Update future dengan Future.value agar FutureBuilder tidak masuk mode 'waiting'
            _future = Future.value(result);
          });
          debugPrint('🔔 Itinerary updated in background');
        }
      } catch (e) {
        debugPrint('⏱️ Itinerary silent refresh error: $e');
      }
    });
  }

  bool _hasDataChanged(List<Itinerary> oldList, List<Itinerary> newList) {
    if (oldList.length != newList.length) return true;

    for (int i = 0; i < newList.length; i++) {
      final n = newList[i];
      // Cari data lama berdasarkan ID (antisipasi jika urutan berubah)
      final o = oldList.firstWhere((item) => item.id == n.id, orElse: () => n);

      if (n.title != o.title) return true;
      if (n.startDate != o.startDate) return true;
      if (n.endDate != o.endDate) return true;
      if (n.daysCount != o.daysCount) return true;
      if (n.tourLeader != o.tourLeader) return true;
    }
    return false;
  }

  void _loadInitialData() {
    setState(() {
      _future = _loadData();
    });
  }

  Future<({List<Itinerary> data, int? nextPage})> _loadData() async {
    try {
      final result = await _service.list();
      _items = result.data;
      _isFirstLoad = false;
      return result;
    } catch (e) {
      _isFirstLoad = false;
      rethrow;
    }
  }

  void _refreshData() {
    // Manual refresh: reset flag first load biar muncul loading spinner
    _timer?.cancel();
    setState(() {
      _isFirstLoad = true;
      _future = _loadData();
    });
    _startAutoRefresh();
  }

  List<Itinerary> _filterItineraries(List<Itinerary> list) {
    switch (_selectedFilter) {
      case 1:
        return list.where((i) => !_isCompleted(i) && !_isUpcoming(i)).toList();
      case 2:
        return list.where(_isUpcoming).toList();
      case 3:
        return list.where(_isCompleted).toList();
      case 0:
      default:
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accentGold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentGold.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: accentGold,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Itinerary Perjalanan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Jadwal & Agenda Zero Complaint',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat Ulang',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            onPressed: _refreshData,
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryDark,
                primaryNavy,
                secondaryNavy,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<({List<Itinerary> data, int? nextPage})>(
        future: _future,
        builder: (context, snap) {
          // Loader hanya muncul saat pertama kali buka atau manual refresh
          if (snap.connectionState == ConnectionState.waiting && _isFirstLoad) {
            return _buildLoadingState();
          }

          if (snap.hasError && _items.isEmpty) {
            return _buildErrorState(snap.error.toString());
          }

          // Gunakan _items yang selalu di-sync oleh timer
          final displayItems =
              _items.isNotEmpty ? _items : (snap.data?.data ?? []);

          if (displayItems.isEmpty) return _buildEmptyState();

          return _buildItineraryList(displayItems);
        },
      ),
    );
  }

  // ============================================
  // 🌟 OVERVIEW / TRIP BANNER AT TOP
  // ============================================
  Widget _buildOverviewCard(List<Itinerary> allItems) {
    final activeItems =
        allItems.where((i) => !_isCompleted(i) && !_isUpcoming(i)).toList();
    final upcomingItems = allItems.where(_isUpcoming).toList();
    final completedItems = allItems.where(_isCompleted).toList();
    final hasActive = activeItems.isNotEmpty;
    final featuredItem = hasActive
        ? activeItems.first
        : (upcomingItems.isNotEmpty ? upcomingItems.first : null);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Ambient luxury shapes
            Positioned(
              top: -25,
              right: -25,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentGold.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -35,
              left: -25,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Tag Status & Realtime Sync Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accentGold.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accentGold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasActive
                                  ? Icons.flight_takeoff_rounded
                                  : Icons.calendar_month_rounded,
                              color: accentGold,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              hasActive
                                  ? 'Trip Sedang Berjalan'
                                  : 'Monitoring Itinerary',
                              style: const TextStyle(
                                color: accentGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Featured Trip Card (Active or Upcoming)
                  if (featuredItem != null) ...[
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItineraryDetailPage(
                            service: _service,
                            id: featuredItem.id,
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accentGold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.mosque_rounded,
                                color: accentGold,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: hasActive
                                              ? success.withValues(alpha: 0.25)
                                              : accentGold
                                                  .withValues(alpha: 0.25),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          hasActive ? 'AKTIF SEKARANG' : 'SELANJUTNYA',
                                          style: TextStyle(
                                            color: hasActive
                                                ? const Color(0xFF6EE7B7)
                                                : accentGold,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatDayCount(featuredItem),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    featuredItem.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white70,
                              size: 13,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Quick Stats Counters Row
                  Row(
                    children: [
                      _buildStatCounter(
                        label: 'Total Paket',
                        value: allItems.length.toString(),
                        icon: Icons.folder_special_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      _buildStatCounter(
                        label: 'Aktif',
                        value: activeItems.length.toString(),
                        icon: Icons.play_circle_fill_rounded,
                        color: hasActive ? const Color(0xFF6EE7B7) : Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      _buildStatCounter(
                        label: 'Mendatang',
                        value: upcomingItems.length.toString(),
                        icon: Icons.schedule_rounded,
                        color: accentGold,
                      ),
                      const SizedBox(width: 8),
                      _buildStatCounter(
                        label: 'Selesai',
                        value: completedItems.length.toString(),
                        icon: Icons.check_circle_rounded,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCounter({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // 🏷️ FILTER TABS
  // ============================================
  Widget _buildFilterTabs(
      int total, int active, int upcoming, int completed) {
    final filters = [
      {'label': 'Semua', 'count': total},
      {'label': 'Aktif', 'count': active},
      {'label': 'Mendatang', 'count': upcoming},
      {'label': 'Selesai', 'count': completed},
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == index;
          final f = filters[index];
          final count = f['count'] as int;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedFilter = index;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? primaryNavy : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? primaryNavy : border,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryNavy.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentGold
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? primaryDark : textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================
  // 📋 ITINERARY LIST & CARD
  // ============================================
  Widget _buildItineraryList(List<Itinerary> items) {
    final totalCount = items.length;
    final activeCount =
        items.where((i) => !_isCompleted(i) && !_isUpcoming(i)).length;
    final upcomingCount = items.where(_isUpcoming).toList().length;
    final completedCount = items.where(_isCompleted).toList().length;

    final filtered = _filterItineraries(items);

    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      color: primaryNavy,
      backgroundColor: surface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. Overview Progress & Featured Active Trip Banner
          SliverToBoxAdapter(
            child: _buildOverviewCard(items),
          ),

          // 2. Filter Tabs
          SliverToBoxAdapter(
            child: _buildFilterTabs(
                totalCount, activeCount, upcomingCount, completedCount),
          ),

          // 3. Itinerary Card List or Filter Empty State
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(isFilterEmpty: true),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildItineraryCard(filtered[index]);
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItineraryCard(Itinerary itinerary) {
    final String dateRange = _formatDateRange(
      itinerary.startDate,
      itinerary.endDate,
    );
    final String tlName = _formatTourLeaderName(itinerary);
    final String dayLabel = _formatDayCount(itinerary);
    final List<String> destinations = _getDestinationTags(itinerary);
    final bool isUpcomingTrip = _isUpcoming(itinerary);
    final bool isCompletedTrip = _isCompleted(itinerary);
    final bool isActiveTrip = !isUpcomingTrip && !isCompletedTrip;

    final Color statusColor = _getStatusColor(itinerary);
    final String statusLabel = _getStatusText(itinerary);
    final Color statusBg = statusColor.withValues(alpha: 0.1);
    final IconData statusIcon = isCompletedTrip
        ? Icons.check_circle_outline_rounded
        : (isUpcomingTrip
            ? Icons.schedule_rounded
            : Icons.radio_button_checked_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActiveTrip ? accentGold.withValues(alpha: 0.7) : border,
          width: isActiveTrip ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1523).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItineraryDetailPage(
                service: _service,
                id: itinerary.id,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Badges Row (Status & Day Count Badge)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge with soft background
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Day Count Badge with Gold Accent
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accentGold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wb_sunny_rounded,
                            size: 12,
                            color: Color(0xFFB45309),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dayLabel,
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  itinerary.title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 12),

                // Date Badge with Gold Accent Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accentGold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Periode Perjalanan',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _buildInfoRow(
                              icon: Icons.calendar_month_rounded,
                              text: dateRange,
                              color: primaryNavy,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Destination Tags
                if (destinations.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: destinations.map((city) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: accentGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              city,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: secondaryNavy,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Subtle Divider
                Container(
                  height: 1,
                  color: border,
                ),

                const SizedBox(height: 12),

                // Footer: Tour Leader Avatar/Chip & Detail Action
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: primaryNavy.withValues(alpha: 0.1),
                      child: Text(
                        tlName.isNotEmpty ? tlName[0].toUpperCase() : 'T',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tour Leader',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: textMuted,
                            ),
                          ),
                          Text(
                            tlName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryNavy.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Detail',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primaryNavy,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
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

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ============================================
  // 🏷️ DESTINATION TAG EXTRACTOR
  // ============================================
  List<String> _getDestinationTags(Itinerary item) {
    final tags = <String>{};

    for (final day in item.days) {
      if (day.city != null && day.city!.trim().isNotEmpty) {
        tags.add(day.city!.trim());
      }
      for (final activity in day.items) {
        if (activity.location != null && activity.location!.trim().isNotEmpty) {
          final loc = activity.location!.trim();
          if (loc.length <= 15) {
            tags.add(loc);
          }
        }
      }
    }

    if (tags.isEmpty) {
      final titleLower = item.title.toLowerCase();
      if (titleLower.contains('makkah') || titleLower.contains('mecca')) {
        tags.add('Makkah');
      }
      if (titleLower.contains('madinah') || titleLower.contains('medina')) {
        tags.add('Madinah');
      }
      if (titleLower.contains('jeddah')) tags.add('Jeddah');
      if (titleLower.contains('turki') || titleLower.contains('turkey')) {
        tags.add('Turki');
      }
      if (titleLower.contains('dubai')) tags.add('Dubai');
      if (titleLower.contains('cairo') || titleLower.contains('mesir')) {
        tags.add('Mesir');
      }
      if (titleLower.contains('thaif') || titleLower.contains('taif')) {
        tags.add('Thaif');
      }
    }

    if (tags.isEmpty) {
      return ['Makkah', 'Madinah'];
    }

    return tags.take(3).toList();
  }

  // ============================================
  // 🌟 UI STATES (LOADING, ERROR, EMPTY)
  // ============================================
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: const AlwaysStoppedAnimation<Color>(accentGold),
                  backgroundColor: primaryNavy.withValues(alpha: 0.12),
                ),
              ),
              const Icon(
                Icons.calendar_month_rounded,
                color: primaryNavy,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Memuat Itinerary...',
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sinkronisasi jadwal perjalanan Zero Complaint',
            style: TextStyle(
              color: textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: errorRed,
                size: 48,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Gagal Memuat Itinerary',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 13,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({bool isFilterEmpty = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern travel illustration icon
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryNavy.withValues(alpha: 0.05),
                  ),
                ),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [primaryDark, primaryNavy],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryNavy.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flight_takeoff_rounded,
                    color: accentGold,
                    size: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              isFilterEmpty
                  ? 'Tidak Ada Itinerary di Filter Ini'
                  : 'Belum Ada Jadwal Itinerary',
              style: const TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFilterEmpty
                  ? 'Silakan pilih tab filter lain untuk melihat jadwal perjalanan yang tersedia.'
                  : 'Jadwal dan rute perjalanan ibadah Umrah akan otomatis muncul di sini setelah ditugaskan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isFilterEmpty
                  ? () => setState(() => _selectedFilter = 0)
                  : _refreshData,
              icon: Icon(
                isFilterEmpty
                    ? Icons.filter_alt_off_rounded
                    : Icons.refresh_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                isFilterEmpty ? 'Tampilkan Semua' : 'Muat Ulang',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: primaryNavy.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // 🛠️ HELPERS
  // ============================================
  bool _isUpcoming(Itinerary itinerary) {
    try {
      final now = DateTime.now();
      final startDate = DateTime.parse(itinerary.startDate!).toLocal();
      return startDate.isAfter(now);
    } catch (_) {
      return false;
    }
  }

  bool _isCompleted(Itinerary itinerary) {
    try {
      final now = DateTime.now();
      final endDate = DateTime.parse(itinerary.endDate!).toLocal();
      return endDate.isBefore(now);
    } catch (_) {
      return false;
    }
  }

  Color _getStatusColor(Itinerary itinerary) {
    if (_isCompleted(itinerary)) return success;
    if (_isUpcoming(itinerary)) return warning;
    return primaryNavy;
  }

  String _getStatusText(Itinerary itinerary) {
    if (_isCompleted(itinerary)) return 'Selesai';
    if (_isUpcoming(itinerary)) return 'Mendatang';
    return 'Aktif';
  }

  String _formatDateRange(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) return 'Date not specified';
    try {
      final s = DateTime.parse(startDate).toLocal();
      final e = DateTime.parse(endDate).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      return '${s.day} ${months[s.month - 1]} ${s.year} - ${e.day} ${months[e.month - 1]} ${e.year}';
    } catch (_) {
      return '$startDate - $endDate';
    }
  }

  String _formatTourLeaderName(Itinerary itinerary) {
    final name = (itinerary.tourLeader).trim();
    return name.isNotEmpty ? name : 'Tour Leader';
  }

  String _formatDayCount(Itinerary itinerary) {
    if (itinerary.daysCount != null) {
      final d = itinerary.daysCount!;
      return '$d Hari';
    }
    final int count = itinerary.days.length;
    if (count > 0) return '$count Hari';
    return 'Belum diatur';
  }
}
