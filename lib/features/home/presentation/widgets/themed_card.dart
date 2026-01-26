import 'dart:ui';
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24), // More rounded for liquid feel
        child: BackdropFilter(
          // Blur is subtle but adds depth if elements overlap or scrolling
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                       colorScheme.surfaceContainer.withValues(alpha: 0.7),
                       colorScheme.surfaceContainer.withValues(alpha: 0.3),
                     ],
                   ),
                   boxShadow: [
                     BoxShadow(
                       color: colorScheme.primary.withValues(alpha: 0.05),
                       blurRadius: 20,
                       offset: const Offset(0, 8),
                     ),
                   ],
                 ),
                 child: AnimatedSize(
                   duration: const Duration(milliseconds: 300),
                   curve: Curves.easeInOut,
                   child: child,
                 ),
               ),
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
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: child,
          ),
        ),
      ),
    );
  }
}
