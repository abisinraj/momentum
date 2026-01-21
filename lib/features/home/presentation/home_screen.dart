import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/workout_providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/ai_insights_service.dart';
import '../../workout/presentation/active_workout_screen.dart';
import '../../../app/widgets/skeleton_loader.dart';
import '../../health/presentation/health_insights_card.dart';
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting and notification bell
              _buildHeader(context, userName),
              
              const SizedBox(height: 24),
              
              // Main workout content
              switch (nextWorkoutAsync) {
                AsyncData(:final value) => _buildWorkoutContent(context, ref, value, activeSession),
                AsyncError(:final error) => _buildErrorState(context, error.toString()),
                _ => const WorkoutCardSkeleton(),
              },
              
              const SizedBox(height: 16),
              
              // Health Insights Card (from Health Connect)
              const HealthInsightsCard(),
              
              const SizedBox(height: 16),
              
              // Bottom stats row
              _buildStatsRow(context, ref),
              
              const SizedBox(height: 20),
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
        color: AppTheme.darkSurfaceContainer,
        borderRadius: BorderRadius.circular(32),
        image: imageProvider != null ? DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            // Silently handle image load errors
            debugPrint('Image load error: $exception');
          },
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.2), // Slight dark tint globally
            BlendMode.darken,
          ),
        ) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                      Colors.black.withOpacity(0.5), // Darker at top for header visibility
                      Colors.black.withOpacity(0.3), // Mid section slightly lighter
                      Colors.black.withOpacity(0.7), // Darker toward bottom
                      Colors.black.withOpacity(0.95), // Very dark at bottom for text
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
                // Header Row with "Today's Focus"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.tealPrimary.withOpacity(0.5)),
                        // backdropFilter: null, // blur could be added effectively with ClipRRect
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
                              fontWeight: FontWeight.w700,
                              color: AppTheme.tealPrimary,
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
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getWorkoutDescription(workout),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Progress Insight (Semi-transparent to blend)
                _buildProgressInsight(ref, workout),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                _buildActionButtons(context, ref, workout, activeSession),
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
  
  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Workout workout, ActiveSession? activeSession) {
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
                backgroundColor: AppTheme.tealPrimary,
                foregroundColor: AppTheme.darkBackground,
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
                     backgroundColor: AppTheme.darkSurface,
                     title: const Text('Stop Workout?', style: TextStyle(color: Colors.white)),
                     content: const Text('This will finish the current session.', style: TextStyle(color: Colors.white70)),
                     actions: [
                       TextButton(
                         onPressed: () => Navigator.pop(context, false),
                         child: const Text('Cancel'),
                       ),
                       FilledButton(
                         style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
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
                foregroundColor: AppTheme.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('STOP WORKOUT'),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
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
            elevation: 4,
            shadowColor: AppTheme.tealPrimary.withOpacity(0.4),
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
  
  Widget _buildProgressInsight(WidgetRef ref, Workout workout) {
    final db = ref.watch(appDatabaseProvider);
    final aiService = ref.watch(aiInsightsServiceProvider);
    
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
      
      // Fetch AI insight (non-blocking, use fallback if slow)
      String? aiInsight;
      try {
        aiInsight = await aiService.generateWorkoutInsight(
          workoutName: workout.name,
          progressData: progressData,
        ).timeout(const Duration(seconds: 3), onTimeout: () => null);
      } on TimeoutException catch (_) {
        aiInsight = null;
      } on Exception catch (e) {
        debugPrint('AI Insight Error: $e');
        aiInsight = null;
      }
      
      return {
        ...progressData,
        'aiInsight': aiInsight,
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
          icon: lastMinutes < avgMinutes ? Icons.trending_up : Icons.trending_flat,
          title: 'Last: $lastMinutes min',
          subtitle: insight,
          trend: lastMinutes < avgMinutes,
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
        Text(
          'Create your training split to start\nbuilding momentum',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
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
            backgroundColor: AppTheme.tealPrimary,
            foregroundColor: AppTheme.darkBackground,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
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
}
