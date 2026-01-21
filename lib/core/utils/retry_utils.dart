import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Retry configuration for network operations
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool Function(Object error)? shouldRetry;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 10),
    this.backoffMultiplier = 2.0,
    this.shouldRetry,
  });

  /// Default retry config for network operations
  static const RetryConfig network = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 10),
  );

  /// Retry config for payment operations (more attempts)
  static const RetryConfig payment = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 5),
  );

  /// Retry config for quick operations (fewer attempts)
  static const RetryConfig quick = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 3),
  );
}

/// Utility class for retrying operations with exponential backoff
class RetryUtils {
  /// Execute an async operation with retry logic
  /// 
  /// Returns the result of the operation if successful, or throws the last error
  /// after all retries are exhausted.
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    RetryConfig config = RetryConfig.network,
    void Function(int attempt, Object error)? onRetry,
  }) async {
    int attempt = 0;
    Duration delay = config.initialDelay;
    Object? lastError;

    while (attempt < config.maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;
        attempt++;

        // Check if we should retry this error
        if (config.shouldRetry != null && !config.shouldRetry!(error)) {
          rethrow;
        }

        // Don't retry on the last attempt
        if (attempt >= config.maxAttempts) {
          break;
        }

        // Don't retry on non-retryable errors
        if (!_isRetryableError(error)) {
          rethrow;
        }

        // Notify callback about retry
        onRetry?.call(attempt, error);

        // Wait before retrying (exponential backoff)
        await Future.delayed(delay);

        // Increase delay for next retry (capped at maxDelay)
        delay = Duration(
          milliseconds: (delay.inMilliseconds * config.backoffMultiplier).round(),
        );
        if (delay > config.maxDelay) {
          delay = config.maxDelay;
        }

        debugPrint('Retry attempt $attempt/${config.maxAttempts} after ${delay.inMilliseconds}ms');
      }
    }

    // All retries exhausted
    throw lastError ?? Exception('Operation failed after ${config.maxAttempts} attempts');
  }

  /// Check if an error is retryable (network errors, timeouts)
  static bool _isRetryableError(Object error) {
    // Network errors - retryable
    if (error is SocketException) {
      return true;
    }
    if (error is HttpException) {
      return true;
    }
    if (error is TimeoutException) {
      return true;
    }

    // Check error strings for network-related errors
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socketexception') ||
        errorString.contains('httpexception')) {
      return true;
    }

    // Firebase errors - some are retryable
    if (errorString.contains('unavailable') ||
        errorString.contains('deadline-exceeded') ||
        errorString.contains('aborted')) {
      return true;
    }

    // Non-retryable errors (authentication, permissions, validation)
    if (errorString.contains('permission-denied') ||
        errorString.contains('unauthenticated') ||
        errorString.contains('invalid-argument') ||
        errorString.contains('already-exists') ||
        errorString.contains('not-found')) {
      return false;
    }

    // Default: don't retry unknown errors
    return false;
  }

  /// Execute operation with retry and return a result object
  static Future<RetryResult<T>> retryWithResult<T>({
    required Future<T> Function() operation,
    RetryConfig config = RetryConfig.network,
    void Function(int attempt, Object error)? onRetry,
  }) async {
    try {
      final result = await retry(
        operation: operation,
        config: config,
        onRetry: onRetry,
      );
      return RetryResult<T>.success(result);
    } catch (error) {
      return RetryResult<T>.failure(error);
    }
  }
}

/// Result wrapper for retry operations
class RetryResult<T> {
  final T? data;
  final Object? error;
  final bool isSuccess;

  RetryResult._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory RetryResult.success(T data) {
    return RetryResult._(data: data, isSuccess: true);
  }

  factory RetryResult.failure(Object error) {
    return RetryResult._(error: error, isSuccess: false);
  }

  /// Get the data or throw the error
  T get value {
    if (isSuccess && data != null) {
      return data!;
    }
    throw error ?? Exception('Operation failed');
  }
}
