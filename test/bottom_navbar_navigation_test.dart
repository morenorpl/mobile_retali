import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_retali/screens/home_screen.dart';
import 'package:mobile_retali/screens/tugas_ceklis/checklist_list_screen.dart';
import 'package:mobile_retali/screens/riwayat_scan/history_screen.dart';
import 'package:mobile_retali/screens/profile_screen.dart';
import 'package:mobile_retali/services/presence_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'token': 'fake-token',
      'name': 'Test User',
      'role': 'tour_leader',
      'kloter': 'Kloter 1',
    });
  });

  testWidgets('Bottom navbar switches between Home, History, and Profile while navbar stays visible',
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

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify BottomAppBar is present
    expect(find.byType(BottomAppBar), findsOneWidget);

    // Verify icons exist
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.assignment), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);

    // Initial state: IndexedStack index 0 (Home)
    final indexedStackFinder = find.byType(IndexedStack);
    expect(indexedStackFinder, findsOneWidget);
    IndexedStack stack = tester.widget(indexedStackFinder);
    expect(stack.index, 0);

    // Tap History icon -> switches to tab index 1 (HistoryScreen)
    await tester.tap(find.byIcon(Icons.history));
    await tester.pump(const Duration(milliseconds: 100));

    stack = tester.widget(indexedStackFinder);
    expect(stack.index, 1);
    // Bottom navbar is STILL visible!
    expect(find.byType(BottomAppBar), findsOneWidget);
    expect(find.byType(HistoryScreen), findsOneWidget);

    // Tap Profile icon -> switches to tab index 2 (ProfileScreen)
    await tester.tap(find.byIcon(Icons.person));
    await tester.pump(const Duration(milliseconds: 100));

    stack = tester.widget(indexedStackFinder);
    expect(stack.index, 2);
    // Bottom navbar is STILL visible!
    expect(find.byType(BottomAppBar), findsOneWidget);
    expect(find.byType(ProfileScreen), findsOneWidget);

    // Tap Home icon -> switches back to tab index 0
    await tester.tap(find.byIcon(Icons.home));
    await tester.pump(const Duration(milliseconds: 100));

    stack = tester.widget(indexedStackFinder);
    expect(stack.index, 0);
    expect(find.byType(BottomAppBar), findsOneWidget);

    PresenceService.stop();
  });

  testWidgets('Tapping assignment icon in bottom navbar pushes ChecklistListScreen',
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

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap assignment icon
    await tester.tap(find.byIcon(Icons.assignment));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // ChecklistListScreen should be pushed on top
    expect(find.byType(ChecklistListScreen), findsOneWidget);

    PresenceService.stop();
  });
}
