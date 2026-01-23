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
        return "Configure your API Key in Settings to unlock AI insights.";
      }

      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

      final prompt = _constructPrompt(user, recentSessions);
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text?.trim() ?? "Stay consistent and keep pushing!";
    } catch (e) {
      // print('AI Insight Error: $e');
      if (e.toString().contains('API_KEY_INVALID')) {
         return "Invalid API Key. Please check your settings.";
      }
      return "Focus on your form and breathing today. You got this!";
    }
  }

  String _constructPrompt(User user, List<Map<String, dynamic>> sessions) {
    final goal = user.goal ?? 'General Fitness';
    final weight = user.weightKg != null ? '${user.weightKg}kg' : 'Unknown';
    
    StringBuffer recentActivity = StringBuffer();
    if (sessions.isEmpty) {
      recentActivity.writeln("No recent workouts.");
    } else {
      for (var s in sessions.take(5)) { // Last 5 sessions
        final workoutName = s['workoutName'] as String? ?? 'Workout';
        final date = s['completedAt'] as DateTime?;
        final dateStr = date != null ? "${date.day}/${date.month}" : "Unknown date";
        recentActivity.writeln("- $workoutName on $dateStr");
      }
    }

    return '''
    You are an expert fitness coach for a user named ${user.name}.
    User Stats:
    - Goal: $goal
    - Weight: $weight
    
    Recent Activity:
    $recentActivity
    
    Based on this, generate a ONE sentence daily insight or motivation for their workout today.
    - Be brief and punchy.
    - If they have been consistent, praise them.
    - If they missed a few days, gently encourage them.
    - Do not use hashtags.
    ''';
  }
}
