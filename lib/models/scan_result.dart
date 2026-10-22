class ScanResult {
  final bool success;
  final bool duplicate;

  final String code; // passport_number / koper_code
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
    return ScanResult(
      success: true,
      duplicate: false,
      code: data['passport_number'] ?? data['koper_code'],
      ownerName: data['owner_name'],
      ownerPhone: data['owner_phone'],
      kloter: data['kloter'],
      scannedAt: DateTime.tryParse(data['scanned_at'] ?? ''),
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
    return ScanResult(
      success: false,
      duplicate: true,
      code: code,
      scannedAt: DateTime.tryParse(data['scanned_at'] ?? ''),
      scannedBy: data['tourleader'],
      message: message,
    );
  }
}
