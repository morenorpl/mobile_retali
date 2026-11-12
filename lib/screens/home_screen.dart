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
import 'package:mobile_retali/screens/tugas_tourleader/tugas_screen.dart';
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
    PresenceService.stop();
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

  Widget _buildHomeTab() {
    return Scaffold(
      backgroundColor: Colors.white,

      // 🔰 APPBAR
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(300),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF842D62),
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF842D62), Color(0xFF5A1847)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Salam + Notifikasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Assalamualaikum, ${_name.isNotEmpty ? _name : 'User'}!",
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Anda masuk sebagai $_roleDisplay",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),

                      // 🔔 Notifikasi
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                              _loadUnread();
                            },
                            icon: const Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          if (_unreadCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$_unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 🔔 Bar notifikasi berjalan
                  const RunningNotificationBar(),
                  const SizedBox(height: 12),

                  Expanded(child: const DualClockBanner()),
                ],
              ),
            ),
          ),
        ),
      ),

      // 🔽 BODY bisa di-pull-to-refresh
      body: RefreshIndicator(
        color: const Color(0xFF842D62),
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            children: [
              // 📚 Menu Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.9,
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
              const SizedBox(height: 20),

              // 💬 Potensi Masalah
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Potensi Masalah",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.black,
                    ),
                    label: const Text(
                      "Lihat Semua",
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    PotensiCard(
                      imagePath: "assets/home/kesehatan.png",
                      title: "Kumpulan\nMasalah Kesehatan",
                    ),
                    SizedBox(width: 12),
                    PotensiCard(
                      imagePath: "assets/home/ibadah.png",
                      title: "Kumpulan\nMasalah Ibadah",
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
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildHomeTab(),
            HistoryScreen(key: _historyKey, isTab: true),
            const ProfileScreen(isTab: true),
          ],
        ),

        // 🔻 Bottom Navbar
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          color: const Color(0xFF842D62),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home),
                color: _currentTabIndex == 0 ? Colors.white : Colors.white70,
                tooltip: "Beranda",
                onPressed: () {
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
              IconButton(
                icon: const Icon(Icons.assignment),
                color: Colors.white70,
                tooltip: "Tugas Ceklis",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChecklistListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 40),
              IconButton(
                icon: const Icon(Icons.history),
                color: _currentTabIndex == 1 ? Colors.white : Colors.white70,
                tooltip: "History Scan",
                onPressed: () {
                  if (_currentTabIndex == 1) {
                    _historyKey.currentState?.reload();
                  } else {
                    setState(() => _currentTabIndex = 1);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.person),
                color: _currentTabIndex == 2 ? Colors.white : Colors.white70,
                tooltip: "Profil",
                onPressed: () {
                  setState(() => _currentTabIndex = 2);
                },
              ),
            ],
          ),
        ),

        // 📸 FAB Scan
        floatingActionButton: SizedBox(
          height: 70,
          width: 70,
          child: FloatingActionButton(
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
              Icons.qr_code_scanner,
              color: Color(0xFF842D62),
              size: 40,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}

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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
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
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF842D62),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 43, height: 43, fit: BoxFit.contain),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class PotensiCard extends StatelessWidget {
  final String imagePath;
  final String title;
  const PotensiCard({super.key, required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 235,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withOpacity(0.3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
