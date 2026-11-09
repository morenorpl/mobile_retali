import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Model tugas
import '../models/task_models.dart';
// Model checklist
import '../models/checklist_models.dart';

// ambil ROOT_URL dari ApiService
import 'api_service.dart';
import 'supabase_service.dart';

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
        'Accept': 'application/json',
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
    var res = await http.get(
      Uri.parse('$_baseUrl/tourleader/tasks'),
      headers: _headers(token),
    );

    if (res.statusCode == 404) {
      res = await http.get(
        Uri.parse('$_baseUrl/tasks/mine'),
        headers: _headers(token),
      );
    }

    if (res.statusCode == 404) {
      res = await http.get(
        Uri.parse('$_baseUrl/tasks'),
        headers: _headers(token),
      );
    }

    if (res.statusCode != 200) {
      throw Exception("Gagal ambil daftar tugas: ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    final list =
        (decoded is Map<String, dynamic> ? decoded['data'] ?? decoded['tasks'] : decoded) as List;

    return list
        .map((e) => TaskSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// DETAIL TUGAS + SOAL
  static Future<TaskDetail> getTaskDetail(int id) async {
    final token = await _getToken();
    var res = await http.get(
      Uri.parse('$_baseUrl/tourleader/tasks/$id'),
      headers: _headers(token),
    );

    if (res.statusCode == 404) {
      res = await http.get(
        Uri.parse('$_baseUrl/tasks/$id'),
        headers: _headers(token),
      );
    }

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
    var res = await http.post(
      Uri.parse('$_baseUrl/tourleader/tasks/$id/done'),
      headers: _headers(token),
    );

    if (res.statusCode == 404) {
      res = await http.patch(
        Uri.parse('$_baseUrl/tasks/$id/status'),
        headers: _headers(token),
        body: jsonEncode({'status': 'selesai'}),
      );
    }

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? body['detail'] ?? "Gagal submit tugas");
    }

    final decoded = jsonDecode(res.body);
    final iso = decoded['done_at'] ?? DateTime.now().toIso8601String();
    return DateTime.parse(iso).toLocal();
  }

  // ===========================================================================
  // ======================= TUGAS - PER SOAL ================================
  // ===========================================================================

  /// Ambil status per soal (id soal yang sudah dijawab)
  static Future<Set<int>> getTaskAnswers(int taskId) async {
    final token = await _getToken();
    var res = await http.get(
      Uri.parse('$_baseUrl/tourleader/tasks/$taskId/answers'),
      headers: _headers(token),
    );

    if (res.statusCode == 404) {
      res = await http.get(
        Uri.parse('$_baseUrl/tasks/$taskId/answers'),
        headers: _headers(token),
      );
    }

    if (res.statusCode != 200) {
      throw Exception("Gagal ambil status soal");
    }

    final decoded = jsonDecode(res.body);
    final List list = decoded['answers'] ?? [];
    return list.map<int>((e) => e as int).toSet();
  }

  /// Tandai satu soal = SUDAH
  static Future<void> markQuestionDone(
    int taskId,
    int questionId,
  ) async {
    final token = await _getToken();
    var res = await http.post(
      Uri.parse(
          '$_baseUrl/tourleader/tasks/$taskId/questions/$questionId/answer'),
      headers: _headers(token),
    );

    if (res.statusCode == 404) {
      res = await http.post(
        Uri.parse('$_baseUrl/tasks/$taskId/questions/$questionId/answer'),
        headers: _headers(token),
      );
    }

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
    var res = await http.delete(
      Uri.parse(
          '$_baseUrl/tourleader/tasks/$taskId/questions/$questionId/answer'),
      headers: _headers(token),
    );

    if (res.statusCode == 404) {
      res = await http.delete(
        Uri.parse('$_baseUrl/tasks/$taskId/questions/$questionId/answer'),
        headers: _headers(token),
      );
    }

    if (res.statusCode != 200) {
      throw Exception("Gagal membatalkan soal");
    }
  }

  // ===========================================================================
  // =========================== CHECKLIST =====================================
  // ===========================================================================

  static Future<List<ChecklistSummary>> getChecklistList() async {
    // 1. Ambil dari tabel Supabase checklist_ assignments berdasarkan petugas yang sedang login
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString("user_id") ?? prefs.getString("id");
        final email = prefs.getString("email");

        // Jika userId kosong atau belum berupa UUID profiles, cari dari tabel profiles berdasarkan email
        if (email != null && email.isNotEmpty) {
          try {
            final profile = await client
                .from('profiles')
                .select('id, role, username')
                .eq('email', email)
                .maybeSingle();

            if (profile != null && profile['id'] != null) {
              userId = profile['id'].toString();
              await prefs.setString("user_id", userId);
              await prefs.setString("id", userId);
              if (profile['role'] != null) {
                await prefs.setString("role", profile['role'].toString());
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error resolve profile by email in getChecklistList: $e');
          }
        }

        if (userId != null && userId.isNotEmpty) {
          // Ambil checklist_assignments khusus petugas ini (recipient_id = userId)
          final assignments = await client
              .from('checklist_assignments')
              .select('*, checklist_tasks(*)')
              .eq('recipient_id', userId)
              .order('assigned_at', ascending: false);

          final result = <ChecklistSummary>[];
          for (final item in assignments) {
            final task = item['checklist_tasks'] as Map<String, dynamic>?;
            if (task == null) continue;

            result.add(ChecklistSummary.fromJson({
              'id': item['id'],
              'assignment_id': item['id'],
              'task_id': item['task_id'],
              'recipient_id': item['recipient_id'],
              'title': task['title'] ?? 'Checklist',
              'description': task['description'],
              'opens_at': task['opens_at'],
              'closes_at': task['closes_at'],
              'status': task['status'],
              'assignment_status': item['status'],
              'submitted_at': item['submitted_at'],
              'done_at': (item['status'] == 'completed' || item['submitted_at'] != null)
                  ? (item['submitted_at'] ?? item['assigned_at'])
                  : null,
            }));
          }
          return result;
        }
      } catch (e) {
        debugPrint('⚠️ Gagal ambil checklist dari Supabase: $e');
      }
    }

    // 2. Fallback ke endpoint backend HTTP jika Supabase offline/error
    final token = await _getToken();
    var res = await http.get(
      Uri.parse('$_baseUrl/tourleader/checklist'),
      headers: _headers(token),
    );

    if (res.statusCode == 404) {
      res = await http.get(
        Uri.parse('$_baseUrl/checklist-tasks/my-assignments'),
        headers: _headers(token),
      );
    }

    if (res.statusCode == 404) {
      res = await http.get(
        Uri.parse('$_baseUrl/checklist-tasks'),
        headers: _headers(token),
      );
    }

    if (res.statusCode != 200) {
      throw Exception("Gagal ambil daftar ceklis: ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    final list =
        (decoded is Map<String, dynamic> ? decoded['data'] ?? decoded['assignments'] : decoded) as List;

    return list
        .map((e) => ChecklistSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<ChecklistDetail> getChecklistDetail(dynamic id) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final idStr = id.toString();
        // Coba cari assignment berdasarkan id
        var assignment = await client
            .from('checklist_assignments')
            .select('*, checklist_tasks(*)')
            .eq('id', idStr)
            .maybeSingle();

        Map<String, dynamic>? task;
        String taskId = idStr;
        String? assignmentId;
        bool isSubmitted = false;

        if (assignment != null) {
          assignmentId = assignment['id']?.toString();
          taskId = assignment['task_id']?.toString() ?? idStr;
          task = assignment['checklist_tasks'] as Map<String, dynamic>?;
          isSubmitted = assignment['status'] == 'completed' || assignment['submitted_at'] != null;
        } else {
          // Jika id yang dioper adalah task_id
          task = await client
              .from('checklist_tasks')
              .select('*')
              .eq('id', idStr)
              .maybeSingle();
        }

        if (task != null) {
          final questionsRes = await client
              .from('checklist_questions')
              .select('*')
              .eq('task_id', taskId)
              .order('sort_order', ascending: true);

          final questions = (questionsRes as List)
              .map((q) => ChecklistQuestion.fromJson(q as Map<String, dynamic>))
              .toList();

          return ChecklistDetail(
            id: assignmentId ?? taskId,
            taskId: taskId,
            assignmentId: assignmentId,
            title: (task['title'] ?? 'Checklist Detail').toString(),
            status: (task['status'] ?? 'dibuka').toString(),
            submitted: isSubmitted,
            questions: questions,
          );
        }
      } catch (e) {
        debugPrint('⚠️ Error Supabase getChecklistDetail: $e');
      }
    }

    // Fallback ke REST backend
    final token = await _getToken();
    var res = await http.get(
      Uri.parse('$_baseUrl/tourleader/checklist/$id'),
      headers: _headers(token),
    );

    if (res.statusCode == 404) {
      res = await http.get(
        Uri.parse('$_baseUrl/checklist-tasks/assignments/$id'),
        headers: _headers(token),
      );
    }

    if (res.statusCode == 404) {
      res = await http.get(
        Uri.parse('$_baseUrl/checklist-tasks/$id'),
        headers: _headers(token),
      );
    }

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
    required dynamic checklistId,
    required String namaPetugas,
    required List<Map<String, dynamic>> answers,
  }) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final idStr = checklistId.toString();
        var assignment = await client
            .from('checklist_assignments')
            .select('*')
            .eq('id', idStr)
            .maybeSingle();

        String assignmentId = idStr;
        if (assignment == null) {
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString("user_id") ?? prefs.getString("id");
          if (userId != null) {
            assignment = await client
                .from('checklist_assignments')
                .select('*')
                .eq('task_id', idStr)
                .eq('recipient_id', userId)
                .maybeSingle();
            if (assignment != null) {
              assignmentId = assignment['id'].toString();
            }
          }
        }

        // 1. Simpan jawaban ke checklist_answers
        for (final ans in answers) {
          final qId = ans['checklist_question_id'] ?? ans['question_id'];
          final val = ans['value'] ?? ans['answer'] ?? '';
          final note = ans['note'];
          final answerText = (note != null && note.toString().isNotEmpty)
              ? '$val (Catatan: $note)'
              : val.toString();

          try {
            await client.from('checklist_answers').insert({
              'assignment_id': assignmentId,
              'question_id': qId,
              'answer': answerText,
            });
          } catch (e) {
            debugPrint('⚠️ Error insert checklist_answer ($qId): $e');
          }
        }

        // 2. Update status assignment menjadi completed
        final nowIso = DateTime.now().toUtc().toIso8601String();
        await client.from('checklist_assignments').update({
          'status': 'completed',
          'submitted_at': nowIso,
        }).eq('id', assignmentId);

        return;
      } catch (e) {
        debugPrint('⚠️ Error submitChecklist via Supabase: $e');
      }
    }

    // Fallback ke REST backend
    final token = await _getToken();

    final body = jsonEncode({
      'nama_petugas': namaPetugas,
      'answers': answers,
    });

    var res = await http.post(
      Uri.parse('$_baseUrl/tourleader/checklist/$checklistId/submit'),
      headers: _headers(token),
      body: body,
    );

    if (res.statusCode == 404) {
      res = await http.post(
        Uri.parse('$_baseUrl/checklist-tasks/assignments/$checklistId/submit'),
        headers: _headers(token),
        body: body,
      );
    }

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Gagal submit ceklis: ${res.body}");
    }
  }
}
