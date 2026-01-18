import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/providers/workout_providers.dart';
import '../../../core/database/app_database.dart';
import '../../workout/presentation/active_workout_screen.dart';

/// Home screen - shows next workout in cycle
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nextWorkoutAsync = ref.watch(nextWorkoutProvider);
    final activeSession = ref.watch(activeWorkoutSessionProvider);
    
    // If there's an active session, show the active workout screen
    if (activeSession != null) {
      // Use addPostFrameCallback to avoid build errors
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActiveWorkoutScreen(session: activeSession),
          ),
        );
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Momentum'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: switch (nextWorkoutAsync) {
            AsyncData(:final value) => _buildContent(context, ref, value),
            AsyncError(:final error) => Text('Error: $error'),
            _ => const CircularProgressIndicator(),
          },
        ),
      ),
    );
  }
  
  Widget _buildContent(
    BuildContext context, 
    WidgetRef ref, 
    Workout? workout,
  ) {
    final theme = Theme.of(context);
    
    // If no workouts defined
    if (workout == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'No workouts yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add workouts in the Workout tab',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }
    
    // Show next workout
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Workout icon with short code
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              workout.shortCode,
              style: theme.textTheme.displayLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Next Workout',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          workout.name,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildClockTypeChip(context, workout.clockType),
        if (workout.clockType == ClockType.timer && workout.timerDurationSeconds != null) ...[
          const SizedBox(height: 4),
          Text(
            '${workout.timerDurationSeconds! ~/ 60} minutes',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () async {
            await ref.read(activeWorkoutSessionProvider.notifier)
                .startWorkout(workout);
            
            if (context.mounted) {
              final session = ref.read(activeWorkoutSessionProvider);
              if (session != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ActiveWorkoutScreen(session: session),
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }
  
  Widget _buildClockTypeChip(BuildContext context, ClockType clockType) {
    final theme = Theme.of(context);
    
    final (icon, label) = switch (clockType) {
      ClockType.none => (Icons.timer_off_outlined, 'No timer'),
      ClockType.stopwatch => (Icons.timer_outlined, 'Stopwatch'),
      ClockType.timer => (Icons.hourglass_bottom, 'Timer'),
      ClockType.alarm => (Icons.alarm, 'Alarm'),
    };
    
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    );
  }
}

