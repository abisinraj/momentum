import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidChannel = AndroidNotificationChannel(
      'momentum_alerts_channel',
      'Momentum Alerts',
      description: 'Important training reminders',
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
        
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
    );
    
    await _plugin.initialize(initializationSettings);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'momentum_alerts_channel',
      'Momentum Alerts',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'launcher_icon',
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details, payload: payload);
  }
}
