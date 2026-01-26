
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
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API Key not found. Please add it in Settings.');
    }

    final model = GenerativeModel(
      model: 'gemini-3-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
    
    final prompt = '''
    Analyze the following food description and estimate the nutrition facts.
    Return ONLY a JSON object with keys: "description" (short summarized name), "calories" (int), "protein" (double), "carbs" (double), "fats" (double).
    If the input is not food, return {"error": "not food"}.
    
    Input: "$input"
    ''';

    final response = await model.generateContent([Content.text(prompt)]);
    
    if (response.text != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.text!);
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }
        return data;
      } catch (e) {
        throw Exception('Failed to parse Gemini response: ${response.text}');
      }
    } else {
      throw Exception('Empty response from Gemini');
    }
  }
  Future<Map<String, dynamic>> analyzeFoodImage(Uint8List imageBytes) async { 
     final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('Gemini API Key not found');
    }

    final model = GenerativeModel(
      model: 'gemini-3-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
    
    const prompt = 'Identify the food in this image and estimate nutrition. Return ONLY a JSON object with keys: "description" (short name), "calories" (int), "protein" (double), "carbs" (double), "fats" (double).';
    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    final response = await model.generateContent(content);

    if (response.text != null) {
      try {
         final Map<String, dynamic> data = jsonDecode(response.text!);
         return data;
      } catch (e) {
        throw Exception('Failed to parse Gemini response: ${response.text}');
      }
    } else {
      throw Exception('Empty response from Gemini');
    }
  }
}

@riverpod
DietService dietService(Ref ref) {
  return DietService(ref);
}
