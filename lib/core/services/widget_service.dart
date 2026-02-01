import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/database_providers.dart';
import 'settings_service.dart';

/// Service to sync data to Android Home Screen Widget
class WidgetService {
  static const String _androidName = 'com.silo.momentum.MomentumWidgetProvider';
  
  // Storage Keys
  static const String keyStreak = 'widget_streak';
  static const String keyTitle = 'widget_title';
  static const String keyDesc = 'widget_desc';
  static const String keyCycleProgress = 'widget_cycle_progress';
  static const String keyNextWorkout = 'widget_next_workout';
  static const String keyTheme = 'widget_theme';
  


  Future<void> updateWidget({
    required int streak,
    required String title,
    required String desc,
    required String cycleProgress,
    required String widgetTheme,
    String? nextWorkoutName,
  }) async {
    try {
      // Use standard SharedPreferences to save data.
      // This is more reliable as HomeWidget's group ID saving can be flaky on some Android setups.
      // Native code (MomentumWidgetProvider) is configured to fallback to reading identifiers
      // from FlutterSharedPreferences (prefixed with 'flutter.') if the main group file is empty.
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt(keyStreak, streak);
      await prefs.setString(keyTitle, title);
      
      final time = '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
      await prefs.setString(keyDesc, '$desc • $time');
      await prefs.setString(keyCycleProgress, cycleProgress);
      await prefs.setString(keyNextWorkout, nextWorkoutName ?? '');
      await prefs.setString(keyTheme, widgetTheme);

      debugPrint('[WidgetService] Data saved to SharedPreferences (FlutterSharedPreferences). Updating widget now...');
      
      // Trigger the update intent
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
    
    // 4. Get Theme
    final currentTheme = ref.read(widgetThemeProvider).valueOrNull ?? 'classic';

    // 5. Update Widget
    await widgetService.updateWidget(
      streak: streak,
      title: title,
      desc: desc,
      cycleProgress: cycleProgress,
      widgetTheme: currentTheme,
      nextWorkoutName: nextWorkout?.name ?? 'Momentum', 
    );
  } catch (e) {
    debugPrint('[WidgetSync] Error: $e');
  }
});
