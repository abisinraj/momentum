import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../providers/database_providers.dart';

/// Service to sync data to Android Home Screen Widget
class WidgetService {
  static const String _androidName = 'com.silo.momentum.MomentumWidgetProvider';
  
  // Define a consistent group ID (used as prefs file name on Android)
  static const String _groupId = 'com.silo.momentum.widget';

  Future<void> updateWidget({
    required int streak,
    required String title,
    required String desc,
    required String cycleProgress,
    String? nextWorkoutName,
  }) async {
    try {
      // Set the group ID (important for Android SharedPreferences name consistency)
      await HomeWidget.setAppGroupId(_groupId);
      await HomeWidget.saveWidgetData('widget_streak', streak.toString());
      await HomeWidget.saveWidgetData('widget_title', title);
      final time = '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
      await HomeWidget.saveWidgetData('widget_desc', '$desc • $time');
      await HomeWidget.saveWidgetData('widget_cycle_progress', cycleProgress);
      await HomeWidget.saveWidgetData('widget_next_workout', nextWorkoutName ?? '');
      
      await HomeWidget.saveWidgetData('widget_next_workout', nextWorkoutName ?? '');
      
      debugPrint('[WidgetService] Data saved. Updating widget now...');
      await HomeWidget.updateWidget(
        name: _androidName,
        androidName: _androidName,
        qualifiedAndroidName: _androidName,
      );
      debugPrint('[WidgetService] updateWidget called for name: $_androidName');
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }
}

final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService();
});

final widgetSyncProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final widgetService = ref.watch(widgetServiceProvider);

  // REACTIVE WATCHES: This provider will re-run whenever these streams emit new values
  final userAsync = ref.watch(userStreamProvider);
  final workoutsAsync = ref.watch(workoutsStreamProvider);
  ref.watch(activityGridProvider(1)); // Watch recent activity to catch session completions

  // Wait for data to be available (skip loading states if possible, or just proceed)
  // We utilize .when to unwrap safely, or default to null/empty if loading
  final user = userAsync.valueOrNull;
  final workouts = workoutsAsync.valueOrNull; // Just to trigger dependency
  
  debugPrint('[WidgetSync] Triggered. User: ${user?.name}, Workouts: ${workouts?.length}');

  try {
    // 1. Calculate Streak
    // Get activity for last 365 days
    final activityGrid = await db.getActivityGrid(365);
    int streak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check from today backwards
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
    String title = 'No Active Plan';
    String desc = 'Create an active split to start';
    
    if (nextWorkout != null) {
      title = nextWorkout.name;
      
      // Check if done today - this also needs to be reactive
      final completedIds = await db.getTodayCompletedWorkoutIds();
      if (completedIds.contains(nextWorkout.id)) {
        title = 'Done: ${nextWorkout.name}';
        desc = 'All done for today!';
      } else {
        // Not done
        final exercises = await db.getExercisesForWorkout(nextWorkout.id);
        desc = '${exercises.length} Exercises • Tap to Start';
      }
    } else {
       // Check if setup is needed
       if (workouts?.isEmpty ?? true) {
         desc = 'Create your first workout!';
       }
    }
    
    // 3. Calculate Cycle Progress
    String cycleProgress = 'Day 1';
    
    if (user != null && user.splitDays != null && user.splitDays! > 0) {
      final current = user.currentSplitIndex + 1;
      final total = user.splitDays!;
      cycleProgress = '$current/$total';
    }

    debugPrint('[WidgetSync] Updating Widget -> Streak: $streak, Title: $title, Progress: $cycleProgress');

    debugPrint('[WidgetSync] Calling widgetService.updateWidget with: Streak=$streak, Title=$title');
    
    // 4. Update Widget
    await widgetService.updateWidget(
      streak: streak,
      title: title,
      desc: desc,
      cycleProgress: cycleProgress,
      nextWorkoutName: nextWorkout?.name ?? 'Momentum', 
    );
  } catch (e) {
    debugPrint('[WidgetSync] Error: $e');
  }
});
