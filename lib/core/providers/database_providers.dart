import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';

part 'database_providers.g.dart';

/// Single database instance for the entire app
@Riverpod(keepAlive: true)
AppDatabase appDatabase(ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}

/// Provider for checking if setup is complete (from database)
@riverpod
Future<bool> isSetupComplete(ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.isSetupComplete();
}

/// Provider for the current user
@riverpod
Future<User?> currentUser(ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getUser();
}

/// Provider for all workouts (reactive stream)
@riverpod
Stream<List<Workout>> workoutsStream(ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllWorkouts();
}

/// Provider for today's completed workout IDs
@riverpod
Future<List<int>> todayCompletedWorkoutIds(ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getTodayCompletedWorkoutIds();
}

/// Provider for the next workout in the cycle
@riverpod
Future<Workout?> nextWorkout(ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getNextWorkout();
}

/// Provider for activity grid data (last N days)
@riverpod
Future<Map<DateTime, String>> activityGrid(ref, {int days = 30}) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getActivityGrid(days);
}
