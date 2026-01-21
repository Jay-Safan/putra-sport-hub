import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../../features/auth/data/models/user_model.dart';

/// Reusable avatar widget that displays user profile picture or initial letter
/// 
/// Features:
/// - Displays profile picture if available
/// - Falls back to initial letter with gradient background
/// - Supports different sizes
/// - Optional glow effect
class AvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double radius;
  final bool showGlow;
  final bool isStudent;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    this.photoUrl,
    required this.displayName,
    this.radius = 24,
    this.showGlow = false,
    this.isStudent = true,
    this.backgroundColor,
    this.textColor,
    this.onTap,
  });

  /// Factory constructor from UserModel
  factory AvatarWidget.fromUser({
    required UserModel? user,
    double radius = 24,
    bool showGlow = false,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return AvatarWidget(
      photoUrl: user?.photoUrl,
      displayName: user?.displayName ?? 'User',
      radius: radius,
      showGlow: showGlow,
      isStudent: user?.isStudent ?? true,
      backgroundColor: backgroundColor,
      textColor: textColor,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? const Color(0xFF1A3D32),
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: photoUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildInitialLetter(),
                errorWidget: (context, url, error) => _buildInitialLetter(),
              ),
            )
          : _buildInitialLetter(),
    );

    if (showGlow) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(radius * 0.125), // 3px for 24px radius
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isStudent
                  ? [AppTheme.primaryGreen, AppTheme.accentGold]
                  : [AppTheme.futsalBlue, const Color(0xFF42A5F5)],
            ),
            boxShadow: [
              BoxShadow(
                color: (isStudent ? AppTheme.primaryGreen : AppTheme.futsalBlue)
                    .withValues(alpha: 0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: avatar,
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildInitialLetter() {
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'U';

    return Text(
      initial,
      style: TextStyle(
        color: textColor ?? Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: radius * 0.833, // 20px for 24px radius
      ),
    );
  }
}
