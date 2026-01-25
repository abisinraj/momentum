import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/user_providers.dart';

/// Screen to select number of days in the split
class SplitSetupScreen extends ConsumerStatefulWidget {
  const SplitSetupScreen({super.key});

  @override
  ConsumerState<SplitSetupScreen> createState() => _SplitSetupScreenState();
}

class _SplitSetupScreenState extends ConsumerState<SplitSetupScreen> {
  int _selectedDays = 4;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          'Create Your Split',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'How many days a week do you plan to workout? We\'ll help you organize your routine.',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Day Selector
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_selectedDays',
                                style: TextStyle(
                                  fontSize: 120,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                'DAYS / WEEK',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: colorScheme.primary,
                            inactiveTrackColor: colorScheme.surfaceContainerHighest,
                            thumbColor: colorScheme.surface,
                            overlayColor: colorScheme.primary.withValues(alpha: 0.2),
                            thumbShape: _CustomThumbShape(colorScheme),
                            trackHeight: 8,
                          ),
                          child: Slider(
                            value: _selectedDays.toDouble(),
                            min: 1,
                            max: 7,
                            divisions: 6,
                            onChanged: (value) {
                              setState(() => _selectedDays = value.round());
                            },
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () async {
                              // Save the selected split configuration
                              await ref.read(userSetupProvider.notifier).setSplitDays(_selectedDays);
                              
                              // Start the creation wizard
                              if (context.mounted) {
                                context.push('/create-workout/1/$_selectedDays');
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Start Building',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CustomThumbShape extends SliderComponentShape {
  final ColorScheme colorScheme;
  _CustomThumbShape(this.colorScheme);

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(32, 32);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    
    // Outer ring
    final paintOuter = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 16, paintOuter);
    
    // Inner circle
    final paintInner = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(center, 8, paintInner);
  }
}
