import 'package:flutter/material.dart';
import 'package:mobile_retali/services/itinerary_service.dart';
import 'package:mobile_retali/models/itinerary_models.dart';
import 'package:mobile_retali/screens/itinerary/itinerary_widgets.dart';

class ItineraryDetailPage extends StatefulWidget {
  final ItineraryService service;
  final dynamic id;

  const ItineraryDetailPage({
    super.key,
    required this.service,
    required this.id,
  });

  @override
  State<ItineraryDetailPage> createState() => _ItineraryDetailPageState();
}

class _ItineraryDetailPageState extends State<ItineraryDetailPage> {
  late Future<Itinerary> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.show(widget.id);
  }

  void _refreshData() {
    setState(() {
      _future = widget.service.show(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(
        backgroundColor: AppTheme.brand,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Itinerary Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<Itinerary>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }
          if (snap.hasError) {
            return _buildErrorState(snap.error.toString());
          }

          final itinerary = snap.data!;
          final days = itinerary.days;

          return DefaultTabController(
            length: days.isEmpty ? 1 : days.length,
            child: _buildItineraryContent(itinerary, days),
          );
        },
      ),
    );
  }

  // ===================== STATES =====================

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brand),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading itinerary details...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
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
            Icon(Icons.error_outline, color: Colors.red[300], size: 64),
            const SizedBox(height: 16),
            Text(
              'Failed to load details',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== MAIN CONTENT =====================

  Widget _buildItineraryContent(
      Itinerary itinerary, List<ItineraryDay> days) {
    return Column(
      children: [
        // Header Information Card
        Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          itinerary.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(itinerary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(itinerary),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Date range
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatDateRange(
                            itinerary.startDate,
                            itinerary.endDate,
                          ),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Tour Leader
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          itinerary.tourLeader,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Summary: days & activities
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${days.length} Days • ${_calculateTotalActivities(days)} Activities',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Days Tabs
        _DaysTabBar(days: days),

        // Tab Content
        Expanded(
          child: TabBarView(
            children: days.isEmpty
                ? [_buildEmptyDayState()]
                : days.map((day) => _DayContent(day: day)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDayState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No Itinerary Planned',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Activities for this day will appear here once they are added',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateTotalActivities(List<ItineraryDay> days) {
    return days.fold(0, (total, day) => total + day.items.length);
  }

  // ===================== DATE & STATUS HELPERS =====================

  Color _getStatusColor(Itinerary itinerary) {
    try {
      if (itinerary.startDate == null || itinerary.endDate == null) {
        return Colors.grey;
      }

      final now = DateTime.now();
      final startDate = DateTime.parse(itinerary.startDate!).toLocal();
      final endDate = DateTime.parse(itinerary.endDate!).toLocal();

      if (endDate.isBefore(now)) {
        return Colors.green; // Completed
      } else if (startDate.isAfter(now)) {
        return Colors.orange; // Upcoming
      } else {
        return AppTheme.brand; // Changed from Colors.blue to AppTheme.brand
      }
    } catch (_) {
      return Colors.grey;
    }
  }

  String _getStatusText(Itinerary itinerary) {
    try {
      if (itinerary.startDate == null || itinerary.endDate == null) {
        return 'Unknown';
      }

      final now = DateTime.now();
      final startDate = DateTime.parse(itinerary.startDate!).toLocal();
      final endDate = DateTime.parse(itinerary.endDate!).toLocal();

      if (endDate.isBefore(now)) {
        return 'Completed';
      } else if (startDate.isAfter(now)) {
        return 'Upcoming';
      } else {
        return 'Active'; // Changed from 'Ongoing' to 'Active'
      }
    } catch (_) {
      return 'Unknown';
    }
  }

  String _formatDateRange(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) {
      return 'Date not specified';
    }

    try {
      final start = DateTime.parse(startDate).toLocal();
      final end = DateTime.parse(endDate).toLocal();

      final startFormatted =
          '${start.day}/${start.month}/${start.year}';
      final endFormatted =
          '${end.day}/${end.month}/${end.year}';

      return '$startFormatted - $endFormatted';
    } catch (_) {
      return '$startDate - $endDate';
    }
  }
}

// ===================== DAYS TAB BAR =====================

class _DaysTabBar extends StatefulWidget {
  final List<ItineraryDay> days;

  const _DaysTabBar({required this.days});

  @override
  State<_DaysTabBar> createState() => _DaysTabBarState();
}

class _DaysTabBarState extends State<_DaysTabBar> {
  final ScrollController _scrollController = ScrollController();
  TabController? _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.of(context);
    if (_tabController != controller) {
      _tabController?.removeListener(_handleTabChange);
      _tabController = controller;
      _tabController?.addListener(_handleTabChange);
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController != null && !_tabController!.indexIsChanging) {
      _scrollToIndex(_tabController!.index);
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    const itemWidth = 145.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset =
        (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _formatShortDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    try {
      final d = DateTime.parse(raw).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _tabController!,
      builder: (context, _) {
        final selectedIndex = _tabController!.index;

        return Container(
          height: 78,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: widget.days.isEmpty ? 1 : widget.days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final isSelected = selectedIndex == index;
              final day = widget.days.isNotEmpty ? widget.days[index] : null;

              return _buildDayCard(
                index: index,
                day: day,
                isSelected: isSelected,
                onTap: () {
                  _tabController?.animateTo(index);
                  _scrollToIndex(index);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDayCard({
    required int index,
    required ItineraryDay? day,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cityName = (day?.city != null && day!.city!.trim().isNotEmpty)
        ? day.city!.trim()
        : (day != null && day.items.isNotEmpty
            ? '${day.items.length} Agenda'
            : 'Agenda');
    final shortDate = _formatShortDate(day?.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF842D62).withValues(alpha: 0.15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          constraints: const BoxConstraints(minWidth: 130),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF842D62), Color(0xFF5C1C3B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : const Color(0xFFE5E7EB),
              width: 1.2,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF842D62).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.22)
                          : const Color(0xFF842D62).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Day ${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF842D62),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (shortDate.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      shortDate,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.85)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 13,
                    color: isSelected
                        ? const Color(0xFFFDE047)
                        : const Color(0xFF842D62),
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 135),
                    child: Text(
                      cityName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1F2937),
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== DAY CONTENT =====================

class _DayContent extends StatelessWidget {
  final ItineraryDay day;

  const _DayContent({required this.day});

  String _getFormattedDate(String? date) {
    if (date == null) return 'No date';

    try {
      final parsedDate = DateTime.parse(date).toLocal();
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (_) {
      return 'Invalid date';
    }
  }

  Widget _buildEmptyActivitiesState() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.checklist,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No Activities Planned',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Activities for this day will be shown here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(ItineraryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Column
              Container(
                width: 70,
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          AppTheme.brand.withOpacity(0.1),
                          Colors.white,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.time ?? '--:--',
                        style: TextStyle(
                          color: AppTheme.brand,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Timeline
              Column(
                children: [
                  Container(
                    width: 2,
                    height: 8,
                    color: AppTheme.brand,
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.brand,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height:
                        item.content != null && item.content!.length > 50
                            ? 80
                            : 40,
                    color: Color.alphaBlend(
                      AppTheme.brand.withOpacity(0.3),
                      Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.title != null && item.title!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          item.title!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    if (item.location != null &&
                        item.location!.isNotEmpty &&
                        item.location != item.title)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppTheme.brand,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.brand.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item.content != null &&
                        item.content!.isNotEmpty)
                      Text(
                        item.content!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // kalau mau, nanti bisa dihubungkan ke refresh dari parent
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Day Header Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day ${day.dayNumber}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        if (day.city != null && day.city!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              day.city!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        AppTheme.brand.withOpacity(0.1),
                        Colors.white,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getFormattedDate(day.date),
                      style: TextStyle(
                        color: AppTheme.brand,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Activities list
          if (day.items.isEmpty)
            _buildEmptyActivitiesState()
          else
            ...day.items.map(_buildActivityItem).toList(),
        ],
      ),
    );
  }
}