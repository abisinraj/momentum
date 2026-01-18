import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'settings_service.dart';

part 'ai_insights_service.g.dart';

/// Service for generating AI-powered workout insights using OpenAI
class AiInsightsService {
  final SettingsService _settings;
  
  AiInsightsService(this._settings);
  
  /// Generate a progress insight for a specific workout
  /// Returns a short, motivational message based on workout history
  Future<String?> generateWorkoutInsight({
    required String workoutName,
    required Map<String, dynamic> progressData,
  }) async {
    final apiKey = await _settings.getOpenAiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return _generateFallbackInsight(progressData);
    }
    
    try {
      final sessionCount = progressData['sessionCount'] as int;
      final avgDuration = progressData['averageDuration'] as double;
      final lastDuration = progressData['lastDuration'] as int?;
      final durations = progressData['durations'] as List<int>;
      
      // Build context for AI
      final prompt = _buildPrompt(
        workoutName: workoutName,
        sessionCount: sessionCount,
        avgDuration: avgDuration,
        lastDuration: lastDuration,
        durations: durations,
      );
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a friendly fitness coach. Generate a SHORT (1-2 sentences max) 
motivational insight about the user's workout progress. Be encouraging but honest. 
Include specific numbers when helpful. Use emojis sparingly.'''
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 100,
          'temperature': 0.7,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        return _generateFallbackInsight(progressData);
      }
    } catch (e) {
      return _generateFallbackInsight(progressData);
    }
  }
  
  String _buildPrompt({
    required String workoutName,
    required int sessionCount,
    required double avgDuration,
    required int? lastDuration,
    required List<int> durations,
  }) {
    final avgMinutes = (avgDuration / 60).round();
    final lastMinutes = lastDuration != null ? (lastDuration / 60).round() : null;
    
    final buffer = StringBuffer();
    buffer.writeln('Workout: $workoutName');
    buffer.writeln('Sessions in last 30 days: $sessionCount');
    
    if (sessionCount == 0) {
      buffer.writeln('The user has not done this workout recently.');
    } else {
      buffer.writeln('Average duration: $avgMinutes minutes');
      if (lastMinutes != null) {
        buffer.writeln('Last session duration: $lastMinutes minutes');
        
        // Calculate trend
        if (durations.length >= 2) {
          final recent = durations.take(2).toList();
          if (recent[0] < recent[1]) {
            buffer.writeln('Trend: Getting faster');
          } else if (recent[0] > recent[1]) {
            buffer.writeln('Trend: Taking more time (could mean more intensity)');
          } else {
            buffer.writeln('Trend: Consistent timing');
          }
        }
      }
    }
    
    return buffer.toString();
  }
  
  /// Generate a simple insight without AI when API key is missing
  String? _generateFallbackInsight(Map<String, dynamic> progressData) {
    final sessionCount = progressData['sessionCount'] as int;
    final avgDuration = progressData['averageDuration'] as double;
    final lastDuration = progressData['lastDuration'] as int?;
    
    if (sessionCount == 0) {
      return "First time doing this workout! Let's set a baseline 💪";
    }
    
    final avgMinutes = (avgDuration / 60).round();
    
    if (lastDuration == null) {
      return "$sessionCount sessions this month, avg $avgMinutes min";
    }
    
    final lastMinutes = (lastDuration / 60).round();
    final diff = lastMinutes - avgMinutes;
    
    if (diff < -2) {
      return "Last session was ${-diff} min faster than average! 🔥";
    } else if (diff > 2) {
      return "Took ${diff} min longer last time - more volume or rest?";
    } else {
      return "Consistent at ~$avgMinutes min. $sessionCount sessions this month.";
    }
  }
}

@riverpod
AiInsightsService aiInsightsService(Ref ref) {
  return AiInsightsService(ref.watch(settingsServiceProvider));
}
