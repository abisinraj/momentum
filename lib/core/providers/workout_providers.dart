import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';


import '../database/app_database.dart';
import '../services/widget_service.dart';
import '../services/background_service.dart';
import 'database_providers.dart';

import 'dashboard_providers.dart';
import 'ai_providers.dart';
import '../../features/workout/providers/comparison_provider.dart';

part 'workout_providers.g.dart';

/// State for workout being currently run
class ActiveSession {
  final int sessionId;
  final int workoutId;
  final String workoutName;
  final ClockType clockType;
  final Duration? timerDuration;
  final DateTime startedAt;
  
  const ActiveSession({
    required this.sessionId,
    required this.workoutId,
    required this.workoutName,
    required this.clockType,
    this.timerDuration,
    required this.startedAt,
  });
}



/// Notifier for managing active workout session
@riverpod
class ActiveWorkoutSession extends _$ActiveWorkoutSession {
  @override
  ActiveSession? build() => null;
  
  /// Check for any crashed/incomplete sessions and restore state
  Future<void> checkResumableSession() async {
    // Prevent overwriting if already running (though unlikely on clean start)
    if (state != null) return;
    
    final db = ref.read(appDatabaseProvider);
    final session = await db.getActiveSession();
    
    if (session != null) {
      final workout = await db.getWorkout(session.workoutId);
      final scheduledWorkout = await ref.read(nextWorkoutProvider.future);

      if (workout != null) {
        // Multi-Layered Stale Check
        final now = DateTime.now();
        final nowUtc = now.toUtc();
        final startedAtLocal = session.startedAt.toLocal();
        final startedAtUtc = session.startedAt.isUtc ? session.startedAt : session.startedAt.toUtc();
        final age = nowUtc.difference(startedAtUtc);
        
        // 1. Date Check: If not started today, it's stale
        final isNotToday = startedAtLocal.year != now.year || 
                          startedAtLocal.month != now.month || 
                          startedAtLocal.day != now.day;
                          
        // 2. Future Check: Clock drift protection (if session is > 5 mins in future)
        final isInFuture = age.inMinutes < -5;

        // 3. Strict Matching: If session type doesn't match today's scheduled workout
        final isDifferentWorkout = scheduledWorkout != null && scheduledWorkout.id != workout.id;
        final timeoutHours = isDifferentWorkout ? 1 : 4;

        if (isNotToday || isInFuture || age.inHours.abs() >= timeoutHours) {
          debugPrint('Found stale/ghost session (ID: ${session.id}, NotToday: $isNotToday, Future: $isInFuture, Age: ${age.inHours}h). Cleaning all active.');
          // Global Cleanup: Close everything to be sure
          await db.cleanupActiveSessions();
          return;
        }

        state = ActiveSession(
          sessionId: session.id,
          workoutId: workout.id,
          workoutName: workout.name,
          clockType: workout.clockType,
          timerDuration: workout.timerDurationSeconds != null 
              ? Duration(seconds: workout.timerDurationSeconds!)
              : null,
          startedAt: session.startedAt,
        );
        
        // Restore background service
        final service = BackgroundService();
        await service.startService(workout.name);
        service.setStartTime(session.startedAt);
      }
    }
  }



  Future<void> startWorkout(Workout workout) async {
    final db = ref.read(appDatabaseProvider);
    
    // Aggressive Auto-Cleanup: Close ANY existing active session globally
    debugPrint('Starting workout "${workout.name}". Running global active session cleanup.');
    await db.cleanupActiveSessions();

    final sessionId = await db.startSession(workout.id);
    
    state = ActiveSession(
      sessionId: sessionId,
      workoutId: workout.id,
      workoutName: workout.name,
      clockType: workout.clockType,
      timerDuration: workout.timerDurationSeconds != null 
          ? Duration(seconds: workout.timerDurationSeconds!)
          : null,
      startedAt: DateTime.now(),
    );
    
    // Start background service
    final service = BackgroundService();
    await service.startService(workout.name);
    service.setStartTime(DateTime.now());

  }
  
  /// Complete the current workout session
  Future<void> completeWorkout({
    int? intensity, 
    int? avgBpm, 
    int? maxBpm,
    List<SessionExercisesCompanion> exercises = const [],
  }) async {
    if (state == null) return;
    
    final db = ref.read(appDatabaseProvider);
    final duration = DateTime.now().difference(state!.startedAt);
    
    await db.completeSession(
      state!.sessionId, 
      duration.inSeconds, 
      intensity: intensity,
      avgBpm: avgBpm,
      maxBpm: maxBpm,
    );
    
    // Save Exercise Details
    for (final exercise in exercises) {
      await db.saveSessionExercise(exercise);
    }
    
    // Stop background service
    await BackgroundService().stopService();

    
    // Invalidate providers that depend on session data

    ref.invalidate(todayCompletedWorkoutIdsProvider);
    ref.invalidate(nextWorkoutProvider);
    // Note: activityGridProvider requires days arg, so we can't simple invalidate without family arg. 
    // Usually Riverpod invalidates all family variants if we invalidate the provider itself? No, only if we use `ref.invalidate(provider)`. 
    // But `activityGridProvider` is a family. `ref.invalidate(activityGridProvider)` is a compile error unless we pass args.
    // However, if we don't know the args, we can't easily invalidate specific families unless we track them.
    // WORKAROUND: We rely on the fact that UI widgets watching these will likely trigger a refresh if they are autoDispose, 
    // OR we accept that "Activity Grid" might lagging slightly unless we force it.
    // BETTER: Use `ref.container.invalidate(activityGridProvider)`? No.
    // Let's focus on non-family ones or commonly used ones.
    
    ref.invalidate(weeklyStatsProvider);
    ref.invalidate(weeklyInsightProvider);
    ref.invalidate(sessionHistoryProvider); // IMPORTANT: Updates history tab
    
    // Dashboard & AI
    ref.invalidate(muscleWorkloadProvider);
    ref.invalidate(volumeLoadProvider);
    ref.invalidate(analyticsSummaryProvider); // Analytics Card
    ref.invalidate(workoutComparisonProvider(state!.workoutId)); // Comparison Card
    ref.invalidate(dailyInsightProvider); // Re-generate AI insight based on new completion
    
    // Activity Grid - Explicitly invalidate the one used by Home Screen (150 days)
    ref.invalidate(activityGridProvider(150));
    
    // Sync widget data
    final _ = ref.refresh(widgetSyncProvider);
    
    state = null;
  }
  
  /// Cancel the current workout (don't save completion)
  void cancelWorkout() {
    BackgroundService().stopService();
    state = null;
  }

}

/// Provider for adding a new workout
@riverpod
class WorkoutManager extends _$WorkoutManager {
  @override
  FutureOr<void> build() {}
  
  /// Add a new workout to the cycle
  Future<void> addWorkout({
    required String name,
    required String shortCode,
    bool isRestDay = false,
    ClockType clockType = ClockType.none,

    Duration? timerDuration,
    int? orderIndex, // If provided, use this; otherwise append at end
  }) async {
    final db = ref.read(appDatabaseProvider);
    
    // If orderIndex not provided, append at end
    final index = orderIndex ?? (await db.getAllWorkouts()).length;
    
    await db.addWorkout(WorkoutsCompanion.insert(
      name: name,
      shortCode: isRestDay ? 'R' : shortCode,
      isRestDay: Value(isRestDay),
      orderIndex: index,

      clockType: Value(clockType),
      timerDurationSeconds: timerDuration != null 
          ? Value(timerDuration.inSeconds)
          : const Value.absent(),
    ));
    
    // Invalidate workouts stream
    ref.invalidate(workoutsStreamProvider);
    ref.invalidate(nextWorkoutProvider);
    // ignore: unused_result
    ref.refresh(widgetSyncProvider); // Force widget update
  }
  
  /// Delete a workout
  Future<void> deleteWorkout(int id) async {
    final db = ref.read(appDatabaseProvider);
    await db.deleteWorkout(id);
    
    ref.invalidate(workoutsStreamProvider);
    ref.invalidate(nextWorkoutProvider);
  }
  
  /// Reorder workouts
  Future<void> reorderWorkouts(List<Workout> newOrder) async {
    final db = ref.read(appDatabaseProvider);
    for (int i = 0; i < newOrder.length; i++) {
      await db.updateWorkoutOrder(newOrder[i].id, i);
    }
    
    ref.invalidate(workoutsStreamProvider);
    ref.invalidate(nextWorkoutProvider);
  }

  /// Log a rest day completion immediately
  Future<void> logRestDay(Workout workout) async {
    final db = ref.read(appDatabaseProvider);
    
    // Start and immediately complete
    final sessionId = await db.startSession(workout.id);
    await db.completeSession(sessionId, 0); // 0 duration for rest days
    
    // Trigger standard invalidations
    ref.invalidate(todayCompletedWorkoutIdsProvider);
    ref.invalidate(nextWorkoutProvider);
    ref.invalidate(weeklyStatsProvider);
    ref.invalidate(weeklyInsightProvider);
    ref.invalidate(sessionHistoryProvider);
    
    // Dashboard & AI
    ref.invalidate(dailyInsightProvider); 
    
    // Sync widgets
    final _ = ref.refresh(widgetSyncProvider);
  }

}
