import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Model tugas
import '../models/task_models.dart';
// Model checklist
import '../models/checklist_models.dart';

// ambil ROOT_URL dari ApiService
import 'api_service.dart';

class TugasService {
  // ===========================================================================
  // BASE URL
  // ===========================================================================
  static String get _baseUrl {
    var b = ApiService.ROOT_URL.trim();
    if (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    if (!b.endsWith('/api')) {
      b = '$b/api';
    }
    return b;
  }

  // ===========================================================================
  // TOKEN
  // ===========================================================================
  static Future<String?> _getToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('tl_token') ??
        sp.getString('tourleader_token') ??
        sp.getString('token');
  }

  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
  };

  // ===========================================================================
  // =========================== TUGAS =========================================
  // ===========================================================================

  /// LIST TUGAS
  static Future<List<TaskSummary>> getTasks() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/tourleader/tasks'),
      headers: _headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception("Gagal ambil daftar tugas: ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    final list =
        (decoded is Map<String, dynamic> ? decoded['data'] : decoded) as List;

    return list
        .map((e) => TaskSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// DETAIL TUGAS + SOAL
  static Future<TaskDetail> getTaskDetail(int id) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/tourleader/tasks/$id'),
      headers: _headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception("Gagal ambil detail tugas: ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    final data = decoded is Map<String, dynamic>
        ? decoded['data'] ?? decoded
        : decoded;

    return TaskDetail.fromJson(data);
  }

  /// SUBMIT FINAL (SELESAIKAN TUGAS)
  static Future<DateTime> markTaskDone(int id) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse('$_baseUrl/tourleader/tasks/$id/done'),
      headers: _headers(token),
    );

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? "Gagal submit tugas");
    }

    final iso = jsonDecode(res.body)['done_at'];
    return DateTime.parse(iso).toLocal();
  }

  // ===========================================================================
  // ======================= TUGAS - PER SOAL ================================
  // ===========================================================================

  /// Ambil status per soal (id soal yang sudah dijawab)
  /// Ambil status per soal (id soal yang sudah dijawab)
static Future<Set<int>> getTaskAnswers(int taskId) async {
  final token = await _getToken();
  final res = await http.get(
    Uri.parse('$_baseUrl/tourleader/tasks/$taskId/answers'),
    headers: _headers(token),
  );

  if (res.statusCode != 200) {
    throw Exception("Gagal ambil status soal");
  }

  final decoded = jsonDecode(res.body);

  final List list = decoded['answers'] ?? [];

  // ⬅️ KARENA ISINYA SUDAH INT
  return list.map<int>((e) => e as int).toSet();
}



  /// Tandai satu soal = SUDAH
  static Future<void> markQuestionDone(
    int taskId,
    int questionId,
  ) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse(
          '$_baseUrl/tourleader/tasks/$taskId/questions/$questionId/answer'),
      headers: _headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception("Gagal menandai soal");
    }
  }

  /// Tandai satu soal = BELUM
  static Future<void> markQuestionUndone(
    int taskId,
    int questionId,
  ) async {
    final token = await _getToken();
    final res = await http.delete(
      Uri.parse(
          '$_baseUrl/tourleader/tasks/$taskId/questions/$questionId/answer'),
      headers: _headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception("Gagal membatalkan soal");
    }
  }

  // ===========================================================================
  // =========================== CHECKLIST =====================================
  // ===========================================================================

  static Future<List<ChecklistSummary>> getChecklistList() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/tourleader/checklist'),
      headers: _headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception("Gagal ambil daftar ceklis: ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    final list =
        (decoded is Map<String, dynamic> ? decoded['data'] : decoded) as List;

    return list
        .map((e) => ChecklistSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<ChecklistDetail> getChecklistDetail(int id) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/tourleader/checklist/$id'),
      headers: _headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception("Gagal ambil detail ceklis: ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    final data = decoded is Map<String, dynamic>
        ? decoded['data'] ?? decoded
        : decoded;

    return ChecklistDetail.fromJson(data);
  }

  static Future<void> submitChecklist({
  required int checklistId,
  required String namaPetugas,
  required List<Map<String, dynamic>> answers,
}) async {
  final token = await _getToken();

  final body = jsonEncode({
    'nama_petugas': namaPetugas,
    'answers': answers,
  });

  final res = await http.post(
    Uri.parse('$_baseUrl/tourleader/checklist/$checklistId/submit'),
    headers: _headers(token),
    body: body,
  );

  if (res.statusCode != 200) {
    throw Exception("Gagal submit ceklis: ${res.body}");
  }
}

}
