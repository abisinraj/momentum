import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/providers/database_providers.dart';

import 'dart:async';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}\n${details.stack}');
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Platform Error: $error\n$stack');
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

