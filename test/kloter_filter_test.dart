import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_retali/services/api_service.dart';

void main() {
  group('Kloter matching tests', () {
    test('Exact match and case differences', () {
      expect(ApiService.isSameKloter('kloter 198', 'Kloter 198'), isTrue);
      expect(ApiService.isSameKloter('KLOTER 198', 'kloter 198'), isTrue);
      expect(ApiService.isSameKloter('Kloter 126', 'kloter 126'), isTrue);
    });

    test('Number-only vs prefixed kloter', () {
      expect(ApiService.isSameKloter('kloter 198', '198'), isTrue);
      expect(ApiService.isSameKloter('198', 'Kloter 198'), isTrue);
      expect(ApiService.isSameKloter('Kloter-198', 'kloter 198'), isTrue);
    });

    test('Different kloters do not match', () {
      expect(ApiService.isSameKloter('kloter 198', 'Kloter 126'), isFalse);
      expect(ApiService.isSameKloter('kloter 198', 'Kloter 207'), isFalse);
      expect(ApiService.isSameKloter('kloter 198', '19'), isFalse);
      expect(ApiService.isSameKloter('kloter 19', '198'), isFalse);
      expect(ApiService.isSameKloter('Kloter 192', 'Kloter 198'), isFalse);
    });

    test('Empty and null values', () {
      expect(ApiService.isSameKloter(null, 'Kloter 198'), isFalse);
      expect(ApiService.isSameKloter('kloter 198', null), isFalse);
      expect(ApiService.isSameKloter('-', 'Kloter 198'), isFalse);
      expect(ApiService.isSameKloter('kloter 198', '-'), isFalse);
      expect(ApiService.isSameKloter('', ''), isFalse);
    });
  });
}
