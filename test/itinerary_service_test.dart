import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_retali/models/itinerary_models.dart';
import 'package:mobile_retali/screens/itinerary/itinerary_detail_page.dart';
import 'package:mobile_retali/screens/itinerary/itinerary_list_page.dart';
import 'package:mobile_retali/services/itinerary_service.dart';
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

  group('Itinerary Models Tests (Supabase Format)', () {
    test('ItineraryItem parses correctly from Supabase itinerary_activities format', () {
      final activityMap = {
        'id': 'ce045547-24ca-4f6b-bdb5-bc2da5009038',
        'itinerary_day_id': '3d96d5f8-3dca-4dbc-8d1c-36171e4c3731',
        'activity_time': '08:30:00',
        'title': 'Keberangkatan dari bandara',
        'description': 'Persiapan rombongan dan pembagian paspor',
        'location': 'Bandara Soekarno-Hatta',
        'sort_order': 1,
      };

      final item = ItineraryItem.fromJson(activityMap);
      expect(item.id, 'ce045547-24ca-4f6b-bdb5-bc2da5009038');
      expect(item.time, '08:30');
      expect(item.title, 'Keberangkatan dari bandara');
      expect(item.content, 'Persiapan rombongan dan pembagian paspor');
      expect(item.location, 'Bandara Soekarno-Hatta');
      expect(item.sequence, 1);
    });

    test('ItineraryDay parses correctly with nested itinerary_activities', () {
      final dayMap = {
        'id': '3d96d5f8-3dca-4dbc-8d1c-36171e4c3731',
        'itinerary_id': 'e3d0c7ab-ae36-4f24-ad3a-df0881941b86',
        'day_number': 1,
        'activity_date': '2026-11-01',
        'title': 'Hari Keberangkatan',
        'itinerary_activities': [
          {
            'id': 'act-1',
            'activity_time': '08:00:00',
            'title': 'Kumpul Bandara',
            'description': 'Terminal 3',
            'location': 'Jakarta',
            'sort_order': 1,
          },
          {
            'id': 'act-2',
            'activity_time': '12:00:00',
            'title': 'Take Off',
            'description': 'Penerbangan SV819',
            'location': 'Pesawat',
            'sort_order': 2,
          },
        ],
      };

      final day = ItineraryDay.fromJson(dayMap);
      expect(day.id, '3d96d5f8-3dca-4dbc-8d1c-36171e4c3731');
      expect(day.dayNumber, 1);
      expect(day.date, '2026-11-01');
      expect(day.city, 'Hari Keberangkatan');
      expect(day.items.length, 2);
      expect(day.items.first.title, 'Kumpul Bandara');
      expect(day.items.first.time, '08:00');
    });

    test('Itinerary parses correctly with nested itinerary_days and profiles relation', () {
      final itineraryMap = {
        'id': 'e3d0c7ab-ae36-4f24-ad3a-df0881941b86',
        'title': 'Umrah Reguler 12 Hari',
        'start_date': '2026-11-01',
        'end_date': '2026-11-12',
        'profiles': {'username': 'Ustadz Ahmad'},
        'itinerary_days': [
          {
            'id': 'day-1',
            'day_number': 1,
            'activity_date': '2026-11-01',
            'title': 'Hari Keberangkatan',
            'itinerary_activities': [
              {
                'id': 'act-1',
                'activity_time': '08:00:00',
                'title': 'Kumpul Bandara',
                'sort_order': 1,
              }
            ],
          },
          {
            'id': 'day-2',
            'day_number': 2,
            'activity_date': '2026-11-02',
            'title': 'Tiba di Madinah',
            'itinerary_activities': [],
          },
        ],
      };

      final it = Itinerary.fromJson(itineraryMap);
      expect(it.id, 'e3d0c7ab-ae36-4f24-ad3a-df0881941b86');
      expect(it.title, 'Umrah Reguler 12 Hari');
      expect(it.startDate, '2026-11-01');
      expect(it.endDate, '2026-11-12');
      expect(it.tourLeader, 'Ustadz Ahmad');
      expect(it.days.length, 2);
      expect(it.daysCount, 2);
    });
  });

  group('Itinerary Widgets Tests', () {
    testWidgets('ItineraryDetailPage renders properly with Itinerary data',
        (WidgetTester tester) async {
      final mockItinerary = Itinerary(
        id: 'e3d0c7ab-ae36-4f24-ad3a-df0881941b86',
        title: 'Paket Umrah Berkah',
        tourLeader: 'Ustadz Fajar',
        startDate: '2026-11-01',
        endDate: '2026-11-12',
        days: [
          ItineraryDay(
            id: 'day-1',
            dayNumber: 1,
            city: 'Jakarta',
            date: '2026-11-01',
            items: [
              ItineraryItem(
                id: 'act-1',
                sequence: 1,
                time: '08:00',
                title: 'Briefing Keberangkatan',
                content: 'Rapat koordinasi bersama jamaah di Gate 1',
                location: 'Bandara Soekarno-Hatta',
              ),
            ],
          ),
        ],
      );

      final service = ItineraryService(baseRoot: 'https://example.com');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItineraryDetailPage(
              service: service,
              id: mockItinerary.id,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Itinerary Details'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('ItineraryListPage renders AppBar with title Itinerary',
        (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed') ||
            details.exceptionAsString().contains('asset')) {
          return;
        }
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      SharedPreferences.setMockInitialValues({
        'token': 'mock-token',
        'name': 'Test Tour Leader',
        'role': 'tour_leader',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ItineraryListPage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Itinerary'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
