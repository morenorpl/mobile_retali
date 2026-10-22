import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PasporDetailScreen extends StatelessWidget {
  const PasporDetailScreen({
    super.key,
    required this.passportNumber,
    required this.namaPemilik,
    required this.phone,
    required this.timestamp,
    required this.kloter,
  });

  final String passportNumber;
  final String namaPemilik;
  final String phone;
  final String timestamp;
  final String kloter;

  static const Color _primaryColor = Color(0xFF842D62);
  static const Color _secondaryColor = Color(0xFFA84B7C);
  static const Color _pageBg = Color(0xFFFDF8FB);
  static const Color _cardBg = Colors.white;

  String _formatTimestamp(String raw) {
    try {
      if (raw.contains('•')) return raw;

      final dt = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
      if (dt != null) {
        final localDt = dt.toLocal();
        final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
        final timeFormat = DateFormat('HH:mm:ss', 'id_ID');
        return '${dateFormat.format(localDt)} • ${timeFormat.format(localDt)}';
      }
      return raw;
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTimestamp = _formatTimestamp(timestamp);

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Detail Paspor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ============================
            // HEADER CARD
            // ============================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primaryColor, _secondaryColor],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.badge,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    passportNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'NO PASPOR',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ============================
            // DETAIL CARD
            // ============================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Detail',
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _infoItem("Nama Pemilik", namaPemilik),
                  const SizedBox(height: 16),

                  _infoItem("Nomor Telepon", phone),
                  const SizedBox(height: 16),

                  _infoItem("Kloter", kloter),
                  const SizedBox(height: 16),

                  _infoItem("Waktu Scan", formattedTimestamp),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ============================
            // STATUS CARD
            // ============================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle,
                      color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Paspor berhasil discan dan tersimpan di sistem",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  static Widget _infoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            "$label :",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
