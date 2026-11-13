import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'supabase_service.dart';

class JamaahAttendanceService {
  static String get baseUrl {
    var b = ApiService.ROOT_URL.trim();
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    if (!b.endsWith('/api')) b = '$b/api';
    return b;
  }

  // ============================================================
  // 🔑 AMBIL TOKEN TOUR LEADER
  // ============================================================
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ============================================================
  // 1️⃣ HOME LIST ABSEN JAMAAH (SUPABASE & API FALLBACK)
  // ============================================================
  static Future<List<dynamic>> fetchAbsenList() async {
    final client = SupabaseService.client;

    // 1. Coba ambil dari Supabase tabel `attendance_grup`
    if (client != null) {
      try {
        final grupRows = await client
            .from('attendance_grup')
            .select()
            .order('created_at', ascending: false);

        if (grupRows.isNotEmpty) {
          final List<Map<String, dynamic>> result = [];
          for (final row in grupRows) {
            final m = Map<String, dynamic>.from(row as Map);
            final int id = (m['id'] is int)
                ? m['id']
                : int.tryParse('${m['id']}') ?? 0;

            final String sesi = m['sesi']?.toString() ?? 'Sesi Absensi';
            final String kloter = m['kloter']?.toString() ?? 'Kloter Umum';
            final int total = (m['total_jamaah'] is int)
                ? m['total_jamaah']
                : int.tryParse('${m['total_jamaah']}') ?? 0;

            result.add({
              'id': id,
              'judul_absen': sesi,
              'kloter': {'nama': kloter},
              'periode_kloter': m['kloter_date']?.toString() ?? 'Periode Umrah 2026',
              'tanggal_operasional': m['created_at']?.toString() ?? '',
              'sesi_lengkap': sesi,
              'jamaah_count': total,
              'is_done': false,
            });
          }
          debugPrint('✅ [JamaahAttendanceService] Loaded ${result.length} groups from Supabase');
          return result;
        }
      } catch (e) {
        debugPrint('⚠️ [JamaahAttendanceService] Supabase fetch error: $e');
      }
    }

    // 2. Fallback via HTTP REST API
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return [];
    }

    try {
      var resp = await http.get(
        Uri.parse('$baseUrl/tourleader/attendance-jamaah'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 404) {
        resp = await http.get(
          Uri.parse('$baseUrl/attendance'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is Map && body['data'] is List) {
          return body['data'];
        }
        if (body is List) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [JamaahAttendanceService] REST fetch error: $e');
    }

    return [];
  }

  // ============================================================
  // 2️⃣ DETAIL ABSEN + LIST JAMAAH (SUPABASE & API FALLBACK)
  // ============================================================
  static Future<Map<String, dynamic>> fetchAbsenDetail(int absenId) async {
    final client = SupabaseService.client;

    // 1. Coba ambil dari Supabase tabel `attendance_grup` & `attendance_user`
    if (client != null) {
      try {
        final grup = await client
            .from('attendance_grup')
            .select()
            .eq('id', absenId)
            .maybeSingle();

        final userRows = await client
            .from('attendance_user')
            .select()
            .eq('grup_id', absenId)
            .order('created_at', ascending: true);

        if (userRows.isNotEmpty || grup != null) {
          final List<Map<String, dynamic>> jamaahList = [];
          for (int i = 0; i < userRows.length; i++) {
            final u = Map<String, dynamic>.from(userRows[i] as Map);
            final statusRaw = (u['attendance_status'] ?? '').toString().toLowerCase();

            String mappedStatus = 'BELUM_ABSEN';
            if (statusRaw == 'hadir') {
              mappedStatus = 'HADIR';
            } else if (statusRaw == 'tidak_hadir' ||
                statusRaw == 'alpa' ||
                statusRaw == 'izin' ||
                statusRaw == 'sakit') {
              mappedStatus = 'TIDAK_HADIR';
            }

            // Ekstrak angka nomor bus dari text (misal "Bus 1" -> 1)
            final busStr = u['bus']?.toString() ?? '1';
            final busNum = int.tryParse(busStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;

            jamaahList.add({
              'jamaah_id': i + 1,
              'db_id': u['id'], // ID UUID asli di database
              'urutan': i + 1,
              'nama_jamaah': u['jamaah_name']?.toString() ?? '-',
              'no_paspor': u['passport_number']?.toString() ?? '-',
              'no_hp': u['phone_number']?.toString() ?? '-',
              'kode_kloter': u['kloter']?.toString() ?? grup?['kloter']?.toString() ?? '-',
              'nomor_bus': busNum,
              'status': mappedStatus,
              'catatan': u['note']?.toString(),
            });
          }

          return {
            'absen': {
              'id': absenId,
              'periode_kloter': grup?['kloter_date']?.toString() ?? 'Periode Umrah 2026',
              'kloter': grup?['kloter']?.toString() ?? '-',
              'sesi': grup?['sesi']?.toString() ?? '-',
            },
            'jamaah': jamaahList,
          };
        }
      } catch (e) {
        debugPrint('⚠️ [JamaahAttendanceService] Supabase detail error: $e');
      }
    }

    // 2. Fallback via HTTP REST API
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan');
    }

    var resp = await http.get(
      Uri.parse('$baseUrl/tourleader/attendance-jamaah/$absenId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode == 404) {
      resp = await http.get(
        Uri.parse('$baseUrl/attendance/$absenId'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
    }

    if (resp.statusCode != 200) {
      throw Exception('Load detail gagal: ${resp.body}');
    }

    return jsonDecode(resp.body);
  }

  // ============================================================
  // 3️⃣ SUBMIT ABSEN (SUPABASE & API FALLBACK)
  // ============================================================
  static Future<void> submitAttendance({
    required int jamaahId,
    required int absensiJamaahId,
    required String status,
    String? catatan,
  }) async {
    final client = SupabaseService.client;
    final nowIso = DateTime.now().toIso8601String();

    String dbStatus = 'belum_hadir';
    if (status.toUpperCase() == 'HADIR') {
      dbStatus = 'hadir';
    } else if (status.toUpperCase() == 'TIDAK_HADIR') {
      dbStatus = 'tidak_hadir';
    }

    // 1. Coba update ke Supabase
    if (client != null) {
      try {
        final users = await client
            .from('attendance_user')
            .select('id')
            .eq('grup_id', absensiJamaahId)
            .order('created_at', ascending: true);

        if (users.isNotEmpty && jamaahId > 0 && jamaahId <= users.length) {
          final targetUuid = users[jamaahId - 1]['id'];
          await client.from('attendance_user').update({
            'attendance_status': dbStatus,
            'note': catatan,
            'updated_at': nowIso,
          }).eq('id', targetUuid);

          debugPrint('✅ [JamaahAttendanceService] Single update success to Supabase');
          return;
        }
      } catch (e) {
        debugPrint('⚠️ [JamaahAttendanceService] Supabase submit error: $e');
      }
    }

    // 2. Fallback ke Backend API
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    var resp = await http.post(
      Uri.parse('$baseUrl/tourleader/attendance-jamaah'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'jamaah_id': jamaahId,
        'absensi_jamaah_id': absensiJamaahId,
        'status': status,
        'catatan': catatan,
      }),
    );

    if (resp.statusCode == 404) {
      resp = await http.post(
        Uri.parse('$baseUrl/attendance'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': jamaahId.toString(),
          'type': status,
          'note': catatan,
        }),
      );
    }
  }

  // ============================================================
  // 4️⃣ SUBMIT BULK ABSENSI (SUPABASE & API FALLBACK)
  // ============================================================
  static Future<void> submitBulk({
    required int absensiJamaahId,
    required List<Map<String, dynamic>> data,
  }) async {
    final client = SupabaseService.client;
    final nowIso = DateTime.now().toIso8601String();

    // 1. Coba update ke Supabase secara bulk/iterasi
    if (client != null) {
      try {
        final users = await client
            .from('attendance_user')
            .select('id')
            .eq('grup_id', absensiJamaahId)
            .order('created_at', ascending: true);

        for (final item in data) {
          final int jId = item['jamaah_id'] ?? 0;
          final String st = (item['status'] ?? 'BELUM_ABSEN').toString();
          final String? cat = item['catatan'];

          String dbStatus = 'belum_hadir';
          if (st.toUpperCase() == 'HADIR') dbStatus = 'hadir';
          if (st.toUpperCase() == 'TIDAK_HADIR') dbStatus = 'tidak_hadir';

          if (jId > 0 && jId <= users.length) {
            final targetUuid = users[jId - 1]['id'];
            await client.from('attendance_user').update({
              'attendance_status': dbStatus,
              'note': cat,
              'updated_at': nowIso,
            }).eq('id', targetUuid);
          }
        }
        debugPrint('✅ [JamaahAttendanceService] Bulk update success to Supabase');
        return;
      } catch (e) {
        debugPrint('⚠️ [JamaahAttendanceService] Supabase bulk error: $e');
      }
    }

    // 2. Fallback via HTTP REST API
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    var resp = await http.post(
      Uri.parse('$baseUrl/tourleader/attendance-jamaah/bulk'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'absensi_jamaah_id': absensiJamaahId, 'data': data}),
    );

    if (resp.statusCode == 404) {
      resp = await http.post(
        Uri.parse('$baseUrl/attendance'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'absensi_jamaah_id': absensiJamaahId, 'data': data}),
      );
    }
  }
}
