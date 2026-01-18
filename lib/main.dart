import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

import 'dart:async';
import 'package:flutter/foundation.dart';

void main() {
  // Global error handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}\n${details.stack}');
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Platform Error: $error\n$stack');
    return true;
  };

  runZonedGuarded(
    () => runApp(
      const ProviderScope(
        child: MomentumApp(),
      ),
    ),
    (error, stack) {
      print('Zoned Error: $error\n$stack');
    },
  );
}
