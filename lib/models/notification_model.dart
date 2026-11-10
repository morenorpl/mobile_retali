import 'package:flutter/material.dart';

/// 4 Status Notifikasi sesuai sistem Retali:
/// - abuAbu : Belum ada peringatan (> 24 jam sebelum kegiatan atau tanpa jadwal)
/// - merah  : Peringatan 24 jam sebelum kegiatan (12 < diffHours <= 24)
/// - kuning : Peringatan 12 jam sebelum kegiatan (0 < diffHours <= 12)
/// - hijau  : Saat kegiatan tiba / sedang berlangsung (diffHours <= 0)
enum NotificationStatus {
  abuAbu,
  merah,
  kuning,
  hijau,
}

class NotificationItem {
  final String id;
  final String? recipientId;
  final String? userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;

  NotificationItem({
    required this.id,
    this.recipientId,
    this.userId,
    required this.title,
    required this.message,
    this.type = 'info',
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.startDate,
    this.endDate,
  });

  /// Hitung selisih jam antara jadwal kegiatan (startDate) dan waktu sekarang.
  /// diffHours > 0 : kegiatan di masa depan
  /// diffHours <= 0 : waktu kegiatan sudah tiba / lewat
  double? get diffHours {
    if (startDate == null) return null;
    final now = DateTime.now();
    return startDate!.difference(now).inMinutes / 60.0;
  }

  /// Penentuan status berdasarkan selisih jam terhadap startDate
  NotificationStatus get status {
    final diff = diffHours;
    if (diff == null) return NotificationStatus.abuAbu;

    if (diff <= 0) {
      return NotificationStatus.hijau;
    } else if (diff <= 12) {
      return NotificationStatus.kuning;
    } else if (diff <= 24) {
      return NotificationStatus.merah;
    } else {
      return NotificationStatus.abuAbu;
    }
  }

  /// Label singkat status peringatan (sama persis dengan web Retali-sistem)
  String get statusLabel {
    switch (status) {
      case NotificationStatus.hijau:
        return 'Saat Kegiatan';
      case NotificationStatus.kuning:
        return 'Peringatan 12 Jam';
      case NotificationStatus.merah:
        return 'Peringatan 24 Jam';
      case NotificationStatus.abuAbu:
        return 'Belum Ada Peringatan';
    }
  }

  /// Penjelasan detail status peringatan
  String get statusDescription {
    switch (status) {
      case NotificationStatus.hijau:
        return 'Petugas telah diingatkan saat kegiatan';
      case NotificationStatus.kuning:
        return 'Petugas telah diingatkan 12 jam sebelum kegiatan';
      case NotificationStatus.merah:
        return 'Petugas telah diingatkan 24 jam sebelum kegiatan';
      case NotificationStatus.abuAbu:
        return 'Belum ada peringatan terkirim (jadwal > 24 jam)';
    }
  }

  /// Pesan pengingat dinamis sesuai instruksi:
  /// - merah: '24 jam lagi [notif a] harus dilaksanakan'
  /// - kuning: '12 jam lagi [notif a] harus dilaksanakan'
  /// - hijau: 'Saatnya [notif a] dilaksanakan'
  /// - abu-abu: 'Notifikasi telah dibuat admin (jadwal belum tiba)'
  String get dynamicReminderText {
    final cleanTitle = title.trim().isNotEmpty ? title.trim() : 'kegiatan';
    switch (status) {
      case NotificationStatus.hijau:
        return 'Saat ini $cleanTitle harus dilaksanakan';
      case NotificationStatus.kuning:
        return '12 jam lagi $cleanTitle harus dilaksanakan';
      case NotificationStatus.merah:
        return '24 jam lagi $cleanTitle harus dilaksanakan';
      case NotificationStatus.abuAbu:
        return 'Notifikasi telah dibuat oleh admin (belum masuk waktu pengingat)';
    }
  }

  /// Warna utama badge/icon
  Color get statusColor {
    switch (status) {
      case NotificationStatus.hijau:
        return const Color(0xFF10B981); // Emerald 500
      case NotificationStatus.kuning:
        return const Color(0xFFF59E0B); // Amber 500
      case NotificationStatus.merah:
        return const Color(0xFFEF4444); // Rose/Red 500
      case NotificationStatus.abuAbu:
        return const Color(0xFF9CA3AF); // Gray 400
    }
  }

  /// Warna latar badge
  Color get statusBgColor {
    switch (status) {
      case NotificationStatus.hijau:
        return const Color(0xFFECFDF5); // Emerald 50
      case NotificationStatus.kuning:
        return const Color(0xFFFFFBEB); // Amber 50
      case NotificationStatus.merah:
        return const Color(0xFFFFF1F2); // Rose 50
      case NotificationStatus.abuAbu:
        return const Color(0xFFF3F4F6); // Gray 100
    }
  }

  /// Warna border badge
  Color get statusBorderColor {
    switch (status) {
      case NotificationStatus.hijau:
        return const Color(0xFFA7F3D0); // Emerald 200
      case NotificationStatus.kuning:
        return const Color(0xFFFDE68A); // Amber 200
      case NotificationStatus.merah:
        return const Color(0xFFFECDD3); // Rose 200
      case NotificationStatus.abuAbu:
        return const Color(0xFFE5E7EB); // Gray 200
    }
  }

  /// Icon representatif untuk status
  IconData get statusIcon {
    switch (status) {
      case NotificationStatus.hijau:
        return Icons.check_circle_outline;
      case NotificationStatus.kuning:
        return Icons.access_time_filled;
      case NotificationStatus.merah:
        return Icons.warning_amber_rounded;
      case NotificationStatus.abuAbu:
        return Icons.hourglass_empty_rounded;
    }
  }

  /// Konversi ke Map JSON standar
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipient_id': recipientId,
      'user_id': userId,
      'title': title,
      'message': message,
      'body': message,
      'type': type,
      'is_read': isRead,
      'read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status_label': statusLabel,
      'status_name': status.name,
      'dynamic_reminder': dynamicReminderText,
      'diff_hours': diffHours,
    };
  }

  factory NotificationItem.fromMap(
    Map<String, dynamic> notifData, {
    Map<String, dynamic>? recipientData,
  }) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }

    DateTime? parseNullableDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    final bool isRead = recipientData != null
        ? (recipientData['is_read'] == true || recipientData['read_at'] != null)
        : (notifData['is_read'] == true || notifData['read'] == true || notifData['read_at'] != null);

    final DateTime? readAt = recipientData != null
        ? parseNullableDate(recipientData['read_at'])
        : parseNullableDate(notifData['read_at']);

    return NotificationItem(
      id: (notifData['id'] ?? recipientData?['notification_id'] ?? '').toString(),
      recipientId: recipientData?['id']?.toString(),
      userId: recipientData?['user_id']?.toString() ?? notifData['user_id']?.toString(),
      title: (notifData['title'] ?? notifData['subject'] ?? 'Notifikasi').toString(),
      message: (notifData['message'] ?? notifData['body'] ?? notifData['content'] ?? notifData['description'] ?? '').toString(),
      type: (notifData['type'] ?? 'info').toString(),
      isRead: isRead,
      readAt: readAt,
      createdAt: parseDate(notifData['created_at'] ?? recipientData?['created_at']),
      startDate: parseNullableDate(notifData['start_date']),
      endDate: parseNullableDate(notifData['end_date']),
    );
  }

  NotificationItem copyWith({
    String? id,
    String? recipientId,
    String? userId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
