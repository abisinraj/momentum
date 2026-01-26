import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/notification_service.dart';

import 'app/app.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // BackgroundService removed for stability
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Initialization Failed: $e');
  }


  // Global error handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}\n${details.stack}');
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error\n$stack');
    return true;
  };

  final container = ProviderContainer();

  // Run app in the same zone as Flutter bindings
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MomentumApp(),
    ),
  );
}

