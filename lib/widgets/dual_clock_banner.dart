import 'dart:async';
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
    final arabHour = DateFormat('HH:mm:ss').format(arabTime);
    final arabHourArabic = _toArabicNumber(arabHour);

    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage("assets/home/masjid_madinah.jpg"), // ganti sesuai asset kamu
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 📅 Tanggal Indonesia
            Text(
              indoDate,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            // 🕒 Jam besar Arab (pakai angka Arab)
            Center(
              child: Text(
                arabHourArabic,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),

            // 🕰 Zona waktu bawah
            Center(
              child: Text(
                "Arab: ${_toArabicNumber(DateFormat('HH:mm').format(arabTime))} | Jakarta: ${DateFormat('HH:mm').format(jakartaTime)}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
