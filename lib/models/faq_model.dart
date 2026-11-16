// lib/models/faq_model.dart

class FaqItem {
  final String id;
  final String category;
  final String question;
  final String answer;
  final int sortOrder;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    this.sortOrder = 1,
    this.isPublished = true,
    this.createdAt,
    this.updatedAt,
  });

  factory FaqItem.fromMap(Map<String, dynamic> map) {
    return FaqItem(
      id: (map['id'] ?? '').toString(),
      category: (map['category'] == null || map['category'].toString().trim().isEmpty)
          ? 'Umum'
          : map['category'].toString().trim(),
      question: (map['question'] ?? '').toString().trim(),
      answer: (map['answer'] ?? '').toString().trim(),
      sortOrder: (map['sort_order'] is int)
          ? map['sort_order'] as int
          : int.tryParse(map['sort_order']?.toString() ?? '1') ?? 1,
      isPublished: map['is_published'] == null ||
          map['is_published'] == true ||
          map['is_published'].toString().toLowerCase() == 'true',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'answer': answer,
      'sort_order': sortOrder,
      'is_published': isPublished,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
