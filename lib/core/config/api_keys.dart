/// Centralized API Keys Configuration
///
/// Add your API keys here for all external services.
/// For production, consider using environment variables or secure storage.
class ApiKeys {
  ApiKeys._(); // Prevent instantiation

  // ═══════════════════════════════════════════════════════════════════════════
  // GOOGLE SERVICES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Google Maps Static API Key
  /// Used for displaying static map images in booking details
  static const String googleMapsStatic =
      'AIzaSyAq7MhJ1xbwp5b9IYcVr9lzu4VyAd7scmU';

  // ═══════════════════════════════════════════════════════════════════════════
  // AI SERVICES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Google Gemini API Key
  /// Used for:
  /// - AI chatbot assistant (ChatbotService)
  ///
  /// Get your API key from: https://aistudio.google.com/app/apikey
  static const String gemini = 'AIzaSyA_sdLfeaxbVvW7PIezs2yjr82f1UwCl8M';

  // ═══════════════════════════════════════════════════════════════════════════
  // IMAGE STORAGE (CLOUDINARY)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cloudinary Cloud Name
  /// Used for image storage (profile images)
  /// Free tier: 25 GB storage + 25 GB bandwidth/month
  ///
  /// Get your credentials from: https://cloudinary.com/console
  static const String cloudinaryCloudName = 'dw3xmf8vm';

  /// Cloudinary API Key
  static const String cloudinaryApiKey = '452589634447949';

  /// Cloudinary API Secret
  /// Required for signed uploads (if not using upload preset)
  static const String cloudinaryApiSecret = 'VR_JQcTPNDr9Zhu9lkF7WX5JNsE';

  /// Cloudinary Upload Preset
  /// Recommended: Create an unsigned upload preset in Cloudinary Console
  /// This allows uploads without requiring API secret in the app
  ///
  /// Setup: https://cloudinary.com/documentation/upload_presets
  /// Set to null to use signed uploads (more reliable, uses API secret)
  static const String? cloudinaryUploadPreset =
      null; // Use signed uploads with API secret

  // ═══════════════════════════════════════════════════════════════════════════
  // WEATHER SERVICES
  // ═══════════════════════════════════════════════════════════════════════════

  /// OpenWeatherMap API Key
  /// Used for weather checking to block outdoor bookings during rain
  ///
  /// Get your API key from: https://openweathermap.org/api
  static const String openWeatherMap = '28782cf39a07c0664034afcdebe7db17';

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if all required API keys are configured
  static bool get areAllKeysConfigured {
    return googleMapsStatic.isNotEmpty &&
        gemini.isNotEmpty &&
        cloudinaryCloudName.isNotEmpty &&
        (cloudinaryApiKey.isNotEmpty ||
            cloudinaryUploadPreset != null &&
                cloudinaryUploadPreset!.isNotEmpty) &&
        openWeatherMap.isNotEmpty;
  }

  /// Get list of missing API keys (for debugging)
  static List<String> get missingKeys {
    final missing = <String>[];
    if (gemini.isEmpty) {
      missing.add('Gemini API Key (for chatbot)');
    }
    if (cloudinaryCloudName.isEmpty) {
      missing.add('Cloudinary Cloud Name (for image storage)');
    }
    if ((cloudinaryApiKey.isEmpty) &&
        (cloudinaryUploadPreset == null || cloudinaryUploadPreset!.isEmpty)) {
      missing.add('Cloudinary API Key OR Upload Preset (for image uploads)');
    }
    if (openWeatherMap.isEmpty) {
      missing.add('OpenWeatherMap API Key (for weather checking)');
    }
    return missing;
  }

  /// Get list of optional/missing API keys
  /// Returns info about what features are enabled/disabled
  static Map<String, bool> get featureStatus {
    final hasCloudinary =
        cloudinaryCloudName.isNotEmpty &&
        (cloudinaryApiKey.isNotEmpty ||
            cloudinaryUploadPreset != null &&
                cloudinaryUploadPreset!.isNotEmpty);

    return {
      'Google Maps': googleMapsStatic.isNotEmpty,
      'AI Chatbot (Gemini)': gemini.isNotEmpty,
      'Image Storage (Cloudinary)': hasCloudinary,
      'Weather Service (OpenWeatherMap)':
          openWeatherMap.isNotEmpty,
    };
  }
}
