// services/cloudinary_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  // Ganti dengan credentials Cloudinary kamu
  static const String cloudName =
      'dza6qy2jw'; // Ganti dengan cloud name kamu
  static const String uploadPreset =
      'flutter_upload'; // Ganti dengan upload preset kamu
  static const String apiKey =
      '781568637671818'; // Optional, tapi lebih baik pakai

  /// Upload single image ke Cloudinary
  /// Returns URL gambar yang sudah di-upload
  static Future<String?> uploadImage(File imageFile, {String? folder}) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url);

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Add upload preset
      request.fields['upload_preset'] = uploadPreset;

      // Optional: Add folder organization
      if (folder != null) {
        request.fields['folder'] = folder;
      }

      // Send request
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = json.decode(responseString);

        // Return secure URL
        return jsonMap['secure_url'];
      } else {
        print('Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  /// Upload multiple images ke Cloudinary
  /// Returns list of URLs
  static Future<List<String>> uploadMultipleImages(
    List<File> imageFiles, {
    String? folder,
  }) async {
    final List<String> uploadedUrls = [];

    for (final imageFile in imageFiles) {
      final url = await uploadImage(imageFile, folder: folder);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }
}
