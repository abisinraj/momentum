import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/providers/workout_providers.dart';
import '../../../core/database/app_database.dart';
import '../../workout/presentation/active_workout_screen.dart';
import '../../../app/widgets/skeleton_loader.dart';
import '../../health/presentation/health_insights_card.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../home/presentation/widgets/ai_insights_card.dart';
import '../../home/presentation/widgets/consistency_grid_widget.dart';
import '../../home/presentation/widgets/recovery_score_card.dart';
import '../../home/presentation/widgets/volume_load_widget.dart';
import '../../../core/providers/dashboard_providers.dart';
import '../../../core/providers/health_connect_provider.dart';

import 'package:momentum/core/utils/screen_utils.dart';

/// Home screen - shows next workout in cycle with Momentum design
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Log screen resolution on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScreenUtils.printScreenInfo(context);
        // Check for crashed session
        ref.read(activeWorkoutSessionProvider.notifier).checkResumableSession();
      }
    });
  }


  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  @override
  Widget build(BuildContext context) {
    final nextWorkoutAsync = ref.watch(nextWorkoutProvider);
    final userAsync = ref.watch(currentUserProvider);
    final activeSession = ref.watch(activeWorkoutSessionProvider);
    final todayCompletedAsync = ref.watch(todayCompletedWorkoutIdsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
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
    
    // Get today's completed workout IDs
    final todayCompleted = switch (todayCompletedAsync) {
      AsyncData(:final value) => value,
      _ => <int>[],
    };
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting and notification bell
              _buildHeader(context, userName),
              
              const SizedBox(height: 24),
              
              if (activeSession != null) ...[
                _buildResumeBanner(context, activeSession),
                const SizedBox(height: 24),
              ],

              
              // Main workout content
              switch (nextWorkoutAsync) {
                AsyncData(:final value) => _buildWorkoutContent(context, ref, value, activeSession, todayCompleted),
                AsyncError(:final error) => _buildErrorState(context, error.toString()),
                _ => const WorkoutCardSkeleton(),
              },
              
              const SizedBox(height: 16),

              // AI Insights Card (New)
              const AIInsightsCard(),

              const SizedBox(height: 16),
              // Health Insights Card (from Health Connect)
              const HealthInsightsCard(),

              const SizedBox(height: 32),
              
              // === DASHBOARD 2.0 ===
              _buildSectionHeader(context, "ANALYTICS"),
              const SizedBox(height: 16),
              
              // 1. Recovery Score
              _buildRecoveryCard(ref),
              const SizedBox(height: 16),
              
              // 2. Volume Load
              _buildVolumeCard(ref),
              const SizedBox(height: 16),
              
              // 3. Consistency Grid
              // 4. Consistency Grid
              _buildConsistencyGrid(ref),
              
              const SizedBox(height: 16),
              
              // Bottom stats row (Existing - maybe redundant now? Let's keep for day-specific stats)
              _buildSectionHeader(context, "THIS WEEK"),
              const SizedBox(height: 16),
              _buildStatsRow(context, ref),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildResumeBanner(BuildContext context, ActiveSession session) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer, // Urgent color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.error.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Text(
                'Workout Interrupted',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'It seems Momentum crashed during "${session.workoutName}".',
            style: TextStyle(color: colorScheme.onErrorContainer),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ActiveWorkoutScreen(session: session),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                   // Cancel
                   // Note: This effectively discards the session or we could prompt to save partial.
                   // For now simple discard/completion.
                   ref.read(activeWorkoutSessionProvider.notifier).cancelWorkout();
                },
                style: OutlinedButton.styleFrom(
                   foregroundColor: colorScheme.error,
                   side: BorderSide(color: colorScheme.error),
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, String userName) {

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildWorkoutContent(BuildContext context, WidgetRef ref, Workout? workout, ActiveSession? activeSession, List<int> todayCompleted) {
    if (workout == null) {
      return _buildEmptyState(context);
    }
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Check if this workout was completed today
    final isCompletedToday = todayCompleted.contains(workout.id);
    
    // Determine image provider
    ImageProvider? imageProvider;
    if (workout.thumbnailUrl != null && workout.thumbnailUrl!.isNotEmpty) {
      if (workout.thumbnailUrl!.startsWith('http')) {
        imageProvider = NetworkImage(workout.thumbnailUrl!);
      } else {
        imageProvider = AssetImage(workout.thumbnailUrl!);
      }
    }
    
    return LayoutBuilder(
      builder: (context, _) {
        // Calculate responsive minHeight based on screen
        final screenHeight = MediaQuery.of(context).size.height;
        final responsiveMinHeight = (screenHeight * 0.55).clamp(350.0, 550.0);
        
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: responsiveMinHeight),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(32),
        image: imageProvider != null ? DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            // Silently handle image load errors
            debugPrint('Image load error: $exception');
          },
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.2), // Slight dark tint globally
            BlendMode.darken,
          ),
        ) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient Overlay for text readability
          if (imageProvider != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5), // Darker at top for header visibility
                      Colors.black.withValues(alpha: 0.3), // Mid section slightly lighter
                      Colors.black.withValues(alpha: 0.7), // Darker toward bottom
                      Colors.black.withValues(alpha: 0.95), // Very dark at bottom for text
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with completion status or "Today's Focus"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCompletedToday 
                            ? Colors.green.withValues(alpha: 0.8)
                            : Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCompletedToday 
                              ? Colors.green.withValues(alpha: 0.9)
                              : colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompletedToday ? Icons.check_circle : Icons.bolt,
                            size: 16,
                            color: isCompletedToday ? Colors.white : colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCompletedToday ? "COMPLETED TODAY" : "TODAY'S FOCUS",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isCompletedToday ? Colors.white : colorScheme.primary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Optional: Add more badges here (e.g. Duration)
                  ],
                ),
                
                // Flexible space instead of unbounded Spacer
                const SizedBox(height: 100),
                
                // Workout Title
                _buildImmersiveTitle(workout.name),
                
                const SizedBox(height: 8),
                
                // Description / Type
                Row(
                  children: [
                    Icon(
                      _getWorkoutIcon(workout.clockType),
                      color: colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getWorkoutDescription(workout),
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Progress Insight (Semi-transparent to blend)
                _buildProgressInsight(context, ref, workout),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                _buildActionButtons(context, ref, workout, activeSession, isCompletedToday),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildImmersiveTitle(String name) {
    return Text(
      name.toUpperCase(),
      style: const TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        height: 1.0,
        letterSpacing: -1.0,
        shadows: [
          Shadow(
            offset: Offset(0, 2),
            blurRadius: 4,
            color: Colors.black54,
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
  
  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Workout workout, ActiveSession? activeSession, bool isCompletedToday) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (activeSession != null && activeSession.workoutId == workout.id) {
      return Column(
        children: [
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
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
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
                  SizedBox(width: 12),
                  Icon(Icons.open_in_new, size: 24),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                 final confirm = await showDialog<bool>(
                   context: context,
                   builder: (context) => AlertDialog(
                     backgroundColor: colorScheme.surfaceContainer,
                     title: Text('Stop Workout?', style: TextStyle(color: colorScheme.onSurface)),
                     content: Text('This will finish the current session.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                     actions: [
                       TextButton(
                         onPressed: () => Navigator.pop(context, false),
                         child: const Text('Cancel'),
                       ),
                       FilledButton(
                         style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                         onPressed: () => Navigator.pop(context, true),
                         child: const Text('Stop'),
                       ),
                     ],
                   ),
                 );
                 
                 if (confirm == true) {
                   await ref.read(activeWorkoutSessionProvider.notifier).completeWorkout();
                 }
              },
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('STOP WORKOUT'),
            ),
          ),
        ],
      );
    } else if (isCompletedToday) {
      // Completed State
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Done for today",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "See you tomorrow!",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    } else {
      // Start State
      return SizedBox(
        width: double.infinity,
          child: FilledButton(
          onPressed: () => _onStartPressed(context, ref, workout),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: colorScheme.primary.withValues(alpha: 0.4),
          ),
          child: const Row(
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
              SizedBox(width: 12),
              Icon(Icons.play_arrow, size: 24),
            ],
          ),
        ),
      );
    }
  }

  String _getWorkoutDescription(Workout workout) {
    final clockDesc = switch (workout.clockType) {
      ClockType.none => 'Freestyle',
      ClockType.stopwatch => 'Tracked with Stopwatch',
      ClockType.timer => workout.timerDurationSeconds != null
          ? '${workout.timerDurationSeconds! ~/ 60} min Timer'
          : 'Timer Workout',
      ClockType.alarm => 'Alarm Completion',
    };
    return clockDesc;
  }
  
  Widget _buildProgressInsight(BuildContext context, WidgetRef ref, Workout workout) {
    final db = ref.watch(appDatabaseProvider);
    
    // Combined async operation to avoid nested FutureBuilders
    Future<Map<String, dynamic>> fetchInsightData() async {
      // Check connectivity (with timeout to avoid blocking)
      final connectivity = await Connectivity().checkConnectivity().timeout(
        const Duration(seconds: 2),
        onTimeout: () => [ConnectivityResult.wifi],
      );
      
      if (connectivity.contains(ConnectivityResult.none)) {
        return {'offline': true};
      }
      
      // Fetch workout progress
      final progressData = await db.getWorkoutProgressSummary(workout.id, days: 30);
      final sessionCount = progressData['sessionCount'] as int;
      
      if (sessionCount == 0) {
        return {'firstSession': true};
      }
      
      return {
        ...progressData,
      };
    }
    
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchInsightData(),
      builder: (context, snapshot) {
        // Loading or error: show nothing to avoid layout shift
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final data = snapshot.data!;
        
        // Offline case
        if (data['offline'] == true) {
          return const SizedBox.shrink();
        }
        
        // First session case
        if (data['firstSession'] == true) {
          return _buildInsightCard(
            context: context,
            icon: Icons.rocket_launch,
            title: 'First Session',
            subtitle: "Let's set your baseline!",
          );
        }
        
        // Normal case with data
        final sessionCount = data['sessionCount'] as int;
        final lastDuration = data['lastDuration'] as int?;
        final avgDuration = data['averageDuration'] as double;
        final aiInsight = data['aiInsight'] as String?;
        
        final lastMinutes = lastDuration != null ? (lastDuration / 60).round() : 0;
        final avgMinutes = (avgDuration / 60).round();
        
        final insight = aiInsight ?? '$sessionCount sessions • avg $avgMinutes min';
        
        return _buildInsightCard(
          context: context,
          icon: lastMinutes < avgMinutes ? Icons.trending_up : Icons.trending_flat,
          title: 'Last: $lastMinutes min',
          subtitle: insight,
          trend: lastMinutes < avgMinutes,
        );
      },
    );
  }
  
  Widget _buildInsightCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    bool? trend,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: trend == true 
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: trend == true ? colorScheme.primary : colorScheme.onSurfaceVariant,
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
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final stats = switch (statsAsync) {
      AsyncData(:final value) => value,
      _ => {'calories': 0, 'duration': 0},
    };
    
    final calories = stats['calories'] ?? 0;
    final durationSec = stats['duration'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context: context,
              icon: Icons.local_fire_department_outlined,
              value: '$calories',
              label: 'KCAL BURNED',
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: colorScheme.outline,
          ),
          Expanded(
            child: _buildStatItem(
              context: context,
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
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(
          Icons.fitness_center_outlined,
          size: 80,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 24),
        Text(
          'No workouts yet',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          'Create your training split to start\nbuilding momentum',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () {
            // Navigate to split setup
            Navigator.of(context).pushNamed('/split-setup');
          },
          icon: const Icon(Icons.add),
          label: const Text('Create Your First Workout'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }
  
  Widget _buildErrorState(BuildContext context, String error) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Something went wrong',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  void _onStartPressed(BuildContext context, WidgetRef ref, Workout? defaultWorkout) async {
    // Safety check
    if (defaultWorkout == null) return;
    
    // Default behavior: Start the scheduled workout immediately
    // User requested to skip the selection list and just show today's items
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
  
  // NOTE: _showWorkoutSelectionDialog was removed (dead code)

  IconData _getWorkoutIcon(ClockType type) {
    return switch (type) {
      ClockType.none => Icons.fitness_center,
      ClockType.stopwatch => Icons.timer_outlined,
      ClockType.timer => Icons.hourglass_bottom,
      ClockType.alarm => Icons.alarm,
    };
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildRecoveryCard(WidgetRef ref) {
    final healthState = ref.watch(healthNotifierProvider);
    // ignore: unused_local_variable
    final volumeAsync = ref.watch(volumeLoadProvider);
    
    final sleepDuration = healthState.lastNightSleep ?? const Duration(hours: 0);
    
    return RecoveryScoreCard(
      sleepHours: sleepDuration.inHours,
      workoutsLast3Days: 1, // TODO: Connect to real query
      isRestDay: false, 
    );
  }

  Widget _buildVolumeCard(WidgetRef ref) {
    final volumeAsync = ref.watch(volumeLoadProvider);
    
    return volumeAsync.when(
      data: (data) => VolumeLoadWidget(
        currentWeekVolume: data[0],
        lastWeekVolume: data[1],
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildConsistencyGrid(WidgetRef ref) {
    final gridAsync = ref.watch(activityGridProvider(30));
    return gridAsync.when(
      data: (data) => ConsistencyGridWidget(activityData: data),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
