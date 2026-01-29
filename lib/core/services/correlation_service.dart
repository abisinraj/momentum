
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/database_providers.dart';
import 'package:drift/drift.dart';
import 'dart:math';

/// Service to analyze correlations between metrics (e.g. Sleep vs Strength)
class CorrelationService {
  final AppDatabase db;

  CorrelationService(this.db);

  /// Analyzes Sleep Duration vs Workout Volume for the last 30 days
  /// Returns a simple insight string.
  Future<String> analyzeSleepVsPerformance() async {
    // 1. Get Sleep Logs
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    // We need to join sleep logs with sessions.
    // For simplicity, let's get all data and correlate in Dart.
    final sleepLogs = await (db.select(db.sleepLogs)
      ..where((tbl) => tbl.date.isBiggerThan(Variable(thirtyDaysAgo))))
      .get();
      
    final sessions = await (db.select(db.sessions)
      ..where((tbl) => tbl.completedAt.isNotNull()))
      .get();
      
    if (sleepLogs.length < 5 || sessions.length < 5) {
      return "Keep logging sleep and workouts to see correlations.";
    }

    // 2. Pair them up
    // We assume the sleep on Date T affects Workout on Date T (or T+1? usually "Last Night's Sleep" is for "Today's Workout").
    // In our DB, SleepLog.date usually represents the "Day of waking up" or "Day of sleep start"?
    // Let's assume SleepLog.date = The day you woke up (and worked out).
    
    List<double> goodSleepVolumes = [];
    List<double> badSleepVolumes = [];
    
    for (final session in sessions) {
      if (session.completedAt == null) continue;
      
      final sessionDate = session.completedAt!;
      final dateKey = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
      
      // Find sleep for this date (the morning of)
      try {
        final sleep = sleepLogs.firstWhere((s) => 
          s.date.year == dateKey.year && 
          s.date.month == dateKey.month && 
          s.date.day == dateKey.day
        );
        
        // Categorize
        // Bad < 7 hours (420 mins), Good >= 7 hours
        // Note: Volume calculation is tricky without session stats.
        // Let's use Duration as proxy again, OR ideally we assume 'volume' is stored or we fetch it.
        // Since we don't have easy Volume, let's use 'durationSeconds' which is in Session.
        // A better metric would be "RPE" if we had it averaged.
        // Let's just use Duration for the prototype logic.
        
        final duration = (session.durationSeconds ?? 0).toDouble();
        
        if (sleep.durationMinutes >= 420) {
          goodSleepVolumes.add(duration);
        } else {
          badSleepVolumes.add(duration);
        }
      } catch (e) {
        // No sleep log for this day
      }
    }
    
    if (goodSleepVolumes.isEmpty || badSleepVolumes.isEmpty) {
      return "Not enough data overlap to find patterns.";
    }
    
    // 3. Compare Averages
    final avgGood = goodSleepVolumes.reduce((a, b) => a + b) / goodSleepVolumes.length;
    final avgBad = badSleepVolumes.reduce((a, b) => a + b) / badSleepVolumes.length;
    
    final diffPercent = ((avgGood - avgBad) / avgBad) * 100;
    
    if (diffPercent > 5) {
      return "You train ${diffPercent.toStringAsFixed(1)}% longer after a good night's sleep (7h+).";
    } else if (diffPercent < -5) {
      return "Surprisingly, your sessions are shorter after good sleep. Overslept?";
    } else {
      return "Your sleep doesn't significantly affect your session duration.";
    }
  }
}

final correlationServiceProvider = Provider<CorrelationService>((ref) {
  return CorrelationService(ref.read(appDatabaseProvider));
});

final correlationInsightProvider = FutureProvider<String>((ref) async {
  return ref.read(correlationServiceProvider).analyzeSleepVsPerformance();
});
