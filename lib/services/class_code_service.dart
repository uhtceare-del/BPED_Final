import 'dart:math';

class ClassCodeService {
  static const int codeLength = 6;
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String sanitize(String value) {
    return value.trim().toUpperCase();
  }

  static bool isValid(String value) {
    final code = sanitize(value);
    if (code.length != codeLength) {
      return false;
    }
    for (final rune in code.runes) {
      if (!_alphabet.contains(String.fromCharCode(rune))) {
        return false;
      }
    }
    return true;
  }

  static String generate([Random? random]) {
    final source = random ?? Random.secure();
    return List.generate(
      codeLength,
      (_) => _alphabet[source.nextInt(_alphabet.length)],
    ).join();
  }
}
