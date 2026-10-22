import 'package:flutter/material.dart';
import 'package:mobile_retali/services/itinerary_service.dart';
import 'package:mobile_retali/models/itinerary_models.dart';
import 'package:mobile_retali/screens/itinerary/itinerary_detail_page.dart';
import 'package:mobile_retali/screens/itinerary/itinerary_widgets.dart';
import 'dart:async';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Itinerary',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF842D62), // 🔥 sama kayak home
                Color(0xFF5A1847), // 🔥 sama kayak home
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
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
          final displayItems = _items.isNotEmpty
              ? _items
              : (snap.data?.data ?? []);

          if (displayItems.isEmpty) return _buildEmptyState();

          return _buildItineraryList(displayItems);
        },
      ),
    );
  }

  // ===================== UI STATES (Tidak Ada Yang Diubah) =====================

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
            'Loading itinerary...',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
              'Failed to load',
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
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.travel_explore, color: Colors.grey[400], size: 80),
            const SizedBox(height: 20),
            Text(
              'No Itineraries Yet',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your travel plans will appear here once you create them',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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

  // ===================== LIST & CARD (Tidak Ada Yang Diubah) =====================

  Widget _buildItineraryList(List<Itinerary> items) {
    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      color: AppTheme.brand,
      backgroundColor: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          return _buildItineraryCard(items[i]);
        },
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

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ItineraryDetailPage(service: _service, id: itinerary.id),
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[50]!],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itinerary.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _getStatusColor(itinerary),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getStatusText(itinerary),
                              style: TextStyle(
                                fontSize: 13,
                                color: _getStatusColor(itinerary),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.brand.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      dayLabel,
                      style: TextStyle(
                        color: AppTheme.brand,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoRow(
                icon: Icons.calendar_today_rounded,
                text: dateRange,
                color: Colors.grey[700]!,
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                icon: Icons.person_outline_rounded,
                text: tlName,
                color: Colors.grey[700]!,
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                icon: Icons.today_outlined,
                text: dayLabel,
                color: Colors.grey[700]!,
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[200]!,
                      Colors.grey[300]!,
                      Colors.grey[200]!,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      color: AppTheme.brand,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.brand,
                      size: 14,
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

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ===================== HELPERS (Tidak Ada Yang Diubah) =====================

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
    if (_isCompleted(itinerary)) return Colors.green;
    if (_isUpcoming(itinerary)) return Colors.orange;
    return AppTheme.brand;
  }

  String _getStatusText(Itinerary itinerary) {
    if (_isCompleted(itinerary)) return 'Completed';
    if (_isUpcoming(itinerary)) return 'Upcoming';
    return 'Active';
  }

  String _formatDateRange(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) return 'Date not specified';
    try {
      final s = DateTime.parse(startDate).toLocal();
      final e = DateTime.parse(endDate).toLocal();
      return '${s.day}/${s.month}/${s.year} - ${e.day}/${e.month}/${e.year}';
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
      return '$d day${d > 1 ? 's' : ''}';
    }
    final int count = itinerary.days.length;
    if (count > 0) return '$count day${count > 1 ? 's' : ''}';
    return 'No days set';
  }
}
