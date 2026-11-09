import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AbsensiService {
  static String get baseUrl {
    var b = ApiService.ROOT_URL.trim();
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    if (!b.endsWith('/api')) b = '$b/api';
    return b;
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Upload absensi (foto + koordinat) untuk Web & Mobile menggunakan XFile
  static Future<Map<String, dynamic>> uploadAttendance({
    required XFile pickedFile,
    required String role,
    double? lat,
    double? lng,
  }) async {
    final token = await _getToken();

    final endpoint = role == 'muthawif'
        ? '/muthawif/attendance'
        : '/tourleader/attendance';

    Uri url = Uri.parse('$baseUrl$endpoint');

    Future<http.Response> sendReq(Uri targetUrl) async {
      final req = http.MultipartRequest('POST', targetUrl);
      if (token != null) {
        req.headers['Authorization'] = 'Bearer $token';
      }
      if (lat != null) req.fields['lat'] = lat.toString();
      if (lng != null) req.fields['lng'] = lng.toString();

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        req.files.add(
          http.MultipartFile.fromBytes('photo', bytes, filename: pickedFile.name),
        );
      } else {
        req.files.add(
          await http.MultipartFile.fromPath(
            'photo',
            pickedFile.path,
            filename: pickedFile.name,
          ),
        );
      }

      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    }

    try {
      var res = await sendReq(url);
      if (res.statusCode == 404) {
        // Fallback ke endpoint umum backend Vercel: /api/attendance
        res = await sendReq(Uri.parse('$baseUrl/attendance'));
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }

      return {'success': false, 'message': res.body, 'code': res.statusCode};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Ambil riwayat absensi TL sendiri
  static Future<Map<String, dynamic>> myHistory({int page = 1}) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/attendance?page=$page');

    try {
      var res = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 404) {
        res = await http.get(
          Uri.parse('$baseUrl/tourleader/attendance?page=$page'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 20));
      }

      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'message': res.body, 'code': res.statusCode};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
