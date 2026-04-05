import 'dart:convert';
import 'dart:math';

/// Utility class for QR code generation and team code management
class QRUtils {
  static final Random _random = Random();

  /// Generate a unique QR code data string for booking check-in
  static String generateBookingQR({
    required String bookingId,
    required String refereeJobId,
    required String facilityName,
    required DateTime dateTime,
  }) {
    final data = {
      'type': 'BOOKING_CHECKIN',
      'booking_id': bookingId,
      'job_id': refereeJobId,
      'facility': facilityName,
      'timestamp': dateTime.toIso8601String(),
      'code': _generateRandomCode(8),
    };
    return base64Encode(utf8.encode(jsonEncode(data)));
  }

  /// Generate a unique QR code for referee check-in
  static String generateRefereeQR({
    required String jobId,
    required String refereeId,
    required String refereeName,
  }) {
    final data = {
      'type': 'REFEREE_CHECKIN',
      'job_id': jobId,
      'referee_id': refereeId,
      'referee_name': refereeName,
      'code': _generateRandomCode(8),
      'generated_at': DateTime.now().toIso8601String(),
    };
    return base64Encode(utf8.encode(jsonEncode(data)));
  }

  /// Parse QR code data
  static Map<String, dynamic>? parseQRData(String qrData) {
    try {
      final decoded = utf8.decode(base64Decode(qrData));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Validate QR code data for booking check-in
  static bool validateBookingQR(String qrData, String expectedBookingId) {
    final data = parseQRData(qrData);
    if (data == null) return false;
    return data['type'] == 'BOOKING_CHECKIN' &&
        data['booking_id'] == expectedBookingId;
  }

  /// Validate QR code data for referee check-in
  static bool validateRefereeQR(String qrData, String expectedJobId) {
    final data = parseQRData(qrData);
    if (data == null) return false;
    return data['type'] == 'REFEREE_CHECKIN' && data['job_id'] == expectedJobId;
  }

  /// Generate a random alphanumeric code
  static String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }
}
