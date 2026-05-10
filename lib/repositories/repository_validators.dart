import '../core/app_exceptions.dart';

abstract class RepositoryValidators {
  static void validateSubmissionData(Map<String, dynamic> data) {
    final errors = <String>[];

    if (data['studentId'] == null || (data['studentId'] as String).isEmpty) {
      errors.add('Student ID is required');
    }
    if (data['taskId'] == null || (data['taskId'] as String).isEmpty) {
      errors.add('Task ID is required');
    }
    final fileUrl = data['fileUrl'] as String?;
    final grade = data['grade'];
    final hasFile = fileUrl != null && fileUrl.trim().isNotEmpty;
    final hasGrade = grade != null && grade.toString().trim().isNotEmpty;

    if (!hasFile && !hasGrade) {
      errors.add('Submission must include either a file URL or a grade');
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join('; '));
    }
  }

  static void validateGradeData(Map<String, dynamic> data) {
    final grade = data['grade'];
    if (grade == null || grade is! num || grade < 0 || grade > 100) {
      throw const ValidationException(
        'Grade must be a number between 0 and 100',
      );
    }
  }

  static void validateUserData(Map<String, dynamic> data) {
    final email = data['email'] as String?;
    if (email == null || !email.contains('@')) {
      throw const ValidationException('Valid email is required');
    }

    final role = data['role'] as String?;
    if (role == null || !['student', 'instructor', 'admin'].contains(role)) {
      throw const ValidationException('Invalid role');
    }
  }

  static void validateUserAuthorization(String role, String requiredRole) {
    if (role != 'admin' && role != requiredRole) {
      throw const AuthException(
        'User does not have permission to access this resource',
        code: 'insufficient-permissions',
      );
    }
  }

  static String validateAndFormatClassCode(String code) {
    final trimmed = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(trimmed)) {
      throw const ValidationException(
        'Class code must be exactly 6 alphanumeric characters',
      );
    }
    return trimmed;
  }

  static List<String> validateBatchData(
    List<Map<String, dynamic>> items,
    void Function(Map<String, dynamic>) validator,
  ) {
    final errors = <String>[];
    for (var i = 0; i < items.length; i++) {
      try {
        validator(items[i]);
      } catch (error) {
        errors.add('Item $i: $error');
      }
    }

    if (errors.isNotEmpty) {
      throw ValidationException(
        'Batch validation failed:\n${errors.join('\n')}',
      );
    }

    return errors;
  }
}
