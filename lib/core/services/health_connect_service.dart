import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for interacting with Google Health Connect.
class HealthConnectService {
  final Health _health = Health();
  
  /// Data types we want to read from Health Connect.
  static const List<HealthDataType> _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.WEIGHT,
    HealthDataType.WORKOUT,
  ];
  
  /// Check if Health Connect is available on this device.
  Future<HealthConnectSdkStatus> checkAvailability() async {
    return await Health().getHealthConnectSdkStatus();
  }
  
  /// Request permissions for activity recognition (required for steps).
  Future<bool> requestActivityRecognition() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }
  
  /// Request Health Connect permissions for all data types.
  Future<bool> requestPermissions() async {
    // First request activity recognition
    await requestActivityRecognition();
    
    // Then request Health Connect permissions
    final permissions = _dataTypes.map((type) => HealthDataAccess.READ).toList();
    
    final granted = await _health.requestAuthorization(
      _dataTypes,
      permissions: permissions,
    );
    
    return granted;
  }
  
  /// Check if we have all required permissions.
  Future<bool> hasPermissions() async {
    final permissions = _dataTypes.map((type) => HealthDataAccess.READ).toList();
    return await _health.hasPermissions(_dataTypes, permissions: permissions) ?? false;
  }
  
  /// Fetch step count for a given date range.
  Future<int> fetchSteps(DateTime start, DateTime end) async {
    try {
      final steps = await _health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Fetch heart rate data for a given date range.
  Future<List<HealthDataPoint>> fetchHeartRate(DateTime start, DateTime end) async {
    try {
      return await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );
    } catch (e) {
      return [];
    }
  }
  
  /// Fetch sleep data for a given date range.
  Future<List<HealthDataPoint>> fetchSleep(DateTime start, DateTime end) async {
    try {
      return await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP, HealthDataType.SLEEP_AWAKE],
        startTime: start,
        endTime: end,
      );
    } catch (e) {
      return [];
    }
  }
  
  /// Fetch weight data for a given date range.
  Future<List<HealthDataPoint>> fetchWeight(DateTime start, DateTime end) async {
    try {
      return await _health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: start,
        endTime: end,
      );
    } catch (e) {
      return [];
    }
  }
  
  /// Fetch workout data for a given date range.
  Future<List<HealthDataPoint>> fetchWorkouts(DateTime start, DateTime end) async {
    try {
      return await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: start,
        endTime: end,
      );
    } catch (e) {
      return [];
    }
  }
  
  /// Fetch all health data for a given date range.
  Future<List<HealthDataPoint>> fetchAllData(DateTime start, DateTime end) async {
    try {
      return await _health.getHealthDataFromTypes(
        types: _dataTypes,
        startTime: start,
        endTime: end,
      );
    } catch (e) {
      return [];
    }
  }
}
