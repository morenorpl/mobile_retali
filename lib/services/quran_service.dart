import 'dart:convert';
import 'package:http/http.dart' as http;

class QuranService {
  static const _base = 'https://equran.id/api/v2';

  static Future<List<Map<String, dynamic>>> getSurahList() async {
    final res = await http.get(Uri.parse('$_base/surat'));
    if (res.statusCode != 200) throw Exception('Gagal memuat daftar surat');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (json['data'] as List).cast<Map<String, dynamic>>();
    return list;
  }

  static Future<Map<String, dynamic>> getSurahDetail(int nomor) async {
    final res = await http.get(Uri.parse('$_base/surat/$nomor'));
    if (res.statusCode != 200) throw Exception('Gagal memuat detail surat');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (json['data'] as Map<String, dynamic>);
  }
}
