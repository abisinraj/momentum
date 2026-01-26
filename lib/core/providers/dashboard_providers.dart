import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momentum/core/providers/database_providers.dart';

// Note: activityGridProvider is in database_providers.dart

// Muscle Workload (Last 5 days to define "soreness")
final muscleWorkloadProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getMuscleWorkload(5);
});

// Calculate Volume Load (Current Week)
// Returns [CurrentWeekVolume, LastWeekVolume]
final volumeLoadProvider = FutureProvider<List<double>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  
  // Current Week (Last 7 days)
  final current = await db.getVolumeLoad(7, offsetDays: 0);
  
  // Last Week (7 days before that)
  final last = await db.getVolumeLoad(7, offsetDays: 7);
  
  return [current, last];
});

// Workout Progress Insight (Family provider by workout ID)
// Used in Home Screen to show "velocity" or "consistency" for the specific workout
final workoutInsightProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, workoutId) async {
  final db = ref.watch(appDatabaseProvider);
  
  // Check connectivity (simple check)
  final connectivity = await Connectivity().checkConnectivity();
  
  if (connectivity.contains(ConnectivityResult.none)) {
    return {'offline': true};
  }
  
  // Fetch workout progress
  final progressData = await db.getWorkoutProgressSummary(workoutId, days: 30);
  final sessionCount = progressData['sessionCount'] as int;
  
  if (sessionCount == 0) {
    return {'firstSession': true};
  }
  
  return {
    ...progressData,
  };
});
