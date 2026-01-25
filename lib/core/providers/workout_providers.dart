import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';


import '../database/app_database.dart';
import '../services/widget_service.dart';
import 'database_providers.dart';
import 'dashboard_providers.dart';
import 'ai_providers.dart';

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
      if (workout != null) {
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
      }
    }
  }

  /// Start a workout session
  Future<void> startWorkout(Workout workout) async {

    final db = ref.read(appDatabaseProvider);
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
  }
  
  /// Complete the current workout session
  Future<void> completeWorkout({int? intensity}) async {
    if (state == null) return;
    
    final db = ref.read(appDatabaseProvider);
    final duration = DateTime.now().difference(state!.startedAt);
    
    await db.completeSession(state!.sessionId, duration.inSeconds, intensity: intensity);

    
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
    ref.invalidate(dailyInsightProvider); // Re-generate AI insight based on new completion
    
    // Activity Grid (Try to invalidate common usages if possible, or leave it be if complex)
    // Actually, `activityGridProvider` is used in ConsistencyGridWidget with days=90 usually. 
    // Since we can't guess, we might skip explicit invalidation and hope for auto-refresh, 
    // or if `ConsistencyGridWidget` watches `workoutsStreamProvider` too? No.
    // Actually, `widget_service.dart` usually triggers updates.
    
    // Sync widget data
    final _ = ref.refresh(widgetSyncProvider);
    
    state = null;
  }
  
  /// Cancel the current workout (don't save completion)
  void cancelWorkout() {
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
