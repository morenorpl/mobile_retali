class SesiAbsensi {
  final String id;
  final String judul;
  final String kategori;
  final String? targetJamMulai;
  final String? targetJamSelesai;
  final String? keterangan;
  final int urutan;
  final List<BagianSesiAbsensi> bagianSesi;

  const SesiAbsensi({
    required this.id,
    required this.judul,
    required this.kategori,
    this.targetJamMulai,
    this.targetJamSelesai,
    this.keterangan,
    this.urutan = 1,
    this.bagianSesi = const [],
  });

  factory SesiAbsensi.fromMap(
    Map<String, dynamic> map, {
    List<BagianSesiAbsensi> bagianList = const [],
  }) {
    return SesiAbsensi(
      id: map['id']?.toString() ?? '',
      judul: map['judul']?.toString() ?? '',
      kategori: map['kategori']?.toString() ?? 'all',
      targetJamMulai: map['target_jam_mulai']?.toString(),
      targetJamSelesai: map['target_jam_selesai']?.toString(),
      keterangan: map['keterangan']?.toString(),
      urutan: (map['urutan'] is int)
          ? map['urutan']
          : int.tryParse('${map['urutan']}') ?? 1,
      bagianSesi: bagianList,
    );
  }

  SesiAbsensi copyWith({List<BagianSesiAbsensi>? bagianSesi}) {
    return SesiAbsensi(
      id: id,
      judul: judul,
      kategori: kategori,
      targetJamMulai: targetJamMulai,
      targetJamSelesai: targetJamSelesai,
      keterangan: keterangan,
      urutan: urutan,
      bagianSesi: bagianSesi ?? this.bagianSesi,
    );
  }

  /// Menampilkan rentang jam yang diformat (misal "04:30 - 06:30 WIB")
  String get formattedTargetTime {
    if ((targetJamMulai == null || targetJamMulai!.isEmpty) &&
        (targetJamSelesai == null || targetJamSelesai!.isEmpty)) {
      return 'Fleksibel';
    }
    final mulai = _formatTimeOnly(targetJamMulai);
    final selesai = _formatTimeOnly(targetJamSelesai);
    if (mulai.isNotEmpty && selesai.isNotEmpty) {
      return '$mulai - $selesai WIB';
    } else if (mulai.isNotEmpty) {
      return 'Mulai $mulai WIB';
    } else {
      return 'Sampai $selesai WIB';
    }
  }

  /// Menampilkan jam target mulai (misal "05:00")
  String get formattedJamMulai {
    return _formatTimeOnly(targetJamMulai);
  }

  /// Memeriksa apakah saat ini sudah memasuki target jam mulai absensi
  bool get isSudahMasukWaktu {
    if (targetJamMulai == null || targetJamMulai!.trim().isEmpty) {
      return true; // Fleksibel / bebas jika tidak ditentukan
    }
    try {
      final now = DateTime.now();
      final parts = targetJamMulai!.trim().split(':');
      if (parts.isNotEmpty) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        final targetStart = DateTime(now.year, now.month, now.day, hour, minute);
        return now.isAfter(targetStart) || now.isAtSameMomentAs(targetStart);
      }
    } catch (_) {}
    return true;
  }

  static String _formatTimeOnly(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }
}

class BagianSesiAbsensi {
  final String id;
  final String sesiId;
  final String namaBagian;
  final String? targetJamMulai;
  final String? targetJamSelesai;
  final int urutan;

  const BagianSesiAbsensi({
    required this.id,
    required this.sesiId,
    required this.namaBagian,
    this.targetJamMulai,
    this.targetJamSelesai,
    this.urutan = 1,
  });

  factory BagianSesiAbsensi.fromMap(Map<String, dynamic> map) {
    return BagianSesiAbsensi(
      id: map['id']?.toString() ?? '',
      sesiId: map['sesi_id']?.toString() ?? '',
      namaBagian: map['nama_bagian']?.toString() ?? '',
      targetJamMulai: map['target_jam_mulai']?.toString(),
      targetJamSelesai: map['target_jam_selesai']?.toString(),
      urutan: (map['urutan'] is int)
          ? map['urutan']
          : int.tryParse('${map['urutan']}') ?? 1,
    );
  }
}

class AttendanceGuideRecord {
  final String id;
  final String userId;
  final String attendanceDate;
  final String? kloter;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final String type;
  final String? note;
  final String? sesi;
  final String? bagianSesi;
  final String? sesiId;
  final String? targetJamMulai;
  final String? targetJamSelesai;
  final String? statusWaktu;
  final String attendanceStatus;
  final DateTime? createdAt;

  const AttendanceGuideRecord({
    required this.id,
    required this.userId,
    required this.attendanceDate,
    this.kloter,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.type = 'masuk',
    this.note,
    this.sesi,
    this.bagianSesi,
    this.sesiId,
    this.targetJamMulai,
    this.targetJamSelesai,
    this.statusWaktu,
    this.attendanceStatus = 'belum_absen',
    this.createdAt,
  });

  factory AttendanceGuideRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceGuideRecord(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      attendanceDate: map['attendance_date']?.toString() ?? '',
      kloter: map['kloter']?.toString(),
      photoUrl: map['photo_url']?.toString(),
      latitude: map['latitude'] != null
          ? double.tryParse('${map['latitude']}')
          : null,
      longitude: map['longitude'] != null
          ? double.tryParse('${map['longitude']}')
          : null,
      type: map['type']?.toString() ?? 'masuk',
      note: map['note']?.toString(),
      sesi: map['sesi']?.toString(),
      bagianSesi: map['bagian_sesi']?.toString(),
      sesiId: map['sesi_id']?.toString(),
      targetJamMulai: map['target_jam_mulai']?.toString(),
      targetJamSelesai: map['target_jam_selesai']?.toString(),
      statusWaktu: map['status_waktu']?.toString(),
      attendanceStatus: map['attendance_status']?.toString() ?? 'belum_absen',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse('${map['created_at']}')
          : null,
    );
  }

  bool get isSudahAbsen {
    final s = attendanceStatus.toLowerCase();
    return s == 'hadir' ||
        s == 'sudah_absen' ||
        s == 'masuk' ||
        (photoUrl != null && photoUrl!.isNotEmpty);
  }

  String get formattedCreatedTime {
    if (createdAt == null) return '-';
    final local = createdAt!.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m WIB';
  }
}
