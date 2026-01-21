import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Custom sport icon widget that displays sport-specific icons
/// Uses custom asset icons when available, falls back to Material icons
class SportIcon extends StatelessWidget {
  final SportType sport;
  final double? size;
  final Color? color;
  final bool useAsset; // Set to true to use custom assets, false for Material icons

  const SportIcon({
    super.key,
    required this.sport,
    this.size = 24,
    this.color,
    this.useAsset = true,
  });

  @override
  Widget build(BuildContext context) {
    if (useAsset) {
      // For PNG assets, don't apply color tinting (PNGs are already colored)
      // Use ColorFiltered if color tinting is needed for monochrome icons
      Widget iconWidget = Image.asset(
        AppTheme.getSportIconAsset(sport),
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to Material icon if asset fails to load
          return Icon(
            AppTheme.getSportIconFromType(sport),
            size: size,
            color: color,
          );
        },
      );

      // Apply color filter only if color is specified and icon should be tinted
      if (color != null) {
        iconWidget = ColorFiltered(
          colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
          child: iconWidget,
        );
      }

      return iconWidget;
    } else {
      return Icon(
        AppTheme.getSportIconFromType(sport),
        size: size,
        color: color,
      );
    }
  }
}

/// Sport icon widget that works with sport code strings
class SportIconFromCode extends StatelessWidget {
  final String sportCode;
  final double? size;
  final Color? color;
  final bool useAsset;

  const SportIconFromCode({
    super.key,
    required this.sportCode,
    this.size = 24,
    this.color,
    this.useAsset = true,
  });

  @override
  Widget build(BuildContext context) {
    if (useAsset) {
      // For PNG assets, don't apply color tinting directly
      // Use ColorFiltered if color tinting is needed
      Widget iconWidget = Image.asset(
        AppTheme.getSportIconAssetFromCode(sportCode),
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to Material icon if asset fails to load
          return Icon(
            AppTheme.getSportIcon(sportCode),
            size: size,
            color: color,
          );
        },
      );

      // Apply color filter only if color is specified and icon should be tinted
      if (color != null) {
        iconWidget = ColorFiltered(
          colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
          child: iconWidget,
        );
      }

      return iconWidget;
    } else {
      return Icon(
        AppTheme.getSportIcon(sportCode),
        size: size,
        color: color,
      );
    }
  }
}

