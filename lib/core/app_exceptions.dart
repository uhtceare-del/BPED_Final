class AppException implements Exception {
  final String message;
  final String? code;
  final Object? originalError;

  const AppException(this.message, {this.code, this.originalError});

  AppException withContext(String context) {
    final trimmedContext = context.trim();
    if (trimmedContext.isEmpty) {
      return this;
    }

    return AppException(
      '$trimmedContext: $message',
      code: code,
      originalError: originalError,
    );
  }

  @override
  String toString() =>
      '$runtimeType: $message${code != null ? ' (code: $code)' : ''}';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});
}

class FileStorageException extends AppException {
  const FileStorageException(super.message, {super.code, super.originalError});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError});
}

class ConfigurationException extends AppException {
  const ConfigurationException(
    super.message, {
    super.code,
    super.originalError,
  });
}

class Result<T> {
  final T? data;
  final AppException? error;

  const Result.success(this.data) : error = null;
  const Result.failure(this.error) : data = null;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  R fold<R>(R Function(T) onSuccess, R Function(AppException) onFailure) {
    if (isSuccess) {
      return onSuccess(data as T);
    }

    return onFailure(error!);
  }
}
