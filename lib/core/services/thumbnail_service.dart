import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_service.dart';

/// Service to provide workout thumbnail images
class ThumbnailService {
  final Ref ref;
  
  ThumbnailService(this.ref);

  // Keyword-based fallback images (Unsplash)
  final Map<String, List<String>> _keywordMap = {
    'push': [
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=1000&q=80', // Pushups
      'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=1000&q=80', // Bench/Barbell
      'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&w=1000&q=80', // Weights
    ],
    'chest': [
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=1000&q=80', // Pushups
      'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=1000&q=80', // Bench
    ],
    'bench': [
      'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=1000&q=80', // Bench
    ],
    'pull': [
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=1000&q=80', // Back/Pullups
      'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?auto=format&fit=crop&w=1000&q=80', // Rows/Lifting
      'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?auto=format&fit=crop&w=1000&q=80', // Equipment
    ],
    'back': [
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=1000&q=80', // Back
    ],
    'legs': [
      'https://images.unsplash.com/photo-1434608519344-49d77a699ded?auto=format&fit=crop&w=1000&q=80', // Squat/Stretch
      'https://images.unsplash.com/photo-1574680096141-1cddd32e012e?auto=format&fit=crop&w=1000&q=80', // Lunges
      'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?auto=format&fit=crop&w=1000&q=80', // Running/Legs
    ],
    'squat': [
      'https://images.unsplash.com/photo-1434608519344-49d77a699ded?auto=format&fit=crop&w=1000&q=80', // Squat
      'https://images.unsplash.com/photo-1574680096141-1cddd32e012e?auto=format&fit=crop&w=1000&q=80', // Lunges
    ],
    'cardio': [
      'https://images.unsplash.com/photo-1538805060512-e2596d6aade0?auto=format&fit=crop&w=1000&q=80', // Running track
      'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?auto=format&fit=crop&w=1000&q=80', // Running man
      'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?auto=format&fit=crop&w=1000&q=80', // Athletics
    ],
    'run': [
      'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?auto=format&fit=crop&w=1000&q=80', // Running man
      'https://images.unsplash.com/photo-1538805060512-e2596d6aade0?auto=format&fit=crop&w=1000&q=80', // Track
    ],
    'yoga': [
      'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=1000&q=80', // Meditating
      'https://images.unsplash.com/photo-1544367563-12123d896589?auto=format&fit=crop&w=1000&q=80', // Yoga pose
    ],
    'stretch': [
      'https://images.unsplash.com/photo-1434608519344-49d77a699ded?auto=format&fit=crop&w=1000&q=80', // Stretch
    ],
    'abs': [
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=1000&q=80', // Core/Pushups
      'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff?auto=format&fit=crop&w=1000&q=80', // Home core
    ],
    'core': [
      'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff?auto=format&fit=crop&w=1000&q=80', // Home core
    ],
  };
  
  // Flattened list of all available images for general display
  List<String> get _thumbnails => _keywordMap.values.expand((element) => element).toSet().toList();

  /// Search for images using Pexels API, falling back to local smart-search
  Future<List<String>> searchImages(String query) async {
    // 1. If query is empty, return mixed featured list
    if (query.trim().isEmpty) {
      return [..._thumbnails]..shuffle();
    }
    
    // 2. Try Pexels API if key exists
    final settings = ref.read(settingsServiceProvider);
    final pexelsKey = await settings.getPexelsKey();
    
    if (pexelsKey != null && pexelsKey.isNotEmpty) {
      try {
        final results = await _searchPexels(query, pexelsKey);
        if (results.isNotEmpty) return results;
      } catch (e) {
        print('Pexels search failed: $e. Falling back to local.');
      }
    }
    
    // 3. Fallback: Local Keyword Search
    // Simulate slight delay for realism
    await Future.delayed(const Duration(milliseconds: 300));
    return _localSearch(query);
  }
  
  List<String> _localSearch(String query) {
    final lowerQuery = query.toLowerCase();
    final Set<String> results = {};
    
    // Direct matches in keyword map
    _keywordMap.forEach((key, urls) {
      if (lowerQuery.contains(key) || key.contains(lowerQuery)) {
        results.addAll(urls);
      }
    });
    
    // If we found specific matches, return them (plus a few randoms for variety)
    if (results.isNotEmpty) {
      final variety = [..._thumbnails]..shuffle();
      return [...results, ...variety.take(4)];
    }
    
    // If no specific match, return shuffled general list
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
