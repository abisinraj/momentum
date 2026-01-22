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
    // If today is active, streak includes it.
    // If today is NOT active, check yesterday.
    DateTime checkDate = today;
    if (!activityGrid.containsKey(checkDate)) {
      checkDate = today.subtract(const Duration(days: 1));
    }
    
    while (activityGrid.containsKey(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // 2. Get Next Workout
    final nextWorkout = await db.getNextWorkout();
    String title = nextWorkout?.name ?? 'Complete Setup';
    String desc = 'Tap to start';
    
    // Check if this workout is already completed today
    if (nextWorkout != null) {
      final completedIds = await db.getTodayCompletedWorkoutIds();
      if (completedIds.contains(nextWorkout.id)) {
        // Workout done!
        title = 'Session Complete';
        desc = 'Great job keeping momentum!';
      } else {
        // Not done yet
        final exercises = await db.getExercisesForWorkout(nextWorkout.id);
        desc = '${exercises.length} Exercises';
      }
    }
    
    // 3. Calculate Cycle Progress
    final user = await db.getUser();
    final allWorkouts = await db.getAllWorkouts();
    
    String cycleProgress = '1/3'; // Default
    
    if (user != null && allWorkouts.isNotEmpty) {
      final splitDays = user.splitDays ?? allWorkouts.length;
      final currentIndex = user.currentSplitIndex;
      // Display as "Day X/Y"
      cycleProgress = '${currentIndex + 1}/$splitDays';
    }
    
    // For "Session Complete" state, we might want to show that we finished the cycle?
    // But currentSplitIndex usually updates AFTER session completion.
    // If we just finished session, currentSplitIndex is already pointing to tomorrow.
    // So if title is "Session Complete", maybe show the progress of the JUST finished one?
    // Let's keep it simple: Show current index pointer.
    
    // Pass cycleProgress instead of weeklyProgress

    // 4. Update Widget
    String? nextWorkoutName;
    
    if (title == 'Session Complete' && nextWorkout != null) {
      // Find the *next* workout in the cycle
      // If current is index N, next is (N+1) % splitDays
      // We can query all workouts and find the one with index + 1
      final allWorkouts = await db.getAllWorkouts();
      final user = await db.getUser();
      if (user != null && allWorkouts.isNotEmpty) {
        final currentSplitIndex = nextWorkout.orderIndex; // The one we just finished/checked
        final splitDays = user.splitDays ?? allWorkouts.length;
        final nextIndex = (currentSplitIndex + 1) % splitDays;
        
        final nextDayWorkout = allWorkouts.firstWhere(
          (w) => w.orderIndex == nextIndex, 
          orElse: () => allWorkouts.first
        );
        nextWorkoutName = nextDayWorkout.name;
      }
    }

    await widgetService.updateWidget(
      streak: streak,
      title: title,
      desc: desc,
      nextWorkoutName: nextWorkoutName,
      cycleProgress: cycleProgress,
    );
  } catch (e) {
    debugPrint('Widget Sync Error: $e');
  }
});
