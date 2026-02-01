
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
         color: Colors.transparent,
         child: InkWell(
           onTap: onTap,
           borderRadius: BorderRadius.circular(24),
           child: Container(
             padding: padding,
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(24),
               border: Border.all(
                 color: colorScheme.outline.withValues(alpha: 0.2), 
                 width: 1.0
               ),
               color: Colors.transparent, // Fully transparent background
             ),
             child: child,
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
