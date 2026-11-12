class PersiapanMateri {
  final String id;
  final String title;
  final String? subTitle;
  final String? description;
  final String? content;
  final String category;
  final String? visibility;
  final String? attachmentUrl;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PersiapanMateri({
    required this.id,
    required this.title,
    this.subTitle,
    this.description,
    this.content,
    required this.category,
    this.visibility,
    this.attachmentUrl,
    this.isPublished = false,
    this.createdAt,
    this.updatedAt,
  });

  factory PersiapanMateri.fromMap(Map<String, dynamic> map) {
    return PersiapanMateri(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subTitle: map['sub_title']?.toString(),
      description: map['description']?.toString(),
      content: map['content']?.toString(),
      category: map['category']?.toString() ?? '',
      visibility: map['visibility']?.toString(),
      attachmentUrl: map['attachment_url']?.toString(),
      isPublished: map['is_published'] == true,
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
      'title': title,
      'sub_title': subTitle,
      'description': description,
      'content': content,
      'category': category,
      'visibility': visibility,
      'attachment_url': attachmentUrl,
      'is_published': isPublished,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
