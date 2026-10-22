import 'package:flutter/material.dart';

class AppTheme {
  static const brand = Color(0xFF7A3456);
  static const _shadow = Color(0x14000000);

  static TextStyle get title =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

  static TextStyle get muted =>
      const TextStyle(fontSize: 12, color: Colors.black54);

  /// Format tanggal dari string ISO (misal: "2025-11-22" atau "2025-11-22T00:00:00.000000Z")
  /// jadi: "22 November 2025"
  static String fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;

    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${d.day} ${bulan[d.month - 1]} ${d.year}';
  }

  /// Range tanggal: "22 November 2025 - 25 November 2025"
  static String rangeDate(String? start, String? end) {
    final a = fmtDate(start);
    final b = fmtDate(end);
    if (a.isEmpty && b.isEmpty) return '';
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    return '$a - $b';
  }

  static const shadow = [
    BoxShadow(
      color: _shadow,
      blurRadius: 8,
      offset: Offset(0, 2),
    )
  ];
}

class AppCard extends StatelessWidget {
  final Widget child;
  const AppCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.shadow,
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class AppPill extends StatelessWidget {
  final String text;
  const AppPill({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xfff2f2f2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          )
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class AppChip extends StatelessWidget {
  final String label;
  const AppChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          )
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AppEmptyCard extends StatelessWidget {
  final String text;
  const AppEmptyCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        child: Center(
          child: Text(text),
        ),
      ),
    );
  }
}