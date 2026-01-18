import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/workout_providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/ai_insights_service.dart';
import '../../workout/presentation/active_workout_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
    // REMOVED: User prefers manual control
    /*
    if (activeSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActiveWorkoutScreen(session: activeSession),
          ),
        );
      });
    }
    */
    
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
                AsyncData(:final value) => _buildWorkoutContent(context, ref, value, activeSession),
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
  
  Widget _buildWorkoutContent(BuildContext context, WidgetRef ref, Workout? workout, ActiveSession? activeSession) {
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
        
        const SizedBox(height: 20),
        
        // Progress Insight Card
        _buildProgressInsight(ref, workout),
        
        const SizedBox(height: 24),
        
        // Start/Resume/Stop Controls
        if (activeSession != null && activeSession.workoutId == workout.id) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final currentSession = ref.read(activeWorkoutSessionProvider);
                if (currentSession != null && context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ActiveWorkoutScreen(session: currentSession),
                    ),
                  );
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
                    'RESUME SESSION',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.open_in_new, size: 24),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                 // Confirm stop
                 final confirm = await showDialog<bool>(
                   context: context,
                   builder: (context) => AlertDialog(
                     title: const Text('Stop Workout?'),
                     content: const Text('This will finish the current session.'),
                     actions: [
                       TextButton(
                         onPressed: () => Navigator.pop(context, false),
                         child: const Text('Cancel'),
                       ),
                       FilledButton(
                         onPressed: () => Navigator.pop(context, true),
                         child: const Text('Stop Framework'),
                       ),
                     ],
                   ),
                 );
                 
                 if (confirm == true) {
                   await ref.read(activeWorkoutSessionProvider.notifier).completeWorkout();
                 }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('STOP WORKOUT'),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
              child: FilledButton(
              onPressed: () => _onStartPressed(context, ref, workout),
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
  
  Widget _buildProgressInsight(WidgetRef ref, Workout workout) {
    final db = ref.watch(appDatabaseProvider);
    final aiService = ref.watch(aiInsightsServiceProvider);
    
    // First check connectivity
    return FutureBuilder<List<ConnectivityResult>>(
      future: Connectivity().checkConnectivity(),
      builder: (context, connectivitySnapshot) {
        // If no connectivity data yet or offline, hide the card
        if (!connectivitySnapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final results = connectivitySnapshot.data!;
        final isOnline = results.isNotEmpty && 
            !results.contains(ConnectivityResult.none);
        
        // If offline, don't show the insight card at all
        if (!isOnline) {
          return const SizedBox.shrink();
        }
        
        // Online - fetch and display progress
        return FutureBuilder<Map<String, dynamic>>(
          future: db.getWorkoutProgressSummary(workout.id, days: 30),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            
            final data = snapshot.data!;
            final sessionCount = data['sessionCount'] as int;
            final lastDuration = data['lastDuration'] as int?;
            final avgDuration = data['averageDuration'] as double;
            
            // If no history, show a "first time" message
            if (sessionCount == 0) {
              return _buildInsightCard(
                icon: Icons.rocket_launch,
                title: 'First Session',
                subtitle: "Let's set your baseline!",
              );
            }
            
            // Calculate comparison
            final lastMinutes = lastDuration != null ? (lastDuration / 60).round() : 0;
            final avgMinutes = (avgDuration / 60).round();
            
            // Get AI insight asynchronously
            return FutureBuilder<String?>(
              future: aiService.generateWorkoutInsight(
                workoutName: workout.name,
                progressData: data,
              ),
              builder: (context, aiSnapshot) {
                final insight = aiSnapshot.data ?? 
                    '$sessionCount sessions • avg $avgMinutes min';
                
                return _buildInsightCard(
                  icon: lastMinutes < avgMinutes ? Icons.trending_up : Icons.trending_flat,
                  title: 'Last: $lastMinutes min',
                  subtitle: insight,
                  trend: lastMinutes < avgMinutes,
                );
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: trend == true 
                  ? AppTheme.tealPrimary.withOpacity(0.15)
                  : AppTheme.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: trend == true ? AppTheme.tealPrimary : AppTheme.textMuted,
              size: 24,
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
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsRow(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weeklyStatsProvider);
    
    final stats = switch (statsAsync) {
      AsyncData(:final value) => value,
      _ => {'calories': 0, 'duration': 0},
    };
    
    final calories = stats['calories'] ?? 0;
    final durationSec = stats['duration'] ?? 0;
    
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
              value: '$calories',
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
              value: '${durationSec ~/ 60}m',
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
  
  void _onStartPressed(BuildContext context, WidgetRef ref, Workout? defaultWorkout) async {
    final workoutsAsync = ref.read(workoutsStreamProvider);
    
    // Safety check
    if (defaultWorkout == null) return;
    
    // If we have access to the full list, check count
    if (workoutsAsync is AsyncData<List<Workout>>) {
      final workouts = workoutsAsync.value;
      if (workouts.length > 1) {
        // Multiple workouts - show selection dialog
        final selected = await _showWorkoutSelectionDialog(context, workouts);
        if (selected != null) {
          _startSession(context, ref, selected);
        }
        return;
      }
    }
    
    // Default single workout behavior
    _startSession(context, ref, defaultWorkout);
  }
  
  void _startSession(BuildContext context, WidgetRef ref, Workout workout) async {
    await ref.read(activeWorkoutSessionProvider.notifier).startWorkout(workout);
    
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
  }
  
  Future<Workout?> _showWorkoutSelectionDialog(BuildContext context, List<Workout> workouts) {
    return showGeneralDialog<Workout>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(), // not used
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.easeInOutBack.transform(anim1.value) - 1.0;
        
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              backgroundColor: AppTheme.darkSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 16,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CHOOSE SESSION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.tealPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: workouts.asMap().entries.map((entry) {
                            final index = entry.key;
                            final w = entry.value;
                            return _SelectionCard(
                              workout: w,
                              index: index,
                              onTap: () => Navigator.of(context).pop(w),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final Workout workout;
  final int index;
  final VoidCallback onTap;
  
  const _SelectionCard({
    required this.workout,
    required this.index,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkSurfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            // Mini gradient icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getGradientColors(index),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getWorkoutIcon(workout.clockType),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    _getSubtitle(workout),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
  
  String _getSubtitle(Workout workout) {
    return switch (workout.clockType) {
      ClockType.none => 'Freestyle',
      ClockType.stopwatch => 'Stopwatch',
      ClockType.timer => workout.timerDurationSeconds != null
          ? '${workout.timerDurationSeconds! ~/ 60} min'
          : 'Timer',
      ClockType.alarm => 'Alarm',
    };
  }
  
  IconData _getWorkoutIcon(ClockType type) {
    return switch (type) {
      ClockType.none => Icons.fitness_center,
      ClockType.stopwatch => Icons.timer_outlined,
      ClockType.timer => Icons.hourglass_bottom,
      ClockType.alarm => Icons.alarm,
    };
  }
  
  List<Color> _getGradientColors(int index) {
    final gradients = [
      [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)], // Purple
      [const Color(0xFF00B4DB), const Color(0xFF0083B0)], // Blue
      [const Color(0xFFE91E63), const Color(0xFF9C27B0)], // Pink
      [const Color(0xFF00D9B8), const Color(0xFF00A88A)], // Teal
    ];
    return gradients[index % gradients.length];
  }
}
