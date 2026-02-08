
import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'settings_service.dart';

part 'diet_service.g.dart';

class DietService {
  final Ref ref;

  DietService(this.ref);

  Future<String?> _getApiKey() async {
    return ref.read(settingsServiceProvider).getGeminiKey();
  }

  /// Analyze food text info and return structured data
  /// Returns a Map with description, calories, protein, carbs, fats
  /// Now supports multiple items in one message (e.g., "burger and fries")
  Future<Map<String, dynamic>> analyzeFoodText(String input) async {
    try {
      final apiKey = await _getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return _analyzeOffline(input);
      }

      final prompt = '''
Analyze the following food description and estimate nutrition for EACH item mentioned.
Return a JSON object with:
- "items": array of food objects
- Each object must have: "description" (string), "calories" (int), "protein" (double), "carbs" (double), "fats" (double), "fiber" (double), "sugar" (double), "sodium" (double)

Examples:
Input: "chicken burger and fries"
Output: {
  "items": [
    {"description": "Chicken Burger", "calories": 450, "protein": 28.0, "carbs": 42.0, "fats": 18.0, "fiber": 2.0, "sugar": 6.0, "sodium": 850.0},
    {"description": "French Fries", "calories": 365, "protein": 4.0, "carbs": 48.0, "fats": 17.0, "fiber": 4.0, "sugar": 0.3, "sodium": 246.0}
  ]
}

Input: "apple"
Output: {
  "items": [
    {"description": "Apple", "calories": 95, "protein": 0.5, "carbs": 25.0, "fats": 0.3, "fiber": 4.4, "sugar": 19.0, "sodium": 2.0}
  ]
}

If the input is not food, return {"error": "not food"}.

Input: "$input"
      ''';

      final response = await _generateWithFallback([Content.text(prompt)], apiKey, useJson: true);
      
      final Map<String, dynamic> data = jsonDecode(response.text!);
      if (data.containsKey('error')) {
         return _analyzeOffline(input);
      }
      
      // Return the full response with items array
      return data;
    } catch (e) {
      // debugPrint('DietService Error: $e');
      return _analyzeOffline(input);
    }
  }

  Future<Map<String, dynamic>> analyzeFoodImage(Uint8List imageBytes) async { 
    final apiKey = await _getApiKey();
    if (apiKey == null) throw Exception('API Key not found');

    const prompt = 'Identify the food in this image and estimate nutrition. Return ONLY a JSON object with a key "items" which is an array of objects. Each object must have keys: "description", "calories", "protein", "carbs", "fats".';
    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    final response = await _generateWithFallback(content, apiKey, useJson: true);
    final decoded = jsonDecode(response.text!);
    
    // Ensure structure is correct (sometimes AI returns just the object if only one item)
    if (decoded is Map<String, dynamic> && !decoded.containsKey('items')) {
      return {'items': [decoded]};
    }
    
    return decoded;
  }

  Future<GenerateContentResponse> _generateWithFallback(
    List<Content> content,
    String apiKey, {
    bool useJson = false,
  }) async {
    final preferredModel = await ref.read(settingsServiceProvider).getGeminiModel();
    // Updated 2026 Model Priority List
    final modelsToTry = [
      preferredModel,
      'gemini-3.0-flash',
      'gemini-3.0-pro-preview',
      'gemini-2.0-flash',
      'gemini-2.0-flash-lite-preview-02-05',
      'gemini-2.0-pro-experimental-02-05',
      'gemini-1.5-flash',
      'gemini-1.5-pro',
      'gemini-1.5-flash-8b',
    ];

    // Remove duplicates while preserving order
    final uniqueModels = modelsToTry.toSet().toList();

    Object? lastError;
    for (final modelName in uniqueModels) {
      try {
        // debugPrint('DietAI: Trying $modelName...');
        final model = GenerativeModel(
          model: modelName, 
          apiKey: apiKey,
          generationConfig: useJson ? GenerationConfig(responseMimeType: 'application/json') : null,
        );
        final response = await model.generateContent(content);
        // debugPrint('DietAI: Success with $modelName');
        return response;
      } catch (e) {
        // debugPrint('DietAI: Error with $modelName: $e');
        lastError = e;
      }
    }
    throw lastError ?? Exception('All models failed');
  }

  /// Simple offline fallback using exact phrase matching
  /// Preserves user's original input to avoid unwanted auto-corrections
  Map<String, dynamic> _analyzeOffline(String input) {
    final lower = input.toLowerCase().trim();
    
    // Exact phrase matches - prevents "chicken burger" from becoming "Chicken Breast"
    final exactMatches = <String, Map<String, dynamic>>{
      // Chicken dishes
      'chicken breast': {'description': 'Chicken Breast', 'calories': 165, 'protein': 31.0, 'carbs': 0.0, 'fats': 3.6, 'fiber': 0.0, 'sugar': 0.0, 'sodium': 74.0},
      'grilled chicken': {'description': 'Grilled Chicken', 'calories': 165, 'protein': 31.0, 'carbs': 0.0, 'fats': 3.6, 'fiber': 0.0, 'sugar': 0.0, 'sodium': 74.0},
      'fried chicken': {'description': 'Fried Chicken', 'calories': 320, 'protein': 24.0, 'carbs': 12.0, 'fats': 19.0, 'fiber': 0.5, 'sugar': 0.0, 'sodium': 480.0},
      'chicken burger': {'description': 'Chicken Burger', 'calories': 450, 'protein': 28.0, 'carbs': 42.0, 'fats': 18.0, 'fiber': 2.0, 'sugar': 6.0, 'sodium': 850.0},
      'chicken sandwich': {'description': 'Chicken Sandwich', 'calories': 450, 'protein': 28.0, 'carbs': 42.0, 'fats': 18.0, 'fiber': 2.0, 'sugar': 6.0, 'sodium': 850.0},
      'chicken wings': {'description': 'Chicken Wings', 'calories': 290, 'protein': 27.0, 'carbs': 0.0, 'fats': 20.0, 'fiber': 0.0, 'sugar': 0.0, 'sodium': 360.0},
      
      // Eggs
      'egg': {'description': 'Egg', 'calories': 78, 'protein': 6.3, 'carbs': 0.6, 'fats': 5.3, 'fiber': 0.0, 'sugar': 0.6, 'sodium': 62.0},
      'eggs': {'description': 'Eggs (2)', 'calories': 155, 'protein': 13.0, 'carbs': 1.1, 'fats': 11.0, 'fiber': 0.0, 'sugar': 1.1, 'sodium': 124.0},
      'boiled egg': {'description': 'Boiled Egg', 'calories': 78, 'protein': 6.3, 'carbs': 0.6, 'fats': 5.3, 'fiber': 0.0, 'sugar': 0.6, 'sodium': 62.0},
      'scrambled eggs': {'description': 'Scrambled Eggs', 'calories': 200, 'protein': 13.0, 'carbs': 2.0, 'fats': 15.0, 'fiber': 0.0, 'sugar': 1.0, 'sodium': 340.0},
      
      // Carbs
      'rice': {'description': 'Rice (1 cup)', 'calories': 205, 'protein': 4.3, 'carbs': 45.0, 'fats': 0.4, 'fiber': 0.6, 'sugar': 0.1, 'sodium': 2.0},
      'white rice': {'description': 'White Rice (1 cup)', 'calories': 205, 'protein': 4.3, 'carbs': 45.0, 'fats': 0.4, 'fiber': 0.6, 'sugar': 0.1, 'sodium': 2.0},
      'brown rice': {'description': 'Brown Rice (1 cup)', 'calories': 216, 'protein': 5.0, 'carbs': 45.0, 'fats': 1.8, 'fiber': 3.5, 'sugar': 0.7, 'sodium': 10.0},
      'pasta': {'description': 'Pasta (1 cup)', 'calories': 220, 'protein': 8.0, 'carbs': 43.0, 'fats': 1.3, 'fiber': 2.5, 'sugar': 0.8, 'sodium': 1.0},
      'bread': {'description': 'Bread (1 slice)', 'calories': 79, 'protein': 2.7, 'carbs': 15.0, 'fats': 1.0, 'fiber': 0.8, 'sugar': 1.5, 'sodium': 147.0},
      
      // Fruits
      'apple': {'description': 'Apple', 'calories': 95, 'protein': 0.5, 'carbs': 25.0, 'fats': 0.3, 'fiber': 4.4, 'sugar': 19.0, 'sodium': 2.0},
      'banana': {'description': 'Banana', 'calories': 105, 'protein': 1.3, 'carbs': 27.0, 'fats': 0.3, 'fiber': 3.1, 'sugar': 14.0, 'sodium': 1.0},
      'orange': {'description': 'Orange', 'calories': 62, 'protein': 1.2, 'carbs': 15.0, 'fats': 0.2, 'fiber': 3.1, 'sugar': 12.0, 'sodium': 0.0},
      
      // Common meals
      'burger': {'description': 'Burger', 'calories': 540, 'protein': 25.0, 'carbs': 45.0, 'fats': 27.0, 'fiber': 2.0, 'sugar': 8.0, 'sodium': 1050.0},
      'pizza': {'description': 'Pizza (1 slice)', 'calories': 285, 'protein': 12.0, 'carbs': 36.0, 'fats': 10.0, 'fiber': 2.0, 'sugar': 4.0, 'sodium': 640.0},
      'fries': {'description': 'French Fries', 'calories': 365, 'protein': 4.0, 'carbs': 48.0, 'fats': 17.0, 'fiber': 4.0, 'sugar': 0.3, 'sodium': 246.0},
      'french fries': {'description': 'French Fries', 'calories': 365, 'protein': 4.0, 'carbs': 48.0, 'fats': 17.0, 'fiber': 4.0, 'sugar': 0.3, 'sodium': 246.0},
      'salad': {'description': 'Salad', 'calories': 150, 'protein': 3.0, 'carbs': 15.0, 'fats': 9.0, 'fiber': 4.0, 'sugar': 5.0, 'sodium': 300.0},
    };
    
    // Check for exact match first
    if (exactMatches.containsKey(lower)) {
      // Wrap in items array for consistency with AI response
      return {'items': [exactMatches[lower]!]};
    }
    
    // No exact match - preserve user's original input
    // This prevents unwanted auto-corrections like "chicken burger" → "Chicken Breast"
    return {
      'items': [{
        'description': input, // Keep original user input!
        'calories': 0, 
        'protein': 0.0, 
        'carbs': 0.0, 
        'fats': 0.0,
        'fiber': 0.0,
        'sugar': 0.0,
        'sodium': 0.0,
      }]
    };
  }
}

@riverpod
DietService dietService(Ref ref) {
  return DietService(ref);
}
