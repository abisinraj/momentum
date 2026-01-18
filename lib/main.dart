import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/providers/database_providers.dart';
import 'core/database/seed_data.dart';

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

  // Seed Data Check
  final container = ProviderContainer();
  try {
    final db = container.read(appDatabaseProvider);
    final isSetup = await db.isSetupComplete();
    
    if (!isSetup) {
      print('Database empty. Seeding "Abisin Raj" profile and 7-day split...');
      await seedDatabase(db);
      print('Seeding complete.');
    }
  } catch (e) {
    print('Error during seeding: $e');
  }

  runZonedGuarded(
    () => runApp(
      UncontrolledProviderScope(
        container: container,
        child: const MomentumApp(),
      ),
    ),
    (error, stack) {
      print('Zoned Error: $error\n$stack');
    },
  );
}
