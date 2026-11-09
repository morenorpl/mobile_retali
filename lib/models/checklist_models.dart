// lib/models/checklist_models.dart
class ChecklistSummary {
  final dynamic id;
  final String title;
  final DateTime opensAt;
  final DateTime closesAt;
  final String status; // 'belum_dibuka' | 'dibuka' | 'ditutup'
  final DateTime? doneAt;
  final String? taskId;
  final String? assignmentId;
  final String? recipientId;
  final String? assignmentStatus;

  ChecklistSummary({
    required this.id,
    required this.title,
    required this.opensAt,
    required this.closesAt,
    required this.status,
    this.doneAt,
    this.taskId,
    this.assignmentId,
    this.recipientId,
    this.assignmentStatus,
  });

  // getter tambahan biar mudah
  bool get submitted =>
      doneAt != null ||
      assignmentStatus == 'completed' ||
      assignmentStatus == 'submitted';
  bool get canWork => status == 'dibuka' && !submitted;

  factory ChecklistSummary.fromJson(Map<String, dynamic> j) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val == null) return fallback;
      try {
        return DateTime.parse(val.toString()).toLocal();
      } catch (_) {
        return fallback;
      }
    }

    final opens = parseDate(j['opens_at'], DateTime.now());
    final closes = parseDate(
        j['closes_at'], DateTime.now().add(const Duration(days: 7)));

    final now = DateTime.now();
    String st = (j['status'] ?? 'dibuka').toString().toLowerCase();
    if (st == 'published' || st == 'active' || st == 'dibuka') {
      if (now.isBefore(opens)) {
        st = 'belum_dibuka';
      } else if (now.isAfter(closes)) {
        st = 'ditutup';
      } else {
        st = 'dibuka';
      }
    }

    final doneAtVal = j['done_at'] ?? j['submitted_at'];
    final done = doneAtVal != null ? parseDate(doneAtVal, DateTime.now()) : null;

    final assignStatus = (j['assignment_status'] ?? j['status'])?.toString();

    return ChecklistSummary(
      id: j['id'],
      title: (j['title'] ?? 'Checklist') as String,
      opensAt: opens,
      closesAt: closes,
      status: st,
      doneAt: done,
      taskId: j['task_id']?.toString(),
      assignmentId: (j['assignment_id'] ?? j['id'])?.toString(),
      recipientId: j['recipient_id']?.toString(),
      assignmentStatus: assignStatus,
    );
  }

  ChecklistSummary copyWith({
    dynamic id,
    String? title,
    DateTime? opensAt,
    DateTime? closesAt,
    String? status,
    DateTime? doneAt,
    String? taskId,
    String? assignmentId,
    String? recipientId,
    String? assignmentStatus,
  }) {
    return ChecklistSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      opensAt: opensAt ?? this.opensAt,
      closesAt: closesAt ?? this.closesAt,
      status: status ?? this.status,
      doneAt: doneAt ?? this.doneAt,
      taskId: taskId ?? this.taskId,
      assignmentId: assignmentId ?? this.assignmentId,
      recipientId: recipientId ?? this.recipientId,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
    );
  }
}

// ===================== ChecklistQuestion =====================
class ChecklistQuestion {
  final dynamic id;
  final int orderNo;
  final String text;
  final String? answerType;
  final dynamic options;
  final bool isRequired;

  ChecklistQuestion({
    required this.id,
    required this.orderNo,
    required this.text,
    this.answerType,
    this.options,
    this.isRequired = false,
  });

  factory ChecklistQuestion.fromJson(Map<String, dynamic> j) =>
      ChecklistQuestion(
        id: j['id'],
        orderNo: (j['sort_order'] ?? j['order_no'] ?? 1) is int
            ? (j['sort_order'] ?? j['order_no'] ?? 1) as int
            : int.tryParse(
                    (j['sort_order'] ?? j['order_no'] ?? 1).toString()) ??
                1,
        text: (j['question_text'] ?? j['text'] ?? '') as String,
        answerType: j['answer_type']?.toString(),
        options: j['options'],
        isRequired: j['is_required'] == true,
      );
}

// ===================== ChecklistDetail =====================
class ChecklistDetail {
  final dynamic id;
  final String title;
  final String status;
  final bool submitted;
  final List<ChecklistQuestion> questions;
  final String? taskId;
  final String? assignmentId;

  ChecklistDetail({
    required this.id,
    required this.title,
    required this.status,
    required this.submitted,
    required this.questions,
    this.taskId,
    this.assignmentId,
  });

  factory ChecklistDetail.fromJson(Map<String, dynamic> j) {
    final questionsRaw = (j['questions'] ?? []) as List;
    final isDone = j['done_at'] != null ||
        j['submitted'] == true ||
        j['submitted_at'] != null ||
        j['status'] == 'completed';

    return ChecklistDetail(
      id: j['id'],
      title: (j['title'] ?? '') as String,
      status: (j['status'] ?? 'dibuka') as String,
      submitted: isDone,
      questions: questionsRaw
          .map((e) => ChecklistQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      taskId: j['task_id']?.toString(),
      assignmentId: j['assignment_id']?.toString(),
    );
  }
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
