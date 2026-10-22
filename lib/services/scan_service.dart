import '../models/scan_result.dart';
import 'api_service.dart';

class ScanService {
  // ===============================
  // SCAN PASPOR (FINAL – TANPA STATUS)
  // ===============================
  Future<ScanResult> scanPassport({
    required String qrRaw,
  }) async {
    final Map<String, dynamic> res =
        await ApiService.scanPassport(
          qrRaw: qrRaw,
        );

    // ===============================
    // SUCCESS
    // ===============================
    if (res['status'] == 'success') {
      final data = (res['data'] is Map<String, dynamic>)
          ? res['data'] as Map<String, dynamic>
          : <String, dynamic>{};

      return ScanResult.success(data);
    }

    // ===============================
    // DUPLICATE (409)
    // ===============================
    if (res['status'] == 'error' && res['code'] == 409) {
      final data = (res['data'] is Map<String, dynamic>)
          ? res['data'] as Map<String, dynamic>
          : <String, dynamic>{};

      return ScanResult.duplicate(
        data['passport_number']?.toString() ?? '',
        data,
        res['message'] ?? 'Paspor sudah pernah discan',
      );
    }

    // ===============================
    // OTHER ERROR
    // ===============================
    throw Exception(
      res['message'] ?? 'Gagal scan paspor',
    );
  }

  // ===============================
  // SCAN KOPER (TIDAK DIUBAH)
  // ===============================
  Future<ScanResult> scanKoper({
    required String qrRaw,
  }) async {
    final Map<String, dynamic> res =
        await ApiService.storeScanFromRaw(qrRaw);

    // ===============================
    // SUCCESS
    // ===============================
    if (res['status'] == 'success') {
      final data = (res['data'] is Map<String, dynamic>)
          ? res['data'] as Map<String, dynamic>
          : <String, dynamic>{};

      return ScanResult.success(data);
    }

    // ===============================
    // DUPLICATE (409)
    // ===============================
    if (res['status'] == 'error' && res['code'] == 409) {
      final data = (res['data'] is Map<String, dynamic>)
          ? res['data'] as Map<String, dynamic>
          : <String, dynamic>{};

      return ScanResult.duplicate(
        data['koper_code']?.toString() ?? '',
        data,
        res['message'] ?? 'Koper sudah pernah discan',
      );
    }

    
    // ===============================
    // OTHER ERROR
    // ===============================
    throw Exception(
      res['message'] ?? 'Gagal scan koper',
    );
  }
}
