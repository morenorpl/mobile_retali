import 'package:flutter/material.dart';
import 'package:mobile_retali/services/itinerary_service.dart';
import 'package:mobile_retali/models/itinerary_models.dart';
import 'package:mobile_retali/screens/itinerary/itinerary_widgets.dart';

class ItineraryDetailPage extends StatefulWidget {
  final ItineraryService service;
  final int id;

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
        Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  isScrollable: true,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  indicator: BoxDecoration(
                    color: AppTheme.brand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black87,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: days.isEmpty
                      ? const [Tab(text: 'Day 1')]
                      : days.asMap().entries.map((entry) {
                          final index = entry.key;
                          final day = entry.value;
                          return Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Day ${index + 1}'),
                                if (day.city != null &&
                                    day.city!.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withOpacity(0.2),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      day.city!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                ),
              ),
              Container(
                height: 1,
                color: Colors.grey[200],
              ),
            ],
          ),
        ),

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