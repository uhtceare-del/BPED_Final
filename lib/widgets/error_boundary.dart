import 'package:flutter/material.dart';
import '../core/app_exceptions.dart';
import '../core/error_handler.dart';

/// Global error boundary widget that catches unhandled errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext, AppException)? errorBuilder;
  final void Function(AppException)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  AppException? _error;

  @override
  void initState() {
    super.initState();
    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      final error = AppException(
        'Flutter error: ${details.exception}',
        originalError: details.exception,
      );
      _handleError(error);
    };
  }

  void _handleError(AppException error) {
    ErrorHandler.logError(error, context: 'ErrorBoundary');
    widget.onError?.call(error);

    setState(() {
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error!);
      }

      // Default error UI
      return Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  ErrorHandler.getUserFriendlyMessage(_error!),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

/// Extension to add error handling to BuildContext
extension ErrorHandlingExtension on BuildContext {
  /// Show a snackbar with an error message
  void showErrorSnackBar(AppException error, {Duration? duration}) {
    final message = ErrorHandler.getUserFriendlyMessage(error);

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: duration ?? const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(this).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show a success snackbar
  void showSuccessSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }
}
