import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/dz0ypmyur/image/upload';
  static const String _uploadPreset = 'reshot_unsigned';

  /// Uploads a file to Cloudinary using unsigned upload preset.
  /// Traces the file size, existence, and MIME type.
  /// Throws an [Exception] if verification fails or the API call fails.
  static Future<String> uploadImage(String filePath) async {
    debugPrint('CLOUDINARY_LOG [Pipeline Step 1: File Check] Path: $filePath');
    
    final file = File(filePath);
    final exists = await file.exists();
    debugPrint('CLOUDINARY_LOG [Pipeline Step 2: File Existence] Exists: $exists');
    if (!exists) {
      throw Exception('Cloudinary upload failed: Local file does not exist at $filePath');
    }

    final fileLength = await file.length();
    debugPrint('CLOUDINARY_LOG [Pipeline Step 3: File Size] Length: $fileLength bytes (${(fileLength / 1024).toStringAsFixed(2)} KB)');
    if (fileLength == 0) {
      throw Exception('Cloudinary upload failed: Local file at $filePath is empty (0 bytes)');
    }

    // Determine MIME type
    final extension = filePath.split('.').last.toLowerCase();
    MediaType contentType;
    if (extension == 'png') {
      contentType = MediaType('image', 'png');
    } else if (extension == 'gif') {
      contentType = MediaType('image', 'gif');
    } else if (extension == 'webp') {
      contentType = MediaType('image', 'webp');
    } else {
      contentType = MediaType('image', 'jpeg');
    }
    debugPrint('CLOUDINARY_LOG [Pipeline Step 4: MIME Type] Resolved MIME: ${contentType.toString()}');

    debugPrint('CLOUDINARY_LOG [Pipeline Step 5: Multipart Request Construction] Preparing request...');
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath(
        'file', 
        filePath,
        contentType: contentType,
      ));

    debugPrint('CLOUDINARY_LOG [Pipeline Step 6: Sending Request] URL: $_uploadUrl, fields: ${request.fields}');
    
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('CLOUDINARY_LOG [Pipeline Step 7: Cloudinary Response Received] Status Code: ${response.statusCode}');
      debugPrint('CLOUDINARY_LOG [Pipeline Step 7: Cloudinary Response Body] Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String? secureUrl = data['secure_url'] as String?;
        final String? publicId = data['public_id'] as String?;

        if (secureUrl == null || secureUrl.isEmpty) {
          throw Exception('Cloudinary upload validation failed: "secure_url" is missing in response JSON');
        }
        if (publicId == null || publicId.isEmpty) {
          throw Exception('Cloudinary upload validation failed: "public_id" is missing in response JSON');
        }

        debugPrint('CLOUDINARY_LOG [Pipeline Step 8: Upload Success] public_id: $publicId, secure_url: $secureUrl');
        return secureUrl;
      } else {
        throw Exception('Cloudinary upload failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('CLOUDINARY_LOG [Pipeline Step 9: Exception Caught] Error: $e');
      rethrow;
    }
  }
}
