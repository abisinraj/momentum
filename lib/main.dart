

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:momentum/core/services/background_sync_service.dart';

import 'package:momentum/core/services/notification_service.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'app/app.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Set high refresh rate for smoother UI on supported Android devices
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
      try {
        await FlutterDisplayMode.setHighRefreshRate();
      } catch (e) {
        debugPrint('Failed to set high refresh rate: $e');
      }
    }

    // BackgroundService removed for stability
    await NotificationService().initialize();
    
    // Initialize Workmanager
    Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      // isInDebugMode: kDebugMode, // Deprecated and removed
    );
    
    // Register Periodic Task (Every 4 hours)
    Workmanager().registerPeriodicTask(
      "momentum-health-sync", 
      kBackgroundSyncTask,
      frequency: const Duration(hours: 4),
      constraints: Constraints(
        networkType: NetworkType.connected, 
        requiresBatteryNotLow: true,
      ),
      initialDelay: const Duration(minutes: 15),
    );
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

