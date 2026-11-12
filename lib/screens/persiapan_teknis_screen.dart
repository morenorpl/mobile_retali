import 'package:flutter/material.dart';
import 'persiapan_materi_screen.dart';

class PersiapanTeknisScreen extends StatelessWidget {
  const PersiapanTeknisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PersiapanMateriScreen(category: PersiapanCategory.teknis);
  }
}
