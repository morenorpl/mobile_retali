// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static Dio? _dio;

  // =====================================
  // SATU-SATUNYA YANG PERLU KAMU GANTI
  // =====================================
  //
  // Contoh untuk development:
  // - Android emulator:  http://10.0.2.2:8000
  // - Web / HP / device lain (satu WiFi): http://192.168.1.10:8000
  //
  // Contoh untuk hosting:
  // - https://api.retali.com
  //
  static const String ROOT_URL = 'http://192.168.205.160:8000/api';

  static String get _baseUrl {
    final root = ROOT_URL.endsWith('/')
        ? ROOT_URL.substring(0, ROOT_URL.length - 1)
        : ROOT_URL;

    // kalau ROOT_URL belum pakai /api, tambahin
    return root.endsWith('/api') ? root : '$root/api';
  }

  // =====================
  // BASIC CLIENT
  // =====================
  static Dio _client() {
    if (_dio != null) return _dio!;

    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        // TAMBAHKAN HEADERS DI SINI
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    return _dio!;
  }

  // =====================
  // TOKEN HANDLER
  // =====================
  static const _tokenKey = 'token';
  static const _sessionTokenKey = 'session_token';

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> _saveSessionToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionTokenKey, token);
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> _getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionTokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<String?> getTourLeaderToken() => _getToken();

  static Future<Dio> _authedClient() async {
    final dio = _client();
    final token = await _getToken();
    final sessionToken = await _getSessionToken();

    dio.options.headers = {
      'Accept': 'application/json',

      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',

      if (sessionToken != null && sessionToken.isNotEmpty)
        'Session-Token': sessionToken,
    };

    return dio;
  }

  // =====================
  // SAVE PROFILE TO LOCAL
  // =====================
  static Future<void> saveProfileToLocal(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("name", user['name']?.toString() ?? '-');
    await prefs.setString("email", user['email']?.toString() ?? '-');
    await prefs.setString(
      "role",
      user['role']?.toString() ?? 'tourleader',
    ); // 🔥 TAMBAH INI

    await prefs.setString("kloter", user['kloter']?.toString() ?? '-');

    await prefs.setString(
      "kloter_tanggal",
      user['kloter_tanggal']?.toString() ?? '-',
    );
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final dio = _client();

    try {
      print("=== LOGIN REQUEST ===");
      print("URL: ${dio.options.baseUrl}/login");
      print("EMAIL: $email");
      print("PASSWORD: $password");

      final res = await dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      print("=== RESPONSE ===");
      print("STATUS CODE: ${res.statusCode}");
      print("DATA: ${res.data}");

      final data = res.data;

      if (res.statusCode == 200 && data['token'] != null) {
        final token = data['token'].toString();
        final sessionToken = data['session_token'].toString();

        await _saveToken(token);
        await _saveSessionToken(sessionToken);
        if (data['user'] is Map<String, dynamic>) {
          await saveProfileToLocal(data['user']);
        }

        return {'success': true, 'message': 'Login Berhasil'};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Email atau password salah',
      };
    } on DioException catch (e) {
      print("=== DIO ERROR ===");
      print("TYPE: ${e.type}");
      print("MESSAGE: ${e.message}");
      print("STATUS: ${e.response?.statusCode}");
      print("DATA: ${e.response?.data}");

      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Server error: ${e.type}',
      };
    } catch (e) {
      print("=== UNKNOWN ERROR ===");
      print(e);

      return {'success': false, 'message': 'Terjadi kesalahan sistem'};
    }
  }

  // =====================
  // GET PASSPORT SCANS
  // =====================
  static Future<List<dynamic>> getPassportScans() async {
    final dio = await _authedClient();

    try {
      final res = await dio.get('/tourleader/passport-scans');

      if (res.data is List) return res.data;

      if (res.data is Map && res.data['data'] is List) {
        return res.data['data'];
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  // =====================
  // DELETE KOPER
  // =====================
  static Future<bool> deleteKoper(int id) async {
    final dio = await _authedClient();

    try {
      final res = await dio.delete('/tourleader/scans/$id');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =====================
  // DELETE PASPOR
  // =====================
  static Future<bool> deletePassport(int id) async {
    final dio = await _authedClient();

    try {
      final res = await dio.delete('/tourleader/passport-scans/$id');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =====================
  // GET USER INFO
  // =====================
  static Future<Map<String, dynamic>> getUserInfo() async {
    final dio = await _authedClient();
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString("role") ?? "tourleader";

    try {
      final endpoint = role == "muthawif"
          ? '/muthawif/profile'
          : '/tourleader/profile';

      final res = await dio.get(endpoint);

      if (res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      return {};
    }
  }

  // =====================
  // NOTIFICATIONS
  // =====================
  static Future<List<dynamic>> getNotifications() async {
    final dio = await _authedClient();
    try {
      final res = await dio.get('/notifications');

      if (res.data is List) return res.data;
      if (res.data is Map<String, dynamic> && res.data['data'] is List)
        return res.data['data'];

      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> markAllNotificationsAsRead() async {
    final dio = await _authedClient();
    try {
      await dio.post('/notifications/read-all');
    } catch (_) {}
  }

  static Future<void> markNotificationAsRead(dynamic id) async {
    final dio = await _authedClient();
    try {
      await dio.post('/notifications/$id/read');
    } catch (_) {}
  }

  /// =====================
  /// SCAN KOPER (RAW)
  /// =====================
  static Future<Map<String, dynamic>> storeScanFromRaw(String qrRaw) async {
    final dio = await _authedClient();

    try {
      final res = await dio.post('/tourleader/scans', data: {'qr_text': qrRaw});

      final data = res.data;

      if (data is Map<String, dynamic>) {
        return {
          'success': data['status'] == 'success',
          'code': res.statusCode,
          ...data,
        };
      }

      return {
        'success': false,
        'code': res.statusCode,
        'message': 'Format response tidak dikenali',
      };
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        return {
          'success': false,
          'code': e.response!.statusCode,
          ...e.response!.data,
        };
      }

      return {'success': false, 'code': 0, 'message': e.message};
    }
  }

  // =====================
  // SCAN PASPOR (FINAL)
  // =====================
  static Future<Map<String, dynamic>> scanPassport({
    required String qrRaw,
  }) async {
    final dio = await _authedClient();

    try {
      final res = await dio.post(
        '/tourleader/passport-scan',
        data: {'qr_text': qrRaw},
      );

      final data = res.data;
      if (data is Map<String, dynamic>) {
        return {'status': data['status'], 'code': res.statusCode, ...data};
      }

      return {
        'status': 'error',
        'code': res.statusCode,
        'message': 'Format response tidak dikenali',
      };
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        return {
          'status': 'error',
          'code': e.response!.statusCode,
          ...e.response!.data,
        };
      }

      return {'status': 'error', 'code': 0, 'message': e.message};
    }
  }

  // =====================
  // GET SCANS
  // =====================
  static Future<List<dynamic>> getScans() async {
    final dio = await _authedClient();

    try {
      final res = await dio.get('/tourleader/scans');
      if (res.data is List) return res.data;
      if (res.data is Map && res.data['data'] is List) {
        return res.data['data'];
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
