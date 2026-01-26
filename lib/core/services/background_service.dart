import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages the background service for lock screen controls
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'momentum_workout_channel',
      'Workout Controls',
      description: 'Shows active workout controls',
      importance: Importance.low, // Low importance to prevent sound on every update
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);


    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // This will be executed in the isolate
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'momentum_workout_channel',
        initialNotificationTitle: 'Momentum',
        initialNotificationContent: 'Workout Active',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }
  
  // Call this from the main app to start
  Future<void> startService(String workoutName) async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      service.startService();
    }
    service.invoke('set_workout_name', {'name': workoutName});
  }
  
  // Call this to stop
  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
  
  // Call this to set start time for auto-ticking
  void setStartTime(DateTime startedAt) {
    final service = FlutterBackgroundService();
    service.invoke('set_start_time', {'epoch': startedAt.millisecondsSinceEpoch});
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String workoutName = "Workout";
  
  Timer? timer;
  DateTime? startedAt;

  // Listen for stop
  service.on('stopService').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });
  
  // Listen for name update
  service.on('set_workout_name').listen((event) {
    if (event != null && event['name'] != null) {
      workoutName = event['name'] as String;
      _updateNotification(flutterLocalNotificationsPlugin, workoutName, "00:00");
    }
  });

  // Listen for start time
  service.on('set_start_time').listen((event) {
    if (event != null && event['epoch'] != null) {
      final epoch = event['epoch'] as int;
      startedAt = DateTime.fromMillisecondsSinceEpoch(epoch);
      
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (startedAt == null) return;
          final diff = DateTime.now().difference(startedAt!);
          final hours = diff.inHours;
          final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
          final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
          final timeStr = hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
          
          _updateNotification(flutterLocalNotificationsPlugin, workoutName, timeStr);
      });
    }
  });

}

Future<void> _updateNotification(
    FlutterLocalNotificationsPlugin plugin,
    String title,
    String content) async {
  
  plugin.show(
    888,
    title,
    content,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'momentum_workout_channel',
        'Workout Controls',
        icon: 'launcher_icon',
        ongoing: true,

        showWhen: false, // Hide timestamp
        onlyAlertOnce: true, // Don't buzz on updates
        color: Color(0xFF000000), // Dark background color hint
      ),
    ),
  );
}
