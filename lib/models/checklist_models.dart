// lib/models/checklist_models.dart
class ChecklistSummary {
  final int id;
  final String title;
  final DateTime opensAt;
  final DateTime closesAt;
  final String status; // 'belum_dibuka' | 'dibuka' | 'ditutup'
  final DateTime? doneAt;

  ChecklistSummary({
    required this.id,
    required this.title,
    required this.opensAt,
    required this.closesAt,
    required this.status,
    this.doneAt,
  });

  // getter tambahan biar mudah
  bool get submitted => doneAt != null;
  bool get canWork => status == 'dibuka' && !submitted;

  factory ChecklistSummary.fromJson(Map<String, dynamic> j) => ChecklistSummary(
        id: j['id'] as int,
        title: j['title'] as String,
        opensAt: DateTime.parse(j['opens_at']).toLocal(),
        closesAt: DateTime.parse(j['closes_at']).toLocal(),
        status: j['status'] as String,
        doneAt: j['done_at'] != null
            ? DateTime.parse(j['done_at']).toLocal()
            : null,
      );

  // ✅ Tambahkan method copyWith
  ChecklistSummary copyWith({
    int? id,
    String? title,
    DateTime? opensAt,
    DateTime? closesAt,
    String? status,
    DateTime? doneAt,
  }) {
    return ChecklistSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      opensAt: opensAt ?? this.opensAt,
      closesAt: closesAt ?? this.closesAt,
      status: status ?? this.status,
      doneAt: doneAt ?? this.doneAt,
    );
  }
}

// ===================== ChecklistQuestion =====================
class ChecklistQuestion {
  final int id;
  final int orderNo;
  final String text;

  ChecklistQuestion({
    required this.id,
    required this.orderNo,
    required this.text,
  });

  factory ChecklistQuestion.fromJson(Map<String, dynamic> j) =>
      ChecklistQuestion(
        id: j['id'] as int,
        orderNo: j['order_no'] as int,
        text: (j['question_text'] ?? j['text']) as String,
      );
}

// ===================== ChecklistDetail =====================
class ChecklistDetail {
  final int id;
  final String title;
  final String status;
  final bool submitted;
  final List<ChecklistQuestion> questions;

  ChecklistDetail({
    required this.id,
    required this.title,
    required this.status,
    required this.submitted,
    required this.questions,
  });

  factory ChecklistDetail.fromJson(Map<String, dynamic> j) => ChecklistDetail(
        id: j['id'] as int,
        title: j['title'] as String,
        status: j['status'] as String,
        submitted: j['done_at'] != null, // ubah dari submitted ke done_at
        questions: (j['questions'] as List)
            .map((e) => ChecklistQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// nilai jawaban
enum CkAns { sudah, tidak, rekan }

String ckAnsToString(CkAns v) =>
    v == CkAns.sudah ? 'sudah' : v == CkAns.tidak ? 'tidak' : 'rekan';

/// fungsi balik dari string ke enum (untuk load dari SharedPreferences)
CkAns? stringToCkAns(String? s) {
  switch (s) {
    case 'sudah':
      return CkAns.sudah;
    case 'tidak':
      return CkAns.tidak;
    case 'rekan':
      return CkAns.rekan;
    default:
      return null;
  }
}
