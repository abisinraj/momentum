import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';

part 'database_providers.g.dart';

/// Single database instance for the entire app
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}

/// Provider for checking if setup is complete (from database)
@riverpod
Future<bool> isSetupComplete(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.isSetupComplete();
}

/// Provider for the current user
@riverpod
Future<User?> currentUser(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getUser();
}

/// Provider for watching the current user
@riverpod
Stream<User?> userStream(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchUser();
}

/// Provider for all workouts (reactive stream)
@riverpod
Stream<List<Workout>> workoutsStream(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllWorkouts();
}

/// Provider for today's completed workout IDs
@riverpod
Future<List<int>> todayCompletedWorkoutIds(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getTodayCompletedWorkoutIds();
}

/// Provider for the next workout in the cycle
@riverpod
Future<Workout?> nextWorkout(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  try {
    final workout = await db.getNextWorkout();
    return workout;
  } catch (e, st) {
    debugPrint('[DEBUG] nextWorkoutProvider ERROR: $e\n$st');
    rethrow;
  }
}

/// Provider for activity grid data (last N days)
/// Provider for activity grid data (last N days)
@riverpod
Stream<Map<DateTime, String>> activityGrid(Ref ref, int days) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchActivityGrid(days);
}

/// Provider for exercises in a workout
@riverpod
Future<List<Exercise>> exercisesForWorkout(Ref ref, int workoutId) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getExercisesForWorkout(workoutId);
}

/// Provider for weekly stats
@riverpod
Future<Map<String, int>> weeklyStats(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getWeeklyStats();
}

/// Provider for weekly insight text
@riverpod
Future<String> weeklyInsight(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getWeeklyInsight();
}

/// Provider for session history with workout details
@riverpod
Future<List<Map<String, dynamic>>> sessionHistory(Ref ref, int limit) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getRecentSessionsWithDetails(limit: limit);
}

/// Provider for exercise details of a specific session
@riverpod
Future<List<Map<String, dynamic>>> sessionExerciseDetails(Ref ref, int sessionId) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getSessionExerciseDetails(sessionId);
}
