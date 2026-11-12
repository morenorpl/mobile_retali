// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'presence_service.dart';
import 'supabase_service.dart';

class ApiService {
  static Dio? _dio;

  // =====================================
  // BASE URL BACKEND VERCEL
  // =====================================
  static const String ROOT_URL = 'https://be-projectretalitwo.vercel.app/api';

  static String get _baseUrl {
    final root = ROOT_URL.endsWith('/')
        ? ROOT_URL.substring(0, ROOT_URL.length - 1)
        : ROOT_URL;

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
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 25),
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
    try {
      await PresenceService.setOfflineNow();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try {
      final client = SupabaseService.client;
      if (client != null) {
        await client.auth.signOut();
      }
    } catch (_) {}
  }

  static Future<String?> getTourLeaderToken() => _getToken();

  static Future<Dio> _authedClient() async {
    final dio = _client();
    final token = await _getToken();
    final sessionToken = await _getSessionToken();

    dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
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

    final userId = user['id'] ?? user['user_id'] ?? '';
    final name = user['name'] ?? user['full_name'] ?? user['username'] ?? '-';
    final email = user['email'] ?? '-';
    final role = user['role'] ?? 'tour_leader';

    String kloter = '-';
    if (user['kloter'] is Map) {
      kloter = (user['kloter']['name'] ?? user['kloter']['nama'] ?? '-').toString();
    } else if (user['kloter'] != null && user['kloter'].toString().isNotEmpty) {
      kloter = user['kloter'].toString();
    } else if (user['kloter_name'] != null) {
      kloter = user['kloter_name'].toString();
    }

    final kloterTanggal = user['kloter_tanggal'] ?? user['kloter_date'] ?? '-';
    final kloterId = user['kloter_id'] ?? (user['kloter'] is Map ? user['kloter']['id'] : null) ?? '';

    await prefs.setString("id", userId.toString());
    await prefs.setString("user_id", userId.toString());
    await prefs.setString("name", name.toString());
    await prefs.setString("email", email.toString());
    await prefs.setString("role", role.toString());
    await prefs.setString("kloter", kloter);
    if (kloterId.toString().isNotEmpty) {
      await prefs.setString("kloter_id", kloterId.toString());
    }
    await prefs.setString("kloter_tanggal", kloterTanggal.toString());
  }

  // =====================
  // GET CURRENT USER KLOTER
  // =====================
  static Future<String?> getCurrentUserKloter() async {
    final prefs = await SharedPreferences.getInstance();
    String? kloter = prefs.getString("kloter");

    // Jika sudah ada kloter tersimpan yang valid (bukan '-'), return langsung
    if (kloter != null && kloter.trim().isNotEmpty && kloter.trim() != '-') {
      return kloter.trim();
    }

    // Jika belum ada atau masih '-', coba sinkronkan dari Supabase profiles
    final supabaseClient = SupabaseService.client;
    final userId = prefs.getString("user_id") ?? prefs.getString("id");
    final email = prefs.getString("email");

    if (supabaseClient != null) {
      try {
        Map<String, dynamic>? profile;
        if (userId != null && userId.isNotEmpty) {
          profile = await supabaseClient
              .from('profiles')
              .select('*, kloter(*)')
              .eq('id', userId)
              .maybeSingle();
        }
        if (profile == null && email != null && email.isNotEmpty) {
          profile = await supabaseClient
              .from('profiles')
              .select('*, kloter(*)')
              .eq('email', email)
              .maybeSingle();
        }

        if (profile != null) {
          String? foundKloter;
          String? foundTanggal;
          if (profile['kloter'] is Map) {
            foundKloter = (profile['kloter']['name'] ?? profile['kloter']['nama'])?.toString();
            foundTanggal = profile['kloter']['start_date']?.toString();
          } else if (profile['kloter'] != null && profile['kloter'].toString().isNotEmpty) {
            foundKloter = profile['kloter'].toString();
          } else if (profile['kloter_id'] != null) {
            final k = await supabaseClient
                .from('kloter')
                .select('name, start_date')
                .eq('id', profile['kloter_id'].toString())
                .maybeSingle();
            if (k != null && k['name'] != null) {
              foundKloter = k['name'].toString();
              foundTanggal = k['start_date']?.toString();
            }
          }

          if (foundKloter != null && foundKloter.trim().isNotEmpty && foundKloter.trim() != '-') {
            await prefs.setString("kloter", foundKloter.trim());
            if (foundTanggal != null && foundTanggal.isNotEmpty) {
              await prefs.setString("kloter_tanggal", foundTanggal);
            }
            if (profile['kloter_id'] != null) {
              await prefs.setString("kloter_id", profile['kloter_id'].toString());
            }
            return foundKloter.trim();
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error getCurrentUserKloter Supabase client: $e');
      }
    }

    // Direct REST Fallback
    try {
      if (email != null && email.isNotEmpty) {
        final restData = await SupabaseService.restGet(
          'profiles?select=*,kloter(*)&email=eq.$email',
        );
        if (restData.isNotEmpty && restData.first is Map) {
          final p = Map<String, dynamic>.from(restData.first as Map);
          String? foundKloter;
          if (p['kloter'] is Map) {
            foundKloter = (p['kloter']['name'] ?? p['kloter']['nama'])?.toString();
          } else if (p['kloter'] != null && p['kloter'].toString().isNotEmpty) {
            foundKloter = p['kloter'].toString();
          }
          if (foundKloter != null && foundKloter.trim().isNotEmpty && foundKloter.trim() != '-') {
            await prefs.setString("kloter", foundKloter.trim());
            return foundKloter.trim();
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error getCurrentUserKloter Supabase REST: $e');
    }

    return kloter;
  }

  // =====================
  // KLOTER COMPARISON HELPER
  // =====================
  static bool isSameKloter(String? userKloter, String? itemKloter) {
    if (userKloter == null || itemKloter == null) return false;
    final u = userKloter.trim().toLowerCase();
    final i = itemKloter.trim().toLowerCase();
    if (u.isEmpty || i.isEmpty || u == '-' || i == '-') return false;

    // 1. Exact match (case-insensitive & trimmed)
    if (u == i) return true;

    // 2. Remove standard separators & 'kloter' keyword
    // e.g. "kloter 198" -> "198", "kloter-198" -> "198", "umrah_reguler" -> "umrahreguler"
    final uClean = u.replaceAll('kloter', '').replaceAll(RegExp(r'[^a-z0-9]'), '');
    final iClean = i.replaceAll('kloter', '').replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (uClean.isNotEmpty && iClean.isNotEmpty && uClean == iClean) {
      return true;
    }

    // 3. Number-only comparison: if both contain digits, compare extracted digits
    final uDigits = RegExp(r'\d+').allMatches(u).map((m) => m.group(0)).join();
    final iDigits = RegExp(r'\d+').allMatches(i).map((m) => m.group(0)).join();
    if (uDigits.isNotEmpty && iDigits.isNotEmpty && uDigits == iDigits) {
      return true;
    }

    return false;
  }

  // =====================
  // LOGIN
  // =====================
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    // 1. Coba login melalui backend FastAPI
    final dio = _client();

    try {
      Response res;
      try {
        res = await dio.post(
          '/auth/login',
          data: {'email': email, 'password': password},
        );
      } catch (_) {
        res = await dio.post(
          '/login',
          data: {'email': email, 'password': password},
        );
      }

      final data = res.data;

      if (res.statusCode == 200 && data is Map<String, dynamic>) {
        final token = (data['access_token'] ?? data['token'] ?? data['session_token'])?.toString();
        final sessionToken = (data['session_token'] ?? data['access_token'] ?? data['token'])?.toString() ?? '';

        if (token != null && token.isNotEmpty) {
          final user = data['user'] ?? data['profile'] ?? data['data'];
          String userRole = user is Map<String, dynamic> ? (user['role']?.toString() ?? '') : '';
          String userId = user is Map<String, dynamic> ? (user['id'] ?? user['user_id'] ?? '').toString() : '';
          String userName = user is Map<String, dynamic> ? (user['name'] ?? user['username'] ?? user['full_name'] ?? '').toString() : '';
          String userKloter = '';
          String? userKloterId;
          String userKloterTanggal = '';

          // Sinkronkan ke Supabase Auth jika tersedia & ambil data profile
          final supabaseClient = SupabaseService.client;
          if (supabaseClient != null) {
            try {
              final authRes = await supabaseClient.auth.signInWithPassword(
                email: email,
                password: password,
              );
              if (authRes.user != null) {
                if (userId.isEmpty) userId = authRes.user!.id;
              }
            } catch (_) {}

            try {
              final profile = await supabaseClient
                  .from('profiles')
                  .select('*, kloter(*)')
                  .or('email.eq.$email,id.eq.$userId')
                  .maybeSingle();

              if (profile != null) {
                userId = profile['id']?.toString() ?? userId;
                userRole = profile['role']?.toString() ?? userRole;
                userName = profile['username'] ?? profile['name'] ?? userName;
                if (profile['kloter'] is Map) {
                  userKloter = (profile['kloter']['name'] ?? profile['kloter']['nama'] ?? '').toString();
                  userKloterTanggal = (profile['kloter']['start_date'] ?? '').toString();
                } else if (profile['kloter'] != null && profile['kloter'].toString().isNotEmpty) {
                  userKloter = profile['kloter'].toString();
                }
                userKloterId = profile['kloter_id']?.toString();
              }
            } catch (_) {}
          }

          if (userKloter.isEmpty && userKloterId != null && userKloterId.isNotEmpty && supabaseClient != null) {
            try {
              final k = await supabaseClient.from('kloter').select('name, start_date').eq('id', userKloterId).maybeSingle();
              if (k != null && k['name'] != null) {
                userKloter = k['name'].toString();
                if (userKloterTanggal.isEmpty && k['start_date'] != null) {
                  userKloterTanggal = k['start_date'].toString();
                }
              }
            } catch (_) {}
          }

          if (userKloter.isEmpty && user is Map) {
            if (user['kloter'] is Map) {
              userKloter = (user['kloter']['name'] ?? user['kloter']['nama'] ?? '').toString();
            } else if (user['kloter'] != null && user['kloter'].toString().isNotEmpty) {
              userKloter = user['kloter'].toString();
            } else if (user['kloter_name'] != null) {
              userKloter = user['kloter_name'].toString();
            }
            userKloterTanggal = (user['kloter_tanggal'] ?? user['kloter_date'] ?? '').toString();
          }

          // 🛑 VALIDASI ROLE: Hanya Tour Leader dan Muthawif yang boleh login (Admin ditolak)
          final normalizedRole = userRole.toLowerCase().replaceAll('_', '').trim();
          if (normalizedRole == 'admin' || (normalizedRole != 'tourleader' && normalizedRole != 'muthawif')) {
            await logout();
            return {
              'success': false,
              'message': 'Akses ditolak: Aplikasi ini khusus untuk petugas (Tour Leader & Muthawif). Admin tidak dapat login.',
            };
          }

          await _saveToken(token);
          await _saveSessionToken(sessionToken);

          await saveProfileToLocal({
            'id': userId,
            'user_id': userId,
            'email': email,
            'name': userName.isNotEmpty ? userName : email.split('@').first,
            'role': userRole.isNotEmpty ? userRole : 'tour_leader',
            'kloter': userKloter.isNotEmpty ? userKloter : '-',
            'kloter_id': userKloterId,
            'kloter_tanggal': userKloterTanggal.isNotEmpty ? userKloterTanggal : '-',
          });

          return {'success': true, 'message': 'Login Berhasil'};
        }
      }

      String message = 'Email atau password salah';
      if (data is Map<String, dynamic>) {
        if (data['detail'] != null) {
          message = data['detail'].toString();
        } else if (data['message'] != null) {
          message = data['message'].toString();
        }
      }

      return {'success': false, 'message': message};
    } on DioException catch (e) {
      // 2. Jika backend gagal (misal server down atau CORS),
      // otomatis fallback ke Supabase Auth langsung
      final supabaseClient = SupabaseService.client;
      if (supabaseClient != null) {
        try {
          final authRes = await supabaseClient.auth.signInWithPassword(
            email: email,
            password: password,
          );

          final session = authRes.session;
          final user = authRes.user;

          if (session != null && user != null) {
            String userRole = '';
            String userName = '';
            String profileId = user.id;
            String userKloter = '';
            String? userKloterId;
            String userKloterTanggal = '';

            try {
              final profile = await supabaseClient
                  .from('profiles')
                  .select('*, kloter(*)')
                  .or('id.eq.${user.id},email.eq.$email')
                  .maybeSingle();

              if (profile != null) {
                profileId = profile['id']?.toString() ?? user.id;
                userRole = profile['role']?.toString() ?? '';
                userName = profile['username'] ?? profile['name'] ?? '';
                if (profile['kloter'] is Map) {
                  userKloter = (profile['kloter']['name'] ?? profile['kloter']['nama'] ?? '').toString();
                  userKloterTanggal = (profile['kloter']['start_date'] ?? '').toString();
                } else if (profile['kloter'] != null && profile['kloter'].toString().isNotEmpty) {
                  userKloter = profile['kloter'].toString();
                }
                userKloterId = profile['kloter_id']?.toString();
              }
            } catch (_) {}

            if (userKloter.isEmpty && userKloterId != null && userKloterId.isNotEmpty) {
              try {
                final k = await supabaseClient.from('kloter').select('name, start_date').eq('id', userKloterId).maybeSingle();
                if (k != null && k['name'] != null) {
                  userKloter = k['name'].toString();
                  if (userKloterTanggal.isEmpty && k['start_date'] != null) {
                    userKloterTanggal = k['start_date'].toString();
                  }
                }
              } catch (_) {}
            }

            final meta = user.userMetadata ?? {};
            if (userRole.isEmpty) {
              userRole = meta['role']?.toString() ?? '';
            }
            if (userKloter.isEmpty) {
              userKloter = (meta['kloter'] ?? '-').toString();
            }
            if (userKloterTanggal.isEmpty) {
              userKloterTanggal = (meta['kloter_tanggal'] ?? '-').toString();
            }

            // 🛑 VALIDASI ROLE: Hanya Tour Leader dan Muthawif yang boleh login (Admin ditolak)
            final normalizedRole = userRole.toLowerCase().replaceAll('_', '').trim();
            if (normalizedRole == 'admin' || (normalizedRole != 'tourleader' && normalizedRole != 'muthawif')) {
              await logout();
              return {
                'success': false,
                'message': 'Akses ditolak: Aplikasi ini khusus untuk petugas (Tour Leader & Muthawif). Admin tidak dapat login.',
              };
            }

            await _saveToken(session.accessToken);
            await _saveSessionToken(session.accessToken);

            await saveProfileToLocal({
              'id': profileId,
              'user_id': profileId,
              'email': user.email ?? email,
              'name': userName.isNotEmpty ? userName : (meta['full_name'] ?? meta['name'] ?? user.email?.split('@').first ?? 'Petugas'),
              'role': userRole.isNotEmpty ? userRole : 'tour_leader',
              'kloter': userKloter.isNotEmpty ? userKloter : '-',
              'kloter_id': userKloterId,
              'kloter_tanggal': userKloterTanggal.isNotEmpty ? userKloterTanggal : '-',
            });

            return {'success': true, 'message': 'Login Berhasil'};
          }
        } on AuthException catch (authErr) {
          return {'success': false, 'message': authErr.message};
        } catch (_) {}
      }

      String errMsg = 'Terjadi kesalahan jaringan';
      if (e.response?.data is Map<String, dynamic>) {
        final errData = e.response!.data as Map<String, dynamic>;
        errMsg = (errData['detail'] ?? errData['message'] ?? errMsg).toString();
      } else if (e.message != null && e.message!.isNotEmpty) {
        if (e.message!.contains('XMLHttpRequest')) {
          errMsg = 'Gagal terhubung (CORS Web). Silakan jalankan Flutter Web pada port 3000: flutter run -d chrome --web-port=3000, atau jalankan di Android.';
        } else {
          errMsg = e.message!;
        }
      }
      return {'success': false, 'message': errMsg};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  // =====================
  // AUTH: FORGOT & RESET PASSWORD
  // =====================
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final supabaseClient = SupabaseService.client;
    if (supabaseClient != null) {
      try {
        await supabaseClient.auth.resetPasswordForEmail(email);
        return {'success': true, 'message': 'Email reset password telah dikirim via Supabase'};
      } catch (_) {}
    }

    final dio = _client();
    try {
      final res = await dio.post('/auth/forgot-password', data: {'email': email});
      return {'success': res.statusCode == 200, 'data': res.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyResetOtp(String email, String otp) async {
    final dio = _client();
    try {
      final res = await dio.post('/auth/verify-reset-otp', data: {'email': email, 'otp': otp});
      return {'success': res.statusCode == 200, 'data': res.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    final dio = _client();
    try {
      final res = await dio.post('/auth/reset-password', data: {
        'email': email,
        'reset_token': resetToken,
        'new_password': newPassword,
      });
      return {'success': res.statusCode == 200, 'data': res.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // =====================
  // GET PASSPORT SCANS
  // =====================
  static Future<List<dynamic>> getPassportScans({String? kloter}) async {
    final targetKloter = kloter ?? await getCurrentUserKloter();
    List<dynamic> list = [];

    // 1. Ambil dari Supabase tabel passport_scans via Supabase Client
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final res = await client
            .from('passport_scans')
            .select('*')
            .order('created_at', ascending: false);

        list = res.map((row) {
          final map = Map<String, dynamic>.from(row as Map);
          map['owner_phone'] = map['phone'];
          map['scanned_at'] = map['scanned_at'] ?? map['created_at'];
          return map;
        }).toList();
      } catch (e) {
        debugPrint('⚠️ Error getPassportScans from Supabase client: $e');
      }
    }

    // 2. Direct REST Fallback ke Supabase
    if (list.isEmpty) {
      try {
        final restData = await SupabaseService.restGet('passport_scans');
        if (restData.isNotEmpty) {
          list = restData.map((row) {
            final map = Map<String, dynamic>.from(row as Map);
            map['owner_phone'] = map['phone'];
            map['scanned_at'] = map['scanned_at'] ?? map['created_at'];
            return map;
          }).toList();
        }
      } catch (e) {
        debugPrint('⚠️ Error getPassportScans Supabase REST fallback: $e');
      }
    }

    if (list.isEmpty) {
      final dio = await _authedClient();
      try {
        Response res;
        try {
          res = await dio.get('/tourleader/passport-scans');
        } catch (_) {
          res = await dio.get('/scans', queryParameters: {'scan_type': 'passport'});
        }

        if (res.data is List) {
          list = res.data;
        } else if (res.data is Map && res.data['data'] is List) {
          list = res.data['data'];
        }
      } catch (_) {}
    }

    // Filter berdasarkan kloter petugas yang sedang login
    if (targetKloter != null && targetKloter.isNotEmpty && targetKloter != '-' && targetKloter != 'ALL') {
      return list.where((scan) {
        final itemKloter = (scan['kloter'] ?? '').toString();
        return isSameKloter(targetKloter, itemKloter);
      }).toList();
    } else if (targetKloter == null || targetKloter.isEmpty || targetKloter == '-') {
      // Petugas belum memiliki kloter, tidak menampilkan kloter lain
      return [];
    }

    return list;
  }

  // =====================
  // DELETE KOPER
  // =====================
  static Future<bool> deleteKoper(dynamic id) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from('koper').delete().eq('id', id.toString());
        return true;
      } catch (e) {
        debugPrint('⚠️ Error delete koper Supabase client: $e');
      }
    }

    // REST Fallback
    final deleted = await SupabaseService.restDelete('koper', 'id', id);
    if (deleted) return true;

    final dio = await _authedClient();

    try {
      Response res;
      try {
        res = await dio.delete('/tourleader/scans/$id');
      } catch (_) {
        res = await dio.delete('/scans/$id');
      }
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =====================
  // DELETE PASPOR
  // =====================
  static Future<bool> deletePassport(dynamic id) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from('passport_scans').delete().eq('id', id.toString());
        return true;
      } catch (e) {
        debugPrint('⚠️ Error delete passport Supabase client: $e');
      }
    }

    // REST Fallback
    final deleted = await SupabaseService.restDelete('passport_scans', 'id', id);
    if (deleted) return true;

    final dio = await _authedClient();

    try {
      Response res;
      try {
        res = await dio.delete('/tourleader/passport-scans/$id');
      } catch (_) {
        res = await dio.delete('/scans/$id');
      }
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =====================
  // GET USER INFO
  // =====================
  static Future<Map<String, dynamic>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString("role") ?? "tour_leader";
    final userId = prefs.getString("user_id") ?? prefs.getString("id");
    final email = prefs.getString("email");

    // 1. Coba ambil dari Supabase tabel profiles
    final supabaseClient = SupabaseService.client;
    if (supabaseClient != null) {
      try {
        final query = supabaseClient.from('profiles').select('*, kloter(*)');
        final profile = userId != null && userId.isNotEmpty
            ? await query.eq('id', userId).maybeSingle()
            : (email != null && email.isNotEmpty
                ? await query.eq('email', email).maybeSingle()
                : null);

        if (profile != null) {
          if (profile['role'] != null) {
            await prefs.setString("role", profile['role'].toString());
          }
          if (profile['username'] != null || profile['name'] != null) {
            await prefs.setString(
              "name",
              (profile['username'] ?? profile['name']).toString(),
            );
          }
          String? kloter;
          String? kloterTanggal;
          if (profile['kloter'] is Map) {
            kloter = (profile['kloter']['name'] ?? profile['kloter']['nama'])?.toString();
            kloterTanggal = profile['kloter']['start_date']?.toString();
          } else if (profile['kloter'] != null && profile['kloter'].toString().isNotEmpty) {
            kloter = profile['kloter'].toString();
          } else if (profile['kloter_id'] != null) {
            final k = await supabaseClient
                .from('kloter')
                .select('name, start_date')
                .eq('id', profile['kloter_id'].toString())
                .maybeSingle();
            if (k != null && k['name'] != null) {
              kloter = k['name'].toString();
              kloterTanggal = k['start_date']?.toString();
            }
          }
          if (kloter != null && kloter.trim().isNotEmpty && kloter.trim() != '-') {
            await prefs.setString("kloter", kloter.trim());
          }
          if (kloterTanggal != null && kloterTanggal.trim().isNotEmpty && kloterTanggal.trim() != '-') {
            await prefs.setString("kloter_tanggal", kloterTanggal.trim());
          }
          if (profile['kloter_id'] != null) {
            await prefs.setString("kloter_id", profile['kloter_id'].toString());
          }
          return profile;
        }
      } catch (_) {}
    }

    final dio = await _authedClient();
    try {
      Response res;
      if (userId != null && userId.isNotEmpty) {
        try {
          res = await dio.get('/users/$userId');
          if (res.data is Map<String, dynamic>) {
            return res.data as Map<String, dynamic>;
          }
        } catch (_) {}
      }

      final endpoint = role == "muthawif"
          ? '/muthawif/profile'
          : '/tourleader/profile';

      res = await dio.get(endpoint);

      if (res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      return {};
    }
  }

  // =====================
  // GET CURRENT USER ID
  // =====================
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("user_id") ?? prefs.getString("id");

    if (userId != null && userId.isNotEmpty && userId != '-') {
      return userId;
    }

    // Coba ambil dari Supabase Auth
    final supaUser = SupabaseService.client?.auth.currentUser;
    if (supaUser != null && supaUser.id.isNotEmpty) {
      await prefs.setString("id", supaUser.id);
      await prefs.setString("user_id", supaUser.id);
      return supaUser.id;
    }

    // Coba sinkronisasi dari profile berdasarkan email
    final email = prefs.getString("email");
    if (email != null && email.isNotEmpty && SupabaseService.client != null) {
      try {
        final prof = await SupabaseService.client!
            .from('profiles')
            .select('id')
            .eq('email', email)
            .maybeSingle();

        if (prof != null && prof['id'] != null) {
          final foundId = prof['id'].toString();
          await prefs.setString("id", foundId);
          await prefs.setString("user_id", foundId);
          return foundId;
        }
      } catch (e) {
        debugPrint("⚠️ Gagal sync profile id: $e");
      }
    }

    return null;
  }

  // =====================
  // NOTIFICATIONS (SUPABASE CONNECTED)
  // =====================
  static Future<List<NotificationItem>> getNotificationItems() async {
    final userId = await getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      debugPrint("ℹ️ [ApiService.getNotificationItems] User belum login / userId belum tersedia");
      return [];
    }

    final client = SupabaseService.client;
    final List<NotificationItem> items = [];
    final Set<String> seenNotifIds = {};

    // 1. Ambil dari Supabase Client
    if (client != null) {
      try {
        // A. Ambil dari notification_recipients yang ditujukan spesifik ke user login
        final recipList = await client
            .from('notification_recipients')
            .select('*, notifications(*)')
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        for (final row in recipList) {
          if (row['notifications'] is Map) {
            final notifMap = Map<String, dynamic>.from(row['notifications'] as Map);
            final notifId = notifMap['id']?.toString() ?? '';
            if (notifId.isNotEmpty && !seenNotifIds.contains(notifId)) {
              seenNotifIds.add(notifId);
              items.add(NotificationItem.fromMap(
                notifMap,
                recipientData: Map<String, dynamic>.from(row),
              ));
            }
          }
        }

        // B. Periksa juga tabel notifications jika ada yang ditujukan langsung (user_id == userId)
        final directList = await client
            .from('notifications')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        for (final row in directList) {
          final rowMap = Map<String, dynamic>.from(row);
          final notifId = rowMap['id']?.toString() ?? '';
          if (notifId.isNotEmpty && !seenNotifIds.contains(notifId)) {
            seenNotifIds.add(notifId);
            items.add(NotificationItem.fromMap(rowMap));
          }
        }
      } catch (e) {
        debugPrint("⚠️ [ApiService.getNotificationItems] Supabase error: $e");
      }
    }

    // 2. Fallback REST Supabase jika Supabase Client belum aktif / ada kendala
    if (items.isEmpty && SupabaseConfig.isConfigured) {
      try {
        final uri = Uri.parse(
          '${SupabaseConfig.supabaseUrl}/rest/v1/notification_recipients?select=*,notifications(*)&user_id=eq.$userId&order=created_at.desc',
        );
        final res = await http.get(uri, headers: SupabaseConfig.restHeaders);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final decoded = jsonDecode(res.body);
          if (decoded is List) {
            for (final row in decoded) {
              if (row is Map && row['notifications'] is Map) {
                final notifMap = Map<String, dynamic>.from(row['notifications'] as Map);
                final notifId = notifMap['id']?.toString() ?? '';
                if (notifId.isNotEmpty && !seenNotifIds.contains(notifId)) {
                  seenNotifIds.add(notifId);
                  items.add(NotificationItem.fromMap(
                    notifMap,
                    recipientData: Map<String, dynamic>.from(row),
                  ));
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint("⚠️ [ApiService.getNotificationItems] REST error: $e");
      }
    }

    // Urutkan notifikasi: yang mendesak / aktif (hijau, kuning, merah) di atas,
    // lalu urutkan berdasarkan startDate / createdAt terbaru
    items.sort((a, b) {
      final rankA = a.status == NotificationStatus.hijau
          ? 0
          : a.status == NotificationStatus.kuning
              ? 1
              : a.status == NotificationStatus.merah
                  ? 2
                  : 3;
      final rankB = b.status == NotificationStatus.hijau
          ? 0
          : b.status == NotificationStatus.kuning
              ? 1
              : b.status == NotificationStatus.merah
                  ? 2
                  : 3;

      if (rankA != rankB) {
        return rankA.compareTo(rankB);
      }

      final dateA = a.startDate ?? a.createdAt;
      final dateB = b.startDate ?? b.createdAt;
      return dateB.compareTo(dateA);
    });

    return items;
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final items = await getNotificationItems();
    return items.map((item) {
      final map = item.toMap();
      map['_model'] = item;
      return map;
    }).toList();
  }

  static Future<void> markAllNotificationsAsRead() async {
    final userId = await getCurrentUserId();
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final client = SupabaseService.client;

    if (client != null && userId != null && userId.isNotEmpty) {
      try {
        await client
            .from('notification_recipients')
            .update({'is_read': true, 'read_at': nowUtc})
            .eq('user_id', userId)
            .eq('is_read', false);
      } catch (e) {
        debugPrint("⚠️ [markAllNotificationsAsRead] error updating notification_recipients: $e");
      }

      try {
        await client
            .from('notifications')
            .update({'is_read': true, 'read_at': nowUtc})
            .eq('user_id', userId)
            .eq('is_read', false);
      } catch (_) {}
    }

    // Direct REST update
    if (SupabaseConfig.isConfigured && userId != null && userId.isNotEmpty) {
      try {
        final uri = Uri.parse(
          '${SupabaseConfig.supabaseUrl}/rest/v1/notification_recipients?user_id=eq.$userId&is_read=eq.false',
        );
        await http.patch(
          uri,
          headers: SupabaseConfig.restHeaders,
          body: jsonEncode({'is_read': true, 'read_at': nowUtc}),
        );
      } catch (_) {}
    }

    // Fallback Dio jika ada backend
    try {
      final dio = await _authedClient();
      await dio.post('/notifications/read-all');
    } catch (_) {}
  }

  static Future<void> markNotificationAsRead(dynamic id) async {
    final userId = await getCurrentUserId();
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final client = SupabaseService.client;

    if (client != null && userId != null && userId.isNotEmpty) {
      try {
        await client
            .from('notification_recipients')
            .update({'is_read': true, 'read_at': nowUtc})
            .eq('notification_id', id.toString())
            .eq('user_id', userId);
      } catch (e) {
        debugPrint("⚠️ [markNotificationAsRead] error updating notification_recipients: $e");
      }

      try {
        await client
            .from('notifications')
            .update({'is_read': true, 'read_at': nowUtc})
            .eq('id', id.toString())
            .eq('user_id', userId);
      } catch (_) {}
    }

    // Direct REST update
    if (SupabaseConfig.isConfigured && userId != null && userId.isNotEmpty) {
      try {
        final uri = Uri.parse(
          '${SupabaseConfig.supabaseUrl}/rest/v1/notification_recipients?notification_id=eq.$id&user_id=eq.$userId',
        );
        await http.patch(
          uri,
          headers: SupabaseConfig.restHeaders,
          body: jsonEncode({'is_read': true, 'read_at': nowUtc}),
        );
      } catch (_) {}
    }

    // Fallback backend
    try {
      final dio = await _authedClient();
      await dio.patch('/notifications/$id/read');
    } catch (_) {
      try {
        final dio = await _authedClient();
        await dio.post('/notifications/$id/read');
      } catch (_) {}
    }
  }

  // =====================
  // SCAN KOPER (RAW)
  // =====================
  static Future<Map<String, dynamic>> storeScanFromRaw(String qrRaw) async {
    // 1. Coba simpan ke Supabase tabel koper
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userKloter = await getCurrentUserKloter();
        final defaultKloter = (userKloter != null && userKloter.trim().isNotEmpty && userKloter.trim() != '-')
            ? userKloter.trim()
            : (prefs.getString("kloter") ?? "-");

        String kodeKoper = "";
        String namaPemilik = "-";
        String nomorTelepon = "-";
        String kloter = defaultKloter;

        bool parsed = false;
        try {
          final j = jsonDecode(qrRaw);
          if (j is Map) {
            kodeKoper = (j['kode_koper'] ?? j['koper_code'] ?? j['code'] ?? '').toString().trim();
            namaPemilik = (j['nama_pemilik'] ?? j['owner_name'] ?? j['name'] ?? '-').toString().trim();
            nomorTelepon = (j['nomor_telepon'] ?? j['owner_phone'] ?? j['phone'] ?? '-').toString().trim();
            kloter = (j['kloter'] ?? defaultKloter).toString().trim();
            parsed = true;
          }
        } catch (_) {}

        if (!parsed) {
          final parts = qrRaw.split('|').map((e) => e.trim()).toList();
          kodeKoper = parts.isNotEmpty ? parts[0] : qrRaw.trim();
          if (parts.length >= 2) namaPemilik = parts[1];
          if (parts.length >= 3) nomorTelepon = parts[2];
          if (parts.length >= 4) kloter = parts[3];
        }

        if (kodeKoper.isEmpty) {
          kodeKoper = qrRaw.trim();
        }

        // Cek apakah koper sudah pernah discan / ada di database
        final existing = await client
            .from('koper')
            .select('*')
            .eq('kode_koper', kodeKoper)
            .maybeSingle();

        if (existing != null) {
          return {
            'status': 'error',
            'code': 409,
            'message': 'Koper sudah pernah discan',
            'data': {
              'koper_code': existing['kode_koper'],
              'kode_koper': existing['kode_koper'],
              'owner_name': existing['nama_pemilik'],
              'nama_pemilik': existing['nama_pemilik'],
              'owner_phone': existing['nomor_telepon'],
              'nomor_telepon': existing['nomor_telepon'],
              'kloter': existing['kloter'],
              'scanned_at': existing['created_at'],
              'created_at': existing['created_at'],
            },
          };
        }

        final nowIso = DateTime.now().toUtc().toIso8601String();
        final inserted = await client.from('koper').insert({
          'kode_koper': kodeKoper,
          'nama_pemilik': namaPemilik,
          'nomor_telepon': nomorTelepon,
          'kloter': kloter,
          'created_at': nowIso,
        }).select().single();

        return {
          'status': 'success',
          'success': true,
          'code': 200,
          'data': {
            'koper_code': inserted['kode_koper'] ?? kodeKoper,
            'kode_koper': inserted['kode_koper'] ?? kodeKoper,
            'owner_name': inserted['nama_pemilik'] ?? namaPemilik,
            'nama_pemilik': inserted['nama_pemilik'] ?? namaPemilik,
            'owner_phone': inserted['nomor_telepon'] ?? nomorTelepon,
            'nomor_telepon': inserted['nomor_telepon'] ?? nomorTelepon,
            'kloter': inserted['kloter'] ?? kloter,
            'scanned_at': inserted['created_at'] ?? nowIso,
            'created_at': inserted['created_at'] ?? nowIso,
          },
        };
      } catch (e) {
        debugPrint('⚠️ Error storeScanFromRaw Supabase: $e');
      }
    }

    final dio = await _authedClient();

    try {
      Response res;
      try {
        res = await dio.post('/tourleader/scans', data: {'qr_text': qrRaw});
      } catch (_) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString("user_id") ?? prefs.getString("id") ?? '';
        res = await dio.post('/scans', data: {
          'user_id': userId,
          'scan_type': 'koper',
          'location': qrRaw,
        });
      }

      final data = res.data;

      if (data is Map<String, dynamic>) {
        return {
          'success': data['status'] == 'success' || res.statusCode == 200 || res.statusCode == 201,
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
    // 1. Coba simpan ke Supabase tabel passport_scans
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userKloter = await getCurrentUserKloter();
        final defaultKloter = (userKloter != null && userKloter.trim().isNotEmpty && userKloter.trim() != '-')
            ? userKloter.trim()
            : (prefs.getString("kloter") ?? "-");

        String passportNumber = "";
        String ownerName = "-";
        String phone = "-";
        String kloter = defaultKloter;

        bool parsed = false;
        try {
          final j = jsonDecode(qrRaw);
          if (j is Map) {
            passportNumber = (j['passport_number'] ?? j['passport'] ?? j['passportNumber'] ?? j['code'] ?? '').toString().trim();
            ownerName = (j['owner_name'] ?? j['name'] ?? j['nama_pemilik'] ?? '-').toString().trim();
            phone = (j['phone'] ?? j['owner_phone'] ?? j['nomor_telepon'] ?? '-').toString().trim();
            kloter = (j['kloter'] ?? defaultKloter).toString().trim();
            parsed = true;
          }
        } catch (_) {}

        if (!parsed) {
          final parts = qrRaw.split('|').map((e) => e.trim()).toList();
          passportNumber = parts.isNotEmpty ? parts[0] : qrRaw.trim();
          if (parts.length >= 2) ownerName = parts[1];
          if (parts.length >= 3) phone = parts[2];
          if (parts.length >= 4) kloter = parts[3];
        }

        if (passportNumber.isEmpty) {
          passportNumber = qrRaw.trim();
        }

        // Cek apakah paspor sudah pernah discan di database
        final existing = await client
            .from('passport_scans')
            .select('*')
            .eq('passport_number', passportNumber)
            .maybeSingle();

        if (existing != null) {
          return {
            'status': 'error',
            'code': 409,
            'message': 'Paspor sudah pernah discan',
            'data': {
              'passport_number': existing['passport_number'],
              'owner_name': existing['owner_name'],
              'owner_phone': existing['phone'],
              'phone': existing['phone'],
              'kloter': existing['kloter'],
              'scanned_at': existing['scanned_at'] ?? existing['created_at'],
              'created_at': existing['created_at'],
            },
          };
        }

        final nowIso = DateTime.now().toUtc().toIso8601String();
        final inserted = await client.from('passport_scans').insert({
          'passport_number': passportNumber,
          'owner_name': ownerName,
          'phone': phone,
          'kloter': kloter,
          'scanned_at': nowIso,
          'created_at': nowIso,
        }).select().single();

        return {
          'status': 'success',
          'success': true,
          'code': 200,
          'data': {
            'passport_number': inserted['passport_number'] ?? passportNumber,
            'owner_name': inserted['owner_name'] ?? ownerName,
            'owner_phone': inserted['phone'] ?? phone,
            'phone': inserted['phone'] ?? phone,
            'kloter': inserted['kloter'] ?? kloter,
            'scanned_at': inserted['scanned_at'] ?? nowIso,
            'created_at': inserted['created_at'] ?? nowIso,
          },
        };
      } catch (e) {
        debugPrint('⚠️ Error scanPassport Supabase: $e');
      }
    }

    final dio = await _authedClient();

    try {
      Response res;
      try {
        res = await dio.post(
          '/tourleader/passport-scan',
          data: {'qr_text': qrRaw},
        );
      } catch (_) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString("user_id") ?? prefs.getString("id") ?? '';
        res = await dio.post('/scans', data: {
          'user_id': userId,
          'scan_type': 'paspor',
          'location': qrRaw,
        });
      }

      final data = res.data;
      if (data is Map<String, dynamic>) {
        return {
          'status': data['status'] ?? (res.statusCode == 200 ? 'success' : 'error'),
          'code': res.statusCode,
          ...data,
        };
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
  // GET SCANS (KOPER)
  // =====================
  static Future<List<dynamic>> getScans({String? kloter}) async {
    final targetKloter = kloter ?? await getCurrentUserKloter();
    List<dynamic> list = [];

    // 1. Ambil dari Supabase tabel koper via Supabase Client
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final res = await client
            .from('koper')
            .select('*')
            .order('created_at', ascending: false);

        list = res.map((row) {
          final map = Map<String, dynamic>.from(row as Map);
          map['koper_code'] = map['kode_koper'];
          map['owner_name'] = map['nama_pemilik'];
          map['owner_phone'] = map['nomor_telepon'];
          map['scanned_at'] = map['created_at'];
          return map;
        }).toList();
      } catch (e) {
        debugPrint('⚠️ Error getScans from Supabase client: $e');
      }
    }

    // 2. Direct REST Fallback ke Supabase
    if (list.isEmpty) {
      try {
        final restData = await SupabaseService.restGet('koper');
        if (restData.isNotEmpty) {
          list = restData.map((row) {
            final map = Map<String, dynamic>.from(row as Map);
            map['koper_code'] = map['kode_koper'];
            map['owner_name'] = map['nama_pemilik'];
            map['owner_phone'] = map['nomor_telepon'];
            map['scanned_at'] = map['created_at'];
            return map;
          }).toList();
        }
      } catch (e) {
        debugPrint('⚠️ Error getScans Supabase REST fallback: $e');
      }
    }

    if (list.isEmpty) {
      final dio = await _authedClient();
      try {
        Response res;
        try {
          res = await dio.get('/tourleader/scans');
        } catch (_) {
          res = await dio.get('/scans');
        }

        if (res.data is List) {
          list = res.data;
        } else if (res.data is Map && res.data['data'] is List) {
          list = res.data['data'];
        }
      } catch (_) {}
    }

    // Filter berdasarkan kloter petugas yang sedang login
    if (targetKloter != null && targetKloter.isNotEmpty && targetKloter != '-' && targetKloter != 'ALL') {
      return list.where((scan) {
        final itemKloter = (scan['kloter'] ?? '').toString();
        return isSameKloter(targetKloter, itemKloter);
      }).toList();
    } else if (targetKloter == null || targetKloter.isEmpty || targetKloter == '-') {
      // Petugas belum memiliki kloter, tidak menampilkan kloter lain
      return [];
    }

    return list;
  }

  // =====================
  // DASHBOARD STATS
  // =====================
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final dio = await _authedClient();
    try {
      final res = await dio.get('/dashboard/stats');
      if (res.data is Map<String, dynamic>) {
        return res.data;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  // =====================
  // KLOTER
  // =====================
  static Future<List<dynamic>> getKloterList() async {
    final dio = await _authedClient();
    try {
      final res = await dio.get('/kloter');
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
  // ATTENDANCE
  // =====================
  static Future<List<dynamic>> getAttendance() async {
    final dio = await _authedClient();
    try {
      final res = await dio.get('/attendance');
      if (res.data is List) return res.data;
      if (res.data is Map && res.data['data'] is List) {
        return res.data['data'];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createAttendance({
    required String type,
    String? note,
  }) async {
    final dio = await _authedClient();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id") ?? prefs.getString("id") ?? '';

    try {
      final res = await dio.post('/attendance', data: {
        'user_id': userId,
        'type': type,
        if (note != null) 'note': note,
      });
      return {'success': res.statusCode == 200 || res.statusCode == 201, 'data': res.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
