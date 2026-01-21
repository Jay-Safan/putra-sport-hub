import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

/// Centralized error handling utility for user-friendly error messages
class ErrorHandler {
  /// Get user-friendly error message from any error/exception
  /// 
  /// Handles:
  /// - Firebase/Firestore errors
  /// - Network errors (SocketException, TimeoutException)
  /// - Generic exceptions
  /// 
  /// Returns a user-friendly message instead of technical error details
  static String getUserFriendlyErrorMessage(Object error, {
    String? defaultMessage,
    String? context, // Additional context like "booking", "payment", etc.
  }) {
    // Network errors
    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }
    
    if (error is HttpException) {
      return 'Network error. Please try again later.';
    }
    
    if (error is TimeoutException || error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    
    // Firebase Auth errors
    if (error is FirebaseAuthException) {
      return _getAuthErrorMessage(error.code);
    }
    
    // Firestore errors
    if (error is FirebaseException) {
      return _getFirebaseErrorMessage(error.code, context: context);
    }
    
    // String error codes (from service methods that pass error codes as strings)
    if (error is String) {
      // Check if it's a Firebase error code
      if (error.contains('permission-denied') || error.contains('Permission denied')) {
        return 'You don\'t have permission to perform this action.';
      }
      if (error.contains('not-found') || error.contains('not found')) {
        return context != null 
          ? '${context.capitalize()} not found. Please try again.'
          : 'Item not found. Please try again.';
      }
      if (error.contains('already-exists') || error.contains('already exists')) {
        return context != null
          ? 'This $context already exists. Please try a different one.'
          : 'This item already exists. Please try again.';
      }
      
      // Return the string if it already looks user-friendly
      if (!error.contains('Exception') && !error.contains('Error:') && error.length < 100) {
        return error;
      }
    }
    
    // Generic catch-all - use context-aware default messages
    if (defaultMessage != null) {
      return defaultMessage;
    }
    
    final errorString = error.toString().toLowerCase();
    
    // Try to infer error type from string
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request took too long. Please try again.';
    }
    
    if (errorString.contains('permission') || errorString.contains('unauthorized')) {
      return 'You don\'t have permission to perform this action.';
    }
    
    // Default fallback - context-aware
    switch (context?.toLowerCase()) {
      case 'booking':
        return 'Unable to process booking. Please try again.';
      case 'payment':
        return 'Payment failed. Please check your wallet balance and try again.';
      case 'tournament':
        return 'Unable to process tournament request. Please try again.';
      case 'referee':
        return 'Unable to process referee request. Please try again.';
      case 'profile':
        return 'Unable to update profile. Please try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
  
  /// Get user-friendly message for Firebase Auth error codes
  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Account not found. Please sign up first to create your account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or use "Forgot Password" to reset it.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please sign in instead.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 8 characters with uppercase, lowercase, and numbers.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      case 'too-many-requests':
        return 'Too many login attempts. Please wait a few minutes and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not available. Please contact support.';
      case 'network-request-failed':
        return 'Connection error. Please check your internet and try again.';
      default:
        return 'Unable to sign in. Please check your credentials and try again.';
    }
  }
  
  /// Get user-friendly message for Firebase/Firestore error codes
  static String _getFirebaseErrorMessage(String code, {String? context}) {
    switch (code) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action.';
      case 'not-found':
        return context != null 
          ? '${context.capitalize()} not found. Please try again.'
          : 'Item not found. Please try again.';
      case 'already-exists':
        return context != null
          ? 'This $context already exists. Please try a different one.'
          : 'This item already exists. Please try again.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again later.';
      case 'deadline-exceeded':
        return 'Request took too long. Please try again.';
      case 'failed-precondition':
        return 'Unable to complete this action. Please check the requirements and try again.';
      case 'aborted':
        return 'Action was cancelled. Please try again.';
      case 'out-of-range':
        return 'Invalid request. Please check your input and try again.';
      case 'unimplemented':
        return 'This feature is not yet available.';
      case 'internal':
        return 'An internal error occurred. Please try again later.';
      case 'data-loss':
        return 'Data error. Please try again.';
      case 'unauthenticated':
        return 'Please sign in to continue.';
      default:
        return context != null
          ? 'Unable to process $context request. Please try again.'
          : 'Something went wrong. Please try again.';
    }
  }
}

/// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
