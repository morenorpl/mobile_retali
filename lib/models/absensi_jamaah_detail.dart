class AbsensiJamaahDetail {
  final int jamaahId;
  final int urutan;
  final String nama;
  final String? paspor;
  final String? hp;
  final String? kloter;
  final int? bus;
  final String status;
  final String? catatan;

  AbsensiJamaahDetail({
    required this.jamaahId,
    required this.urutan,
    required this.nama,
    this.paspor,
    this.hp,
    this.kloter,
    this.bus,
    required this.status,
    this.catatan,
  });

  // ✅ TAMBAHKAN INI: Untuk konversi ke Map saat simpan ke SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      'jamaah_id': jamaahId,
      'status': status,
      'catatan': catatan,
      // Kamu bisa tambah field lain jika ingin draft-nya lebih lengkap
    };
  }

  factory AbsensiJamaahDetail.fromJson(Map<String, dynamic> j) {
    return AbsensiJamaahDetail(
      jamaahId: j['jamaah_id'] ?? 0,
      urutan: j['urutan'] ?? 0,
      nama: j['nama_jamaah'] ?? '-',
      paspor: j['no_paspor'],
      hp: j['no_hp'],
      kloter: j['kode_kloter'],
      bus: j['nomor_bus'] is int
          ? j['nomor_bus']
          : int.tryParse('${j['nomor_bus']}'),
      status: j['status'] ?? 'BELUM_ABSEN',
      catatan: j['catatan'],
    );
  }

  AbsensiJamaahDetail copyWith({
    String? status,
    String? catatan,
  }) {
    return AbsensiJamaahDetail(
      jamaahId: jamaahId,
      urutan: urutan,
      nama: nama,
      paspor: paspor,
      hp: hp,
      kloter: kloter,
      bus: bus,
      status: status ?? this.status,
      catatan: catatan ?? this.catatan,
    );
  }
}