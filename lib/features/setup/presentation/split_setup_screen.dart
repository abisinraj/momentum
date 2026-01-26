import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/providers/workout_providers.dart';

/// Screen to select number of days in the split OR use a pre-made split
class SplitSetupScreen extends ConsumerStatefulWidget {
  const SplitSetupScreen({super.key});

  @override
  ConsumerState<SplitSetupScreen> createState() => _SplitSetupScreenState();
}

class _SplitSetupScreenState extends ConsumerState<SplitSetupScreen> {
  int _selectedDays = 4;
  bool _isPreMadeMode = false; // Toggle state
  bool _isSaving = false;

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
                          'Choose how you want to structure your weekly routine.',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 32),

                        // Mode Toggle
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildModeButton(
                                  context,
                                  title: 'Custom',
                                  isSelected: !_isPreMadeMode,
                                  onTap: () => setState(() => _isPreMadeMode = false),
                                ),
                              ),
                              Expanded(
                                child: _buildModeButton(
                                  context,
                                  title: 'Pre-made',
                                  isSelected: _isPreMadeMode,
                                  onTap: () => setState(() => _isPreMadeMode = true),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                        
                        // Dynamic Content
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isPreMadeMode 
                              ? _buildPreMadeView(context)
                              : _buildCustomView(context),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSaving ? null : () async {
                              if (_isPreMadeMode) {
                                await _applyPreMadeSplit();
                              } else {
                                // Custom Flow
                                await ref.read(userSetupProvider.notifier).setSplitDays(_selectedDays);
                                if (context.mounted) {
                                  context.push('/create-workout/1/$_selectedDays');
                                }
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
                            child: _isSaving
                              ? SizedBox(
                                  height: 20, 
                                  width: 20, 
                                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary)
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isPreMadeMode ? 'Use This Split' : 'Start Building',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward),
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

  Widget _buildModeButton(BuildContext context, {required String title, required bool isSelected, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('custom'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
         const Spacer(),
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
            onChanged: (value) => setState(() => _selectedDays = value.round()),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildPreMadeView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('premade'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '8-Day Cycle optimized for balanced strength and conditioning.',
                  style: TextStyle(color: colorScheme.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            children: const [
              _SplitItem(day: 1, title: 'Upper Body Push', desc: 'Push-ups, Dips, Plank'),
              _SplitItem(day: 2, title: 'Boxing Basics', desc: 'Rope, Shadow Boxing, Footwork'),
              _SplitItem(day: 3, title: 'Lower Body', desc: 'Squats, Lunges, Calves'),
              _SplitItem(day: 4, title: 'Upper Body Pull', desc: 'Pull-ups, Rows, Holds'),
              _SplitItem(day: 5, title: 'Boxing Basics 2', desc: 'Bag work, Core'),
              _SplitItem(day: 6, title: 'Full Body', desc: 'Burpees, Climbers, Squats'),
              _SplitItem(day: 7, title: 'Conditioning', desc: 'HIIT & Core'),
              _SplitItem(day: 8, title: 'Rest Day', desc: 'Recovery'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _applyPreMadeSplit() async {
    setState(() => _isSaving = true);
    
    try {
      final db = ref.read(appDatabaseProvider);
      
      // Update user split days
      final user = await db.getUser();
      if (user != null) {
        await db.saveUser(user.toCompanion(true).copyWith(
          splitDays: const drift.Value(8),
        ));
      }

      // Helper to create workout day
      Future<void> createDay({
        required String name,
        required String shortCode,
        required String thumbnail,
        required int dayIndex,
        required ClockType clockType,
        required bool isRestDay,
        List<({String name, int sets, int reps})> exercises = const [],
      }) async {
        final workoutId = await db.addWorkout(
          WorkoutsCompanion(
            name: drift.Value(name),
            shortCode: drift.Value(shortCode),
            thumbnailUrl: drift.Value(thumbnail),
            orderIndex: drift.Value(dayIndex),
            clockType: drift.Value(clockType),
            isRestDay: drift.Value(isRestDay),
          ),
        );

        if (!isRestDay) {
          for (int i = 0; i < exercises.length; i++) {
            final ex = exercises[i];
            await db.addExercise(
              ExercisesCompanion(
                workoutId: drift.Value(workoutId),
                name: drift.Value(ex.name),
                sets: drift.Value(ex.sets),
                reps: drift.Value(ex.reps),
                orderIndex: drift.Value(i),
              ),
            );
          }
        }
      }

      // --- Define 8-Day Split ---
      
      // DAY 1: Upper Body Push
      await createDay(
        name: 'Upper Body Push', shortCode: 'U',
        thumbnailUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&q=80',
        dayIndex: 0, clockType: ClockType.stopwatch, isRestDay: false,
        exercises: [
          (name: 'Push-ups', sets: 3, reps: 12),
          (name: 'Pike push-ups', sets: 3, reps: 10),
          (name: 'Tricep dips', sets: 3, reps: 12),
          (name: 'Plank hold (sec)', sets: 3, reps: 45),
        ],
      );

      // DAY 2: Boxing Basics
      await createDay(
        name: 'Boxing Basics', shortCode: 'B',
        thumbnailUrl: 'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff?auto=format&fit=crop&q=80',
        dayIndex: 1, clockType: ClockType.stopwatch, isRestDay: false,
        exercises: [
          (name: 'Jump rope (sec)', sets: 3, reps: 120),
          (name: 'Shadow boxing (sec)', sets: 3, reps: 180),
          (name: 'Stance/Footwork (sec)', sets: 1, reps: 600),
          (name: 'Combo practice (sec)', sets: 3, reps: 120),
        ],
      );

      // DAY 3: Lower Body
      await createDay(
        name: 'Lower Body', shortCode: 'L',
        thumbnailUrl: 'https://images.unsplash.com/photo-1434608519344-49d77a699ded?auto=format&fit=crop&q=80',
        dayIndex: 2, clockType: ClockType.stopwatch, isRestDay: false,
        exercises: [
          (name: 'Bodyweight squats', sets: 3, reps: 15),
          (name: 'Lunges (per leg)', sets: 3, reps: 10),
          (name: 'Glute bridges', sets: 3, reps: 15),
          (name: 'Calf raises', sets: 3, reps: 20),
        ],
      );

      // DAY 4: Upper Body Pull
      await createDay(
        name: 'Upper Body Pull', shortCode: 'P',
        thumbnailUrl: 'https://images.unsplash.com/photo-1598971639058-211a73287750?auto=format&fit=crop&q=80',
        dayIndex: 3, clockType: ClockType.stopwatch, isRestDay: false,
        exercises: [
          (name: 'Australian pull-ups', sets: 3, reps: 12),
          (name: 'Inverted rows', sets: 3, reps: 10),
          (name: 'Superman holds (sec)', sets: 3, reps: 30),
          (name: 'Dead hangs (sec)', sets: 3, reps: 30),
        ],
      );

      // DAY 5: Boxing Basics 2
      await createDay(
        name: 'Boxing Basics 2', shortCode: 'B',
        thumbnailUrl: 'https://images.unsplash.com/photo-1549719386-74dfcbf7dbed?auto=format&fit=crop&q=80',
        dayIndex: 4, clockType: ClockType.stopwatch, isRestDay: false,
        exercises: [
          (name: 'Jump rope (sec)', sets: 3, reps: 120),
          (name: 'Heavy bag/Shadow (sec)', sets: 4, reps: 180),
          (name: 'Slip/Roll drills (sec)', sets: 1, reps: 600),
          (name: 'Sit-ups', sets: 3, reps: 20),
          (name: 'Russian twists', sets: 3, reps: 20),
        ],
      );

      // DAY 6: Full Body
      await createDay(
        name: 'Full Body', shortCode: 'F',
        thumbnailUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80',
        dayIndex: 5, clockType: ClockType.stopwatch, isRestDay: false,
        exercises: [
          (name: 'Burpees', sets: 3, reps: 10),
          (name: 'Mountain climbers', sets: 3, reps: 20),
          (name: 'Bodyweight squats', sets: 3, reps: 12),
          (name: 'Push-ups', sets: 3, reps: 10),
          (name: 'Plank (sec)', sets: 3, reps: 45),
        ],
      );

      // DAY 7: Conditioning
      await createDay(
        name: 'Conditioning & Core', shortCode: 'C',
        thumbnailUrl: 'https://images.unsplash.com/photo-1601422407692-ec4eeec1d9b3?auto=format&fit=crop&q=80',
        dayIndex: 6, clockType: ClockType.stopwatch, isRestDay: false,
        exercises: [
          (name: 'Jump rope (sec)', sets: 4, reps: 180),
          (name: 'Burpees', sets: 3, reps: 12),
          (name: 'Mountain climbers (sec)', sets: 3, reps: 30),
          (name: 'Plank to Down Dog', sets: 3, reps: 10),
          (name: 'Bicycle crunches', sets: 3, reps: 20),
          (name: 'Leg raises', sets: 3, reps: 12),
          (name: 'Flutter kicks (sec)', sets: 3, reps: 30),
        ],
      );

      // DAY 8: Rest
      await createDay(
        name: 'Rest Day', shortCode: 'R',
        thumbnailUrl: 'assets/images/rest_day.jpg',
        dayIndex: 7, clockType: ClockType.none, isRestDay: true,
      );

      // Finish
      ref.invalidate(workoutsStreamProvider);
      ref.invalidate(isSetupCompleteProvider);
      
      if (mounted) {
        context.go('/home');
      }

    } catch (e) {
      debugPrint('Error creating pre-made split: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _SplitItem extends StatelessWidget {
  final int day;
  final String title;
  final String desc;

  const _SplitItem({required this.day, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Day $day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
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
