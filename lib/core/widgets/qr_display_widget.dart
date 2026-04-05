import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// A glassmorphism styled QR code display widget
class QRDisplayWidget extends StatelessWidget {
  final String data;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final VoidCallback? onShare;

  const QRDisplayWidget({
    super.key,
    required this.data,
    required this.title,
    this.subtitle,
    this.accentColor = AppTheme.primaryGreen,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // QR Code Placeholder (using a styled container)
              // In production, use qr_flutter package
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(child: _buildQRPattern()),
              ),
              const SizedBox(height: 20),

              // Data display (shortened)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data.length > 20 ? '${data.substring(0, 20)}...' : data,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: data));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Code copied to clipboard'),
                            backgroundColor: accentColor,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Icon(Icons.copy, color: accentColor, size: 16),
                    ),
                  ],
                ),
              ),

              if (onShare != null) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: onShare,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.share, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Share',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Simple QR pattern visualization (placeholder)
  Widget _buildQRPattern() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 100,
        itemBuilder: (context, index) {
          // Generate a pseudo-random pattern based on data hash
          final hash = data.hashCode;
          final isBlack = ((hash + index * 7) % 3) != 0;

          // Keep corners for position detection patterns
          final row = index ~/ 10;
          final col = index % 10;
          final isCorner =
              (row < 3 && col < 3) ||
              (row < 3 && col > 6) ||
              (row > 6 && col < 3);

          return Container(
            decoration: BoxDecoration(
              color: isCorner || isBlack ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        },
      ),
    );
  }
}
