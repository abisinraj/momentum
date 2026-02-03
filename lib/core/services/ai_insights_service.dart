import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:momentum/core/database/app_database.dart';
import 'package:http/http.dart' as http;

class AIInsightResponse {
  final String text;
  final String mood; // fire, calm, warning, hero
  final String type; // trend, milestone, recovery, diet_prompt, general

  AIInsightResponse({
    required this.text,
    required this.mood,
    required this.type,
  });

  factory AIInsightResponse.fromJson(Map<String, dynamic> json) {
    return AIInsightResponse(
      text: json['text'] ?? "Consistency is key. Keep pushing forward!",
      mood: json['mood'] ?? "hero",
      type: json['type'] ?? "general",
    );
  }
}

class AIInsightsService {
  // TODO: Ideally, move this to a secure backend or use --dart-define
  // For this prototype, we will use a placeholder or ask the user to input it.
  // We'll store it in SharedPreferences for now if provided by user.
  static const String _defaultApiKey = 'YOUR_API_KEY_HERE'; 

  Future<AIInsightResponse> getDailyInsight({
    required User user,
    required List<Map<String, dynamic>> recentSessions,
    required Map<String, dynamic> allTimeStats,
    required List<Map<String, dynamic>> volumeTrend,
    required int? hoursSinceLastMeal,
    required String? apiKey,
    String? preferredModel,
  }) async {
    try {
      if (apiKey == null || apiKey == _defaultApiKey || apiKey.isEmpty) {
        return AIInsightResponse(
          text: "Configure your Gemini API Key in Settings to unlock AI insights.",
          mood: "warning",
          type: "general",
        );
      }

      // Latest session recovery score check
      final recoveryScore = recentSessions.isNotEmpty 
          ? (recentSessions.first['session'] as dynamic).recoveryScore as int? 
          : null;

      final prompt = _constructDetailedPrompt(
        user: user,
        sessions: recentSessions,
        stats: allTimeStats,
        trend: volumeTrend,
        dietGap: hoursSinceLastMeal,
        recovery: recoveryScore,
      );
      
      final content = [Content.text(prompt)];
      
      try {
        final response = await _generateWithFallback(content, apiKey, preferredModel: preferredModel);
        final rawText = response.text?.trim() ?? "";
        
        // Attempt to parse JSON from AI response
        try {
          // Clean typical AI markdown formatting
          final cleanJson = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
          final decoded = json.decode(cleanJson);
          return AIInsightResponse.fromJson(decoded);
        } catch (e) {
          // Fallback if AI fails to return valid JSON
          return AIInsightResponse(
            text: rawText.isNotEmpty ? rawText : "Keep pushing your limits.",
            mood: "hero",
            type: "general",
          );
        }
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      final errorStr = e.toString();
      String text = "Focus on your form and breathing today. You got this!";
      if (errorStr.contains('API_KEY_INVALID')) {
         text = "Invalid API Key. Please check your settings.";
      } else if (errorStr.contains('not found') || errorStr.contains('404')) {
         text = "AI Model unavailable. Focus on your ${user.goal ?? 'goals'} today!";
      } else if (errorStr.contains('User location is not supported')) {
         text = "AI features are not supported in your region yet.";
      }
      return AIInsightResponse(text: text, mood: "warning", type: "general");
    }
  }

  String _constructDetailedPrompt({
    required User user,
    required List<Map<String, dynamic>> sessions,
    required Map<String, dynamic> stats,
    required List<Map<String, dynamic>> trend,
    required int? dietGap,
    required int? recovery,
  }) {
    final goal = user.goal ?? 'General Fitness';
    final weight = user.weightKg != null ? '${user.weightKg}kg' : 'Unknown';
    
    StringBuffer analysis = StringBuffer();
    
    // 1. Consistency & History
    if (sessions.isEmpty) {
      analysis.writeln("User has no recorded workouts yet.");
    } else {
      final lastWorkout = sessions.first;
      final lastDate = lastWorkout['completedAt'] as DateTime?;
      final daysSince = lastDate != null ? DateTime.now().difference(lastDate).inDays : 99;
      analysis.writeln("Last workout was ${daysSince == 0 ? 'today' : '$daysSince days ago'}.");
    }

    // 2. Trends
    if (trend.length >= 2) {
      final latestVolume = trend.last['volume'] as double;
      final prevVolume = trend[trend.length - 2]['volume'] as double;
      final change = prevVolume > 0 ? ((latestVolume - prevVolume) / prevVolume * 100).round() : 0;
      analysis.writeln("Volume Trend: ${change >= 0 ? '+' : ''}$change% compared to previous session.");
    }

    // 3. Milestones
    analysis.writeln("All-time Stats: ${stats['sessions']} sessions, ${stats['sets']} sets, ${stats['reps']} reps.");

    // 4. Recovery
    if (recovery != null) {
      analysis.writeln("Current Recovery Score: $recovery/100.");
    }

    // 5. Diet
    if (dietGap != null) {
      analysis.writeln("Hours since last meal logged: $dietGap.");
    }

    return '''
    You are an elite fitness coach for ${user.name}. 
    
    User Profile:
    - Goal: $goal
    - Weight: $weight
    
    Current Data:
    ${analysis.toString()}
    
    Task:
    Analyze the data and provide a high-impact coaching insight.
    
    Return your response in STRICT JSON format:
    {
      "text": "A single, punchy, motivational sentence (max 20 words).",
      "mood": "Choose one: fire (intense/streak), calm (recovery/deload), warning (inactive/missing data), hero (milestone/high volume)",
      "type": "Choose one: trend, milestone, recovery, diet_prompt, general"
    }

    Priorities:
    1. If dietGap > 4 hours, prioritize a 'diet_prompt'.
    2. If recovery < 40, prioritize 'calm' recovery advice.
    3. If significant volume trend (+10% or more), prioritize 'trend'.
    4. If milestone achieved (e.g. 50, 100 sets), prioritize 'milestone'.
    5. Otherwise, general 'hero' coaching.

    Style: Professional, stoic, inspiring. No emojis.
    ''';
  }

  Future<int?> estimateCalorieBurn({
    required User user,
    required Workout workout,
    required List<SessionExercise> exercises,
    required int durationSeconds,
    required int? intensity,
    required String? apiKey,
    required List<Exercise> exerciseDefinitions,
    String? preferredModel,
  }) async {
    try {
      if (apiKey == null || apiKey == _defaultApiKey || apiKey.isEmpty) {
        // Fallback to MET formula if no API key
        // MET 7.0 for resistance training
        final weight = user.weightKg ?? 70.0;
        final hours = durationSeconds / 3600.0;
        final intensityFactor = (intensity ?? 5) / 5.0;
        return (7.0 * weight * hours * intensityFactor).round();
      }

      // Use robust fallback logic
      final prompt = _constructCaloriePrompt(user, workout, exercises, durationSeconds, intensity, exerciseDefinitions);
      final content = [Content.text(prompt)];
      
      GenerateContentResponse response;
      try {
         response = await _generateWithFallback(content, apiKey, preferredModel: preferredModel);
      } catch (e) {
         return null;
      }

      final text = response.text?.trim() ?? "";
      
      // Extract number from AI response
      final numbers = RegExp(r'\d+').allMatches(text);
      if (numbers.isNotEmpty) {
        return int.parse(numbers.first.group(0)!);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  String _constructCaloriePrompt(
    User user,
    Workout workout,
    List<SessionExercise> sessions,
    int durationSeconds,
    int? intensity,
    List<Exercise> exerciseDefinitions,
  ) {
    final weight = user.weightKg != null ? '${user.weightKg}kg' : '70kg';
    final age = user.age ?? 30;
    
    StringBuffer exerciseList = StringBuffer();
    for (var se in sessions) {
      final def = exerciseDefinitions.firstWhere((e) => e.id == se.exerciseId);
      exerciseList.writeln("- ${def.name}: ${se.completedSets} sets, ${se.completedReps} total reps, weight: ${se.weightKg ?? 'Bodyweight'}");
    }

    return '''
    Task: Estimate calorie burn for a weightlifting session.
    
    User Stats:
    - Weight: $weight
    - Age: $age
    
    Workout Details:
    - Name: ${workout.name}
    - Duration: ${durationSeconds ~/ 60} minutes
    - Intensity (RPE 1-10): ${intensity ?? 'Moderate (5)'}
    
    Exercises Performed:
    ${exerciseList.toString()}
    
    Instructions:
    Return ONLY the estimated number of calories burned as a single integer. No words, no explanation.
    
    Example:
    350
    ''';
  }

  Future<String> analyzeMessage({
    required String text,
    List<int>? imageBytes,
    required String? apiKey,
    String? extraContext,
    String? preferredModel,
  }) async {
    try {
      if (apiKey == null || apiKey == _defaultApiKey || apiKey.isEmpty) {
        return "Please configure your API Key in settings first.";
      }

      // Use robust fallback
      final List<Part> parts = [];
      if (text.isNotEmpty) {
        String finalPrompt = text;
        if (extraContext != null && extraContext.isNotEmpty) {
           finalPrompt = '''
Context for the conversation:
$extraContext

User Message:
$text

Instructions:
- You are an AI fitness and nutrition assistant.
- Use the context above to answer accurately (includes diet, workouts, or goals).
- You can provide feedback on their workout progress or diet balance.
- You CANNOT modify database records directly.
- If context is missing for a specific question, ask the user for details.
- Be encouraging, concise, and professional.
''';
        }
        parts.add(TextPart(finalPrompt));
      }
      
      if (imageBytes != null) {
        parts.add(DataPart('image/jpeg', Uint8List.fromList(imageBytes)));
      }

      final content = [Content.multi(parts)];
      
      GenerateContentResponse response;
      try {
        response = await _generateWithFallback(content, apiKey, preferredModel: preferredModel);
      } catch (e) {
         final errorStr = e.toString();
         if (errorStr.contains('API_KEY_INVALID')) {
           return "Invalid API Key. Please check your settings.";
         } else if (errorStr.contains('User location is not supported')) {
           return "Gemini AI is not supported in your region yet.";
         }
         return "AI Error (check logs): $errorStr";
      }

      return response.text?.trim() ?? "I couldn't understand that context.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }
  Future<GenerateContentResponse> _generateWithFallback(
    List<Content> content,
    String apiKey, {
    String? preferredModel,
  }) async {
    // Updated 2026 Model Priority List
    final modelsToTry = [
      if (preferredModel != null) preferredModel,
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-1.5-pro',
    ];

    // Remove duplicates while preserving order
    final uniqueModels = modelsToTry.toSet().toList();

    Object? lastError;

    for (final modelName in uniqueModels) {
      try {
        debugPrint('AI: Trying model $modelName...');
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final response = await model.generateContent(content);
        debugPrint('AI: Success with $modelName');
        return response;
      } catch (e) {
        debugPrint('AI: Error with $modelName: $e');
        lastError = e;
        continue;
      }
    }
    
    throw lastError ?? Exception('Failed to generate content with all models');
  }

  Future<List<String>> listAvailableModels(String apiKey) async {
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List models = data['models'] ?? [];
        
        final fetched = models
            .where((m) => (m['supportedGenerationMethods'] as List).contains('generateContent'))
            .map((m) => (m['name'] as String).replaceFirst('models/', ''))
            .toList();
            
        if (fetched.isEmpty) throw Exception('No models found');
        return fetched;
      } else {
        throw Exception('Failed to fetch models: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error listing models: $e. Using fallback list.');
      // Fallback list of known working models
      return [
        'gemini-1.5-flash',
        'gemini-1.5-pro',
        'gemini-2.0-flash-exp', // Experimental
        'gemini-pro',
        'gemini-1.5-flash-8b',
        'gemini-1.0-pro'
      ];
    }
  }
}
