import 'package:flutter/foundation.dart';
import '../models/persiapan_materi.dart';
import 'supabase_service.dart';

class PersiapanService {
  /// Mengambil data persiapan diniyah dari Supabase table `persiapan_diniyah`
  static Future<List<PersiapanMateri>> getPersiapanDiniyah() async {
    return _fetchMateri('persiapan_diniyah');
  }

  /// Mengambil data persiapan teknis dari Supabase table `persiapan_teknis`
  static Future<List<PersiapanMateri>> getPersiapanTeknis() async {
    return _fetchMateri('persiapan_teknis');
  }

  static Future<List<PersiapanMateri>> _fetchMateri(String tableName) async {
    // 1. Coba lewat Supabase client
    try {
      final client = SupabaseService.client;
      if (client != null) {
        final res = await client
            .from(tableName)
            .select()
            .order('created_at', ascending: true);
        if (res.isNotEmpty) {
          final list = res
              .map((m) => PersiapanMateri.fromMap(Map<String, dynamic>.from(m as Map)))
              .toList();
          return list;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [PersiapanService] Error via client ($tableName): $e');
    }

    // 2. Fallback lewat REST direct
    try {
      final restData = await SupabaseService.restGet(tableName, order: 'created_at.asc');
      if (restData.isNotEmpty) {
        final list = restData
            .map((m) => PersiapanMateri.fromMap(Map<String, dynamic>.from(m as Map)))
            .toList();
        return list;
      }
    } catch (e) {
      debugPrint('⚠️ [PersiapanService] Error via restGet ($tableName): $e');
    }

    return [];
  }
}
