import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momentum/core/providers/database_providers.dart';

// Note: activityGridProvider is in database_providers.dart

// Muscle Workload (Last 5 days to define "soreness")
final muscleWorkloadProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getMuscleWorkload(30);
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

// Calculate Reps Progression (Current vs Last Week) - For Bodyweight
final repsProgressionProvider = FutureProvider<List<int>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final current = await db.getTotalReps(7, offsetDays: 0);
  final last = await db.getTotalReps(7, offsetDays: 7);
  return [current, last];
});

// Analytics Summary (Last 30 days)
final analyticsSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getAnalyticsSummary(30);
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
// Daily Nutrition Summary (Today)
final dailyNutritionProvider = StreamProvider<Map<String, double>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  // Yield initial value
  yield await db.getDailyNutritionSummary(DateTime.now());
  
  // Poll every time database updates (or manually invalidated). 
  // For now, since getDailyNutritionSummary isn't a stream in DB, we'll just yield once.
  // Ideally, add a stream variant in DB or invalidate this provider when adding food.
});

// Daily Food Logs List
final dailyFoodLogsProvider = FutureProvider<List<dynamic>>((ref) async { // List<FoodLog> but dynamic to avoid import if not needed
  final db = ref.watch(appDatabaseProvider);
  return db.getFoodLogsForDate(DateTime.now());
});

// Net Calories (Food - Workout)
// Combining analytics summary (which gives average daily calories burned over 30 days... 
// WAIT, analytics is 30 days avg. We need TODAY'S burn for Net Calories.)
// Let's rely on a new provider for Today's Burn specifically.
final dailyBurnProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  // Quick estimation from completed sessions today:
  final todaySessions = await db.getSessionsForDate(DateTime.now());
  final completed = todaySessions.where((s) => s.completedAt != null);
  
  int totalCalories = 0;
  for (final s in completed) {
    if (s.caloriesBurned != null) {
      totalCalories += s.caloriesBurned!;
    } else {
      final mins = (s.durationSeconds ?? 0) ~/ 60;
      final weight = (await db.getUser())?.weightKg ?? 70.0;
      final intensityFactor = (s.intensity ?? 5) / 5.0;
      totalCalories += (6.0 * intensityFactor * weight * (mins / 60.0)).round();
    }
  }
  
  return totalCalories;
});

final netCaloriesProvider = FutureProvider<Map<String, int>>((ref) async {
  final foodAsync = await ref.watch(dailyNutritionProvider.future);
  final burnAsync = await ref.watch(dailyBurnProvider.future);
  
  final eaten = foodAsync['calories']?.toInt() ?? 0;
  final burned = burnAsync;
  
  return {
    'eaten': eaten,
    'burned': burned,
    'net': eaten - burned,
  };
});
