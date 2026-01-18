import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/workout_providers.dart';
import '../../../core/database/app_database.dart';
import '../../workout/presentation/active_workout_screen.dart';

/// Home screen - shows next workout in cycle with Momentum design
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextWorkoutAsync = ref.watch(nextWorkoutProvider);
    final userAsync = ref.watch(currentUserProvider);
    final activeSession = ref.watch(activeWorkoutSessionProvider);
    
    // If there's an active session, navigate to it
    if (activeSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActiveWorkoutScreen(session: activeSession),
          ),
        );
      });
    }
    
    final userName = switch (userAsync) {
      AsyncData(:final value) => value?.name ?? 'Athlete',
      _ => 'Athlete',
    };
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting and notification bell
              _buildHeader(context, userName),
              
              const Spacer(),
              
              // Main workout content
              switch (nextWorkoutAsync) {
                AsyncData(:final value) => _buildWorkoutContent(context, ref, value),
                AsyncError(:final error) => _buildErrorState(context, error.toString()),
                _ => const Center(child: CircularProgressIndicator()),
              },
              
              const Spacer(),
              
              // Bottom stats row
              _buildStatsRow(context, ref),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        // Notification bell
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: AppTheme.tealPrimary,
            ),
            onPressed: () {
              // TODO: Notifications
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildWorkoutContent(BuildContext context, WidgetRef ref, Workout? workout) {
    if (workout == null) {
      return _buildEmptyState(context);
    }
    
    return Column(
      children: [
        // Today's Focus badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt,
                size: 16,
                color: AppTheme.tealPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                "TODAY'S FOCUS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.tealPrimary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Large workout name with accent styling
        _buildWorkoutTitle(workout.name),
        
        const SizedBox(height: 16),
        
        // Workout description / clock type
        Text(
          _getWorkoutDescription(workout),
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 40),
        
        // Start Workout Button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
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
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.tealPrimary,
              foregroundColor: AppTheme.darkBackground,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'START WORKOUT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.play_arrow, size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildWorkoutTitle(String name) {
    // Split name into words and style the middle word with yellow accent
    final words = name.split(' ');
    
    if (words.length == 1) {
      return Text(
        name.toUpperCase(),
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      );
    }
    
    // For multi-word names, accent the middle or second word
    final accentIndex = words.length > 2 ? 1 : 0;
    
    return Column(
      children: words.asMap().entries.map((entry) {
        final isAccent = entry.key == accentIndex;
        return Text(
          entry.value.toUpperCase(),
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: isAccent ? AppTheme.yellowAccent : AppTheme.textPrimary,
            height: 1.2,
          ),
        );
      }).toList(),
    );
  }
  
  String _getWorkoutDescription(Workout workout) {
    final clockDesc = switch (workout.clockType) {
      ClockType.none => 'Freestyle workout',
      ClockType.stopwatch => 'Timed with stopwatch',
      ClockType.timer => workout.timerDurationSeconds != null
          ? 'Timer: ${workout.timerDurationSeconds! ~/ 60} minutes'
          : 'Timer workout',
      ClockType.alarm => 'Alarm when complete',
    };
    return clockDesc;
  }
  
  Widget _buildStatsRow(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityGridProvider(days: 7));
    
    final activeDays = switch (activityAsync) {
      AsyncData(:final value) => value.length,
      _ => 0,
    };
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.local_fire_department_outlined,
              value: '${activeDays * 60}',
              label: 'KCAL BURNED',
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: AppTheme.darkBorder,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.timer_outlined,
              value: '${activeDays * 45}m',
              label: 'ACTIVE MIN',
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.tealPrimary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.fitness_center_outlined,
          size: 80,
          color: AppTheme.textMuted,
        ),
        const SizedBox(height: 24),
        Text(
          'No workouts yet',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add workouts in the Workout tab\nto start building momentum',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildErrorState(BuildContext context, String error) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: AppTheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Something went wrong',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
