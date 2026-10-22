class TaskSummary {
  final int id;
  final String title;
  final int questionCount;
  final DateTime opensAt;
  final DateTime closesAt;
  final String status; // 'belum_dibuka' | 'dibuka' | 'ditutup'
  final DateTime? doneAt;
  final bool canWork;

  TaskSummary({
    required this.id,
    required this.title,
    required this.questionCount,
    required this.opensAt,
    required this.closesAt,
    required this.status,
    required this.canWork,
    this.doneAt,
  });

  factory TaskSummary.fromJson(Map<String, dynamic> j) => TaskSummary(
        id: j['id'],
        title: j['title'],
        questionCount: j['question_count'],
        opensAt: DateTime.parse(j['opens_at']).toLocal(),
        closesAt: DateTime.parse(j['closes_at']).toLocal(),
        status: j['status'],
        canWork: (j['can_work'] ?? false) == true,
        doneAt: j['done_at'] != null ? DateTime.parse(j['done_at']).toLocal() : null,
      );

  /// 🧩 Tambahkan method ini biar bisa update sebagian field
  TaskSummary copyWith({
    int? id,
    String? title,
    int? questionCount,
    DateTime? opensAt,
    DateTime? closesAt,
    String? status,
    bool? canWork,
    DateTime? doneAt,
  }) {
    return TaskSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      questionCount: questionCount ?? this.questionCount,
      opensAt: opensAt ?? this.opensAt,
      closesAt: closesAt ?? this.closesAt,
      status: status ?? this.status,
      canWork: canWork ?? this.canWork,
      doneAt: doneAt ?? this.doneAt,
    );
  }
}

class TaskQuestion {
  final int id;          // ⬅️ WAJIB
  final int orderNo;
  final String text;

  TaskQuestion({
    required this.id,
    required this.orderNo,
    required this.text,
  });

  factory TaskQuestion.fromJson(Map<String, dynamic> j) {
    return TaskQuestion(
      id: j['id'],                    // ⬅️ ambil dari API
      orderNo: j['order_no'],
      text: j['question_text'],
    );
  }
}


class TaskDetail {
  final int id;
  final String title;
  final int questionCount;
  final DateTime opensAt;
  final DateTime closesAt;
  final String status;
  final DateTime? doneAt;
  final List<TaskQuestion> questions;

  TaskDetail({
    required this.id,
    required this.title,
    required this.questionCount,
    required this.opensAt,
    required this.closesAt,
    required this.status,
    required this.questions,
    this.doneAt,
  });

  factory TaskDetail.fromJson(Map<String, dynamic> j) => TaskDetail(
        id: j['id'],
        title: j['title'],
        questionCount: j['question_count'],
        opensAt: DateTime.parse(j['opens_at']).toLocal(),
        closesAt: DateTime.parse(j['closes_at']).toLocal(),
        status: j['status'],
        doneAt: j['done_at'] != null
            ? DateTime.parse(j['done_at']).toLocal()
            : null,
        questions: (j['questions'] as List)
            .map((e) => TaskQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
