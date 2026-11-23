import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_retali/services/api_service.dart';
import 'koper_detail_screen.dart';
import 'paspor_detail_screen.dart';

enum HistoryType { koper, paspor }

class HistoryScreen extends StatefulWidget {
  final bool isTab;
  const HistoryScreen({super.key, this.isTab = false});

  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  HistoryType _type = HistoryType.koper;
  late Future<List<dynamic>> _futureScans;
  String? _currentKloter;

  // Search filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Retali-Sistem Palette (Navy & Gold)
  static const Color primaryDark = Color(0xFF0D1523);
  static const Color primaryNavy = Color(0xFF1B3167);
  static const Color secondaryNavy = Color(0xFF263754);
  static const Color accentGold = Color(0xFFEAB308);
  static const Color surface = Colors.white;
  static const Color pageBg = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

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

  void reload() {
    _loadData();
  }

  void _loadData() {
    _futureScans = _fetchScans();
    setState(() {});
  }

  Future<List<dynamic>> _fetchScans() async {
    final kloter = await ApiService.getCurrentUserKloter();
    final userId = await ApiService.getCurrentUserId();
    if (mounted && _currentKloter != kloter) {
      setState(() {
        _currentKloter = kloter;
      });
    }
    return _type == HistoryType.koper
        ? ApiService.getScans(kloter: kloter, userId: userId)
        : ApiService.getPassportScans(kloter: kloter, userId: userId);
  }

  String _formatDateTime(String v) {
    try {
      final dt = DateTime.parse(v).toLocal();
      return DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return v;
    }
  }

  Future<bool?> _showDeleteConfirmation({
    required String kode,
    required String nama,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.white,
        elevation: 12,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: error,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Hapus Riwayat Scan?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: "Data scan "),
                    TextSpan(
                      text: kode.isNotEmpty ? kode : 'ini',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    if (nama.isNotEmpty && nama != '-') ...[
                      const TextSpan(text: " atas nama "),
                      TextSpan(
                        text: nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryNavy,
                        ),
                      ),
                    ],
                    const TextSpan(
                      text:
                          " akan dihapus secara permanen dari server. Tindakan ini tidak dapat dibatalkan.",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        "Batal",
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        "Hapus",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
    );
  }

  Future<void> _deleteItem(Map<String, dynamic> scan) async {
    final kode = _type == HistoryType.koper
        ? (scan['koper_code'] ?? scan['kode_koper'] ?? '')
        : (scan['passport_number'] ?? scan['passport'] ?? '');
    final nama = scan['owner_name'] ?? scan['nama_pemilik'] ?? '-';

    final confirm = await _showDeleteConfirmation(
      kode: kode.toString(),
      nama: nama.toString(),
    );

    if (confirm != true) return;

    final id = scan['id'];
    bool successResult = false;

    if (_type == HistoryType.koper) {
      successResult = await ApiService.deleteKoper(id);
    } else {
      successResult = await ApiService.deletePassport(id);
    }

    if (successResult) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                "Berhasil dihapus",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      _loadData();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                "Gagal menghapus data",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: Column(
        children: [
          // 🕌 Modern Header with Islamic Arabesque Pattern
          _buildHeader(),

          // 🔍 Filter & Search Bar + Kloter Badge
          _buildFilterSection(),

          // 📋 List Riwayat Scan
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _futureScans,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryNavy),
                          strokeWidth: 2.5,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Memuat riwayat scan...",
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return RefreshIndicator(
                    color: primaryNavy,
                    onRefresh: () async => _loadData(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: error.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                size: 36,
                                color: error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Gagal Memuat Data",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${snapshot.error}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _loadData,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text("Coba Lagi"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryNavy,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
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

                final rawScans = snapshot.data ?? [];
                final allScans = rawScans.cast<Map<String, dynamic>>();

                // In-memory search filtering
                final scans = _searchQuery.isEmpty
                    ? allScans
                    : allScans.where((scan) {
                        final kode = (_type == HistoryType.koper
                                ? (scan['koper_code'] ?? scan['kode_koper'])
                                : (scan['passport_number'] ?? scan['passport']))
                            ?.toString()
                            .toLowerCase() ??
                            '';
                        final nama = (scan['owner_name'] ??
                                scan['nama_pemilik'] ??
                                '')
                            .toString()
                            .toLowerCase();
                        final kloter = (scan['kloter'] ?? '')
                            .toString()
                            .toLowerCase();
                        final phone = (scan['owner_phone'] ??
                                scan['phone'] ??
                                scan['nomor_telepon'] ??
                                '')
                            .toString()
                            .toLowerCase();
                        final q = _searchQuery.toLowerCase();
                        return kode.contains(q) ||
                            nama.contains(q) ||
                            kloter.contains(q) ||
                            phone.contains(q);
                      }).toList();

                if (scans.isEmpty) {
                  return RefreshIndicator(
                    color: primaryNavy,
                    onRefresh: () async => _loadData(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: 380,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: _searchQuery.isNotEmpty
                            ? _buildSearchEmptyState()
                            : _buildEmptyState(),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: primaryNavy,
                  onRefresh: () async => _loadData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: scans.length,
                    itemBuilder: (context, index) {
                      final scan = scans[index];

                      final kode = _type == HistoryType.koper
                          ? (scan['koper_code'] ?? scan['kode_koper'])
                          : (scan['passport_number'] ?? scan['passport']);

                      final nama =
                          scan['owner_name'] ?? scan['nama_pemilik'] ?? '-';
                      final phone = scan['owner_phone'] ??
                          scan['phone'] ??
                          scan['nomor_telepon'] ??
                          '-';
                      final kloter = scan['kloter'] ?? '-';
                      final waktu =
                          scan['scanned_at'] ?? scan['created_at'] ?? '';
                      final lat = (scan['latitude'] != null)
                          ? double.tryParse(scan['latitude'].toString())
                          : null;
                      final lng = (scan['longitude'] != null)
                          ? double.tryParse(scan['longitude'].toString())
                          : null;

                      final itemKey =
                          '${scan['id']}_${kode?.toString() ?? index}';

                      return Dismissible(
                        key: ValueKey(itemKey),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          await _deleteItem(scan);
                          return false;
                        },
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: error,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Hapus Data",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        child: _ModernCard(
                          type: _type,
                          kode: kode?.toString() ?? '-',
                          nama: nama.toString(),
                          phone: phone.toString(),
                          kloter: kloter.toString(),
                          waktu: waktu.toString(),
                          latitude: lat,
                          longitude: lng,
                          formatDateTime: _formatDateTime,
                          onDelete: () => _deleteItem(scan),
                          onDetail: () {
                            if (_type == HistoryType.koper) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => KoperDetailScreen(
                                    kode: kode?.toString() ?? '',
                                    namaPemilik: nama.toString(),
                                    phone: phone.toString(),
                                    timestamp: waktu.toString(),
                                    kloter: kloter.toString(),
                                    latitude: lat,
                                    longitude: lng,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PasporDetailScreen(
                                    passportNumber: kode?.toString() ?? '',
                                    namaPemilik: nama.toString(),
                                    phone: phone.toString(),
                                    timestamp: waktu.toString(),
                                    kloter: kloter.toString(),
                                    latitude: lat,
                                    longitude: lng,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🕌 Modern Header with Islamic Arabesque Pattern
  Widget _buildHeader() {
    return Container(
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
            color: primaryDark.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Geometric Pattern Overlay
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
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Bar Row
                  Row(
                    children: [
                      if (!widget.isTab) ...[
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Riwayat Scan",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentGold.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: accentGold.withValues(alpha: 0.6),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    "LIVE",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: accentGold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Monitoring pergerakan koper & paspor jamaah",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _loadData,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 🔀 Premium Segmented Switch
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildSegmentTab(
                          label: "Koper Jamaah",
                          type: HistoryType.koper,
                          icon: Icons.luggage_rounded,
                        ),
                        _buildSegmentTab(
                          label: "Paspor Jamaah",
                          type: HistoryType.paspor,
                          icon: Icons.menu_book_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({
    required String label,
    required HistoryType type,
    required IconData icon,
  }) {
    final bool isSelected = _type == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_type != type) {
            setState(() {
              _type = type;
              _searchController.clear();
              _searchQuery = '';
            });
            _loadData();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
              : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? primaryNavy
                    : Colors.white.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? primaryNavy
                      : Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔍 Filter, Kloter Pill, and Search Bar
  Widget _buildFilterSection() {
    final hasKloter = _currentKloter != null &&
        _currentKloter!.isNotEmpty &&
        _currentKloter != '-';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kloter Info Pill
          if (hasKloter) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: primaryNavy.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: primaryNavy.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
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
                  const Icon(
                    Icons.badge_outlined,
                    size: 16,
                    color: primaryNavy,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Kloter Petugas: $_currentKloter",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryNavy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _type == HistoryType.koper ? "Koper" : "Paspor",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: secondaryNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Search Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              style: const TextStyle(
                fontSize: 13,
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: _type == HistoryType.koper
                    ? "Cari nama jamaah, kode koper, kloter..."
                    : "Cari nama jamaah, nomor paspor, kloter...",
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: textSecondary,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: textSecondary,
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
                  vertical: 12,
                  horizontal: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Empty state illustration
  Widget _buildEmptyState() {
    final isKoper = _type == HistoryType.koper;
    final String kloterText = (_currentKloter != null &&
            _currentKloter!.isNotEmpty &&
            _currentKloter != '-')
        ? " untuk kloter $_currentKloter"
        : "";

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                primaryNavy.withValues(alpha: 0.08),
                secondaryNavy.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: primaryNavy.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              isKoper ? Icons.luggage_outlined : Icons.menu_book_outlined,
              size: 42,
              color: primaryNavy.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          "Belum Ada Riwayat ${isKoper ? 'Koper' : 'Paspor'}",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Data hasil pemindaian ${isKoper ? 'koper' : 'paspor'} jamaah$kloterText akan tercatat otomatis di sini.",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.arrow_downward_rounded,
              size: 14,
              color: textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              "Tarik ke bawah untuk memuat ulang",
              style: TextStyle(
                fontSize: 12,
                color: textMuted.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Search not found empty state
  Widget _buildSearchEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.withValues(alpha: 0.1),
          ),
          child: const Center(
            child: Icon(
              Icons.search_off_rounded,
              size: 36,
              color: textMuted,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Tidak Ada Hasil",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Tidak ditemukan data yang cocok dengan \"$_searchQuery\".",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
            });
          },
          icon: const Icon(Icons.clear_rounded, size: 16),
          label: const Text("Reset Pencarian"),
          style: TextButton.styleFrom(
            foregroundColor: primaryNavy,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// 📇 Modern Scan History Card
class _ModernCard extends StatelessWidget {
  final HistoryType type;
  final String kode;
  final String nama;
  final String phone;
  final String kloter;
  final String waktu;
  final double? latitude;
  final double? longitude;
  final VoidCallback onDetail;
  final VoidCallback onDelete;
  final String Function(String) formatDateTime;

  const _ModernCard({
    required this.type,
    required this.kode,
    required this.nama,
    this.phone = '-',
    required this.kloter,
    required this.waktu,
    this.latitude,
    this.longitude,
    required this.onDetail,
    required this.onDelete,
    required this.formatDateTime,
  });

  // Palette constants inside Card
  static const Color primaryNavy = Color(0xFF1B3167);
  static const Color accentGold = Color(0xFFEAB308);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final isKoper = type == HistoryType.koper;
    final hasGps = latitude != null && longitude != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onDetail,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Type Pill + GPS Pill + Delete Icon
                Row(
                  children: [
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isKoper
                                ? Icons.luggage_rounded
                                : Icons.menu_book_rounded,
                            size: 13,
                            color: primaryNavy,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isKoper ? "KOPER" : "PASPOR",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: primaryNavy,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // GPS Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: hasGps
                            ? success.withValues(alpha: 0.08)
                            : borderColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasGps
                              ? success.withValues(alpha: 0.25)
                              : borderColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasGps
                                ? Icons.gps_fixed_rounded
                                : Icons.gps_off_rounded,
                            size: 11,
                            color: hasGps ? success : textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasGps ? "GPS Aktif" : "Tanpa GPS",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  hasGps ? FontWeight.bold : FontWeight.w500,
                              color: hasGps ? success : textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Delete Action Button
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: error,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Main Identifier (Code / Passport Number)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        kode,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (kloter.isNotEmpty && kloter != '-')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Kloter: $kloter",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Passenger Owner Name
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: primaryNavy.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 13,
                          color: primaryNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Phone number (if available)
                if (phone.isNotEmpty && phone != '-') ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 6),

                // Timestamp
                Row(
                  children: [
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: textMuted,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatDateTime(waktu),
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // GPS Location Details Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasGps
                        ? success.withValues(alpha: 0.05)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasGps
                          ? success.withValues(alpha: 0.25)
                          : borderColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: hasGps ? success : textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasGps
                              ? "${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}"
                              : "Koordinat lokasi belum tersimpan",
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: hasGps ? 'monospace' : null,
                            fontWeight:
                                hasGps ? FontWeight.w600 : FontWeight.w400,
                            color: hasGps ? success : textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Card Bottom Footer Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Ketuk untuk rincian data",
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    InkWell(
                      onTap: onDetail,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Detail",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
}

// 📐 Subtle Geometric Islamic Arabesque Pattern Painter
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
