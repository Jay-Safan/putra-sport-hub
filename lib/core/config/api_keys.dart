import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized API Keys Configuration
///
/// Values are loaded from environment variables via flutter_dotenv (.env file).
class ApiKeys {
  ApiKeys._(); // Prevent instantiation

  // ═══════════════════════════════════════════════════════════════════════════
  // GOOGLE SERVICES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Google Maps Static API Key (GOOGLE_MAPS_STATIC_KEY)
  static String get googleMapsStatic => _env('GOOGLE_MAPS_STATIC_KEY');

  // ═══════════════════════════════════════════════════════════════════════════
  // AI SERVICES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Google Gemini API Key (GEMINI_API_KEY)
  static String get gemini => _env('GEMINI_API_KEY');

  // ═══════════════════════════════════════════════════════════════════════════
  // IMAGE STORAGE (CLOUDINARY)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cloudinary Cloud Name (CLOUDINARY_CLOUD_NAME)
  static String get cloudinaryCloudName => _env('CLOUDINARY_CLOUD_NAME');

  /// Cloudinary API Key (CLOUDINARY_API_KEY)
  static String get cloudinaryApiKey => _env('CLOUDINARY_API_KEY');

  /// Cloudinary API Secret (CLOUDINARY_API_SECRET)
  static String get cloudinaryApiSecret => _env('CLOUDINARY_API_SECRET');

  /// Cloudinary Upload Preset (CLOUDINARY_UPLOAD_PRESET, optional)
  static String? get cloudinaryUploadPreset {
    final val = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];
    return (val == null || val.isEmpty) ? null : val;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WEATHER SERVICES
  // ═══════════════════════════════════════════════════════════════════════════

  /// OpenWeatherMap API Key (OPENWEATHERMAP_API_KEY)
  static String get openWeatherMap => _env('OPENWEATHERMAP_API_KEY');

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if all required API keys are configured
  static bool get areAllKeysConfigured {
    return googleMapsStatic.isNotEmpty &&
        gemini.isNotEmpty &&
        cloudinaryCloudName.isNotEmpty &&
        (cloudinaryApiKey.isNotEmpty ||
            (cloudinaryUploadPreset != null &&
                cloudinaryUploadPreset!.isNotEmpty)) &&
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
    if (cloudinaryApiKey.isEmpty &&
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
            (cloudinaryUploadPreset != null &&
                cloudinaryUploadPreset!.isNotEmpty));

    return {
      'Google Maps': googleMapsStatic.isNotEmpty,
      'AI Chatbot (Gemini)': gemini.isNotEmpty,
      'Image Storage (Cloudinary)': hasCloudinary,
      'Weather Service (OpenWeatherMap)': openWeatherMap.isNotEmpty,
    };
  }

  static String _env(String key) {
    final val = dotenv.env[key];
    return val == null || val.isEmpty ? '' : val;
  }
}
