import 'package:flutter/foundation.dart';
import '../models/curriculum_materi.dart';
import 'supabase_service.dart';

class CurriculumService {
  static const String tableName = 'curriculum_tour_leader';

  /// Mengambil daftar materi curriculum tour leader dari tabel Supabase `curriculum_tour_leader`
  static Future<List<CurriculumMateri>> getCurriculums() async {
    // 1. Coba melalui Supabase Client
    try {
      final client = SupabaseService.client;
      if (client != null) {
        final res = await client
            .from(tableName)
            .select()
            .order('sort_order', ascending: true)
            .order('created_at', ascending: true);

        if (res.isNotEmpty) {
          final list = res
              .map((m) => CurriculumMateri.fromMap(Map<String, dynamic>.from(m as Map)))
              .toList();
          return list;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [CurriculumService] Error via client: $e');
    }

    // 2. Fallback melalui Supabase REST direct
    try {
      final restData = await SupabaseService.restGet(tableName, order: 'sort_order.asc');
      if (restData.isNotEmpty) {
        final list = restData
            .map((m) => CurriculumMateri.fromMap(Map<String, dynamic>.from(m as Map)))
            .toList();
        return list;
      }
    } catch (e) {
      debugPrint('⚠️ [CurriculumService] Error via restGet: $e');
    }

    return [];
  }
}
