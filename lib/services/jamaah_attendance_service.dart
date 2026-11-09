import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class JamaahAttendanceService {
  static String get baseUrl {
    var b = ApiService.ROOT_URL.trim();
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    if (!b.endsWith('/api')) b = '$b/api';
    return b;
  }
  
  // ============================================================
  // 🔑 AMBIL TOKEN TOUR LEADER (SELARAS DENGAN LOGIN)
  // ============================================================
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ============================================================
  // 1️⃣ HOME LIST ABSEN JAMAAH
  // ============================================================
  static Future<List<dynamic>> fetchAbsenList() async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan (belum login)');
    }

    var resp = await http.get(
      Uri.parse('$baseUrl/tourleader/attendance-jamaah'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    if (resp.statusCode == 404) {
      resp = await http.get(
        Uri.parse('$baseUrl/attendance'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
    }

    if (resp.statusCode != 200) {
      throw Exception('Load absen gagal: ${resp.body}');
    }

    final body = jsonDecode(resp.body);

    if (body is Map && body['data'] is List) {
      return body['data'];
    }
    if (body is List) {
      return body;
    }

    return [];
  }

  // ============================================================
  // 2️⃣ DETAIL ABSEN + LIST JAMAAH
  // ============================================================
  static Future<Map<String, dynamic>> fetchAbsenDetail(int absenId) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan (belum login)');
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
  // 3️⃣ SUBMIT ABSEN (BISA BERULANG)
  // ============================================================
  static Future<void> submitAttendance({
    required int jamaahId,
    required int absensiJamaahId,
    required String status,
    String? catatan,
  }) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan (belum login)');
    }

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

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Submit gagal: ${resp.body}');
    }
  }

  // ============================================================
  // 4️⃣ SUBMIT BULK ABSENSI
  // ============================================================
  static Future<void> submitBulk({
    required int absensiJamaahId,
    required List<Map<String, dynamic>> data,
  }) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan (belum login)');
    }

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

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Bulk submit gagal: ${resp.body}');
    }
  }
}
