import 'package:flutter/material.dart';
import 'persiapan_diniyah_screen.dart'; // Import halaman tujuan

class PersiapanUmrahScreen extends StatelessWidget {
  const PersiapanUmrahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: AppBar(
        elevation: 4,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5C1C3B), Color(0xFF842D62)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Persiapan Umrah",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      // 🌙 Body dengan grid card elegan
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          children: [
            // 💠 Card Persiapan Diniyah
            _buildMenuCard(
              context,
              title: "Persiapan Diniyah",
              imagePath: "assets/diniyah/diniyah.png",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PersiapanDiniyahScreen(),
                  ),
                );
              },
            ),

            // 💠 Card Persiapan Teknis
            _buildMenuCard(
              context,
              title: "Persiapan Teknis",
              imagePath: "assets/diniyah/teknis.png",
              onTap: () {
                // TODO: Navigasi ke Persiapan Teknis
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Widget Reusable Card Menu
  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0xFF842D62).withOpacity(0.3),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF842D62), Color(0xFF5C1C3B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gambar dengan sedikit bayangan lembut
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  imagePath,
                  height: 65,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 3,
                width: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37), // aksen emas lembut ✨
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}