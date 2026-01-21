import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standardized SnackBar helper for consistent user feedback
/// Provides success, error, warning, and info messages with consistent styling
class SnackbarHelper {
  SnackbarHelper._(); // Private constructor - static methods only

  /// Show success message (green)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: AppTheme.successGreen,
      icon: Icons.check_circle,
      duration: duration,
    );
  }

  /// Show error message (red)
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: AppTheme.errorRed,
      icon: Icons.error_outline,
      duration: duration,
    );
  }

  /// Show warning message (amber)
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: AppTheme.warningAmber,
      icon: Icons.warning_amber,
      duration: duration,
    );
  }

  /// Show info message (blue)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: AppTheme.futsalBlue,
      icon: Icons.info_outline,
      duration: duration,
    );
  }

  /// Internal method to show SnackBar with consistent styling
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Clear any existing snackbars
    scaffoldMessenger.clearSnackBars();
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }
}