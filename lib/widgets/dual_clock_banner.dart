import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DualClockBanner extends StatefulWidget {
  const DualClockBanner({super.key});

  @override
  State<DualClockBanner> createState() => _DualClockBannerState();
}

class _DualClockBannerState extends State<DualClockBanner> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  // 🔢 Fungsi ubah angka Latin ke angka Arab
  String _toArabicNumber(String input) {
    const arabicDigits = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    return input.replaceAllMapped(RegExp(r'[0-9]'),
        (match) => arabicDigits[int.parse(match.group(0)!)]
    );
  }

  @override
  void initState() {
    super.initState();
    // Update jam setiap detik
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Zona waktu
    final jakartaTime = _now.toUtc().add(const Duration(hours: 7));
    final arabTime = _now.toUtc().add(const Duration(hours: 3));

    // Format tanggal Indonesia
    final indoDate =
        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(jakartaTime);

    // Format jam
    final jakartaHour = DateFormat('HH:mm:ss').format(jakartaTime);
    final arabHour = DateFormat('HH:mm:ss').format(arabTime);
    final arabHourArabic = _toArabicNumber(arabHour);

    return Container(
      height: 136,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1523).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gambar Masjid Background
            Image.asset(
              "assets/home/masjid_madinah.jpg",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF0D1523),
              ),
            ),

            // BackdropFilter Blur & Dark Navy Semi-Transparent Glass Overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0D1523).withValues(alpha: 0.82),
                      const Color(0xFF1B3167).withValues(alpha: 0.72),
                      const Color(0xFF0D1523).withValues(alpha: 0.88),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEAB308).withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Dua zona waktu (Kiri: Jakarta, Kanan: Arab Saudi)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            // 🇮🇩 Sisi Kiri: Waktu Jakarta
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Nama Kota
                                  Text(
                                    "JAKARTA",
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),

                                  // Jam Besar Jakarta
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      jakartaHour,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 23,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),

                                  // Label Zona Waktu
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "WIB (UTC+7)",
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ✨ Golden Accent Divider di Tengah
                            Container(
                              height: 48,
                              width: 1.5,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFFEAB308).withValues(alpha: 0.05),
                                    const Color(0xFFEAB308).withValues(alpha: 0.85),
                                    const Color(0xFFEAB308).withValues(alpha: 0.05),
                                  ],
                                ),
                              ),
                            ),

                            // 🇸🇦 Sisi Kanan: Waktu Arab Saudi
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Nama Wilayah / Kota
                                  const Text(
                                    "ARAB SAUDI",
                                    style: TextStyle(
                                      color: Color(0xFFEAB308),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),

                                  // Jam Besar Arab (Angka Arab)
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      arabHourArabic,
                                      style: const TextStyle(
                                        color: Color(0xFFEAB308),
                                        fontSize: 23,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),

                                  // Label Zona Waktu
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAB308).withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "WSA (UTC+3)",
                                      style: TextStyle(
                                        color: const Color(0xFFEAB308).withValues(alpha: 0.9),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
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

                    // 📅 Tanggal Indonesia elegan di bagian bawah full width
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 5.5,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1523).withValues(alpha: 0.55),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 13,
                              color: const Color(0xFFEAB308).withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              indoDate,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
