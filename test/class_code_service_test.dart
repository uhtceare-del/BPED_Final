import 'package:flutter_test/flutter_test.dart';
import 'package:phys_ed/services/class_code_service.dart';

void main() {
  group('ClassCodeService', () {
    test('sanitizes user input to uppercase code', () {
      expect(ClassCodeService.sanitize(' ab2c3d '), 'AB2C3D');
    });

    test('validates only supported six-character codes', () {
      expect(ClassCodeService.isValid('ABC234'), isTrue);
      expect(ClassCodeService.isValid('ABCDO1'), isFalse);
      expect(ClassCodeService.isValid('SHORT'), isFalse);
    });

    test('generates six-character invitation codes', () {
      final code = ClassCodeService.generate();

      expect(code.length, ClassCodeService.codeLength);
      expect(ClassCodeService.isValid(code), isTrue);
    });
  });
}
