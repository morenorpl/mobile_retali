import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_retali/services/api_service.dart';
import 'package:mobile_retali/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isTab;
  const ProfileScreen({super.key, this.isTab = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;

  String _kloterLabel(String? raw) {
    switch (raw) {
      case 'umrah_reguler_cemerlang':
        return 'Umrah Reguler Cemerlang';
      case 'umrah_reguler_super_cermat':
        return 'Umrah Reguler Super Cermat';
      default:
        // kalau backend kirim nama bebas (mis. "Umrah Turki"), tampilkan apa adanya
        if (raw != null && raw.trim().isNotEmpty) return raw.trim();
        return '-';
    }
  }

  Future<Map<String, String>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "name": prefs.getString("name") ?? "Tourleader",
      "email": prefs.getString("email") ?? "Not set",
      "kloter": prefs.getString("kloter") ?? "-",
      "kloter_tanggal": prefs.getString("kloter_tanggal") ?? "-",
      "role": prefs.getString("role") ?? "tourleader",
    };
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await ApiService.logout();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal logout: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Konfirmasi Keluar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi retali sistem? Anda perlu login kembali untuk mengakses data kloter.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF64748B),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _logout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ya, Keluar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1B3167).withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1B3167).withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1B3167),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D1523).withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1B3167),
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Memuat profil...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data!;
        final kloterNice = _kloterLabel(user['kloter']);
        final tanggalKloter = (user['kloter_tanggal'] ?? '').trim().isEmpty
            ? '-'
            : user['kloter_tanggal']!.trim();

        final rawRole = (user['role'] ?? '')
            .toString()
            .toLowerCase()
            .replaceAll('_', '')
            .trim();
        final roleLabel = rawRole == 'muthawif' ? 'Muthawif' : 'Tour Leader';
        final userName = (user['name'] ?? '').trim().isEmpty
            ? 'Tourleader'
            : user['name']!.trim();
        final userEmail = (user['email'] ?? '').trim().isEmpty
            ? 'Not set'
            : user['email']!.trim();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // 1. HEADER WITH CURVED BOTTOM & OVERLAPPING AVATAR
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Curved Navy Gradient Header
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF0D1523), // Primary Dark
                            Color(0xFF1B3167), // Primary Navy
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(36),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x330D1523),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Subtle background decorative circles
                          Positioned(
                            top: -40,
                            right: -30,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.06),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -10,
                            right: 10,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFEAB308).withOpacity(0.12),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            left: -25,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          // Header Bar Content
                          SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 70),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (!widget.isTab)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.arrow_back_ios_new_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              Navigator.of(context).maybePop(),
                                          tooltip: 'Kembali',
                                        )
                                      else
                                        const SizedBox(width: 48),
                                      const Text(
                                        "Profil Saya",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 48),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Tour Leader & Muthawif Management",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Overlapping Avatar with Signature Gold Ring
                    Positioned(
                      bottom: -54,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFEAB308), // Accent Gold
                                width: 3.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D1523).withOpacity(0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF263754),
                                    Color(0xFF1B3167),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 58,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAB308),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF0D1523),
                                size: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Spacing to clear the bottom half of overlapping avatar
                const SizedBox(height: 64),

                // 2. NAME & ROLE DISPLAYED ELEGANTLY
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        userName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAB308).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFEAB308).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              size: 14,
                              color: Color(0xFF1B3167),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              roleLabel,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B3167),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // 3. PROFILE INFO CARD WITH DIVIDERS
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D1523).withOpacity(0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAB308).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.person_pin_rounded,
                                      color: Color(0xFF1B3167),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    "Informasi Profil",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF1F5F9),
                            ),
                            _buildField(
                              "Nama Lengkap",
                              Icons.person_outline_rounded,
                              userName,
                            ),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              indent: 78,
                              endIndent: 18,
                              color: Color(0xFFF1F5F9),
                            ),
                            _buildField(
                              "Peran / Jabatan",
                              Icons.badge_outlined,
                              roleLabel,
                            ),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              indent: 78,
                              endIndent: 18,
                              color: Color(0xFFF1F5F9),
                            ),
                            _buildField(
                              "Email",
                              Icons.email_outlined,
                              userEmail,
                            ),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              indent: 78,
                              endIndent: 18,
                              color: Color(0xFFF1F5F9),
                            ),
                            _buildField(
                              "Kloter",
                              Icons.groups_outlined,
                              kloterNice,
                            ),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              indent: 78,
                              endIndent: 18,
                              color: Color(0xFFF1F5F9),
                            ),
                            _buildField(
                              "Tanggal Keberangkatan",
                              Icons.calendar_month_outlined,
                              tanggalKloter,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // 4. LOGOUT BUTTON (Outlined Red Border with Confirmation Dialog)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isLoggingOut ? null : _showLogoutConfirmation,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFFEF4444),
                          ),
                          child: _isLoggingOut
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFFEF4444),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Sedang keluar...",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout_rounded,
                                      size: 20,
                                      color: Color(0xFFEF4444),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Keluar dari Aplikasi",
                                      style: TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 5. BRANDING & VERSION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEAB308),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "retali sistem",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B3167),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B3167).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Zero Complaint",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B3167),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Versi 1.0.0 • Umrah Travel Management",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
