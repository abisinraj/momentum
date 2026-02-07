import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Service responsible for the mathematical logic of progressive overload.
class ProgressionService {
  final AppDatabase db;

  // Progression constants
  static const double weightIncrementKg = 2.5;
  static const int repsIncrementSmall = 1;
  static const int repsIncrementLarge = 2;
  static const int repsThreshold = 12; // Switch from large to small increments
  static const int repsCap = 20; // Maximum reps before suggesting weight

  ProgressionService(this.db);

  /// Analyzes a completed session and updates exercise targets for next time.
  Future<void> applyProgression(int sessionId) async {
    final sessionExercises = await db.getSessionExercises(sessionId);
    
    for (final se in sessionExercises) {
      final exercise = await db.getExercise(se.exerciseId);
      if (exercise == null) continue;

      if (_shouldProgress(se, exercise)) {
        final nextTarget = _calculateNextTarget(exercise);
        
        await (db.update(db.exercises)..where((e) => e.id.equals(exercise.id)))
            .write(ExercisesCompanion(
          targetWeight: Value(nextTarget.weight),
          reps: Value(nextTarget.reps),
        ));
      }
    }
  }

  /// Criteria for progression:
  /// 1. User completed ALL sets.
  /// 2. Total reps meet or exceed the target total volume (sets * reps).
  /// This is more flexible than average reps, allowing for drop sets.
  bool _shouldProgress(SessionExercise se, Exercise ex) {
    // Must complete all sets
    if (se.completedSets < ex.sets) return false;

    // Check if total volume (reps) meets or exceeds target
    if (se.completedReps > 0) {
      final targetTotalReps = ex.sets * ex.reps;
      return se.completedReps >= targetTotalReps;
    }

    // Fallback: if reps weren't logged, assume success if all sets were done
    return true;
  }

  /// Mathematical increment logic
  _ProgressionTarget _calculateNextTarget(Exercise ex) {
    // If it's a weighted exercise (or has a target weight > 0)
    if (ex.targetWeight > 0 || (ex.primaryMuscleGroup != null && !_isBodyweightOnly(ex.name))) {
      // Standard linear progression
      return _ProgressionTarget(
        weight: ex.targetWeight + weightIncrementKg,
        reps: ex.reps, // Keep reps same, focus on intensity
      );
    } else {
      // Bodyweight or high-rep progression: Increase reps
      // Use larger increments for lower reps, smaller for higher reps
      int nextReps = ex.reps + (ex.reps < repsThreshold ? repsIncrementLarge : repsIncrementSmall);
      if (nextReps > repsCap) nextReps = repsCap;

      return _ProgressionTarget(
        weight: ex.targetWeight,
        reps: nextReps,
      );
    }
  }

  bool _isBodyweightOnly(String name) {
    final lower = name.toLowerCase();
    return lower.contains('pushup') || 
           lower.contains('pullup') || 
           lower.contains('chinup') || 
           lower.contains('dip') || 
           lower.contains('crunch') || 
           lower.contains('plank');
  }
}

class _ProgressionTarget {
  final double weight;
  final int reps;

  _ProgressionTarget({required this.weight, required this.reps});
}
