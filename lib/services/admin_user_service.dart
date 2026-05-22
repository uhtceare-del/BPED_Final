import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/app_exceptions.dart';
import '../core/input_validator.dart';
import '../repositories/repository_validators.dart';

/// Admin user management service with transaction safety
class AdminUserService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AdminUserService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : auth = auth ?? FirebaseAuth.instance,
      firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a user with atomic safety - if Firestore fails, auth user is deleted
  Future<String> createUserWithProfile({
    required String email,
    required String password,
    required String role,
    String? fullName,
    String? avatarUrl,
    bool onboardingCompleted = true,
  }) async {
    // Validate inputs
    RepositoryValidators.validateUserData({'email': email, 'role': role});
    final emailError = Validator.validateEmail(email);
    if (emailError != null) {
      throw ValidationException(emailError);
    }
    final passwordError = Validator.validatePassword(password);
    if (passwordError != null) {
      throw ValidationException(passwordError);
    }
    if (fullName != null && fullName.trim().isNotEmpty) {
      final fullNameError = Validator.validateFullName(fullName);
      if (fullNameError != null) {
        throw ValidationException(fullNameError);
      }
    }

    FirebaseApp? secondaryApp;
    try {
      // Create Firebase Auth user with secondary app instance
      final appName = 'AdminUser_${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // Create Firestore profile - if this fails, the auth user is cleaned up
      try {
        await firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'fullName': fullName ?? email.split('@')[0],
          'role': role,
          'avatarUrl': avatarUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'onboardingCompleted': onboardingCompleted,
          'isDeleted': false,
          'isDisabled': false,
        });

        return uid;
      } catch (firestoreError) {
        // Cleanup: delete orphaned auth user
        try {
          await credential.user?.delete();
        } catch (_) {
          throw DatabaseException(
            'Failed to create user profile (auth user orphaned and cleanup also failed)',
            originalError: firestoreError,
          );
        }

        throw DatabaseException(
          'Failed to create user profile in database (auth user cleaned up)',
          originalError: firestoreError,
        );
      }
    } on ValidationException {
      rethrow;
    } on DatabaseException {
      rethrow;
    } catch (error) {
      throw DatabaseException('User creation failed', originalError: error);
    } finally {
      // Always clean up secondary Firebase app
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (e) {
          debugPrint('Failed to clean up secondary Firebase app: $e');
        }
      }
    }
  }

  /// Disable a user (soft delete via flag)
  Future<void> disableUser(String userId) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'isDisabled': true,
        'disabledAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw DatabaseException('Failed to disable user', originalError: error);
    }
  }

  /// Enable a user
  Future<void> enableUser(String userId) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'isDisabled': false,
      });
    } catch (error) {
      throw DatabaseException('Failed to enable user', originalError: error);
    }
  }
}
