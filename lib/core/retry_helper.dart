import 'app_exceptions.dart';

class RetryHelper {
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    bool Function(AppException)? shouldRetry,
  }) async {
    var delay = initialDelay;
    AppException? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error is AppException
            ? error
            : AppException('Operation failed: $error', originalError: error);

        if (attempt == maxAttempts) {
          break;
        }

        if (shouldRetry != null && !shouldRetry(lastError)) {
          break;
        }

        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }

    throw lastError ?? const AppException('Operation failed after retry.');
  }
}
