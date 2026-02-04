
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
  Future<Map<String, dynamic>> analyzeFoodText(String input) async {
    try {
      final apiKey = await _getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return _analyzeOffline(input);
      }

      final prompt = '''
      Analyze the following food description and estimate the nutrition facts.
      Return ONLY a JSON object with keys: "description" (short summarized name), "calories" (int), "protein" (double), "carbs" (double), "fats" (double), "fiber" (double), "sugar" (double), "sodium" (double).
      If the input is not food, return {"error": "not food"}.
      
      Input: "$input"
      ''';

      final response = await _generateWithFallback([Content.text(prompt)], apiKey, useJson: true);
      
      final Map<String, dynamic> data = jsonDecode(response.text!);
      if (data.containsKey('error')) {
         return _analyzeOffline(input);
      }
      return data;
    } catch (e) {
      // debugPrint('DietService Error: $e');
      return _analyzeOffline(input);
    }
  }

  Future<Map<String, dynamic>> analyzeFoodImage(Uint8List imageBytes) async { 
    final apiKey = await _getApiKey();
    if (apiKey == null) throw Exception('API Key not found');

    const prompt = 'Identify the food in this image and estimate nutrition. Return ONLY a JSON object with keys: "description", "calories", "protein", "carbs", "fats".';
    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    final response = await _generateWithFallback(content, apiKey, useJson: true);
    return jsonDecode(response.text!);
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

  /// Simple offline fallback using keyword matching
  Map<String, dynamic> _analyzeOffline(String input) {
    final lower = input.toLowerCase();
    
    // Very basic database
    if (lower.contains('chicken') || lower.contains('breast')) {
       return {'description': 'Chicken Breast (Est)', 'calories': 165, 'protein': 31.0, 'carbs': 0.0, 'fats': 3.6, 'fiber': 0.0, 'sugar': 0.0, 'sodium': 74.0};
    } else if (lower.contains('egg')) {
       return {'description': 'Eggs (Est)', 'calories': 155, 'protein': 13.0, 'carbs': 1.1, 'fats': 11.0, 'fiber': 0.0, 'sugar': 1.1, 'sodium': 124.0};
    } else if (lower.contains('rice')) {
       return {'description': 'Rice (Est)', 'calories': 130, 'protein': 2.7, 'carbs': 28.0, 'fats': 0.3, 'fiber': 0.4, 'sugar': 0.1, 'sodium': 1.0};
    } else if (lower.contains('apple')) {
       return {'description': 'Apple (Est)', 'calories': 95, 'protein': 0.5, 'carbs': 25.0, 'fats': 0.3, 'fiber': 4.4, 'sugar': 19.0, 'sodium': 2.0};
    } else if (lower.contains('banana')) {
       return {'description': 'Banana (Est)', 'calories': 105, 'protein': 1.3, 'carbs': 27.0, 'fats': 0.3, 'fiber': 3.1, 'sugar': 14.0, 'sodium': 1.0};
    }

    // Generic Fallback
    return {
      'description': input, 
      'calories': 0, 
      'protein': 0.0, 
      'carbs': 0.0, 
      'fats': 0.0,
      'fiber': 0.0,
      'sugar': 0.0,
      'sodium': 0.0,
    };
  }
}

@riverpod
DietService dietService(Ref ref) {
  return DietService(ref);
}
