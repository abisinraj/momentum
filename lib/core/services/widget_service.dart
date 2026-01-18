import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../providers/database_providers.dart';

part 'widget_service.g.dart';

/// Service for syncing data to Android Home Screen Widget
class WidgetService {
  static const String _prefsName = 'MomentumWidgetPrefs';
  static const String _activityKey = 'activity_data';
  static const MethodChannel _channel = MethodChannel('com.momentum.momentum/widget');
  
  /// Update widget with latest activity data
  static Future<void> updateWidget(Map<DateTime, String> activityMap) async {
    try {
      // Get last 30 days
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Build activity string (1 for active, 0 for rest)
      final activityList = <String>[];
      for (int i = 29; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);
        final hasActivity = activityMap.containsKey(dateKey);
        activityList.add(hasActivity ? '1' : '0');
      }
      
      final activityString = activityList.join(',');
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activityKey, activityString);
      
      // Trigger widget update via platform channel (if on Android)
      try {
        await _channel.invokeMethod('updateWidget');
      } catch (e) {
        // Platform channel may not be available on web
      }
    } catch (e) {
      print('Error updating widget: $e');
    }
  }
}

/// Provider for widget sync service
@riverpod
Future<void> syncWidgetData(ref) async {
  final db = ref.watch(appDatabaseProvider);
  final activityMap = await db.getActivityGrid(30);
  await WidgetService.updateWidget(activityMap);
}
