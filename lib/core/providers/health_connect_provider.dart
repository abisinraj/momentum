
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' show Value;
import '../services/health_connect_service.dart';
import 'database_providers.dart';

part 'health_connect_provider.g.dart';

/// Provider for the Health Connect service instance.
@riverpod
HealthConnectService healthConnectService(Ref ref) {
  return HealthConnectService();
}

/// State class for health data.
class HealthState {
  final bool isAvailable;
  final bool hasPermissions;
  final bool isLoading;
  final int todaySteps;
  final double? latestWeight;
  final Duration? lastNightSleep;
  final List<HealthDataPoint> recentWorkouts;
  final String? error;
  final DateTime? lastSyncTime;

  const HealthState({
    this.isAvailable = false,
    this.hasPermissions = false,
    this.isLoading = false,
    this.todaySteps = 0,
    this.latestWeight,
    this.lastNightSleep,
    this.recentWorkouts = const [],
    this.error,
    this.lastSyncTime,
  });

  HealthState copyWith({
    bool? isAvailable,
    bool? hasPermissions,
    bool? isLoading,
    int? todaySteps,
    double? latestWeight,
    Duration? lastNightSleep,
    List<HealthDataPoint>? recentWorkouts,
    String? error,
    DateTime? lastSyncTime,
  }) {
    return HealthState(
      isAvailable: isAvailable ?? this.isAvailable,
      hasPermissions: hasPermissions ?? this.hasPermissions,
      isLoading: isLoading ?? this.isLoading,
      todaySteps: todaySteps ?? this.todaySteps,
      latestWeight: latestWeight ?? this.latestWeight,
      lastNightSleep: lastNightSleep ?? this.lastNightSleep,
      recentWorkouts: recentWorkouts ?? this.recentWorkouts,
      error: error,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

/// Notifier for managing health data state.
@riverpod
class HealthNotifier extends _$HealthNotifier {
  late HealthConnectService _service;

  @override
  HealthState build() {
    _service = ref.watch(healthConnectServiceProvider);
    _checkAvailability();
    return const HealthState();
  }

  Future<void> _checkAvailability() async {
    final status = await HealthConnectService.checkAvailability();
    final isAvailable = status == HealthConnectSdkStatus.sdkAvailable;
    
    if (isAvailable) {
      final hasPerms = await _service.hasPermissions();
      double? weight;
      if (hasPerms) {
        // ... handled in syncData
      } else {
         // Fallback immediately for manual weight
         final profile = await ref.read(appDatabaseProvider).getUser();
         weight = profile?.weightKg;
      }
      
      state = state.copyWith(
        isAvailable: isAvailable,
        hasPermissions: hasPerms,
        latestWeight: weight,
      );
    } else {
      state = state.copyWith(isAvailable: false);
    }
  }

  /// Request Health Connect permissions.
  Future<bool> requestPermissions() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final granted = await _service.requestPermissions();
      state = state.copyWith(
        hasPermissions: granted,
        isLoading: false,
      );
      
      if (granted) {
        await syncData();
      }
      
      return granted;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request permissions: $e',
      );
      return false;
    }
  }

  /// Sync all health data from Health Connect.
  Future<void> syncData() async {
    if (!state.hasPermissions) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));
      final weekAgo = now.subtract(const Duration(days: 7));
      
      // Fetch today's steps
      final steps = await _service.fetchSteps(todayStart, now);
      
      // Fetch weight (last 7 days)
      final weightData = await _service.fetchWeight(weekAgo, now);
      double? latestWeight;
      if (weightData.isNotEmpty) {
        final numericValue = weightData.last.value;
        if (numericValue is NumericHealthValue) {
          latestWeight = numericValue.numericValue.toDouble();
        }
      }

      // Fallback to manual weight from profile if no health data
      if (latestWeight == null) {
        final profile = await ref.read(appDatabaseProvider).getUser();
        latestWeight = profile?.weightKg;
      }
      
      
      // Fetch sleep (last night - from yesterday 6PM to today 12PM)
      final sleepStart = DateTime(yesterdayStart.year, yesterdayStart.month, yesterdayStart.day, 18);
      final sleepEnd = DateTime(todayStart.year, todayStart.month, todayStart.day, 12);
      final sleepData = await _service.fetchSleep(sleepStart, sleepEnd);
      Duration? totalSleep;
      
      if (sleepData.isNotEmpty) {
        int totalMinutes = 0;
        int? deepSleep;
        int? remSleep;
        
        for (final point in sleepData) {
          final duration = point.dateTo.difference(point.dateFrom).inMinutes;
          if (point.type == HealthDataType.SLEEP_ASLEEP) {
            totalMinutes += duration;
          } else if (point.type == HealthDataType.SLEEP_DEEP) {
            deepSleep = (deepSleep ?? 0) + duration;
          } else if (point.type == HealthDataType.SLEEP_REM) {
            remSleep = (remSleep ?? 0) + duration;
          }
        }
        totalSleep = Duration(minutes: totalMinutes);
        
        // PERSIST: Save to database
        if (totalMinutes > 0) {
          await ref.read(appDatabaseProvider).addSleepLog(SleepLogsCompanion(
                date: Value(todayStart),
                durationMinutes: Value(totalMinutes),
                deepSleepMinutes: Value(deepSleep),
                remSleepMinutes: Value(remSleep),
                isSynced: const Value(true),
              ));
        }
      }
      
      // Fetch recent workouts (last 7 days)
      final workouts = await _service.fetchWorkouts(weekAgo, now);
      
      state = state.copyWith(
        isLoading: false,
        todaySteps: steps,
        latestWeight: latestWeight,
        lastNightSleep: totalSleep,
        recentWorkouts: workouts,
        lastSyncTime: now,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sync data: $e',
      );
    }
  }
}
