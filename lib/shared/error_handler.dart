import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'exceptions.dart';

/// Centralized error handler with retry mechanisms and detailed logging
class ErrorHandler {
  ErrorHandler._();

  static final ErrorHandler _instance = ErrorHandler._();
  static ErrorHandler get instance => _instance;

  /// Configuration for retry behavior
  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(milliseconds: 500);
  static const Duration _maxDelay = Duration(seconds: 10);
  static const double _backoffMultiplier = 2.0;
  static const double _jitterFactor = 0.1;

  /// Execute a network request with exponential backoff retry
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    String? operationName,
    bool Function(Exception error)? shouldRetry = _defaultShouldRetry,
    int maxRetries = _maxRetries,
  }) async {
    var attempt = 0;
    Exception? lastException;

    while (attempt <= maxRetries) {
      try {
        final result = await operation();

        // Log successful retry if this wasn't the first attempt
        if (attempt > 0) {
          _logInfo('Operation ${operationName ?? 'unknown'} succeeded after $attempt retries');
        }

        return result;
      } catch (error) {
        lastException = error is Exception ? error : Exception(error.toString());
        attempt++;

        // Don't retry if we've exceeded max attempts or if error is not retryable
        if (attempt > maxRetries || !(shouldRetry?.call(lastException) ?? false)) {
          break;
        }

        final delay = _calculateDelay(attempt);
        _logWarning(
          'Operation ${operationName ?? 'unknown'} failed (attempt $attempt/$maxRetries). '
          'Retrying in ${delay.inMilliseconds}ms. Error: $lastException'
        );

        await Future.delayed(delay);
      }
    }

    // All retries exhausted, throw the last exception with context
    final enhancedException = _enhanceException(
      lastException!,
      operationName: operationName,
      attempts: attempt,
    );

    _logError('Operation ${operationName ?? 'unknown'} failed after $attempt attempts', enhancedException);
    throw enhancedException;
  }

  /// Execute HTTP request with enhanced error handling
  Future<http.Response> executeHttpRequest(
    Future<http.Response> Function() request, {
    String? operationName,
    Duration? timeout,
  }) async {
    return executeWithRetry(
      () async {
        try {
          final response = await request().timeout(
            timeout ?? const Duration(seconds: 15),
          );

          // Check for HTTP error status codes
          if (response.statusCode >= 400) {
            throw _createHttpException(response);
          }

          return response;
        } on TimeoutException {
          throw const AppNetworkException(
            'Сервер не отвечает. Попробуйте позже.',
            isTimeout: true,
          );
        } on SocketException {
          throw const AppNetworkException(
            'Нет подключения к интернету. Проверьте сеть и попробуйте снова.',
          );
        } on HttpException catch (e) {
          throw AppNetworkException(
            'Ошибка соединения с сервером: ${e.message}',
          );
        }
      },
      operationName: operationName ?? 'HTTP request',
    );
  }

  /// Handle and log exceptions in UI components
  void handleUiError(
    Exception error, {
    String? context,
    VoidCallback? onRetry,
  }) {
    final userMessage = _getUserFriendlyMessage(error);
    _logError('UI Error in ${context ?? 'unknown context'}', error);

    // In a real app, you might show a snackbar or dialog here
    if (kDebugMode) {
      developer.log('UI Error: $userMessage', error: error);
    }
  }

  /// Get user-friendly error message
  String getUserFriendlyMessage(Exception error) {
    return _getUserFriendlyMessage(error);
  }

  /// Default retry logic - retry on network errors but not auth errors
  static bool _defaultShouldRetry(Exception error) {
    if (error is AppNetworkException) {
      // Don't retry timeouts as they already took long enough
      return !error.isTimeout;
    }
    if (error is AppAuthException) {
      return false; // Don't retry auth errors
    }
    if (error is SocketException || error is HttpException) {
      return true;
    }
    return false;
  }

  /// Calculate exponential backoff delay with jitter
  Duration _calculateDelay(int attempt) {
    final exponentialDelay = _baseDelay * pow(_backoffMultiplier, attempt - 1);
    final clampedDelay = Duration(
      milliseconds: min(exponentialDelay.inMilliseconds, _maxDelay.inMilliseconds),
    );

    // Add jitter to prevent thundering herd
    final jitter = Random().nextDouble() * _jitterFactor;
    final jitterMs = (clampedDelay.inMilliseconds * jitter).round();

    return Duration(milliseconds: clampedDelay.inMilliseconds + jitterMs);
  }

  /// Enhance exception with additional context
  Exception _enhanceException(
    Exception original, {
    String? operationName,
    int? attempts,
  }) {
    if (original is AppNetworkException) {
      return AppNetworkException(
        '${original.message}${attempts != null ? ' (после $attempts попыток)' : ''}',
        isTimeout: original.isTimeout,
      );
    }

    if (original is AppDataException) {
      return AppDataException(
        '${original.message}${attempts != null ? ' (после $attempts попыток)' : ''}',
      );
    }

    if (original is AppAuthException) {
      return original; // Don't modify auth exceptions
    }

    return AppDataException(
      'Произошла ошибка${operationName != null ? ' при выполнении $operationName' : ''}: ${original.toString()}'
      '${attempts != null ? ' (после $attempts попыток)' : ''}',
    );
  }

  /// Create appropriate exception from HTTP response
  Exception _createHttpException(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode == 401 || statusCode == 403) {
      return const AppAuthException('Сессия истекла. Войдите снова.');
    }

    if (statusCode >= 500) {
      return const AppNetworkException('Ошибка сервера. Попробуйте позже.');
    }

    if (statusCode == 404) {
      return const AppDataException('Запрашиваемые данные не найдены.');
    }

    if (statusCode == 429) {
      return const AppNetworkException('Слишком много запросов. Попробуйте позже.');
    }

    // Try to extract error message from response body
    try {
      final body = response.body;
      if (body.isNotEmpty) {
        // This is a simplified extraction - in real app you might parse JSON
        return AppDataException('Ошибка сервера: $body');
      }
    } catch (_) {
      // Ignore parsing errors
    }

    return AppDataException('Ошибка HTTP $statusCode');
  }

  /// Get user-friendly message from exception
  String _getUserFriendlyMessage(Exception error) {
    if (error is AppNetworkException) {
      return error.message;
    }
    if (error is AppAuthException) {
      return error.message;
    }
    if (error is AppDataException) {
      return error.message;
    }

    // Fallback for unknown exceptions
    return 'Произошла неожиданная ошибка. Попробуйте позже.';
  }

  /// Logging helpers
  void _logInfo(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'ErrorHandler', level: 800);
    }
  }

  void _logWarning(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'ErrorHandler', level: 900);
    }
  }

  void _logError(String message, Exception error) {
    if (kDebugMode) {
      developer.log(message, name: 'ErrorHandler', error: error, level: 1000);
    }

    // In production, you might send this to crash reporting service
    // FirebaseCrashlytics.instance.recordError(error, null);
  }
}

/// Extension to make error handling more convenient
extension ErrorHandlerExtension<T> on Future<T> Function() {
  /// Execute this function with retry logic
  Future<T> withRetry({
    String? operationName,
    bool Function(Exception)? shouldRetry,
    int maxRetries = 3,
  }) {
    return ErrorHandler.instance.executeWithRetry<T>(
      this,
      operationName: operationName,
      shouldRetry: shouldRetry,
      maxRetries: maxRetries,
    );
  }
}