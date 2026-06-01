import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:student_cabinet_flutter_app/shared/error_handler.dart';
import 'package:student_cabinet_flutter_app/shared/exceptions.dart';

void main() {
  group('ErrorHandler', () {
    late ErrorHandler errorHandler;

    setUp(() {
      errorHandler = ErrorHandler.instance;
    });

    group('executeWithRetry', () {
      test('should succeed on first attempt', () async {
        var callCount = 0;
        final result = await errorHandler.executeWithRetry(
          () async {
            callCount++;
            return 'success';
          },
          operationName: 'test operation',
        );

        expect(result, equals('success'));
        expect(callCount, equals(1));
      });

      test('should retry on retryable exceptions', () async {
        var callCount = 0;
        final result = await errorHandler.executeWithRetry(
          () async {
            callCount++;
            if (callCount < 3) {
              throw const SocketException('Connection failed');
            }
            return 'success after retry';
          },
          operationName: 'test operation',
          maxRetries: 3,
        );

        expect(result, equals('success after retry'));
        expect(callCount, equals(3));
      });

      test('should not retry on non-retryable exceptions', () async {
        var callCount = 0;

        expect(
          () => errorHandler.executeWithRetry(
            () async {
              callCount++;
              throw const AppAuthException('Auth failed');
            },
            operationName: 'test operation',
          ),
          throwsA(isA<AppAuthException>()),
        );

        expect(callCount, equals(1));
      });

      test('should throw after max retries exceeded', () async {
        var callCount = 0;

        expect(
          () => errorHandler.executeWithRetry(
            () async {
              callCount++;
              throw const SocketException('Always fails');
            },
            operationName: 'test operation',
            maxRetries: 2,
          ),
          throwsA(isA<AppNetworkException>()),
        );

        expect(callCount, equals(3)); // Initial attempt + 2 retries
      });

      test('should use custom shouldRetry function', () async {
        var callCount = 0;

        expect(
          () => errorHandler.executeWithRetry(
            () async {
              callCount++;
              throw const SocketException('Network error');
            },
            operationName: 'test operation',
            shouldRetry: (error) => false, // Never retry
            maxRetries: 3,
          ),
          throwsA(isA<Exception>()),
        );

        expect(callCount, equals(1)); // Should not retry
      });
    });

    group('executeHttpRequest', () {
      test('should handle successful HTTP response', () async {
        final response = await errorHandler.executeHttpRequest(
          () async => http.Response('{"success": true}', 200),
          operationName: 'test HTTP request',
        );

        expect(response.statusCode, equals(200));
        expect(response.body, equals('{"success": true}'));
      });

      test('should throw AppAuthException for 401 status', () async {
        expect(
          () => errorHandler.executeHttpRequest(
            () async => http.Response('Unauthorized', 401),
            operationName: 'test HTTP request',
          ),
          throwsA(isA<AppAuthException>()),
        );
      });

      test('should throw AppNetworkException for 500 status', () async {
        expect(
          () => errorHandler.executeHttpRequest(
            () async => http.Response('Internal Server Error', 500),
            operationName: 'test HTTP request',
          ),
          throwsA(isA<AppNetworkException>()),
        );
      });

      test('should throw AppDataException for 404 status', () async {
        expect(
          () => errorHandler.executeHttpRequest(
            () async => http.Response('Not Found', 404),
            operationName: 'test HTTP request',
          ),
          throwsA(isA<AppDataException>()),
        );
      });

      test('should handle timeout exceptions', () async {
        expect(
          () => errorHandler.executeHttpRequest(
            () async {
              await Future.delayed(const Duration(seconds: 20));
              return http.Response('Too late', 200);
            },
            operationName: 'test HTTP request',
            timeout: const Duration(milliseconds: 100),
          ),
          throwsA(isA<AppNetworkException>()),
        );
      });
    });

    group('getUserFriendlyMessage', () {
      test('should return message from AppNetworkException', () {
        const exception = AppNetworkException('Network error message');
        final message = errorHandler.getUserFriendlyMessage(exception);
        expect(message, equals('Network error message'));
      });

      test('should return message from AppAuthException', () {
        const exception = AppAuthException('Auth error message');
        final message = errorHandler.getUserFriendlyMessage(exception);
        expect(message, equals('Auth error message'));
      });

      test('should return message from AppDataException', () {
        const exception = AppDataException('Data error message');
        final message = errorHandler.getUserFriendlyMessage(exception);
        expect(message, equals('Data error message'));
      });

      test('should return fallback message for unknown exceptions', () {
        final exception = Exception('Unknown error');
        final message = errorHandler.getUserFriendlyMessage(exception);
        expect(message, equals('Произошла неожиданная ошибка. Попробуйте позже.'));
      });
    });
  });

  group('ErrorHandlerExtension', () {
    test('should work with extension method', () async {
      var callCount = 0;

      final result = await (() async {
        callCount++;
        if (callCount < 2) {
          throw const SocketException('Network error');
        }
        return 'success';
      }).withRetry(
        operationName: 'extension test',
        maxRetries: 2,
      );

      expect(result, equals('success'));
      expect(callCount, equals(2));
    });
  });
}