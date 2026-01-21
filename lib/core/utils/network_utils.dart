import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network utilities for connectivity checking and network error detection
class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();

  /// Check if device is connected to internet
  /// Returns true if connected, false otherwise
  static Future<bool> isConnectedToInternet() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      
      // If no connectivity at all, return false immediately
      if (connectivityResults.isEmpty || connectivityResults.contains(ConnectivityResult.none)) {
        return false;
      }

      // If we have any connectivity type (wifi, mobile, ethernet, etc.), assume internet access
      // Firebase/Firestore will throw SocketException if there's no actual internet
      return true;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      // On error, assume no connection (safer assumption)
      return false;
    }
  }

  /// Stream of connectivity changes
  /// Listen to this to react to connectivity state changes
  /// Returns Stream of List of ConnectivityResult
  static Stream<List<ConnectivityResult>> get connectivityStream {
    return _connectivity.onConnectivityChanged;
  }

  /// Check current connectivity status
  /// Returns List of ConnectivityResult (may contain multiple types like wifi + mobile)
  static Future<List<ConnectivityResult>> getConnectivityStatus() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('Error getting connectivity status: $e');
      return [ConnectivityResult.none];
    }
  }

  /// Check if error is a network-related error
  /// Helps identify network issues from exceptions
  static bool isNetworkError(Object error) {
    return error is SocketException ||
        error is HttpException ||
        error is TimeoutException ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('SocketException') ||
        error.toString().contains('Network') ||
        error.toString().contains('Connection');
  }

  /// Get user-friendly network error message
  static String getNetworkErrorMessage(Object error) {
    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (error is HttpException) {
      return 'Network error. Please try again later.';
    }
    if (error is TimeoutException || error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    return 'Network error. Please check your internet connection and try again.';
  }
}
