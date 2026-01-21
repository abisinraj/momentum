import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../providers/database_providers.dart';

/// Service to sync data to Android Home Screen Widget
class WidgetService {
  static const String _groupId = 'group.momentum'; // For iOS App Groups if needed later
  static const String _androidName = 'MomentumWidgetProvider';

  Future<void> updateWidget({
    required int streak,
    required String title,
    required String desc,
    String? nextWorkoutName,
  }) async {
    try {
      await HomeWidget.saveWidgetData('widget_streak', streak);
      await HomeWidget.saveWidgetData('widget_title', title);
      await HomeWidget.saveWidgetData('widget_desc', desc);
      await HomeWidget.saveWidgetData('widget_next_workout', nextWorkoutName ?? '');
      
      await HomeWidget.updateWidget(
        name: _androidName,
        androidName: _androidName,
      );
    } catch (e) {
      print('Error updating widget: $e');
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
    
    // 3. Update Widget
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
    );
  } catch (e) {
    print('Widget Sync Error: $e');
  }
});
