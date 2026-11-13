import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_retali/models/sesi_absensi_model.dart';
import 'package:mobile_retali/screens/absensi_form_screen.dart';

void main() {
  group('Absensi Model Tests', () {
    test('SesiAbsensi and BagianSesiAbsensi map properly', () {
      final mapSesi = {
        'id': 'sesi-123',
        'judul': 'Briefing & Kumpul Bandara',
        'kategori': 'tour_leader',
        'target_jam_mulai': '04:30:00',
        'target_jam_selesai': '06:30:00',
        'keterangan': 'Briefing sebelum check-in',
        'urutan': 1,
      };

      final mapBagian = {
        'id': 'bag-1',
        'sesi_id': 'sesi-123',
        'nama_bagian': 'Terminal 3 Gate 1',
        'target_jam_mulai': '04:30:00',
        'target_jam_selesai': '05:30:00',
        'urutan': 1,
      };

      final bagian = BagianSesiAbsensi.fromMap(mapBagian);
      expect(bagian.namaBagian, 'Terminal 3 Gate 1');
      expect(bagian.sesiId, 'sesi-123');

      final sesi = SesiAbsensi.fromMap(mapSesi, bagianList: [bagian]);
      expect(sesi.id, 'sesi-123');
      expect(sesi.judul, 'Briefing & Kumpul Bandara');
      expect(sesi.formattedTargetTime, '04:30 - 06:30 WIB');
      expect(sesi.bagianSesi.length, 1);
    });

    test('AttendanceGuideRecord parses properly and detects isSudahAbsen', () {
      final recordMap = {
        'id': 'rec-001',
        'user_id': 'user-uuid',
        'attendance_date': '2026-11-13',
        'kloter': 'Kloter 1',
        'photo_url': 'https://example.com/photo.jpg',
        'latitude': -6.125,
        'longitude': 106.655,
        'type': 'masuk',
        'note': 'Lengkap',
        'sesi': 'Briefing Bandara',
        'bagian_sesi': 'Terminal 3',
        'sesi_id': 'sesi-123',
        'status_waktu': 'tepat_waktu',
        'attendance_status': 'hadir',
        'created_at': '2026-11-13T05:15:00.000Z',
      };

      final rec = AttendanceGuideRecord.fromMap(recordMap);
      expect(rec.id, 'rec-001');
      expect(rec.isSudahAbsen, true);
      expect(rec.statusWaktu, 'tepat_waktu');
      expect(rec.latitude, -6.125);
    });
  });

  group('AbsensiFormScreen Widget Tests', () {
    testWidgets('AbsensiFormScreen renders session info and form controls',
        (WidgetTester tester) async {
      const testSesi = SesiAbsensi(
        id: 'test-sesi',
        judul: 'Pemeriksaan Imigrasi',
        kategori: 'tour_leader',
        targetJamMulai: '08:00:00',
        targetJamSelesai: '10:00:00',
        keterangan: 'Pengecekan paspor seluruh jamaah',
        urutan: 2,
        bagianSesi: [
          BagianSesiAbsensi(
            id: 'b-1',
            sesiId: 'test-sesi',
            namaBagian: 'Gate Imigrasi',
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AbsensiFormScreen(
            sesi: testSesi,
            userId: 'user-test-123',
            userName: 'Ahmad TL',
            kloter: 'Kloter 01',
            role: 'tour_leader',
          ),
        ),
      );
      await tester.pump();

      // Memastikan judul sesi dan form komponen muncul
      expect(find.text('Isi Absensi Petugas'), findsOneWidget);
      expect(find.text('Pemeriksaan Imigrasi'), findsOneWidget);
      expect(find.text('Pengecekan paspor seluruh jamaah'), findsOneWidget);
      expect(find.text('Foto Bukti Kehadiran'), findsOneWidget);
      expect(find.text('Koordinat GPS Lokasi'), findsOneWidget);
      expect(find.text('Kirim & Simpan Absensi'), findsOneWidget);
    });
  });
}
