import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Konfigurasi Supabase Project
/// Anda dapat mengisi [supabaseUrl] dan [supabaseAnonKey] dengan kredensial project Supabase Anda.
class SupabaseConfig {
  /// URL Project Supabase Anda
  /// Contoh: 'https://xyzcompany.supabase.co'
  static const String supabaseUrl = 'https://ovrwodjthwucdximcobm.supabase.co';

  /// Anon / Publishable Key Project Supabase Anda
  /// Didapat dari Dashboard Supabase -> Project Settings -> API
  static const String supabaseAnonKey = 'sb_publishable_BhSaEzV2BL4EMhoyDPM7yQ_8vrFGb8C';

  /// Memeriksa apakah kredensial Supabase sudah diisi
  static bool get isConfigured {
    return supabaseUrl.startsWith('http') &&
        !supabaseUrl.contains('YOUR_SUPABASE_PROJECT_REF') &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');
  }

  /// REST Headers standar untuk Supabase API
  static Map<String, String> get restHeaders => {
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };
}

/// Service helper untuk mengelola koneksi dan operasi Supabase
class SupabaseService {
  static bool _initialized = false;

  /// Inisialisasi Supabase client saat app startup
  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint(
        '⚠️ [SupabaseService] Supabase belum dikonfigurasi dengan URL & Key yang valid.\n'
        '   Silakan masukkan supabaseUrl dan supabaseAnonKey di lib/services/supabase_service.dart.',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabaseAnonKey,
      );
      _initialized = true;
      debugPrint('✅ [SupabaseService] Supabase berhasil diinisialisasi.');
    } catch (e) {
      debugPrint('❌ [SupabaseService] Gagal menginisialisasi Supabase: $e');
    }
  }

  /// Status apakah Supabase sudah siap digunakan
  static bool get isReady => _initialized;

  /// Mengambil instance SupabaseClient jika sudah siap
  static SupabaseClient? get client {
    try {
      final c = Supabase.instance.client;
      _initialized = true;
      return c;
    } catch (_) {
      return null;
    }
  }

  /// REST Direct Helper: GET query dari table Supabase
  static Future<List<dynamic>> restGet(String table, {String order = 'created_at.desc'}) async {
    try {
      final uri = Uri.parse('${SupabaseConfig.supabaseUrl}/rest/v1/$table?select=*&order=$order');
      final res = await http.get(uri, headers: SupabaseConfig.restHeaders);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) return decoded;
      }
    } catch (e) {
      debugPrint('⚠️ [SupabaseService] REST GET $table error: $e');
    }
    return [];
  }

  /// REST Direct Helper: POST / INSERT ke table Supabase
  static Future<Map<String, dynamic>?> restInsert(String table, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('${SupabaseConfig.supabaseUrl}/rest/v1/$table');
      final res = await http.post(
        uri,
        headers: SupabaseConfig.restHeaders,
        body: jsonEncode(data),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is List && decoded.isNotEmpty) {
          return Map<String, dynamic>.from(decoded.first as Map);
        } else if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SupabaseService] REST INSERT $table error: $e');
    }
    return null;
  }

  /// REST Direct Helper: DELETE dari table Supabase
  static Future<bool> restDelete(String table, String idColumn, dynamic idValue) async {
    try {
      final uri = Uri.parse('${SupabaseConfig.supabaseUrl}/rest/v1/$table?$idColumn=eq.$idValue');
      final res = await http.delete(uri, headers: SupabaseConfig.restHeaders);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ [SupabaseService] REST DELETE $table error: $e');
      return false;
    }
  }
}
