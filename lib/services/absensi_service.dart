import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sesi_absensi_model.dart';
import 'api_service.dart';
import 'supabase_service.dart';

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

  // ===========================================================================
  // 1️⃣ FETCH DAFTAR SESI ABSENSI YANG DITUGASKAN (SUPABASE)
  // ===========================================================================
  /// Mengambil daftar sesi absensi HANYA yang ditugaskan kepada petugas (`attendance_guide` & `attendance_guide_grup`)
  static Future<List<SesiAbsensi>> fetchAssignedSesiList({
    required String userId,
    String? role,
    String? kloter,
    String? dateStr,
  }) async {
    final client = SupabaseService.client;
    final today = dateStr ?? DateTime.now().toIso8601String().substring(0, 10);

    try {
      // 1. Ambil penugasan individual untuk user ini dari `attendance_guide`
      List<dynamic> guideRows = [];
      if (client != null && userId.isNotEmpty) {
        guideRows = await client
            .from('attendance_guide')
            .select()
            .eq('user_id', userId)
            .eq('attendance_date', today)
            .order('created_at', ascending: true);
      } else if (userId.isNotEmpty) {
        guideRows = await SupabaseService.restGet(
          'attendance_guide?user_id=eq.$userId&attendance_date=eq.$today&order=created_at.asc',
        );
      }

      // 2. Jika ada penugasan individual di attendance_guide, gunakan data tersebut
      if (guideRows.isNotEmpty) {
        final List<SesiAbsensi> list = [];
        int idx = 1;
        for (final row in guideRows) {
          final m = Map<String, dynamic>.from(row as Map);
          final String title = m['sesi']?.toString() ?? 'Sesi Petugas';
          final String? bagian = m['bagian_sesi']?.toString();
          final String sesiId = m['sesi_id']?.toString() ?? m['id']?.toString() ?? '';

          List<BagianSesiAbsensi> bagianList = [];
          if (bagian != null && bagian.isNotEmpty) {
            bagianList.add(BagianSesiAbsensi(
              id: 'bagian_$idx',
              sesiId: sesiId,
              namaBagian: bagian,
              targetJamMulai: m['target_jam_mulai']?.toString(),
              targetJamSelesai: m['target_jam_selesai']?.toString(),
            ));
          }

          list.add(SesiAbsensi(
            id: sesiId.isNotEmpty ? sesiId : (m['id']?.toString() ?? 'sesi_$idx'),
            judul: title,
            kategori: role ?? 'tour_leader',
            targetJamMulai: m['target_jam_mulai']?.toString(),
            targetJamSelesai: m['target_jam_selesai']?.toString(),
            keterangan: (m['note']?.toString() ?? '').replaceAll(RegExp(r'\[.*?\]'), '').trim(),
            urutan: idx++,
            bagianSesi: bagianList,
          ));
        }
        debugPrint('✅ [AbsensiService] Loaded ${list.length} assigned sessions for user from attendance_guide');
        return list;
      }

      // 3. Fallback: Cek apakah ada penugasan grup di `attendance_guide_grup`
      List<dynamic> grupRows = [];
      if (client != null) {
        try {
          var query = client.from('attendance_guide_grup').select().eq('attendance_date', today);
          if (kloter != null && kloter.isNotEmpty && kloter != '-') {
            query = query.or('kloter.eq.$kloter,kloter.eq.Umum');
          }
          grupRows = await query.order('created_at', ascending: true);
        } catch (e) {
          debugPrint('⚠️ [AbsensiService] Error fetching attendance_guide_grup: $e');
        }
      }

      if (grupRows.isNotEmpty) {
        final List<SesiAbsensi> list = [];
        int idx = 1;
        for (final row in grupRows) {
          final m = Map<String, dynamic>.from(row as Map);
          final String title = m['sesi']?.toString() ?? 'Sesi Petugas';
          final String? bagian = m['bagian_sesi']?.toString();
          final String sesiId = m['sesi_id']?.toString() ?? m['id']?.toString() ?? '';

          List<BagianSesiAbsensi> bagianList = [];
          if (bagian != null && bagian.isNotEmpty) {
            bagianList.add(BagianSesiAbsensi(
              id: 'bagian_$idx',
              sesiId: sesiId,
              namaBagian: bagian,
              targetJamMulai: m['target_jam_mulai']?.toString(),
              targetJamSelesai: m['target_jam_selesai']?.toString(),
            ));
          }

          list.add(SesiAbsensi(
            id: sesiId.isNotEmpty ? sesiId : (m['id']?.toString() ?? 'grup_$idx'),
            judul: title,
            kategori: m['role_kategori']?.toString() ?? (role ?? 'tour_leader'),
            targetJamMulai: m['target_jam_mulai']?.toString(),
            targetJamSelesai: m['target_jam_selesai']?.toString(),
            keterangan: m['note']?.toString() ?? 'Penugasan absensi grup',
            urutan: idx++,
            bagianSesi: bagianList,
          ));
        }
        debugPrint('✅ [AbsensiService] Loaded ${list.length} groups from attendance_guide_grup');
        return list;
      }

      // 4. Jika memang belum ada yang ditugaskan hari ini, return list kosong (HANYA sesi yang ditugaskan)
      debugPrint('ℹ️ [AbsensiService] Belum ada sesi yang ditugaskan hari ini ($today)');
      return [];
    } catch (e) {
      debugPrint('❌ [AbsensiService] Error fetchAssignedSesiList: $e');
      return [];
    }
  }

  // ===========================================================================
  // 1️⃣.b FETCH DAFTAR SESI MASTER (FALLBACK / MASTER TEMPLATE)
  // ===========================================================================
  /// Mengambil daftar seluruh master sesi absensi dari Supabase table `sesi_absensi` & `bagian_sesi_absensi`
  static Future<List<SesiAbsensi>> fetchSesiAbsensiList({String? role}) async {
    final client = SupabaseService.client;
    final normalizedRole = (role ?? 'tour_leader')
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');

    final List<String> allowedCategories = ['all', 'semua_petugas'];
    if (normalizedRole.contains('tour') || normalizedRole.contains('leader')) {
      allowedCategories.add('tour_leader');
    } else if (normalizedRole.contains('muthawif')) {
      allowedCategories.add('muthawif');
    } else {
      allowedCategories.add('tour_leader');
    }

    try {
      // 1. Ambil data sesi utama
      List<dynamic> sesiRows = [];
      if (client != null) {
        sesiRows = await client
            .from('sesi_absensi')
            .select()
            .order('urutan', ascending: true);
      } else {
        sesiRows = await SupabaseService.restGet(
          'sesi_absensi',
          order: 'urutan.asc',
        );
      }

      // Filter kategori sesuai role
      final filteredSesi = sesiRows.where((row) {
        final cat = (row['kategori'] ?? 'all').toString().toLowerCase();
        return allowedCategories.contains(cat);
      }).toList();

      // 2. Ambil data bagian sesi absensi
      List<dynamic> bagianRows = [];
      try {
        if (client != null) {
          bagianRows = await client
              .from('bagian_sesi_absensi')
              .select()
              .order('urutan', ascending: true);
        } else {
          bagianRows = await SupabaseService.restGet(
            'bagian_sesi_absensi',
            order: 'urutan.asc',
          );
        }
      } catch (e) {
        debugPrint('⚠️ [AbsensiService] Error fetching bagian_sesi_absensi: $e');
      }

      // Grouping bagian sesi by sesi_id
      final Map<String, List<BagianSesiAbsensi>> bagianMap = {};
      for (final b in bagianRows) {
        final map = Map<String, dynamic>.from(b as Map);
        final item = BagianSesiAbsensi.fromMap(map);
        if (item.sesiId.isNotEmpty) {
          bagianMap.putIfAbsent(item.sesiId, () => []).add(item);
        }
      }

      // Map ke list SesiAbsensi model
      final List<SesiAbsensi> list = [];
      for (final s in filteredSesi) {
        final map = Map<String, dynamic>.from(s as Map);
        final id = map['id']?.toString() ?? '';
        final bagianList = bagianMap[id] ?? [];
        list.add(SesiAbsensi.fromMap(map, bagianList: bagianList));
      }

      return list;
    } catch (e) {
      debugPrint('❌ [AbsensiService] Error fetchSesiAbsensiList: $e');
      return [];
    }
  }

  // ===========================================================================
  // 2️⃣ FETCH REKAP KEHADIRAN PETUGAS HARI INI (SUPABASE)
  // ===========================================================================
  /// Mengambil data absensi yang sudah dikirim oleh petugas hari ini dari `attendance_guide`
  static Future<Map<String, AttendanceGuideRecord>> fetchTodayAttendanceRecords({
    required String userId,
    String? dateStr,
  }) async {
    final client = SupabaseService.client;
    final today = dateStr ?? DateTime.now().toIso8601String().substring(0, 10);
    final Map<String, AttendanceGuideRecord> recordMap = {};

    try {
      List<dynamic> rows = [];
      if (client != null) {
        rows = await client
            .from('attendance_guide')
            .select()
            .eq('user_id', userId)
            .eq('attendance_date', today);
      } else {
        rows = await SupabaseService.restGet(
          'attendance_guide?user_id=eq.$userId&attendance_date=eq.$today',
        );
      }

      for (final r in rows) {
        final map = Map<String, dynamic>.from(r as Map);
        final record = AttendanceGuideRecord.fromMap(map);
        if (record.sesiId != null && record.sesiId!.isNotEmpty) {
          recordMap[record.sesiId!] = record;
        }
        if (record.sesi != null && record.sesi!.isNotEmpty) {
          recordMap[record.sesi!] = record;
        }
      }
    } catch (e) {
      debugPrint('❌ [AbsensiService] Error fetchTodayAttendanceRecords: $e');
    }

    return recordMap;
  }

  // ===========================================================================
  // 3️⃣ SUBMIT ABSENSI PETUGAS (SUPABASE ATTENDANCE_GUIDE)
  // ===========================================================================
  /// Mengirim absensi petugas ke Supabase table `attendance_guide`
  static Future<Map<String, dynamic>> submitAttendanceGuide({
    required String userId,
    required String sesiId,
    required String sesiTitle,
    String? bagianSesi,
    String? targetJamMulai,
    String? targetJamSelesai,
    String? kloter,
    String type = 'masuk',
    String? note,
    double? lat,
    double? lng,
    XFile? pickedFile,
  }) async {
    final client = SupabaseService.client;
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    // Hitung status ketepatan waktu
    String statusWaktu = 'tepat_waktu';
    if (targetJamSelesai != null && targetJamSelesai.isNotEmpty) {
      final parts = targetJamSelesai.split(':');
      if (parts.length >= 2) {
        final targetHour = int.tryParse(parts[0]) ?? 23;
        final targetMinute = int.tryParse(parts[1]) ?? 59;
        final targetDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          targetHour,
          targetMinute,
        );
        if (now.isAfter(targetDateTime)) {
          statusWaktu = 'terlambat';
        }
      }
    }

    // Persiapkan Photo (Upload Supabase Storage atau Base64 Data URI)
    String? photoUrl;
    if (pickedFile != null) {
      try {
        final bytes = await pickedFile.readAsBytes();
        final filename =
            'guide_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // 1. Coba upload ke Supabase Storage bucket 'attendance'
        if (client != null) {
          try {
            await client.storage.from('attendance').uploadBinary(
                  filename,
                  bytes,
                );
            photoUrl = client.storage.from('attendance').getPublicUrl(filename);
            debugPrint('✅ [AbsensiService] Photo uploaded to Storage: $photoUrl');
          } catch (storageErr) {
            debugPrint('ℹ️ [AbsensiService] Storage upload fallback to data URI: $storageErr');
          }
        }

        // 2. Jika storage tidak tersedia, simpan base64 data URI
        if (photoUrl == null || photoUrl.isEmpty) {
          final base64Str = base64Encode(bytes);
          photoUrl = 'data:image/jpeg;base64,$base64Str';
        }
      } catch (photoErr) {
        debugPrint('⚠️ [AbsensiService] Error encoding photo: $photoErr');
      }
    }

    final payload = {
      'user_id': userId,
      'attendance_date': todayStr,
      'kloter': kloter ?? '-',
      'photo_url': photoUrl,
      'latitude': lat,
      'longitude': lng,
      'type': type,
      'note': note,
      'sesi': sesiTitle,
      'bagian_sesi': bagianSesi,
      'sesi_id': sesiId.isNotEmpty ? sesiId : null,
      'target_jam_mulai': targetJamMulai,
      'target_jam_selesai': targetJamSelesai,
      'status_waktu': statusWaktu,
      'attendance_status': 'hadir',
      'created_at': now.toUtc().toIso8601String(),
    };

    // 1. Coba simpan ke Supabase Client (Update jika record penugasan sudah ada, atau Insert jika baru)
    if (client != null) {
      try {
        final existing = await client
            .from('attendance_guide')
            .select('id')
            .eq('user_id', userId)
            .eq('attendance_date', todayStr)
            .eq('sesi', sesiTitle)
            .maybeSingle();

        dynamic res;
        if (existing != null && existing['id'] != null) {
          res = await client
              .from('attendance_guide')
              .update(payload)
              .eq('id', existing['id'])
              .select()
              .maybeSingle();
        } else {
          res = await client
              .from('attendance_guide')
              .insert(payload)
              .select()
              .maybeSingle();
        }

        return {
          'success': true,
          'message': 'Absensi berhasil disimpan!',
          'data': res,
          'status_waktu': statusWaktu,
        };
      } catch (e) {
        debugPrint('⚠️ [AbsensiService] Supabase client upsert failed: $e');
      }
    }

    // 2. Fallback simpan via Supabase REST
    try {
      final restRes = await SupabaseService.restInsert('attendance_guide', payload);
      if (restRes != null) {
        return {
          'success': true,
          'message': 'Absensi berhasil disimpan via REST!',
          'data': restRes,
          'status_waktu': statusWaktu,
        };
      }
    } catch (e) {
      debugPrint('⚠️ [AbsensiService] Supabase REST insert failed: $e');
    }

    // 3. Fallback terakhir ke Backend API jika Supabase belum dapat dijangkau
    if (pickedFile != null) {
      return uploadAttendance(
        pickedFile: pickedFile,
        role: 'tour_leader',
        lat: lat,
        lng: lng,
      );
    }

    return {
      'success': false,
      'message': 'Gagal menyimpan absensi ke Supabase. Periksa koneksi internet.',
    };
  }

  // ===========================================================================
  // 4️⃣ LEGACY / FALLBACK UPLOAD ATTENDANCE
  // ===========================================================================
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

    final Uri url = Uri.parse('$baseUrl$endpoint');

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

  // ===========================================================================
  // 5️⃣ AMBIL RIWAYAT ABSENSI PETUGAS
  // ===========================================================================
  static Future<Map<String, dynamic>> myHistory({int page = 1}) async {
    final client = SupabaseService.client;
    final userId = await ApiService.getCurrentUserId();

    if (client != null && userId != null && userId.isNotEmpty) {
      try {
        final rows = await client
            .from('attendance_guide')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(20);

        return {'success': true, 'data': rows};
      } catch (e) {
        debugPrint('⚠️ [AbsensiService.myHistory] Supabase fetch error: $e');
      }
    }

    final token = await _getToken();
    final url = Uri.parse('$baseUrl/attendance?page=$page');

    try {
      var res = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

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
