import 'package:flutter/material.dart';

import '../error_handler.dart';
import '../exceptions.dart';

/// A widget that displays error messages with retry functionality
class ErrorDisplay extends StatelessWidget {
  const ErrorDisplay({
    super.key,
    required this.error,
    this.onRetry,
    this.showRetryButton = true,
    this.padding,
  });

  final Exception error;
  final VoidCallback? onRetry;
  final bool showRetryButton;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getErrorIcon(),
            size: 48,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            ErrorHandler.instance.getUserFriendlyMessage(error),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          if (showRetryButton && onRetry != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    if (error is AppNetworkException) {
      final networkError = error as AppNetworkException;
      if (networkError.isTimeout) {
        return Icons.access_time;
      }
      return Icons.wifi_off;
    }
    if (error is AppAuthException) {
      return Icons.lock_outline;
    }
    return Icons.error_outline;
  }
}

/// A banner widget for showing non-critical errors
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.error,
    this.onDismiss,
    this.onRetry,
  });

  final Exception error;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ErrorHandler.instance.getUserFriendlyMessage(error),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              iconSize: 20,
            ),
          ],
        ],
      ),
    );
  }
}

/// A mixin for handling errors in StatefulWidgets
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  Exception? _currentError;
  bool _isRetrying = false;

  Exception? get currentError => _currentError;
  bool get isRetrying => _isRetrying;
  bool get hasError => _currentError != null;

  /// Handle an error and update the UI state
  void handleError(Exception error, {String? context}) {
    setState(() {
      _currentError = error;
      _isRetrying = false;
    });

    ErrorHandler.instance.handleUiError(
      error,
      context: context ?? widget.runtimeType.toString(),
    );
  }

  /// Clear the current error
  void clearError() {
    if (_currentError != null) {
      setState(() {
        _currentError = null;
        _isRetrying = false;
      });
    }
  }

  /// Execute an async operation with error handling
  Future<void> executeWithErrorHandling(
    Future<void> Function() operation, {
    String? operationName,
    VoidCallback? onSuccess,
  }) async {
    try {
      clearError();
      setState(() {
        _isRetrying = true;
      });

      await operation();

      setState(() {
        _isRetrying = false;
      });

      onSuccess?.call();
    } catch (error) {
      final exception = error is Exception ? error : Exception(error.toString());
      handleError(exception, context: operationName);
    }
  }

  /// Build error display widget
  Widget buildErrorDisplay({
    VoidCallback? onRetry,
    bool showRetryButton = true,
    EdgeInsetsGeometry? padding,
  }) {
    if (_currentError == null) {
      return const SizedBox.shrink();
    }

    return ErrorDisplay(
      error: _currentError!,
      onRetry: onRetry,
      showRetryButton: showRetryButton,
      padding: padding,
    );
  }

  /// Build error banner widget
  Widget buildErrorBanner({
    VoidCallback? onRetry,
  }) {
    if (_currentError == null) {
      return const SizedBox.shrink();
    }

    return ErrorBanner(
      error: _currentError!,
      onDismiss: clearError,
      onRetry: onRetry,
    );
  }
}

/// Extension for showing error snackbars
extension ErrorSnackBar on BuildContext {
  void showErrorSnackBar(
    Exception error, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(this);
    final theme = Theme.of(this);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ErrorHandler.instance.getUserFriendlyMessage(error),
        ),
        backgroundColor: theme.colorScheme.error,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Повторить',
                textColor: theme.colorScheme.onError,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}