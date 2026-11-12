import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_retali/models/persiapan_materi.dart';
import 'package:mobile_retali/screens/persiapan_diniyah_screen.dart';
import 'package:mobile_retali/screens/persiapan_teknis_screen.dart';
import 'package:mobile_retali/screens/persiapan_umrah_Screen.dart';

void main() {
  group('PersiapanMateri Model Tests', () {
    test('Correctly maps from Map and to Map', () {
      final map = {
        'id': 'test-id-123',
        'title': 'Materi Bersuci',
        'sub_title': 'Thaharah',
        'description': 'Panduan bersuci sebelum ihram',
        'content': '<p>Rincian tata cara mandi ihram</p>',
        'category': 'diniyah',
        'visibility': 'public',
        'attachment_url': 'https://example.com/doc.pdf',
        'is_published': true,
        'created_at': '2026-11-12T03:20:34.803Z',
        'updated_at': '2026-11-12T03:20:34.803Z',
      };

      final item = PersiapanMateri.fromMap(map);
      expect(item.id, 'test-id-123');
      expect(item.title, 'Materi Bersuci');
      expect(item.subTitle, 'Thaharah');
      expect(item.description, 'Panduan bersuci sebelum ihram');
      expect(item.content, '<p>Rincian tata cara mandi ihram</p>');
      expect(item.category, 'diniyah');
      expect(item.isPublished, true);

      final toMap = item.toMap();
      expect(toMap['title'], 'Materi Bersuci');
      expect(toMap['is_published'], true);
    });
  });

  group('Persiapan Screen Widget Tests', () {
    testWidgets('PersiapanDiniyahScreen renders correct header and elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PersiapanDiniyahScreen(),
        ),
      );
      await tester.pump();

      // Check AppBar title
      expect(find.text('Persiapan Diniyah'), findsOneWidget);

      // Check top container header text
      expect(find.text('Materi Persiapan Diniyah'), findsOneWidget);
    });

    testWidgets('PersiapanTeknisScreen renders correct header and elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PersiapanTeknisScreen(),
        ),
      );
      await tester.pump();

      // Check AppBar title
      expect(find.text('Persiapan Teknis'), findsOneWidget);

      // Check top container header text
      expect(find.text('Materi Persiapan Teknis'), findsOneWidget);
    });

    testWidgets('PersiapanUmrahScreen navigates to PersiapanDiniyah',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PersiapanUmrahScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Persiapan Diniyah'), findsOneWidget);

      await tester.tap(find.text('Persiapan Diniyah'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PersiapanDiniyahScreen), findsOneWidget);
    });

    testWidgets('PersiapanUmrahScreen navigates to PersiapanTeknis',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PersiapanUmrahScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Persiapan Teknis'), findsOneWidget);

      await tester.tap(find.text('Persiapan Teknis'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PersiapanTeknisScreen), findsOneWidget);
    });
  });
}
