import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_retali/models/notification_model.dart';

void main() {
  group('NotificationItem Status & Timing Tests', () {
    test('startDate null => status abuAbu', () {
      final item = NotificationItem(
        id: '1',
        title: 'Notif Tanpa Jadwal',
        message: 'Deskripsi',
        createdAt: DateTime.now(),
        startDate: null,
      );

      expect(item.status, NotificationStatus.abuAbu);
      expect(item.statusLabel, 'Belum Ada Peringatan');
      expect(item.dynamicReminderText, contains('belum masuk waktu pengingat'));
    });

    test('diffHours > 24 => status abuAbu', () {
      final futureDate = DateTime.now().add(const Duration(hours: 48));
      final item = NotificationItem(
        id: '2',
        title: 'Manasik Haji',
        message: 'Persiapan manasik',
        createdAt: DateTime.now(),
        startDate: futureDate,
      );

      expect(item.status, NotificationStatus.abuAbu);
      expect(item.statusLabel, 'Belum Ada Peringatan');
      expect(item.dynamicReminderText, contains('belum masuk waktu pengingat'));
    });

    test('12 < diffHours <= 24 => status merah (Peringatan 24 Jam)', () {
      final futureDate = DateTime.now().add(const Duration(hours: 18));
      final item = NotificationItem(
        id: '3',
        title: 'Kumpul di Bandara',
        message: 'Terminal 3',
        createdAt: DateTime.now(),
        startDate: futureDate,
      );

      expect(item.status, NotificationStatus.merah);
      expect(item.statusLabel, 'Peringatan 24 Jam');
      expect(item.dynamicReminderText, '24 jam lagi Kumpul di Bandara harus dilaksanakan');
    });

    test('0 < diffHours <= 12 => status kuning (Peringatan 12 Jam)', () {
      final futureDate = DateTime.now().add(const Duration(hours: 6));
      final item = NotificationItem(
        id: '4',
        title: 'Check-in Hotel Makkah',
        message: 'Lobi Hotel',
        createdAt: DateTime.now(),
        startDate: futureDate,
      );

      expect(item.status, NotificationStatus.kuning);
      expect(item.statusLabel, 'Peringatan 12 Jam');
      expect(item.dynamicReminderText, '12 jam lagi Check-in Hotel Makkah harus dilaksanakan');
    });

    test('diffHours <= 0 => status hijau (Saat Kegiatan)', () {
      final pastDate = DateTime.now().subtract(const Duration(minutes: 30));
      final item = NotificationItem(
        id: '5',
        title: 'Thawaf Wada',
        message: 'Mataf',
        createdAt: DateTime.now(),
        startDate: pastDate,
      );

      expect(item.status, NotificationStatus.hijau);
      expect(item.statusLabel, 'Saat Kegiatan');
      expect(item.dynamicReminderText, 'Saat ini Thawaf Wada harus dilaksanakan');
    });
  });
}
