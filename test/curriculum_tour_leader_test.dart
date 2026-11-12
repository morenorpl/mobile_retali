import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_retali/models/curriculum_materi.dart';
import 'package:mobile_retali/screens/curriculum_tour_leader_screen.dart';
import 'package:mobile_retali/screens/home_screen.dart';
import 'package:mobile_retali/services/presence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  tearDown(() {
    PresenceService.stop();
  });

  group('CurriculumMateri Model Tests', () {
    test('Correctly maps from Map and to Map', () {
      final map = {
        'id': 'curr-uuid-001',
        'title': 'Briefing Bandara & Handling Jamaah',
        'sub_title': 'Fase Keberangkatan',
        'description': 'Standar operasional prosedur pengumpulan jamaah di bandara',
        'content': '<p>1. Absensi jamaah<br>2. Pembagian paspor & boarding pass</p>',
        'category': 'curriculum',
        'visibility': 'tour_leader',
        'attachment_url': 'https://example.com/sop-bandara.pdf',
        'is_published': true,
        'sort_order': 1,
        'created_at': '2026-11-12T03:00:00.000Z',
        'updated_at': '2026-11-12T03:00:00.000Z',
      };

      final item = CurriculumMateri.fromMap(map);
      expect(item.id, 'curr-uuid-001');
      expect(item.title, 'Briefing Bandara & Handling Jamaah');
      expect(item.subTitle, 'Fase Keberangkatan');
      expect(item.description, 'Standar operasional prosedur pengumpulan jamaah di bandara');
      expect(item.content, '<p>1. Absensi jamaah<br>2. Pembagian paspor & boarding pass</p>');
      expect(item.category, 'curriculum');
      expect(item.sortOrder, 1);
      expect(item.isPublished, true);

      final toMap = item.toMap();
      expect(toMap['title'], 'Briefing Bandara & Handling Jamaah');
      expect(toMap['sort_order'], 1);
      expect(toMap['is_published'], true);
    });
  });

  group('CurriculumTourLeaderScreen Widget Tests', () {
    testWidgets('CurriculumTourLeaderScreen renders AppBar and Header Banner',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CurriculumTourLeaderScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Check AppBar title & Header Banner
      expect(find.text('Curriculum Tour Leader'), findsNWidgets(2));
      expect(
        find.text('Daftar materi panduan dan standar operasional tugas tour leader'),
        findsOneWidget,
      );

      // Unmount
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('HomeScreen renders Curriculum Tour Leader menu for tourleader role',
        (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed') ||
            details.exceptionAsString().contains('asset') ||
            details.exceptionAsString().contains('FormatException') ||
            details.exceptionAsString().contains('Exception: Gagal ambil')) {
          return;
        }
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        PresenceService.stop();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'token': 'fake-token',
        'name': 'Ahmad Tour Leader',
        'role': 'tour_leader',
        'kloter': 'Kloter 1',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify "Curriculum\nTour Leader" is displayed in HomeScreen
      expect(find.text('Curriculum\nTour Leader'), findsOneWidget);

      PresenceService.stop();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
