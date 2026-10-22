import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class KoperDetailScreen extends StatelessWidget {
  const KoperDetailScreen({
    super.key,
    required this.kode,
    required this.namaPemilik,
    required this.phone,
    required this.timestamp,
    required this.kloter,
  });

  final String kode;
  final String namaPemilik;
  final String phone;
  final String timestamp;
  final String kloter;

  // 🎨 Warna disamakan dengan tema utama (Home)
  static const Color _primaryColor = Color(0xFF842D62);
  static const Color _secondaryColor = Color(0xFFA84B7C);
  static const Color _pageBg = Color(0xFFFDF8FB);
  static const Color _cardBg = Colors.white;

  String _formatTimestamp(String timestamp) {
    try {
      if (timestamp.contains('•')) return timestamp;
      final dt = DateTime.tryParse(timestamp.replaceFirst(' ', 'T'));
      if (dt != null) {
        final localDt = dt.toLocal();
        final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
        final timeFormat = DateFormat('HH:mm:ss', 'id_ID');
        return '${dateFormat.format(localDt)} • ${timeFormat.format(localDt)}';
      }
      return timestamp;
    } catch (e) {
      return timestamp;
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
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Detail Koper',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🧳 Header Card
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
                      Icons.luggage_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    kode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kode Koper',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 📄 Informasi Detail
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
                  Row(
                    children: const [
                      Icon(Icons.info_outline_rounded,
                          color: _primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Informasi Detail',
                        style: TextStyle(
                          color: _primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoItem(
                    icon: Icons.person_rounded,
                    label: 'Nama Pemilik',
                    value: namaPemilik.isNotEmpty ? namaPemilik : '-',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    icon: Icons.phone_rounded,
                    label: 'Nomor Telepon',
                    value: phone.isNotEmpty ? phone : '-',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    icon: Icons.groups_rounded,
                    label: 'Kloter',
                    value: kloter.isNotEmpty ? kloter : '-',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    icon: Icons.access_time_rounded,
                    label: 'Waktu Scan',
                    value: formattedTimestamp,
                    isTimestamp: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ✅ Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status TerScan',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Koper berhasil discan dan tersimpan di sistem',
                          style: TextStyle(
                            color: _primaryColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isTimestamp = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: _primaryColor.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: isTimestamp ? 13.5 : 15,
                  fontWeight: isTimestamp ? FontWeight.w500 : FontWeight.w700,
                  fontFamily: isTimestamp ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}