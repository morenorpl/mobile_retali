import 'package:flutter/material.dart';
import 'persiapan_materi_screen.dart';

class PersiapanDiniyahScreen extends StatelessWidget {
  const PersiapanDiniyahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PersiapanMateriScreen(category: PersiapanCategory.diniyah);
  }
}
