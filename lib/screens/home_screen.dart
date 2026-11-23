import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/presence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_retali/screens/notifications.dart';
import 'package:mobile_retali/screens/scan_screen.dart';
import 'package:mobile_retali/screens/riwayat_scan/history_screen.dart';
import 'package:mobile_retali/screens/profile_screen.dart';
import 'package:mobile_retali/screens/curriculum_tour_leader_screen.dart';
import 'package:mobile_retali/screens/persiapan_umrah_screen.dart';
import 'package:mobile_retali/screens/quran/quran_list_screen.dart';
import 'package:mobile_retali/screens/absensi_screen.dart';
import 'package:mobile_retali/screens/destinasi/destinasi_ziarah_page.dart';
import 'package:mobile_retali/screens/dzikir_doa/dzikir_doa_page.dart';
import 'package:mobile_retali/screens/panduan/panduan_umrah_page.dart';
import 'package:mobile_retali/screens/prosedur/prosedur_perjalanan_page.dart';
import 'package:mobile_retali/screens/fiqih/fiqih_umrah_page.dart';
import 'package:mobile_retali/screens/praktis/info_praktis_page.dart';
import 'package:mobile_retali/screens/tugas_ceklis/checklist_list_screen.dart';
import 'package:mobile_retali/widgets/running_notification_bar.dart';
import 'package:mobile_retali/widgets/dual_clock_banner.dart';
import 'package:mobile_retali/screens/itinerary/itinerary_list_page.dart';
import 'faq_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  final GlobalKey<HistoryScreenState> _historyKey = GlobalKey<HistoryScreenState>();

  String _name = "";
  int _unreadCount = 0;
  String _role = "tour_leader";
  final ScrollController _scrollController = ScrollController();

  // Retali-Sistem Design Palette (Navy & Gold)
  static const Color primaryDark = Color(0xFF0D1523);
  static const Color primaryNavy = Color(0xFF1B3167);
  static const Color secondaryNavy = Color(0xFF263754);
  static const Color accentGold = Color(0xFFEAB308);
  static const Color pageBg = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color errorRed = Color(0xFFEF4444);

  String get _roleDisplay {
    final clean = _role.toLowerCase().replaceAll('_', ' ').trim();
    if (clean == 'muthawif') {
      return 'Muthawif';
    } else if (clean == 'tour leader' || clean == 'tourleader') {
      return 'Tour Leader';
    } else if (clean.isNotEmpty) {
      return clean
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');
    }
    return 'Tour Leader';
  }

  @override
  void initState() {
    super.initState();
    PresenceService.start();
    _loadUserInfo();
    _loadUnread();
    NotificationService.addListener(_loadUnread);
  }

  @override
  void dispose() {
    NotificationService.removeListener(_loadUnread);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _name = prefs.getString("name") ?? "";
      _role = prefs.getString("role") ?? "tour_leader";
    });

    try {
      final info = await ApiService.getUserInfo();
      if (info.isNotEmpty && mounted) {
        final updatedName = prefs.getString("name") ?? _name;
        final updatedRole = prefs.getString("role") ?? _role;
        if (updatedName != _name || updatedRole != _role) {
          setState(() {
            _name = updatedName;
            _role = updatedRole;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadUnread() async {
    try {
      final list = await ApiService.getNotifications();
      final unread = list.where((n) {
        final readAt = n["read_at"] ?? n["readAt"];
        final read = n["read"] ?? false;
        return readAt == null && read != true;
      }).length;
      if (!mounted) return;
      setState(() => _unreadCount = unread);
    } catch (_) {}
  }

  Future<void> _refreshAll() async {
    await _loadUserInfo();
    await _loadUnread();
    RunningNotificationBar.refreshGlobal();
  }

  List<Map<String, String>> get menus {
    final baseMenus = [
      {"img": "assets/home/fiqih umrah.png", "label": "Fiqih\nUmrah"},
      {"img": "assets/home/persiapan umrah.png", "label": "Persiapan\nUmrah"},
      {"img": "assets/home/panduan umrah.png", "label": "Panduan\nUmrah"},
      {"img": "assets/home/dzikir dan doa.png", "label": "Dzikir & Doa"},
      {"img": "assets/home/info praktis.png", "label": "Info\nPraktis"},
      {
        "img": "assets/home/destinasi sejarah.png",
        "label": "Destinasi\nZiarah",
      },
      {"img": "assets/home/al quran.png", "label": "Al-Quran"},
      {"img": "assets/home/absensi_jamaah.png", "label": "Absensi"},
      {
        "img": "assets/home/prosedur perjalanan.png",
        "label": "Prosedur\nPerjalanan",
      },
    ];

    final normalizedRole = _role.toLowerCase().replaceAll('_', '').trim();
    if (normalizedRole == 'tourleader' || normalizedRole == 'muthawif') {
      baseMenus.addAll([
        {"img": "assets/home/ceklis tugas.png", "label": "Ceklis\nTugas"},
        {
          "img": "assets/home/itinerary perjalanan.png",
          "label": "Itinerary\nPerjalanan",
        },
      ]);

      if (normalizedRole == 'tourleader') {
        baseMenus.add({
          "img": "assets/home/tugas tour leader.png",
          "label": "Curriculum\nTour Leader",
        });
      }
    }

    return baseMenus;
  }

  // 🕌 Top Header Area with Islamic Pattern Overlay & Glassmorphism
  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

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
          // Subtle Islamic Geometric Pattern Overlay
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
            padding: EdgeInsets.fromLTRB(16, topPadding + 14, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Salam + Role Badge + FAQ & Notif Icons
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Assalamualaikum, ${_name.isNotEmpty ? _name : 'User'}!",
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Role Badge with Gold Accent
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
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
                                color: accentGold.withValues(alpha: 0.7),
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
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: accentGold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _roleDisplay,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: accentGold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // FAQ & Notification Action Icons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeaderAction(
                          icon: Icons.help_outline_rounded,
                          tooltip: "Pusat Bantuan (FAQ)",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FaqScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildHeaderAction(
                              icon: Icons.notifications_none_rounded,
                              tooltip: "Notifikasi",
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                );
                                _loadUnread();
                              },
                            ),
                            if (_unreadCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: errorRed,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: primaryDark,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: errorRed.withValues(alpha: 0.5),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        height: 1.0,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 🔔 Running Notification Bar with Glassmorphism
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const RunningNotificationBar(),
                ),

                const SizedBox(height: 14),

                // 🕰 Dual Clock Banner wrapped in rounded Card
                Card(
                  elevation: 8,
                  shadowColor: primaryDark.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: accentGold.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.zero,
                  child: const DualClockBanner(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header circular action button
  Widget _buildHeaderAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
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
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white.withValues(alpha: 0.2),
            onTap: onTap,
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // 🔽 Home Tab View
  Widget _buildHomeTab() {
    return Scaffold(
      primary: false,
      backgroundColor: pageBg,
      body: RefreshIndicator(
        color: primaryNavy,
        backgroundColor: Colors.white,
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🕌 Large Custom Header
              _buildHeader(context),

              // 📚 Menu Grid Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: accentGold,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Menu Layanan",
                              style: TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: primaryNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${menus.length} Layanan",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 📚 4-Column Menu Grid (4 column 3 row)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.80,
                      ),
                      itemCount: menus.length,
                      itemBuilder: (context, index) {
                        final menu = menus[index];
                        return MenuItemWidget(
                          imagePath: menu["img"]!,
                          label: menu["label"]!,
                        );
                      },
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

  // Modern bottom nav item on dark blue background
  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final labelColor = isActive ? accentGold : Colors.white70;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? accentGold.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? accentGold : Colors.white70,
                size: 23,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: labelColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentTabIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentTabIndex != 0) {
          setState(() => _currentTabIndex = 0);
        }
      },
      child: Scaffold(
        primary: false,
        backgroundColor: pageBg,
        body: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildHomeTab(),
            HistoryScreen(key: _historyKey, isTab: true),
            const ProfileScreen(isTab: true),
          ],
        ),

        // 🔻 Modern Bottom Navigation Bar matching Top Section Dark Navy Blue
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            color: primaryDark,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: "Beranda",
                  isActive: _currentTabIndex == 0,
                  onTap: () {
                    if (_currentTabIndex == 0) {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    } else {
                      setState(() => _currentTabIndex = 0);
                    }
                  },
                ),
                _buildNavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment_rounded,
                  label: "Ceklis",
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChecklistListScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 48), // Gap for floating scan button
                _buildNavItem(
                  icon: Icons.history_rounded,
                  activeIcon: Icons.history_rounded,
                  label: "Riwayat",
                  isActive: _currentTabIndex == 1,
                  onTap: () {
                    if (_currentTabIndex == 1) {
                      _historyKey.currentState?.reload();
                    } else {
                      setState(() => _currentTabIndex = 1);
                    }
                  },
                ),
                _buildNavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: "Profil",
                  isActive: _currentTabIndex == 2,
                  onTap: () {
                    setState(() => _currentTabIndex = 2);
                  },
                ),
              ],
            ),
          ),
        ),

        // 📸 FAB Scan Button with Golden Gradient Ring & White Background
        floatingActionButton: SizedBox(
          height: 64,
          width: 64,
          child: FittedBox(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFDE047), // Gold highlight
                    accentGold,        // Signature Gold
                    Color(0xFFCA8A04), // Deep Gold
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x66EAB308),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3.5), // Golden gradient ring
              child: FloatingActionButton(
                elevation: 0,
                highlightElevation: 0,
                backgroundColor: Colors.white,
                shape: const CircleBorder(),
                tooltip: "Scan QR",
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanScreen()),
                  );
                  if (mounted) {
                    _historyKey.currentState?.reload();
                  }
                },
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: primaryNavy,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}

// 🎴 Modern White Card Menu Item with Navy Icon Circle & Tap Ripple
class MenuItemWidget extends StatelessWidget {
  final String imagePath;
  final String label;

  const MenuItemWidget({
    super.key,
    required this.imagePath,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3167).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFF1B3167).withValues(alpha: 0.08),
          highlightColor: const Color(0xFFEAB308).withValues(alpha: 0.06),
          onTap: () {
            final pages = {
              "Curriculum\nTour Leader": const CurriculumTourLeaderScreen(),
              "Tugas\nTour Leader": const CurriculumTourLeaderScreen(),
              "Persiapan\nUmrah": const PersiapanUmrahScreen(),
              "Al-Quran": const QuranListScreen(),
              "Destinasi\nZiarah": const DestinasiZiarahPage(),
              "Absensi": const AbsensiScreen(),
              "Dzikir & Doa": const DzikirDoaPage(),
              "Panduan\nUmrah": const PanduanUmrahPage(),
              "Prosedur\nPerjalanan": const ProsedurPerjalananPage(),
              "Fiqih\nUmrah": const FiqihUmrahPage(),
              "Info\nPraktis": const InfoPraktisPage(),
              "Ceklis\nTugas": const ChecklistListScreen(),
              "Itinerary\nPerjalanan": const ItineraryListPage(),
            };

            if (pages.containsKey(label)) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => pages[label]!),
              );
              return;
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Navy Icon Circle with Subtle Gradient & Shadow
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1B3167),
                        Color(0xFF0D1523),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B3167).withValues(alpha: 0.28),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(7.5),
                  child: Image.asset(
                    imagePath,
                    width: 27,
                    height: 27,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                    letterSpacing: -0.2,
                  ),
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
