import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import '../core/services/settings_service.dart';

import 'theme/app_theme.dart';
import 'router.dart';

/// The root Momentum app with Material 3 and dynamic color support
class MomentumApp extends ConsumerWidget {
  const MomentumApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeModeAsync = ref.watch(appThemeModeProvider);
    final themeKey = themeModeAsync.valueOrNull ?? 'teal';
    
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'Momentum',
          debugShowCheckedModeBanner: false,
          
          // Theme configuration
          // Only force dark mode for now, but use our custom theme generation
          theme: AppTheme.getTheme(themeKey),
          darkTheme: AppTheme.getTheme(themeKey),
          themeMode: ThemeMode.dark,
          
          // Router configuration
          routerConfig: router,
        );
      },
    );
  }
}
