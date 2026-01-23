
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'settings_service.dart';

part 'diet_service.g.dart';

class DietService {
  final Ref ref;

  DietService(this.ref);

  Future<String?> _getApiKey() async {
    return ref.read(settingsServiceProvider).getOpenAiKey();
  }

  /// Analyze food text info and return structured data
  /// Returns a Map with description, calories, protein, carbs, fats
  Future<Map<String, dynamic>> analyzeFoodText(String input) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API Key not found');
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    
    final prompt = '''
    Analyze the following food description and estimate the nutrition facts.
    Return ONLY a JSON object with keys: "description" (short summarized name), "calories" (int), "protein" (double), "carbs" (double), "fats" (double).
    If the input is not food, return "error": "not food".
    
    Input: "$input"
    ''';

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o', // or gpt-3.5-turbo
        'messages': [
          {'role': 'system', 'content': 'You are a nutritionist assistant. Output strict JSON.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
        'response_format': { "type": "json_object" }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return jsonDecode(content);
    } else {
      throw Exception('Failed to analyze food: ${response.body}');
    }
  }

  /// Analyze food image using GPT-4 Vision
  Future<Map<String, dynamic>> analyzeFoodImage(String imagePath) async {
     final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API Key not found');
    }

    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);
    
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o', 
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Identify the food in this image and estimate nutrition. Return ONLY a JSON object with keys: "description" (short name), "calories" (int), "protein" (double), "carbs" (double), "fats" (double).'},
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                  'detail': 'low'
                }
              }
            ]
          }
        ],
        'max_tokens': 300,
        'response_format': { "type": "json_object" }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return jsonDecode(content);
    } else {
      throw Exception('Failed to analyze image: ${response.body}');
    }
  }
}

@riverpod
DietService dietService(DietServiceRef ref) {
  return DietService(ref);
}
