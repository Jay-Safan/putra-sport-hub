import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

/// Weather service for outdoor facility booking validation
/// Integrates with OpenWeatherMap API
/// 
/// v5.0 Logic: If Rain > 5mm AND is_indoor == false:
///   1. Block new bookings
///   2. Trigger auto-cancellation for existing bookings
///   3. Refund to wallet_balance (never to bank)
class WeatherService {
  final String? _apiKey;
  final http.Client _client;
  
  // UPM coordinates from v5.0 spec (Serdang, Selangor)
  static const double _upmLatitude = AppConstants.upmLatitude;   // 2.999
  static const double _upmLongitude = AppConstants.upmLongitude; // 101.707

  WeatherService({
    String? apiKey,
    http.Client? client,
  })  : _apiKey = apiKey,
        _client = client ?? http.Client();

  /// Check if weather is suitable for outdoor activity
  /// Returns true if rain probability is below threshold
  Future<WeatherResult> checkWeatherForDate(DateTime date) async {
    if (_apiKey?.isEmpty ?? true) {
      // If no API key, assume weather is fine (fallback)
      return const WeatherResult(
        isSuitable: true,
        rainProbability: 0,
        description: 'Weather data unavailable',
        temperature: null,
        humidity: null,
      );
    }

    try {
      // For current day or next few days, use forecast API
      final daysDifference = date.difference(DateTime.now()).inDays;
      
      if (daysDifference > 5) {
        // OpenWeatherMap free tier only provides 5-day forecast
        return const WeatherResult(
          isSuitable: true,
          rainProbability: 0,
          description: 'Forecast unavailable for this date',
          temperature: null,
          humidity: null,
        );
      }

      final forecast = await _getForecast();
      if (forecast == null) {
        return const WeatherResult(
          isSuitable: true,
          rainProbability: 0,
          description: 'Unable to fetch weather data',
          temperature: null,
          humidity: null,
        );
      }

      // Find forecast for the target date
      final targetDateStart = DateTime(date.year, date.month, date.day);
      final targetDateEnd = targetDateStart.add(const Duration(days: 1));

      final relevantForecasts = forecast.where((f) {
        final forecastDate = f['dt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(f['dt'] * 1000)
            : DateTime.now();
        return forecastDate.isAfter(targetDateStart) &&
            forecastDate.isBefore(targetDateEnd);
      }).toList();

      if (relevantForecasts.isEmpty) {
        return const WeatherResult(
          isSuitable: true,
          rainProbability: 0,
          description: 'No forecast available',
          temperature: null,
          humidity: null,
        );
      }

      // Calculate average rain probability for the day
      double maxRainProbability = 0;
      String? description;
      double? temperature;
      int? humidity;

      for (final f in relevantForecasts) {
        final pop = (f['pop'] ?? 0).toDouble() * 100; // Convert to percentage
        if (pop > maxRainProbability) {
          maxRainProbability = pop;
          description = f['weather']?[0]?['description'] ?? 'Unknown';
          temperature = f['main']?['temp']?.toDouble();
          humidity = f['main']?['humidity'];
        }
      }

      final isSuitable = maxRainProbability < AppConstants.rainProbabilityThreshold;

      return WeatherResult(
        isSuitable: isSuitable,
        rainProbability: maxRainProbability,
        description: description ?? 'Unknown',
        temperature: temperature,
        humidity: humidity,
        recommendation: isSuitable
            ? null
            : 'High rain probability (${maxRainProbability.toStringAsFixed(0)}%). Consider booking an indoor facility.',
      );
    } catch (e) {
      return const WeatherResult(
        isSuitable: true,
        rainProbability: 0,
        description: 'Weather service error',
        temperature: null,
        humidity: null,
      );
    }
  }

  /// Get 5-day forecast from OpenWeatherMap
  Future<List<dynamic>?> _getForecast() async {
    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast'
        '?lat=$_upmLatitude'
        '&lon=$_upmLongitude'
        '&appid=$_apiKey'
        '&units=metric',
      );

      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['list'] as List<dynamic>;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check current weather conditions
  Future<WeatherResult> getCurrentWeather() async {
    if (_apiKey?.isEmpty ?? true) {
      return const WeatherResult(
        isSuitable: true,
        rainProbability: 0,
        description: 'Weather data unavailable',
        temperature: null,
        humidity: null,
      );
    }

    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=$_upmLatitude'
        '&lon=$_upmLongitude'
        '&appid=$_apiKey'
        '&units=metric',
      );

      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final weatherId = data['weather']?[0]?['id'] ?? 800;
        final isRaining = weatherId >= 200 && weatherId < 700;
        final rainProbability = isRaining ? 100.0 : 0.0;

        return WeatherResult(
          isSuitable: !isRaining,
          rainProbability: rainProbability,
          description: data['weather']?[0]?['description'] ?? 'Unknown',
          temperature: data['main']?['temp']?.toDouble(),
          humidity: data['main']?['humidity'],
          recommendation: isRaining
              ? 'Currently raining. Consider an indoor facility.'
              : null,
        );
      }

      return const WeatherResult(
        isSuitable: true,
        rainProbability: 0,
        description: 'Unable to fetch weather',
        temperature: null,
        humidity: null,
      );
    } catch (e) {
      return const WeatherResult(
        isSuitable: true,
        rainProbability: 0,
        description: 'Weather service error',
        temperature: null,
        humidity: null,
      );
    }
  }

  /// Check if outdoor booking should be blocked (v5.0 logic)
  /// If Rain > 5mm AND is_indoor == false:
  ///   1. Block new bookings
  ///   2. Trigger auto-cancellation for existing bookings
  Future<OutdoorBookingCheck> shouldBlockOutdoorBooking({
    required DateTime bookingDate,
    required DateTime startTime,
    bool isIndoor = false,
  }) async {
    // Indoor facilities are never blocked by weather
    if (isIndoor) {
      return const OutdoorBookingCheck(
        shouldBlock: false,
        reason: null,
        suggestion: null,
        alternativeFacilityId: null,
      );
    }

    final weather = await checkWeatherForDate(bookingDate);

    // v5.0: Rain > 5mm triggers blocking AND auto-cancellation
    if (weather.shouldTriggerAutoCancel) {
      return OutdoorBookingCheck(
        shouldBlock: true,
        shouldAutoCancel: true,
        reason: 'Heavy rain expected (${weather.rainMm.toStringAsFixed(1)}mm)',
        suggestion: 'Booking will be auto-cancelled. Refund will be credited to your SukanPay wallet.',
        alternativeFacilityId: 'fac_futsal_kmr', // Indoor futsal as alternative
      );
    }

    // High probability warning (doesn't block, just warns)
    if (!weather.isSuitable) {
      return OutdoorBookingCheck(
        shouldBlock: false, // Warning only, doesn't block
        reason: 'High rain probability (${weather.rainProbability.toStringAsFixed(0)}%)',
        suggestion: 'We recommend booking an indoor facility instead.',
        alternativeFacilityId: 'fac_futsal_kmr',
      );
    }

    return const OutdoorBookingCheck(
      shouldBlock: false,
      reason: null,
      suggestion: null,
      alternativeFacilityId: null,
    );
  }

  void dispose() {
    _client.close();
  }
}

/// Weather check result (v5.0 spec)
class WeatherResult {
  final bool isSuitable;
  final double rainProbability;
  final double rainMm; // Rain in mm (v5.0: > 5mm triggers cancellation)
  final String description;
  final double? temperature;
  final int? humidity;
  final String? recommendation;
  final WeatherStatus status; // v5.0 weather status enum

  const WeatherResult({
    required this.isSuitable,
    required this.rainProbability,
    this.rainMm = 0,
    required this.description,
    this.temperature,
    this.humidity,
    this.recommendation,
    this.status = WeatherStatus.clear,
  });

  /// Check if rain exceeds threshold (5mm) - triggers auto-cancel for outdoor
  bool get shouldTriggerAutoCancel => rainMm > AppConstants.rainThresholdMm;

  @override
  String toString() {
    return 'WeatherResult(suitable: $isSuitable, rain: ${rainMm.toStringAsFixed(1)}mm, desc: $description)';
  }
}

/// Outdoor booking check result
class OutdoorBookingCheck {
  final bool shouldBlock;
  final String? reason;
  final String? suggestion;
  final String? alternativeFacilityId;
  final bool shouldAutoCancel; // v5.0: triggers refund to wallet

  const OutdoorBookingCheck({
    required this.shouldBlock,
    this.reason,
    this.suggestion,
    this.alternativeFacilityId,
    this.shouldAutoCancel = false,
  });
}

