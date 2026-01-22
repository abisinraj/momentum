import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momentum/core/database/app_database.dart';
import 'package:momentum/core/providers/database_providers.dart';

// Activity Grid (Last 90 days)
final activityGridProvider = FutureProvider<Map<DateTime, String>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getActivityGrid(90);
});

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
