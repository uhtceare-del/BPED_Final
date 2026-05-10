import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'app_exceptions.dart';

class ErrorHandler {
  static AppException handleFirebaseException(Object error, {String? context}) {
    final mapped = switch (error) {
      FirebaseAuthException authError => _mapFirebaseAuthException(authError),
      FirebaseException firebaseError => _mapFirebaseException(firebaseError),
      SocketException _ => NetworkException(
        'Network error occurred. Please check your connection and try again.',
        code: 'network-error',
        originalError: error,
      ),
      TimeoutException _ => NetworkException(
        'The request timed out. Please try again.',
        code: 'timeout',
        originalError: error,
      ),
      AppException appException => appException,
      _ => AppException(error.toString(), originalError: error),
    };

    if (context == null || context.trim().isEmpty) {
      return mapped;
    }

    return _withContext(mapped, context);
  }

  static AppException handleNetworkException(Object error, {String? context}) {
    final mapped = NetworkException(
      'Network error occurred. Please check your connection and try again.',
      code: 'network-error',
      originalError: error,
    );

    if (context == null || context.trim().isEmpty) {
      return mapped;
    }

    return _withContext(mapped, context);
  }

  static AppException _withContext(AppException error, String context) {
    final message = '${context.trim()}: ${error.message}';

    return switch (error) {
      NetworkException() => NetworkException(
        message,
        code: error.code,
        originalError: error.originalError,
      ),
      AuthException() => AuthException(
        message,
        code: error.code,
        originalError: error.originalError,
      ),
      DatabaseException() => DatabaseException(
        message,
        code: error.code,
        originalError: error.originalError,
      ),
      FileStorageException() => FileStorageException(
        message,
        code: error.code,
        originalError: error.originalError,
      ),
      ValidationException() => ValidationException(
        message,
        code: error.code,
        originalError: error.originalError,
      ),
      ConfigurationException() => ConfigurationException(
        message,
        code: error.code,
        originalError: error.originalError,
      ),
      _ => AppException(
        message,
        code: error.code,
        originalError: error.originalError,
      ),
    };
  }

  static AppException _mapFirebaseAuthException(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => AuthException(
        'The email address is not valid.',
        code: error.code,
        originalError: error,
      ),
      'user-disabled' => AuthException(
        'This account has been disabled.',
        code: error.code,
        originalError: error,
      ),
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => AuthException(
        'Invalid email or password.',
        code: error.code,
        originalError: error,
      ),
      'email-already-in-use' => AuthException(
        'An account already exists for this email address.',
        code: error.code,
        originalError: error,
      ),
      'weak-password' => ValidationException(
        'The password does not meet security requirements.',
        code: error.code,
        originalError: error,
      ),
      'operation-not-allowed' => AuthException(
        'This sign-in method is not enabled.',
        code: error.code,
        originalError: error,
      ),
      'too-many-requests' => AuthException(
        'Too many authentication attempts. Please try again later.',
        code: error.code,
        originalError: error,
      ),
      _ => AuthException(
        error.message ?? 'Authentication failed.',
        code: error.code,
        originalError: error,
      ),
    };
  }

  static AppException _mapFirebaseException(FirebaseException error) {
    final message = error.message;

    if (_isStoragePlugin(error.plugin)) {
      return switch (error.code) {
        'object-not-found' => FileStorageException(
          'The requested file was not found.',
          code: error.code,
          originalError: error,
        ),
        'unauthorized' || 'permission-denied' => FileStorageException(
          'You do not have permission to access this file.',
          code: error.code,
          originalError: error,
        ),
        'canceled' => FileStorageException(
          'The file operation was cancelled.',
          code: error.code,
          originalError: error,
        ),
        _ => FileStorageException(
          message ?? 'File storage operation failed.',
          code: error.code,
          originalError: error,
        ),
      };
    }

    return switch (error.code) {
      'permission-denied' => AuthException(
        'Access denied. Please check your permissions.',
        code: error.code,
        originalError: error,
      ),
      'not-found' => DatabaseException(
        'The requested resource was not found.',
        code: error.code,
        originalError: error,
      ),
      'already-exists' => DatabaseException(
        'This resource already exists.',
        code: error.code,
        originalError: error,
      ),
      'unavailable' => NetworkException(
        'Service is temporarily unavailable. Please try again later.',
        code: error.code,
        originalError: error,
      ),
      'deadline-exceeded' => NetworkException(
        'The request timed out. Please try again.',
        code: error.code,
        originalError: error,
      ),
      'invalid-argument' => ValidationException(
        message ?? 'The request contains invalid data.',
        code: error.code,
        originalError: error,
      ),
      _ => DatabaseException(
        message ?? 'A database operation failed.',
        code: error.code,
        originalError: error,
      ),
    };
  }

  static bool _isStoragePlugin(String plugin) {
    return plugin == 'firebase_storage' || plugin == 'storage';
  }

  static void logError(AppException error, {String? context}) {
    final message = context != null ? '[$context] $error' : error.toString();
    debugPrint('ERROR: $message');

    if (error.originalError != null) {
      debugPrint('Original error: ${error.originalError}');
    }
  }

  static String getUserFriendlyMessage(AppException error) {
    if (error is NetworkException) {
      return 'Connection problem. Please check your internet and try again.';
    }

    if (error is AuthException) {
      if (error.code == 'permission-denied') {
        return 'You do not have permission to perform this action.';
      }
      return 'Authentication error. Please sign in again.';
    }

    if (error is DatabaseException) {
      return 'Database error. Please try again later.';
    }

    if (error is FileStorageException) {
      return 'File upload/download error. Please try again.';
    }

    if (error is ValidationException) {
      return error.message;
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
