import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/services/auth_service.dart';

void main() {
  group('Phone normalization', () {
    test('adds + prefix if missing', () {
      expect(AuthService.normalizePhone('966512345678'), '+966512345678');
    });
    test('keeps + prefix if present', () {
      expect(AuthService.normalizePhone('+966512345678'), '+966512345678');
    });
    test('strips spaces', () {
      expect(AuthService.normalizePhone('+966 51 234 5678'), '+966512345678');
    });
    test('strips dashes', () {
      expect(AuthService.normalizePhone('+966-51-234-5678'), '+966512345678');
    });
  });
}
