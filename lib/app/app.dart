import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'theme/app_theme.dart';
import 'router.dart';

/// The root Momentum app with Material 3 and dynamic color support
class MomentumApp extends ConsumerWidget {
  const MomentumApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'Momentum',
          debugShowCheckedModeBanner: false,
          
          // Theme configuration - Momentum uses dark theme only
          theme: AppTheme.dark(dynamicScheme: null),
          darkTheme: AppTheme.dark(dynamicScheme: null),
          themeMode: ThemeMode.dark,
          
          // Router configuration
          routerConfig: router,
        );
      },
    );
  }
}
