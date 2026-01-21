import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

/// PutraSportHub Theme Configuration
/// Official UPM branding: UPM Red (#B22222) and UPM Green (#2E8B57)
/// Reference: University Visual Identity Guidelines
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // BRAND COLORS - Official UPM Identity
  // ═══════════════════════════════════════════════════════════════════════════

  // Primary - UPM Official Green (Sea Green)
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color primaryGreenLight = Color(0xFF4CA873);
  static const Color primaryGreenDark = Color(0xFF1D5C3A);

  // Secondary - UPM Official Red (Firebrick)
  static const Color upmRed = Color(0xFFB22222);
  static const Color upmRedLight = Color(0xFFCB4A4A);
  static const Color upmRedDark = Color(0xFF8B1A1A);

  // Secondary - UPM Gold / Championship Gold
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentGoldLight = Color(0xFFFFE54C);
  static const Color accentGoldDark = Color(0xFFC7A600);

  // Sport Category Colors
  static const Color footballOrange = Color(0xFFFF6B35);
  static const Color futsalBlue = Color(0xFF2196F3);
  static const Color badmintonPurple = Color(0xFF9C27B0);
  static const Color tennisGreen = primaryGreenLight; // Use primary green light (same as home button)

  // Semantic Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color errorRed = Color(0xFFE53935);
  static const Color infoBlue = Color(0xFF03A9F4);

  // Neutrals
  static const Color surfaceWhite = Color(0xFFFAFAFA);
  static const Color backgroundCream = Color(0xFFF5F5DC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerGrey = Color(0xFFE0E0E0);

  // Dark Theme Colors - Premium Minimalist Dark Mode
  static const Color darkSurface = Color(0xFF0A0A0A);        // Main background (deeper black)
  static const Color darkCard = Color(0xFF141414);            // Cards (slightly lighter)
  static const Color darkElevated = Color(0xFF1C1C1C);        // Elevated surfaces
  static const Color darkBorder = Color(0xFF242424);          // Subtle borders (replaces shadows)
  
  // Premium Dark Text Colors (Higher Contrast)
  static const Color darkTextPrimary = Color(0xFFFFFFFF);     // Pure white for primary text
  static const Color darkTextSecondary = Color(0xFFB0B0B0);   // Light gray (was white54/60)
  static const Color darkTextTertiary = Color(0xFF808080);    // Muted gray for hints

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, primaryGreenLight],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGold, accentGoldLight],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1D5C3A), // UPM Green Dark
      Color(0xFF2E8B57), // UPM Green
      Color(0xFF4CA873), // UPM Green Light
    ],
  );

  // UPM Red Gradient (for alerts/important actions)
  static const LinearGradient upmRedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [upmRed, upmRedLight],
  );

  static const LinearGradient footballGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [footballOrange, Color(0xFFFF8F65), Color(0xFFFFB299)],
  );

  static const LinearGradient futsalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [futsalBlue, Color(0xFF64B5F6), Color(0xFF90CAF9)],
  );

  static const LinearGradient badmintonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [badmintonPurple, Color(0xFFBA68C8), Color(0xFFCE93D8)],
  );

  static const LinearGradient tennisGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreenLight, Color(0xFF6BC574), Color(0xFF8DD493)],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY
  // ═══════════════════════════════════════════════════════════════════════════

  static TextTheme get _textTheme {
    return TextTheme(
      // Display
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 45,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),

      // Headlines
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),

      // Titles
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),

      // Body
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),

      // Labels
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        onPrimary: Colors.white,
        primaryContainer: primaryGreenLight,
        onPrimaryContainer: Colors.white,
        secondary: accentGold,
        onSecondary: textPrimary,
        secondaryContainer: accentGoldLight,
        onSecondaryContainer: textPrimary,
        tertiary: futsalBlue,
        onTertiary: Colors.white,
        error: errorRed,
        onError: Colors.white,
        surface: surfaceWhite,
        onSurface: textPrimary,
        outline: dividerGrey,
      ),
      scaffoldBackgroundColor: surfaceWhite,
      textTheme: _textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: primaryGreen, width: 1.5),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary),
        hintStyle: GoogleFonts.inter(color: textSecondary),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentGold,
        foregroundColor: textPrimary,
        elevation: 4,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: surfaceWhite,
        selectedColor: primaryGreenLight,
        disabledColor: dividerGrey,
        labelStyle: GoogleFonts.inter(fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: dividerGrey,
        thickness: 1,
        space: 1,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreenLight,
        onPrimary: Colors.white,
        primaryContainer: primaryGreen,
        onPrimaryContainer: Colors.white,
        secondary: accentGold,
        onSecondary: textPrimary,
        secondaryContainer: accentGoldDark,
        onSecondaryContainer: Colors.white,
        tertiary: futsalBlue,
        onTertiary: Colors.white,
        error: errorRed,
        onError: Colors.white,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        outline: darkBorder,
      ),
      scaffoldBackgroundColor: darkSurface,
      textTheme: _textTheme.apply(
        bodyColor: darkTextPrimary,
        displayColor: darkTextPrimary,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Cards - Premium Minimalist (border instead of shadow)
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreenLight,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreenLight, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: darkTextSecondary),
        hintStyle: GoogleFonts.inter(color: darkTextTertiary),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: primaryGreenLight,
        unselectedItemColor: darkTextTertiary,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get gradient for specific sport type
  static LinearGradient getSportGradient(String sportCode) {
    switch (sportCode) {
      case 'FOOTBALL':
        return footballGradient;
      case 'FUTSAL':
        return futsalGradient;
      case 'BADMINTON':
        return badmintonGradient;
      case 'TENNIS':
        return tennisGradient;
      default:
        return primaryGradient;
    }
  }

  /// Get color for specific sport type (by code string)
  static Color getSportColor(String sportCode) {
    switch (sportCode) {
      case 'FOOTBALL':
        return footballOrange;
      case 'FUTSAL':
        return futsalBlue;
      case 'BADMINTON':
        return badmintonPurple;
      case 'TENNIS':
        return tennisGreen;
      default:
        return primaryGreen;
    }
  }

  /// Get color for specific sport type (by SportType enum)
  static Color getSportColorFromType(SportType sport) {
    switch (sport) {
      case SportType.football:
        return footballOrange;
      case SportType.futsal:
        return futsalBlue;
      case SportType.badminton:
        return badmintonPurple;
      case SportType.tennis:
        return tennisGreen;
    }
  }

  /// Get icon for specific sport type (by code string)
  static IconData getSportIcon(String sportCode) {
    switch (sportCode) {
      case 'FOOTBALL':
        return Icons.sports_soccer;
      case 'FUTSAL':
        return Icons.sports_soccer_outlined;
      case 'BADMINTON':
        return Icons.sports_tennis;
      case 'TENNIS':
        return Icons.sports_tennis_rounded;
      default:
        return Icons.sports;
    }
  }

  /// Get icon for specific sport type (by SportType enum)
  /// Returns Material Icon as fallback (for backward compatibility)
  static IconData getSportIconFromType(SportType sport) {
    switch (sport) {
      case SportType.football:
        return Icons.sports_soccer;
      case SportType.futsal:
        return Icons.sports_soccer_outlined;
      case SportType.badminton:
        return Icons.sports_tennis;
      case SportType.tennis:
        return Icons.sports_tennis_rounded;
    }
  }

  /// Get custom icon asset path for specific sport type (by SportType enum)
  static String getSportIconAsset(SportType sport) {
    switch (sport) {
      case SportType.football:
        return 'assets/icons/football icon.png';
      case SportType.futsal:
        return 'assets/icons/futsal icon.png';
      case SportType.badminton:
        return 'assets/icons/badminton icon.png';
      case SportType.tennis:
        return 'assets/icons/tennis icon.png';
    }
  }

  /// Get custom icon asset path for specific sport type (by code string)
  static String getSportIconAssetFromCode(String sportCode) {
    switch (sportCode) {
      case 'FOOTBALL':
        return 'assets/icons/football icon.png';
      case 'FUTSAL':
        return 'assets/icons/futsal icon.png';
      case 'BADMINTON':
        return 'assets/icons/badminton icon.png';
      case 'TENNIS':
        return 'assets/icons/tennis icon.png';
      default:
        return 'assets/icons/football icon.png'; // fallback
    }
  }

  /// Get booking status color
  static Color getStatusColor(String statusCode) {
    switch (statusCode) {
      case 'PENDING_PAYMENT':
        return warningAmber;
      case 'CONFIRMED':
        return successGreen;
      case 'IN_PROGRESS':
        return infoBlue;
      case 'COMPLETED':
        return primaryGreen;
      case 'CANCELLED':
        return errorRed;
      case 'REFUNDED':
        return textSecondary;
      default:
        return textSecondary;
    }
  }
}

/// Extension for convenient spacing
extension AppSpacing on num {
  SizedBox get verticalSpace => SizedBox(height: toDouble());
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
}

