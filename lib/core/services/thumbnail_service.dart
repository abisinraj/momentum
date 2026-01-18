import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_service.dart';

/// Service to provide workout thumbnail images
class ThumbnailService {
  final Ref ref;
  
  ThumbnailService(this.ref);

  // curated list of high-quality fitness images from Unsplash (Fallback)
  final List<String> _thumbnails = [
    'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', // Barbell gym
    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', // Muscular back
    'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', // Pushups info
    'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', // Gym weights
    'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', // Home workout
    'https://images.unsplash.com/photo-1574680096141-1cddd32e012e?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', // Dumbbells
    'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', // Weight lifting
    'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', // Gym equipment
    'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', // Man running
    'https://images.unsplash.com/photo-1434608519344-49d77a699ded?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', // Yoga/stretch
    'https://images.unsplash.com/photo-1518611012118-696072aa579a?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', // Women fitness
    'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', // Athletics
  ];

  Future<List<String>> searchImages(String query) async {
    // Try to get dynamic keys
    final settings = ref.read(settingsServiceProvider);
    final pexelsKey = await settings.getPexelsKey();
    
    // Use Pexels API if key is present
    if (pexelsKey != null && pexelsKey.isNotEmpty) {
      try {
        final results = await _searchPexels(query, pexelsKey);
        if (results.isNotEmpty) return results;
      } catch (e) {
        print('Pexels search failed: $e');
        // fall through to fallback
      }
    }
    
    // Simulate network delay for fallback
    await Future.delayed(const Duration(milliseconds: 500));
    return [..._thumbnails]..shuffle();
  }
  
  Future<List<String>> _searchPexels(String query, String apiKey) async {
    final uri = Uri.parse('https://api.pexels.com/v1/search?query=$query&per_page=30');
    final response = await http.get(uri, headers: {
      'Authorization': apiKey,
    });
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final photos = data['photos'] as List;
      return photos.map<String>((p) => p['src']['medium'] as String).toList();
    }
    throw Exception('Pexels API error: ${response.statusCode}');
  }
  
  List<String> getFeaturedImages() {
    return _thumbnails;
  }
}

final thumbnailServiceProvider = Provider<ThumbnailService>((ref) {
  return ThumbnailService(ref);
});
