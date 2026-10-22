import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class JamaahAttendanceService {
  static const String baseUrl = 'http://36.64.12.107:11281/api';
  
  // ============================================================
  // 🔑 AMBIL TOKEN TOUR LEADER (SELARAS DENGAN LOGIN)
  // ============================================================
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ============================================================
  // 1️⃣ HOME LIST ABSEN JAMAAH
  // GET /tourleader/attendance-jamaah
  // ============================================================
  static Future<List<dynamic>> fetchAbsenList() async {
  final token = await _getToken();

  // 🔥 TAMBAHKAN DI SINI
  print("=== DEBUG TOKEN ===");
  print("TOKEN: $token");

  if (token == null || token.isEmpty) {
    throw Exception('Token tidak ditemukan (belum login)');
  }

  final resp = await http.get(
    Uri.parse('$baseUrl/tourleader/attendance-jamaah'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    },
  );

  // 🔥 TAMBAHKAN JUGA INI BIAR LEBIH JELAS
  print("STATUS CODE: ${resp.statusCode}");
  print("RESPONSE BODY: ${resp.body}");

  if (resp.statusCode != 200) {
    throw Exception('Load absen gagal: ${resp.body}');
  }

  final body = jsonDecode(resp.body);

  if (body is Map && body['data'] is List) {
    return body['data'];
  }

  return [];
}

  // ============================================================
  // 2️⃣ DETAIL ABSEN + LIST JAMAAH
  // GET /tourleader/attendance-jamaah/{id}
  // ============================================================
  static Future<Map<String, dynamic>> fetchAbsenDetail(int absenId) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan (belum login)');
    }

    final resp = await http.get(
      Uri.parse('$baseUrl/tourleader/attendance-jamaah/$absenId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Load detail gagal: ${resp.body}');
    }

    return jsonDecode(resp.body);
  }

  // ============================================================
  // 3️⃣ SUBMIT ABSEN (BISA BERULANG)
  // POST /tourleader/attendance-jamaah
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

    final resp = await http.post(
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

    if (resp.statusCode != 200) {
      throw Exception('Submit gagal: ${resp.body}');
    }
  }

  // ============================================================
  // 4️⃣ SUBMIT BULK ABSENSI
  // POST /tourleader/attendance-jamaah/bulk
  // ============================================================
  static Future<void> submitBulk({
    required int absensiJamaahId,
    required List<Map<String, dynamic>> data,
  }) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan (belum login)');
    }

    final resp = await http.post(
      Uri.parse('$baseUrl/tourleader/attendance-jamaah/bulk'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'absensi_jamaah_id': absensiJamaahId, 'data': data}),
    );

    if (resp.statusCode != 200) {
      throw Exception('Bulk submit gagal: ${resp.body}');
    }
  }
}
