import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:momentum/core/database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIInsightsService {
  // TODO: Ideally, move this to a secure backend or use --dart-define
  // For this prototype, we will use a placeholder or ask the user to input it.
  // We'll store it in SharedPreferences for now if provided by user.
  static const String _defaultApiKey = 'YOUR_API_KEY_HERE'; 

  Future<String> getDailyInsight(User user, List<Map<String, dynamic>> recentSessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String apiKey = prefs.getString('gemini_api_key') ?? _defaultApiKey;

      if (apiKey == 'YOUR_API_KEY_HERE' || apiKey.isEmpty) {
        return "Configure your Gemini API Key in Settings to unlock AI insights.";
      }

      // Use the stable 'gemini-pro' model
      final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

      final prompt = _constructDetailedPrompt(user, recentSessions);
      final content = [Content.text(prompt)];
      
      final response = await model.generateContent(content);

      return response.text?.trim() ?? "Consistency is key. Keep pushing forward!";
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('API_KEY_INVALID')) {
         return "Invalid API Key. Please check your settings.";
      } else if (errorStr.contains('not found') || errorStr.contains('404')) {
         // Fallback if model is somehow still wrong
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
      
      // List recent history for context
      analysis.writeln("Recent History:");
      for (var s in sessions.take(3)) {
         final name = s['workoutName'] ?? 'Workout';
         final date = s['completedAt'] as DateTime?;
         analysis.writeln("- $name (${date?.day}/${date?.month})");
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
}
