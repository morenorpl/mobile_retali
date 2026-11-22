import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_retali/screens/absen_jamaah/jamaah_attendance_page.dart';
import 'package:mobile_retali/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'token': '',
      'kloter': 'Madinah Group',
    });
  });

  group('Absen Jamaah Kloter & Title Tests', () {
    test('Kloter matching works correctly for user kloter', () {
      const userKloter = 'Madinah Group';
      const matchingGroupKloter = 'Madinah Group';
      const nonMatchingGroupKloter = 'Mekah Group 2';

      expect(ApiService.isSameKloter(userKloter, matchingGroupKloter), isTrue);
      expect(ApiService.isSameKloter(userKloter, nonMatchingGroupKloter), isFalse);
    });

    test('Card title falls back to kloter name when constructed', () {
      final groupData = {
        'id': 7,
        'judul_absen': 'Madinah Group',
        'kloter': {'nama': 'Madinah Group'},
        'kloter_name': 'Madinah Group',
        'sesi_lengkap': 'berkumpul oyyyyyyyyy – Bagian 1',
      };

      String judul = (groupData['kloter'] is Map ? (groupData['kloter'] as Map)['nama'] : null) ??
          groupData['kloter_name'] ??
          groupData['judul_absen'] ??
          '-';

      expect(judul, equals('Madinah Group'));
    });

    test('Filter logic filters absensi groups strictly by user kloter', () {
      final groups = [
        {
          'id': 7,
          'kloter': 'Madinah Group',
          'sesi': 'berkumpul oyyyyyyyyy – Bagian 1',
        },
        {
          'id': 9,
          'kloter': 'Mekah Group 2',
          'sesi': 'berkumpul oyyyyyyyyy – Bagian 1',
        },
        {
          'id': 10,
          'kloter': 'Mekah Group 2',
          'sesi': 'Sarapan – sebelum makan',
        },
      ];

      const userKloter = 'Madinah Group';

      final filtered = groups.where((g) {
        final rowKloter = g['kloter']?.toString() ?? '';
        return ApiService.isSameKloter(userKloter, rowKloter);
      }).toList();

      expect(filtered.length, equals(1));
      expect(filtered.first['id'], equals(7));
      expect(filtered.first['kloter'], equals('Madinah Group'));
    });
  });

  group('JamaahAttendancePage Tab & Filter Tests', () {
    testWidgets('JamaahAttendancePage renders with Belum tab first', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: JamaahAttendancePage(
            absenId: 99999,
            judul: 'Madinah Group',
          ),
        ),
      );

      // Pump frames to complete async _loadDetail
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Find FilterChips
      final filterChips = find.byType(FilterChip);
      expect(filterChips, findsNWidgets(4));

      // Tab labels in order: Belum, Hadir, Tidak, Semua
      final chipWidgets = tester.widgetList<FilterChip>(filterChips).toList();
      expect((chipWidgets[0].label as Text).data, equals('Belum'));
      expect((chipWidgets[1].label as Text).data, equals('Hadir'));
      expect((chipWidgets[2].label as Text).data, equals('Tidak'));
      expect((chipWidgets[3].label as Text).data, equals('Semua'));

      // Check that "Belum" is selected by default
      expect(chipWidgets[0].selected, isTrue);
      expect(chipWidgets[1].selected, isFalse);
      expect(chipWidgets[2].selected, isFalse);
      expect(chipWidgets[3].selected, isFalse);
    });
  });
}
