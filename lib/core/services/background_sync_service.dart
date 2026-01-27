import 'package:workmanager/workmanager.dart';
import 'package:momentum/core/database/app_database.dart';
import 'package:momentum/core/services/health_connect_service.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

const String kBackgroundSyncTask = "com.silo.momentum.healthSync";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == kBackgroundSyncTask) {
      debugPrint("[BackgroundSync] Starting Health Connect Sync...");
      
      try {
        // 1. Initialize Database (Isolated)
        final db = AppDatabase();
        
        // 2. Initialize Health Service
        final healthService = HealthConnectService();
        final hasPermissions = await healthService.hasPermissions();
        
        if (!hasPermissions) {
          debugPrint("[BackgroundSync] Permissions not granted. Skipping.");
          await db.close();
          return Future.value(false);
        }
        
        // 3. Define Sync Window (Yesterday + Today)
        // We look back 24-48 hours to ensure we catch last night's sleep even if processed late
        final now = DateTime.now();
        final start = now.subtract(const Duration(days: 1)); // Look back 24h
        final end = now;
        
        // 4. Fetch Sleep Data
        // Note: fetchAllData includes steps, weight, and SLEEP. 
        // We specifically want to process sleep here, but extracting it from generic data points 
        // requires mapping logic similar to HealthNotifier.
        // Let's use fetchSleep directly for clarity if public.
        final sleepData = await healthService.fetchSleep(start, end);
        
        debugPrint("[BackgroundSync] Fetched ${sleepData.length} sleep data points.");

        if (sleepData.isNotEmpty) {
           // Basic aggregation logic (Simplified version of HealthNotifier)
           // If we have any 'SLEEP_ASLEEP' or 'SLEEP_IN_BED' segments
           int totalMinutes = 0;
           for (final point in sleepData) {
              // Health package returns value in 'NumericHealthValue' for some types, 
              // but for sleep it might be time intervals.
              // Actually HealthDataPoint has dateFrom and dateTo.
              final duration = point.dateTo.difference(point.dateFrom);
              totalMinutes += duration.inMinutes;
           }
           
           if (totalMinutes > 60) { // Only log if significant sleep found
             // Associate with the "Wake Up Day" (End date)
             final wakeUpDate = sleepData.last.dateTo;
             final logDate = DateTime(wakeUpDate.year, wakeUpDate.month, wakeUpDate.day);
             
             // Check if already logged to avoid overwrite with partial data?
             // Since we use insertOnConflictUpdate, we should be careful.
             // Ideally we only update if 'isSynced' or if generic.
             
             await db.addSleepLog(SleepLogsCompanion(
               date: Value(logDate),
               durationMinutes: Value(totalMinutes),
               isSynced: const Value(true),
               quality: const Value(0), // Unknown in background
             ));
             
             debugPrint("[BackgroundSync] Saved Sleep Log: $totalMinutes min for $logDate");
           }
        }

        await db.close();
        return Future.value(true);
        
      } catch (e) {
        debugPrint("[BackgroundSync] Error: $e");
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}
