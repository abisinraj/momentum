import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/health_connect_service.dart';

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
  final int? latestHeartRate;
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
    this.latestHeartRate,
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
    int? latestHeartRate,
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
      latestHeartRate: latestHeartRate ?? this.latestHeartRate,
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
      state = state.copyWith(
        isAvailable: isAvailable,
        hasPermissions: hasPerms,
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
      
      // Fetch heart rate (today)
      final hrData = await _service.fetchHeartRate(todayStart, now);
      int? latestHeartRate;
      if (hrData.isNotEmpty) {
        final numericValue = hrData.last.value;
        if (numericValue is NumericHealthValue) {
          latestHeartRate = numericValue.numericValue.toInt();
        }
      }
      
      // Fetch sleep (last night - from yesterday 6PM to today 12PM)
      final sleepStart = DateTime(yesterdayStart.year, yesterdayStart.month, yesterdayStart.day, 18);
      final sleepEnd = DateTime(todayStart.year, todayStart.month, todayStart.day, 12);
      final sleepData = await _service.fetchSleep(sleepStart, sleepEnd);
      Duration? totalSleep;
      if (sleepData.isNotEmpty) {
        int totalMinutes = 0;
        for (final point in sleepData) {
          if (point.type == HealthDataType.SLEEP_ASLEEP) {
            totalMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
          }
        }
        totalSleep = Duration(minutes: totalMinutes);
      }
      
      // Fetch recent workouts (last 7 days)
      final workouts = await _service.fetchWorkouts(weekAgo, now);
      
      state = state.copyWith(
        isLoading: false,
        todaySteps: steps,
        latestWeight: latestWeight,
        latestHeartRate: latestHeartRate,
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
