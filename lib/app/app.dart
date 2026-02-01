import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import '../core/services/settings_service.dart';
import '../core/services/widget_service.dart';

import 'theme/app_theme.dart';
import 'router.dart';

/// Design: Ocean Blue logo centered with "Momentum" text below
class MomentumApp extends ConsumerWidget {
  const MomentumApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Keep widget sync active globally
    // ignore: unused_result
    ref.watch(widgetSyncProvider);
    final themeModeAsync = ref.watch(appThemeModeProvider);
    final themeKey = themeModeAsync.valueOrNull ?? 'black';
    
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final theme = AppTheme.getTheme(themeKey);
        
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: theme.appBarTheme.systemOverlayStyle ?? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
          ),
          child: MaterialApp.router(
            title: 'Momentum',
            debugShowCheckedModeBanner: false,
            
            // Theme configuration
            theme: theme,
            darkTheme: theme,
            themeMode: ThemeMode.dark,
            
            // Router configuration
            routerConfig: router,
          ),
        );
      },
    );
  }
}
