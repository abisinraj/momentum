import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ImageStorageService {
  /// Downloads an image from a URL and saves it locally.
  /// Returns the local file path.
  static Future<String> saveImageOffline(String url) async {
    try {
      if (url.startsWith('assets/') || url.startsWith('file://') || !url.startsWith('http')) {
        return url; // Already local or asset
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${directory.path}/workout_images');
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }

        // Generate a unique filename based on the URL
        final bytes = utf8.encode(url);
        final digest = md5.convert(bytes);
        final extension = path.extension(url).split('?').first; // Remove query params
        final fileName = '${digest.toString()}${extension.isEmpty ? '.jpg' : extension}';
        final localFile = File('${imagesDir.path}/$fileName');

        await localFile.writeAsBytes(response.bodyBytes);
        debugPrint('Image saved offline: ${localFile.path}');
        return localFile.path;
      }
      return url; // Fallback to URL if download fails
    } catch (e) {
      debugPrint('Error saving image offline: $e');
      return url;
    }
  }

  /// Deletes a local image file if it exists.
  static Future<void> deleteLocalImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting local image: $e');
    }
  }
}
