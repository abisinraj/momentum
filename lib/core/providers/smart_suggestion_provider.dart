import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momentum/core/database/app_database.dart';
import 'package:momentum/core/providers/database_providers.dart';
import 'package:momentum/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types of suggestions
enum SuggestionType {
  deload,
  adaptive,
}

/// A smart suggestion to display to the user
class SmartSuggestion {
  final String id;
  final SuggestionType type;
  final String title;
  final String message;
  final String? actionLabel;
  final dynamic payload; // Store ID or context

  SmartSuggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.actionLabel,
    this.payload,
  });
}

/// Provider that analyzes history and returns a list of suggestions
final smartSuggestionsProvider = FutureProvider.autoDispose<List<SmartSuggestion>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final suggestions = <SmartSuggestion>[];

  // Fetch data
  final recentSessionsFull = await db.getRecentSessionsWithDetails(limit: 30); // 30 sessions check
  final allWorkouts = await db.getAllWorkouts();
  final now = DateTime.now();
  
  // 1. Deload Detection
  // Criteria: 4+ High Intensity (RPE >= 8) sessions in the last 7 days.
  final last7Days = recentSessionsFull.where((s) {
    final session = s['session'] as Session;
    final diff = now.difference(session.startedAt);
    return diff.inDays <= 7;
  }).toList();

  final highIntensityCount = last7Days.where((s) => ((s['session'] as Session).intensity ?? 0) >= 8).length;

  if (highIntensityCount >= 4) {
    suggestions.add(SmartSuggestion(
      id: 'deload_suggestion',
      type: SuggestionType.deload,
      title: 'Recovery Check',
      message: 'You\'ve crushed $highIntensityCount high-intensity sessions this week. Overtraining can stall progress.',
      actionLabel: 'Schedule Rest',
    ));
  }

  // 2. Adaptive Cycle (Neglected Workouts)
  // Check for workouts not done in last 10 days (if they exist)
  if (allWorkouts.length > 1) { // Need at least 2 workouts to suggest reorder/missed
    for (final workout in allWorkouts) {
      if (workout.isRestDay) continue; // Ignore rest days
      
      // Check if this workout appears in recent sessions
      final hasDoneRecently = recentSessionsFull.any((s) {
        final sessionWorkout = s['workout'] as Workout?;
        final session = s['session'] as Session;
        
        return sessionWorkout?.id == workout.id && 
          now.difference(session.startedAt).inDays < 10;
      });
      
      if (!hasDoneRecently) {

        // Double check it wasn't done > 30 sessions ago? 
        // We only fetched 30. If user trains daily, that's 30 days.
        // If they skipped it for 30 sessions, it definitely needs attention.
        
        // suggestions.add(SmartSuggestion(...)) // REMOVED FROM UI
        
        // TRIGGER PUSH NOTIFICATION INSTEAD
        // RATE LIMIT: At most once every 24 hours
        final prefs = await SharedPreferences.getInstance();
        final lastNotifyKey = 'last_balance_notify_${workout.id}';
        final lastNotifyMs = prefs.getInt(lastNotifyKey) ?? 0;
        final lastNotify = DateTime.fromMillisecondsSinceEpoch(lastNotifyMs);
        
        if (now.difference(lastNotify).inHours >= 24) {
          NotificationService.showNotification(
            id: workout.id + 1000, // Unique-ish ID
            title: 'Cycle Balance',
            body: 'It\'s been a while since you did ${workout.name}. Consider prioritizing it today!',
          );
          await prefs.setInt(lastNotifyKey, now.millisecondsSinceEpoch);
        }
        
        // Only one adaptive suggestion alert at a time to avoid spam
        break;
      }
    }
  }
  
  return suggestions;
});

