import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Service responsible for the mathematical logic of progressive overload.
class ProgressionService {
  final AppDatabase db;

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
  /// 2. Average reps per set meet or exceed the target reps.
  /// (Note: completedReps is currently stored as total reps across all sets in some flows)
  bool _shouldProgress(SessionExercise se, Exercise ex) {
    if (se.completedSets < ex.sets) return false;

    // If we have total reps, check if average is >= target
    if (se.completedReps > 0) {
      final avgReps = se.completedReps / se.completedSets;
      return avgReps >= ex.reps;
    }

    // fallback if reps weren't logged specifically (assume success if sets done)
    return true;
  }

  /// Mathematical increment logic
  _ProgressionTarget _calculateNextTarget(Exercise ex) {
    // If it's a weighted exercise (or has a target weight > 0)
    if (ex.targetWeight > 0 || (ex.primaryMuscleGroup != null && !_isBodyweightOnly(ex.name))) {
      // Standard linear progression: +2.5kg
      return _ProgressionTarget(
        weight: ex.targetWeight + 2.5,
        reps: ex.reps, // Keep reps same, focus on intensity
      );
    } else {
      // Bodyweight or high-rep progression: Increase reps
      // Cap reps at 20 before suggesting weight or harder variant (manual for now)
      int nextReps = ex.reps + (ex.reps < 12 ? 2 : 1);
      if (nextReps > 20) nextReps = 20;

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
