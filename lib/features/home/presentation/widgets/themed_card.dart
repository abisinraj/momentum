
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momentum/core/services/settings_service.dart';

class ThemedCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(widgetThemeProvider);
    final theme = themeAsync.valueOrNull ?? 'classic';
    debugPrint('ThemedCard: $theme');

    if (theme == 'liquid_glass') {
      return _buildLiquidGlass(context);
    }
    return _buildClassic(context);
  }

  Widget _buildLiquidGlass(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: margin,
      child: Material(
         color: Colors.transparent, // Important for InkWell
         child: InkWell(
           onTap: onTap,
           borderRadius: BorderRadius.circular(24),
           child: Container(
             padding: padding,
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(24),
               border: Border.all(
                 color: colorScheme.onSurface.withValues(alpha: 0.15), 
                 width: 1.5
               ),
               gradient: LinearGradient(
                 begin: Alignment.topLeft,
                 end: Alignment.bottomRight,
                 colors: [
                   colorScheme.surfaceContainer.withValues(alpha: 0.60), // More transparent
                   colorScheme.surfaceContainer.withValues(alpha: 0.30),
                 ],
               ),
               boxShadow: [
                 BoxShadow(
                   color: colorScheme.shadow.withValues(alpha: 0.1),
                   blurRadius: 15,
                   offset: const Offset(0, 5),
                 ),
                 // Inner highlight simulation via border and gradient
               ],
             ),
             child: Container(
               decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(24),
                 gradient: LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: [
                     Colors.white.withValues(alpha: 0.05), // Top reflection
                     Colors.transparent,
                   ],
                   stops: const [0.0, 0.4],
                 ),
               ),
               child: child,
             ),
           ),
         ),
      ),
    );
  }

  Widget _buildClassic(BuildContext context) {
    // Standard AppTheme Card style
    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
            child: child,
        ),
      ),
    );
  }
}
