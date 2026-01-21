import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import '../services/widget_service.dart';
import 'database_providers.dart';

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
  Future<void> completeWorkout() async {
    if (state == null) return;
    
    final db = ref.read(appDatabaseProvider);
    final duration = DateTime.now().difference(state!.startedAt);
    
    await db.completeSession(state!.sessionId, duration.inSeconds);
    
    // Invalidate providers that depend on session data
    ref.invalidate(todayCompletedWorkoutIdsProvider);
    ref.invalidate(nextWorkoutProvider);
    ref.invalidate(activityGridProvider);
    
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
    ClockType clockType = ClockType.none,
    Duration? timerDuration,
    int? orderIndex, // If provided, use this; otherwise append at end
  }) async {
    final db = ref.read(appDatabaseProvider);
    
    // If orderIndex not provided, append at end
    final index = orderIndex ?? (await db.getAllWorkouts()).length;
    
    await db.addWorkout(WorkoutsCompanion.insert(
      name: name,
      shortCode: shortCode,
      orderIndex: index,
      clockType: Value(clockType),
      timerDurationSeconds: timerDuration != null 
          ? Value(timerDuration.inSeconds)
          : const Value.absent(),
    ));
    
    // Invalidate workouts stream
    ref.invalidate(workoutsStreamProvider);
    ref.invalidate(nextWorkoutProvider);
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
}
