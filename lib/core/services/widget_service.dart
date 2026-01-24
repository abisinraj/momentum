import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../providers/database_providers.dart';

/// Service to sync data to Android Home Screen Widget
class WidgetService {
  static const String _androidName = 'MomentumWidgetProvider';

  Future<void> updateWidget({
    required int streak,
    required String title,
    required String desc,
    required String cycleProgress,
    String? nextWorkoutName,
  }) async {
    try {
      await HomeWidget.saveWidgetData('widget_streak', streak);
      await HomeWidget.saveWidgetData('widget_title', title);
      await HomeWidget.saveWidgetData('widget_desc', desc);
      await HomeWidget.saveWidgetData('widget_cycle_progress', cycleProgress);
      await HomeWidget.saveWidgetData('widget_next_workout', nextWorkoutName ?? '');
      
      await HomeWidget.updateWidget(
        name: _androidName,
        androidName: _androidName,
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }
}

final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService();
});

/// Provider to sync data to widget
final widgetSyncProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final widgetService = ref.watch(widgetServiceProvider);

  try {
    // 1. Calculate Streak
    // Get activity for last 365 days to be safe
    final activityGrid = await db.getActivityGrid(365);
    int streak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check from today backwards
    DateTime checkDate = today;
    // optimization: if today has activity, include it. If not, check yesterday.
    if (!activityGrid.containsKey(checkDate)) {
      checkDate = today.subtract(const Duration(days: 1));
    }
    
    while (activityGrid.containsKey(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // 2. Get Next Workout
    final nextWorkout = await db.getNextWorkout();
    String title = 'No Active Plan';
    String desc = 'Create a workout to start';
    
    if (nextWorkout != null) {
      title = nextWorkout.name;
      
      // Check if done today
      final completedIds = await db.getTodayCompletedWorkoutIds();
      if (completedIds.contains(nextWorkout.id)) {
        title = 'Done: ${nextWorkout.name}';
        desc = 'All done for today!';
        // Optional: Show tomorrow's workout?
        // Since we don't easily know "tomorrow" without user cycle logic, just status is fine.
      } else {
        // Not done
        final exercises = await db.getExercisesForWorkout(nextWorkout.id);
        desc = '${exercises.length} Exercises • Tap to Start';
      }
    }
    
    // 3. Calculate Cycle Progress (Day X of Y)
    final user = await db.getUser();
    String cycleProgress = 'Day 1';
    
    if (user != null && user.splitDays != null && user.splitDays! > 0) {
      final current = user.currentSplitIndex + 1;
      final total = user.splitDays!;
      cycleProgress = 'Day $current/$total';
    }

    // 4. Update Widget
    await widgetService.updateWidget(
      streak: streak,
      title: title,
      desc: desc,
      cycleProgress: cycleProgress,
      nextWorkoutName: nextWorkout?.name ?? 'Split Setup', 
    );
  } catch (e) {
    debugPrint('Widget Sync Error: $e');
  }
});
