import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phys_ed/models/user_model.dart';

void main() {
  group('AppUser', () {
    test('serializes user profile fields for Firestore', () {
      final user = AppUser(
        uid: 'user-1',
        email: 'coach@example.com',
        fullName: 'Coach Carter',
        role: 'instructor',
        avatarUrl: 'https://example.com/avatar.png',
        createdAt: DateTime(2026, 4, 8),
        section: 'PE-11',
        yearLevel: '1',
        onboardingCompleted: true,
      );

      final map = user.toFirestore();

      expect(map['uid'], 'user-1');
      expect(map['email'], 'coach@example.com');
      expect(map['fullName'], 'Coach Carter');
      expect(map['role'], 'instructor');
      expect(map['avatarUrl'], 'https://example.com/avatar.png');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['section'], 'PE-11');
      expect(map['yearLevel'], '1');
      expect(map['onboardingCompleted'], isTrue);
    });

    test('normalizes yearLevel from legacy numeric data', () {
      final user = AppUser.fromFirestore({
        'email': 'student@example.com',
        'fullName': 'Student One',
        'role': 'student',
        'avatarUrl': '',
        'createdAt': Timestamp.fromDate(DateTime(2026, 4, 8)),
        'yearLevel': 2,
        'section': 'PE-21',
        'onboardingCompleted': false,
      }, 'student-1');

      expect(user.uid, 'student-1');
      expect(user.yearLevel, '2');
      expect(user.section, 'PE-21');
      expect(user.onboardingCompleted, isFalse);
    });
  });
}
