import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/itinerary_models.dart';
import 'api_service.dart';
import 'supabase_service.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ItineraryService {
  final Dio _dio;

  static String _apiBase(String root) {
    final trimmed = root.replaceAll(RegExp(r'/+$'), '');
    return trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
  }

  ItineraryService({
    required String baseRoot,
    Future<String?> Function()? tokenProvider,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _apiBase(baseRoot),
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                validateStatus: (s) => s != null && s < 500,
              ),
            ) {
    if (tokenProvider != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = await tokenProvider();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          },
        ),
      );
    }
  }

  /// 🔑 Factory khusus Tour Leader: pakai ROOT_URL & token dari ApiService
  factory ItineraryService.forTourLeader() {
    return ItineraryService(
      baseRoot: ApiService.ROOT_URL,
      tokenProvider: ApiService.getTourLeaderToken,
    );
  }

  // ===== helper JSON
  T _unwrap<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return fromJson(data);
      return fromJson(raw);
    }
    throw ApiException('Unexpected response format');
  }

  List<Map<String, dynamic>> _unwrapList(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
    }
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    throw ApiException('Unexpected list response format');
  }

  // =====================================================
  //  SUPABASE HELPERS
  // =====================================================

  /// Ambil daftar itinerary dari Supabase
  Future<List<Itinerary>> _fetchFromSupabase({String? q}) async {
    // 1. Coba dari tabel `itineraries` via Supabase Client
    try {
      final client = SupabaseService.client;
      if (client != null) {
        final res = await client
            .from('itineraries')
            .select('*, profiles:created_by(username), itinerary_days(*, itinerary_activities(*))')
            .order('created_at', ascending: false);

        if (res.isNotEmpty) {
          var list = res
              .map((m) => Itinerary.fromJson(Map<String, dynamic>.from(m as Map)))
              .toList();

          if (q != null && q.trim().isNotEmpty) {
            final queryLower = q.trim().toLowerCase();
            list = list
                .where((item) =>
                    item.title.toLowerCase().contains(queryLower) ||
                    item.tourLeader.toLowerCase().contains(queryLower))
                .toList();
          }

          debugPrint('✅ [ItineraryService] Loaded ${list.length} itineraries from Supabase client');
          return list;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ItineraryService] Error via Supabase client (itineraries): $e');
    }

    // 2. Coba dari tabel `itineraries` via REST API direct
    try {
      final uri = Uri.parse(
        '${SupabaseConfig.supabaseUrl}/rest/v1/itineraries?select=*,profiles:created_by(username),itinerary_days(*,itinerary_activities(*))&order=created_at.desc',
      );
      final res = await http.get(uri, headers: SupabaseConfig.restHeaders);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is List && decoded.isNotEmpty) {
          final list = decoded
              .map((m) => Itinerary.fromJson(Map<String, dynamic>.from(m as Map)))
              .toList();
          if (q != null && q.trim().isNotEmpty) {
            return list
                .where((item) =>
                    item.title.toLowerCase().contains(q.trim().toLowerCase()))
                .toList();
          }
          debugPrint('✅ [ItineraryService] Loaded ${list.length} itineraries from Supabase REST');
          return list;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ItineraryService] Error via Supabase REST (itineraries): $e');
    }

    // 3. Fallback: Ambil langsung dari `itinerary_days` dan `itinerary_activities`
    // Jika tabel `itineraries` belum memiliki policy SELECT publik, data tetap tampil!
    try {
      final uri = Uri.parse(
        '${SupabaseConfig.supabaseUrl}/rest/v1/itinerary_days?select=*,itinerary_activities(*)&order=day_number.asc',
      );
      final res = await http.get(uri, headers: SupabaseConfig.restHeaders);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is List && decoded.isNotEmpty) {
          // Kelompokkan per itinerary_id
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final raw in decoded) {
            if (raw is Map) {
              final itId = (raw['itinerary_id'] ?? 'default').toString();
              grouped.putIfAbsent(itId, () => []).add(Map<String, dynamic>.from(raw));
            }
          }

          final List<Itinerary> synthesized = [];
          grouped.forEach((itId, rawDays) {
            final days = rawDays
                .map((d) => ItineraryDay.fromJson(d))
                .toList()
              ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

            final firstDate = days.first.date;
            final lastDate = days.last.date;

            synthesized.add(
              Itinerary(
                id: itId,
                title: 'Itinerary Perjalanan Umrah',
                startDate: firstDate,
                endDate: lastDate,
                tourLeader: 'Tour Leader',
                days: days,
                daysCount: days.length,
              ),
            );
          });

          if (synthesized.isNotEmpty) {
            if (q != null && q.trim().isNotEmpty) {
              return synthesized
                  .where((item) =>
                      item.title.toLowerCase().contains(q.trim().toLowerCase()))
                  .toList();
            }
            debugPrint('✅ [ItineraryService] Synthesized ${synthesized.length} itineraries from itinerary_days');
            return synthesized;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ItineraryService] Error via itinerary_days fallback: $e');
    }

    return [];
  }

  /// Ambil detail 1 itinerary dari Supabase
  Future<Itinerary?> _showFromSupabase(dynamic id) async {
    final idStr = id.toString();

    // 1. Coba dari tabel `itineraries` via Supabase Client
    try {
      final client = SupabaseService.client;
      if (client != null) {
        final res = await client
            .from('itineraries')
            .select('*, profiles:created_by(username), itinerary_days(*, itinerary_activities(*))')
            .eq('id', idStr)
            .maybeSingle();

        if (res != null) {
          return Itinerary.fromJson(Map<String, dynamic>.from(res as Map));
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ItineraryService] show via Supabase client error: $e');
    }

    // 2. Coba via REST direct
    try {
      final uri = Uri.parse(
        '${SupabaseConfig.supabaseUrl}/rest/v1/itineraries?id=eq.$idStr&select=*,profiles:created_by(username),itinerary_days(*,itinerary_activities(*))',
      );
      final res = await http.get(uri, headers: SupabaseConfig.restHeaders);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is List && decoded.isNotEmpty) {
          return Itinerary.fromJson(Map<String, dynamic>.from(decoded.first as Map));
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ItineraryService] show via Supabase REST error: $e');
    }

    // 3. Fallback: ambil itinerary_days berdasarkan itinerary_id
    try {
      final uri = Uri.parse(
        '${SupabaseConfig.supabaseUrl}/rest/v1/itinerary_days?itinerary_id=eq.$idStr&select=*,itinerary_activities(*)&order=day_number.asc',
      );
      final res = await http.get(uri, headers: SupabaseConfig.restHeaders);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is List && decoded.isNotEmpty) {
          final days = decoded
              .map((d) => ItineraryDay.fromJson(Map<String, dynamic>.from(d as Map)))
              .toList()
            ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

          return Itinerary(
            id: idStr,
            title: 'Itinerary Perjalanan Umrah',
            startDate: days.first.date,
            endDate: days.last.date,
            tourLeader: 'Tour Leader',
            days: days,
            daysCount: days.length,
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ItineraryService] show via itinerary_days error: $e');
    }

    return null;
  }

  // =====================================================
  //  PUBLIC ENDPOINTS (SUPABASE FIRST + HTTP FALLBACK)
  // =====================================================

  /// Mengambil daftar itinerary (Supabase first, fallback ke HTTP)
  Future<({List<Itinerary> data, int? nextPage})> list({
    String? q,
    int page = 1,
  }) async {
    // 1. Coba dari Supabase terlebih dahulu
    try {
      final supabaseData = await _fetchFromSupabase(q: q);
      if (supabaseData.isNotEmpty) {
        return (data: supabaseData, nextPage: null);
      }
    } catch (e) {
      debugPrint('⚠️ [ItineraryService] Supabase fetch error, fallback to HTTP: $e');
    }

    // 2. Fallback ke REST API Backend HTTP lama (Dio)
    try {
      Response res;
      try {
        res = await _dio.get(
          '/tourleader/itinerary',
          queryParameters: {
            if (q != null && q.isNotEmpty) 'q': q,
            'page': page,
          },
        );
      } catch (_) {
        res = await _dio.get(
          '/itineraries',
          queryParameters: {
            if (q != null && q.isNotEmpty) 'search': q,
          },
        );
      }

      if (res.statusCode == 200) {
        final list = _unwrapList(res.data).map(Itinerary.fromJson).toList();

        int? next;
        final meta = (res.data is Map<String, dynamic>)
            ? (res.data['meta'] as Map<String, dynamic>?)
            : null;
        if (meta != null) {
          final current = (meta['current_page'] ?? page) as int;
          final last = (meta['last_page'] ?? page) as int;
          next = current < last ? current + 1 : null;
        }
        return (data: list, nextPage: next);
      }

      throw ApiException(
        res.data?.toString() ?? 'Unexpected status ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?.toString() ?? (e.message ?? 'Network error'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Mengambil detail 1 itinerary berdasarkan ID
  Future<Itinerary> show(dynamic id) async {
    // 1. Coba dari Supabase
    try {
      final fromSupabase = await _showFromSupabase(id);
      if (fromSupabase != null) {
        return fromSupabase;
      }
    } catch (e) {
      debugPrint('⚠️ [ItineraryService] Supabase show error, fallback to HTTP: $e');
    }

    // 2. Fallback ke REST API Backend HTTP lama (Dio)
    try {
      Response res;
      try {
        res = await _dio.get('/tourleader/itinerary/$id');
      } catch (_) {
        res = await _dio.get('/itineraries/$id');
      }

      if (res.statusCode == 200) {
        return _unwrap<Itinerary>(res.data, Itinerary.fromJson);
      }

      throw ApiException(
        res.data?.toString() ?? 'Unexpected status ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?.toString() ?? (e.message ?? 'Network error'),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
