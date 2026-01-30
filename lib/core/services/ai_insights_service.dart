import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:momentum/core/database/app_database.dart';

class AIInsightsService {
  // TODO: Ideally, move this to a secure backend or use --dart-define
  // For this prototype, we will use a placeholder or ask the user to input it.
  // We'll store it in SharedPreferences for now if provided by user.
  static const String _defaultApiKey = 'YOUR_API_KEY_HERE'; 

  Future<String> getDailyInsight(User user, List<Map<String, dynamic>> recentSessions, String? apiKey) async {
    try {
      if (apiKey == null || apiKey == _defaultApiKey || apiKey.isEmpty) {
        return "Configure your Gemini API Key in Settings to unlock AI insights.";
      }



      // Use robust fallback generation
      final prompt = _constructDetailedPrompt(user, recentSessions);
      final content = [Content.text(prompt)];
      
      try {
        final response = await _generateWithFallback(content, apiKey);
        return response.text?.trim() ?? "Consistency is key. Keep pushing forward!";
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('API_KEY_INVALID')) {
         return "Invalid API Key. Please check your settings.";
      } else if (errorStr.contains('not found') || errorStr.contains('404')) {
         return "AI Model unavailable. Focus on your ${user.goal ?? 'goals'} today!";
      } else if (errorStr.contains('User location is not supported')) {
         return "AI features are not supported in your region yet.";
      }
      return "Focus on your form and breathing today. You got this!";
    }
  }

  String _constructDetailedPrompt(User user, List<Map<String, dynamic>> sessions) {
    final goal = user.goal ?? 'General Fitness';
    final weight = user.weightKg != null ? '${user.weightKg}kg' : 'Unknown';
    
    StringBuffer analysis = StringBuffer();
    
    if (sessions.isEmpty) {
      analysis.writeln("User has no recorded workouts yet.");
      analysis.writeln("Context: This is their very first step.");
    } else {
      // Analyze consistency
      final lastWorkout = sessions.first;
      final lastDate = lastWorkout['completedAt'] as DateTime?;
      final daysSince = lastDate != null ? DateTime.now().difference(lastDate).inDays : 99;
      
      analysis.writeln("Last workout was ${daysSince == 0 ? 'today' : '$daysSince days ago'}.");
      
      if (daysSince > 7) {
        analysis.writeln("Status: User has been inactive. Needs gentle re-engagement.");
      } else if (daysSince <= 2) {
        analysis.writeln("Status: User is consistent and active. Needs positive reinforcement or challenge.");
      }
      
      analysis.writeln("Recent History:");
      for (var s in sessions.take(3)) {
         final name = s['workoutName'] ?? 'Workout';
         final date = s['completedAt'] as DateTime?;
         analysis.writeln("- $name (${date?.day}/${date?.month})");
         
         // EXPAND DETAILS FOR LATEST WORKOUT
         if (s == sessions.first && s.containsKey('exercises')) {
           final exercises = s['exercises'] as List<Map<String, dynamic>>?;
           if (exercises != null && exercises.isNotEmpty) {
             analysis.writeln("  > Details from this session:");
             for (var ex in exercises) {
               final eName = ex['exerciseName'] ?? 'Exercise';
               final totalReps = ex['actualReps'] ?? 0;
               final sets = ex['completedSets'] ?? 0;
               // Note: 'weight' might be missing in history view unless specifically queried, 
               // but 'actualReps' and 'completedSets' gives volume context.
               analysis.writeln("    * $eName: $sets sets, ~$totalReps total reps");
             }
           }
         }
      }
    }

    return '''
    You are an elite fitness coach for ${user.name}.
    
    User Profile:
    - Goal: $goal
    - Weight: $weight
    
    Training Status:
    ${analysis.toString()}
    
    Task:
    Generate a SINGLE, punchy, high-impact sentence to motivate them for today's training.
    
    Guidelines:
    - If inactive (>7 days): Be encouraging, emphasize that "starting back is the hardest part".
    - If consistent: Challenge them to focus on form, intensity, or a specific mental cue.
    - Style: Professional, stoic, inspiring. No emojis. No hashtags.
    - Max length: 20 words.
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
         response = await _generateWithFallback(content, apiKey);
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
  }) async {
    try {
      if (apiKey == null || apiKey == _defaultApiKey || apiKey.isEmpty) {
        return "Please configure your API Key in settings first.";
      }

      // Use robust fallback
      final List<Part> parts = [];
      if (text.isNotEmpty) {
        parts.add(TextPart(text));
      }
      
      if (imageBytes != null) {
        parts.add(DataPart('image/jpeg', Uint8List.fromList(imageBytes)));
      }

      final content = [Content.multi(parts)];
      
      GenerateContentResponse response;
      try {
        response = await _generateWithFallback(content, apiKey);
      } catch (e) {
         return "I couldn't reach the AI service right now. Please try again.";
      }

      return response.text?.trim() ?? "I couldn't understand that context.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }
  Future<GenerateContentResponse> _generateWithFallback(
    List<Content> content,
    String apiKey,
  ) async {
    // List of models to try in order of preference
    // Uses standard stable identifiers to avoid "not found" errors
    const modelsToTry = [
      'gemini-1.5-flash',
      'gemini-1.5-pro',
      'gemini-pro',
    ];

    Object? lastError;

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        return await model.generateContent(content);
      } catch (e) {
        lastError = e;
        continue;
      }
    }
    
    throw lastError ?? Exception('Failed to generate content with all models');
  }
}
