// lib/services/itinerary_service.dart
// ❌ gak perlu lagi:
// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

import '../models/itinerary_models.dart';
import 'api_service.dart';   // ⬅ penting: pakai token & ROOT_URL dari sini

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
      baseRoot: ApiService.ROOT_URL,         // ⬅ HTTP / HTTPS cukup diatur di sini (satu tempat)
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
  //  ENDPOINT KHUSUS TOUR LEADER
  // =====================================================

  /// GET /api/tourleader/itinerary
  Future<({List<Itinerary> data, int? nextPage})> list({
    String? q,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get(
        '/tourleader/itinerary',
        queryParameters: {
          if (q != null && q.isNotEmpty) 'q': q,
          'page': page,
        },
      );

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

  /// GET /api/tourleader/itinerary/{id}
  Future<Itinerary> show(int id) async {
    try {
      final res = await _dio.get('/tourleader/itinerary/$id');

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
