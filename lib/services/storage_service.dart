import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../core/config/api_keys.dart';

/// Service for handling Cloudinary image uploads
///
/// Cloudinary provides:
/// - Free tier: 25 GB storage + 25 GB bandwidth/month
/// - Automatic CORS handling
/// - Image optimization
/// - No billing setup required
class StorageService {
  final String _cloudName;
  final String? _apiKey;
  final String? _apiSecret;

  StorageService({String? cloudName, String? apiKey, String? apiSecret})
    : _cloudName = cloudName ?? ApiKeys.cloudinaryCloudName,
      _apiKey = apiKey ?? ApiKeys.cloudinaryApiKey,
      _apiSecret = apiSecret ?? ApiKeys.cloudinaryApiSecret;

  /// Upload user profile image to Cloudinary
  Future<String?> uploadProfileImage({
    required String userId,
    required Uint8List imageBytes,
    String? contentType = 'image/jpeg',
  }) async {
    try {
      if (_cloudName.isEmpty || _apiKey == null || _apiKey.isEmpty) {
        throw Exception(
          'Cloudinary not configured. Please add Cloudinary credentials to api_keys.dart\n'
          'Get your credentials from: https://cloudinary.com/console',
        );
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = 'profiles/$userId/avatar';

      // Base64 encode the image
      final base64Image = base64Encode(imageBytes);
      final dataUri = 'data:$contentType;base64,$base64Image';

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);

      // Check if we should use upload preset (unsigned) or signed upload
      final useUploadPreset =
          ApiKeys.cloudinaryUploadPreset != null &&
          ApiKeys.cloudinaryUploadPreset!.isNotEmpty;

      if (useUploadPreset) {
        // Use unsigned upload with preset
        request.fields.addAll({
          'file': dataUri,
          'public_id': publicId,
          'folder': 'putrasporthub/profiles',
          'upload_preset': ApiKeys.cloudinaryUploadPreset!,
        });
      } else {
        // Use signed upload (requires API secret)
        if (_apiSecret == null || _apiSecret.isEmpty) {
          throw Exception(
            'Cloudinary requires either an upload preset or API secret.\n'
            'Get your credentials from: https://cloudinary.com/console',
          );
        }

        final apiKey = _apiKey; // Already null-checked above
        final signature = _generateSignature({
          'timestamp': timestamp.toString(),
          'public_id': publicId,
          'folder': 'putrasporthub/profiles',
        });

        request.fields.addAll({
          'file': dataUri,
          'public_id': publicId,
          'folder': 'putrasporthub/profiles',
          'timestamp': timestamp.toString(),
          'signature': signature,
          'api_key': apiKey,
        });
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final secureUrl = data['secure_url'] as String?;

        if (secureUrl != null) {
          debugPrint('✅ Profile image uploaded to Cloudinary: $secureUrl');
          return secureUrl;
        } else {
          throw Exception(
            'Cloudinary response missing secure_url: ${response.body}',
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw Exception(
          'Cloudinary upload failed (${response.statusCode}): $errorMessage',
        );
      }
    } catch (e) {
      debugPrint('❌ Cloudinary upload error: $e');
      rethrow;
    }
  }

  /// Generate signature for signed Cloudinary uploads
  /// Requires apiSecret to be configured
  String _generateSignature(Map<String, String> params) {
    final apiSecret = _apiSecret;
    if (apiSecret == null || apiSecret.isEmpty) {
      throw Exception('API Secret required for signed uploads');
    }

    // Sort parameters alphabetically
    final sortedParams =
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    // Create signature string
    final signatureString = sortedParams
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    final signatureWithSecret = '$signatureString$apiSecret';

    // Generate SHA-1 hash
    final bytes = utf8.encode(signatureWithSecret);
    final hash = sha1.convert(bytes);

    return hash.toString();
  }
}
