// lib/services/faq_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/faq_model.dart';
import 'supabase_service.dart';

class FaqService {
  /// Mengambil daftar FAQ dari tabel `faqs` di Supabase
  static Future<List<FaqItem>> fetchFaqs() async {
    final client = SupabaseService.client;
    List<FaqItem> items = [];

    // 1. Coba ambil via Supabase Client
    if (client != null) {
      try {
        final rows = await client
            .from('faqs')
            .select('*')
            .eq('is_published', true)
            .order('sort_order', ascending: true)
            .order('created_at', ascending: true);

        if (rows.isNotEmpty) {
          items = (rows as List)
              .map((r) => FaqItem.fromMap(Map<String, dynamic>.from(r as Map)))
              .toList();
          debugPrint('✅ [FaqService] Berhasil memuat ${items.length} FAQ dari Supabase Client');
          return items;
        }
      } catch (e) {
        debugPrint('⚠️ [FaqService] Supabase Client fetch error: $e');
      }
    }

    // 2. Direct REST Fallback ke Supabase
    if (SupabaseConfig.isConfigured) {
      try {
        final uri = Uri.parse(
          '${SupabaseConfig.supabaseUrl}/rest/v1/faqs?select=*&is_published=eq.true&order=sort_order.asc,created_at.asc',
        );
        final res = await http.get(uri, headers: SupabaseConfig.restHeaders);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final decoded = jsonDecode(res.body);
          if (decoded is List && decoded.isNotEmpty) {
            items = decoded
                .map((r) => FaqItem.fromMap(Map<String, dynamic>.from(r as Map)))
                .toList();
            debugPrint('✅ [FaqService] Berhasil memuat ${items.length} FAQ via REST Supabase');
            return items;
          }
        }
      } catch (e) {
        debugPrint('⚠️ [FaqService] Supabase REST error: $e');
      }
    }

    // 3. Fallback bawaan (offline data) jika jaringan terkendala
    return _defaultFaqs;
  }

  /// Data fallback bawaan jika perangkat belum terkoneksi internet
  static final List<FaqItem> _defaultFaqs = [
    FaqItem(
      id: 'faq-default-1',
      category: 'Tour Leader',
      question: 'Bagaimana cara mencatat absensi jamaah saat kegiatan berlangsung?',
      answer:
          'Tour Leader dapat membuka menu "Absensi" di halaman utama, lalu pilih sesi kegiatan yang aktif. Anda dapat mencatat kehadiran jamaah secara manual atau memindai barcode paspor/koper jamaah secara cepat.',
      sortOrder: 1,
      isPublished: true,
    ),
    FaqItem(
      id: 'faq-default-2',
      category: 'Tour Leader',
      question: 'Apa yang harus dilakukan jika ada jamaah yang terpisah dari rombongan?',
      answer:
          '1. Tetap tenang dan lakukan koordinasi dengan Muthawif serta Tour Leader pendamping.\n'
          '2. Buka menu Kloter untuk melihat daftar nomor kontak jamaah & informasi hotel.\n'
          '3. Hubungi nomor kontak jamaah atau periksa titik kumpul (meeting point) yang telah disepakati.\n'
          '4. Laporkan segera ke tim operasional pusat melalui grup koordinasi.',
      sortOrder: 2,
      isPublished: true,
    ),
    FaqItem(
      id: 'faq-default-3',
      category: 'Muthawif',
      question: 'Bagaimana panduan Muthawif dalam memberikan bimbingan ibadah saat tawaf & sai?',
      answer:
          'Muthawif bertugas memimpin doa dan memastikan seluruh jamaah kloter tetap berada dalam barisan dan tidak terpisah. Sebelum memulai, pastikan semua jamaah dalam keadaan suci (berwudhu), kenakan syal/identitas kloter, dan jelaskan rute serta putaran tawaf maupun sai secara jelas.',
      sortOrder: 3,
      isPublished: true,
    ),
    FaqItem(
      id: 'faq-default-4',
      category: 'Teknis',
      question: 'Bagaimana cara memindai (scan) koper dan paspor jamaah?',
      answer:
          'Tekan tombol "Scan" di bagian tengah bawah menu. Pilih tab "Scan Koper" untuk memindai barcode koper, atau ganti mode ke "Scan Paspor" untuk memindai paspor jamaah. Pastikan kamera memiliki pencahayaan cukup dan QR code terfokus.',
      sortOrder: 4,
      isPublished: true,
    ),
    FaqItem(
      id: 'faq-default-5',
      category: 'Umum',
      question: 'Apa yang harus dilakukan jika aplikasi lambat atau tidak ada koneksi internet?',
      answer:
          'Pastikan koneksi internet (Wi-Fi hotel atau SIM card lokal Arab Saudi seperti STC/Mobily/Zain) aktif. Tarik layar ke bawah (pull-to-refresh) untuk memperbarui data saat koneksi internet kembali stabil.',
      sortOrder: 5,
      isPublished: true,
    ),
  ];
}
