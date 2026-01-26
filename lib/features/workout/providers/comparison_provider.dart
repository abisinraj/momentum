import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_providers.dart';

// Provider for fetching a comparison between a target workout and its last execution
final workoutComparisonProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, workoutId) async {
  final db = ref.watch(appDatabaseProvider);
  
  // 1. Get Target Workout
  final workout = await db.getWorkout(workoutId);
  if (workout == null) throw Exception('Workout not found');
  
  // 2. Get Exercises for this workout (Target) - Always fetch
  final targetExercises = await db.getExercisesForWorkout(workoutId);
  
  // 3. Get Last Completed Session
  final lastSession = await db.getLastSessionForWorkout(workoutId);
  
  List<SessionExercise> lastExercises = [];
  if (lastSession != null) {
     lastExercises = await db.getSessionExercises(lastSession.id);
  }
  
  return {
    'isFirst': lastSession == null,
    'workout': workout,
    'lastSession': lastSession,
    'targetExercises': targetExercises,
    'lastExercises': lastExercises,
  };
});
