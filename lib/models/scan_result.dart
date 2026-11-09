class ScanResult {
  final bool success;
  final bool duplicate;

  final String code; // passport_number / koper_code / kode_koper
  final String? ownerName;
  final String? ownerPhone;
  final String? kloter;

  final DateTime? scannedAt;
  final String? scannedBy;
  final String? message;

  ScanResult({
    required this.success,
    required this.duplicate,
    required this.code,
    this.ownerName,
    this.ownerPhone,
    this.kloter,
    this.scannedAt,
    this.scannedBy,
    this.message,
  });

  // ===============================
  // SUCCESS
  // ===============================
  factory ScanResult.success(Map<String, dynamic> data) {
    final rawTime = data['scanned_at'] ?? data['created_at'];
    return ScanResult(
      success: true,
      duplicate: false,
      code: (data['passport_number'] ??
              data['koper_code'] ??
              data['kode_koper'] ??
              '')
          .toString(),
      ownerName: data['owner_name'] ?? data['nama_pemilik'],
      ownerPhone: data['owner_phone'] ??
          data['phone'] ??
          data['nomor_telepon'],
      kloter: data['kloter']?.toString(),
      scannedAt: rawTime != null
          ? DateTime.tryParse(rawTime.toString())
          : DateTime.now(),
    );
  }

  // ===============================
  // DUPLICATE
  // ===============================
  factory ScanResult.duplicate(
    String code,
    Map<String, dynamic> data,
    String? message,
  ) {
    final rawTime = data['scanned_at'] ?? data['created_at'];
    return ScanResult(
      success: false,
      duplicate: true,
      code: code.isNotEmpty
          ? code
          : (data['passport_number'] ??
                  data['koper_code'] ??
                  data['kode_koper'] ??
                  '')
              .toString(),
      ownerName: data['owner_name'] ?? data['nama_pemilik'],
      ownerPhone: data['owner_phone'] ??
          data['phone'] ??
          data['nomor_telepon'],
      kloter: data['kloter']?.toString(),
      scannedAt: rawTime != null
          ? DateTime.tryParse(rawTime.toString())
          : null,
      scannedBy: data['tourleader']?.toString(),
      message: message,
    );
  }
}
