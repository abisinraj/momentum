import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/database_providers.dart';

import '../../../core/providers/workout_providers.dart';
import '../../../core/database/app_database.dart';
import 'active_workout_screen.dart';
import 'edit_workout_screen.dart';

/// Workout screen - shows list of workouts with completion states
/// Design: Date header, focus subtitle, workout cards with status badges
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  bool _showAllWorkouts = false;
  
  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(workoutsStreamProvider);
    final todayCompletedAsync = ref.watch(todayCompletedWorkoutIdsProvider);
    final userAsync = ref.watch(currentUserProvider);
    
    final userGoal = switch (userAsync) {
      AsyncData(:final value) => value?.goal ?? 'Fitness & Wellness',
      _ => 'Fitness & Wellness',
    };
    
    // Get user's current split index (manual progression, not tied to weekday)
    final currentSplitIndex = switch (userAsync) {
      AsyncData(:final value) => value?.currentSplitIndex ?? 0,
      _ => 0,
    };

    final totalSplitDays = switch (userAsync) {
      AsyncData(:final value) => value?.splitDays ?? 0,
      _ => 0,
    };
    
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEE, MMM d').format(DateTime.now()).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                          letterSpacing: 1.0,
                        ),
                      ),

                      // Toggle: Today / All
                      GestureDetector(
                        onTap: () => setState(() => _showAllWorkouts = !_showAllWorkouts),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _showAllWorkouts 
                                ? colorScheme.primary.withValues(alpha: 0.15) 
                                : colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _showAllWorkouts 
                                  ? colorScheme.primary 
                                  : colorScheme.outlineVariant,
                            ),

                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _showAllWorkouts ? Icons.calendar_view_week : Icons.today,
                                size: 16,
                                color: _showAllWorkouts 
                                    ? colorScheme.primary 
                                    : colorScheme.onSurfaceVariant,
                              ),

                              const SizedBox(width: 4),
                              Text(
                                _showAllWorkouts ? 'All' : 'Current',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _showAllWorkouts 
                                      ? colorScheme.primary 
                                      : colorScheme.onSurfaceVariant,
                                ),

                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    _showAllWorkouts ? 'All Workouts' : 'Current Split Day',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 4),
                  // Focus subtitle
                  Text(
                    'Focus: $userGoal',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                ],
              ),
            ),
            
            // Workout Content
            Expanded(
              child: switch (workoutsAsync) {
                AsyncData(:final value) => _buildSplitView(context, ref, value, todayCompletedAsync, currentSplitIndex, totalSplitDays),
                AsyncError(:final error) => Center(child: Text('Error: $error', style: TextStyle(color: colorScheme.error))),
                _ => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
               // Add new workout (default to day 0 or next available, but standalone logic applies)
               builder: (context) => EditWorkoutScreen(
                 splitIndex: currentSplitIndex, // Pre-select current day or 0
               ),
            ),
          );
        },
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
      ),

    );
  }
  
  Widget _buildEmptyState(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),

          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'Tap + to add a workout',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),

        ],
      ),
    );
  }
  
  Widget _buildSplitView(
    BuildContext context,
    WidgetRef ref,
    List<Workout> workouts,
    AsyncValue<List<int>> todayCompletedAsync,
    int currentSplitIndex,
    int totalSplitDays,
  ) {
    if (workouts.isEmpty) return _buildEmptyState('No workouts yet');

    final todayCompleted = todayCompletedAsync.valueOrNull ?? [];
    
    // 1. Identify "Today's Target" (Current Split Index)
    final todaysWorkouts = workouts.where((w) => w.orderIndex == currentSplitIndex).toList();
    
    // 2. Identify "Tomorrow's Target"
    final nextSplitIndex = totalSplitDays > 0 ? (currentSplitIndex + 1) % totalSplitDays : -1;
    final tomorrowsWorkouts = nextSplitIndex != -1 
        ? workouts.where((w) => w.orderIndex == nextSplitIndex).toList()
        : <Workout>[];

    // If user toggled "Show All", show standard list view
    if (_showAllWorkouts) {
      return _buildWorkoutList(context, ref, workouts, todayCompletedAsync, workouts.length, currentSplitIndex);
    }
    
    if (todaysWorkouts.isEmpty) {
       return _buildEmptyState('Rest Day or Empty Split');
    }
    
    // Primary View: Scrollable Dashboard
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
             "TODAY'S WORKOUTS",
             style: TextStyle(
               fontSize: 12,
               fontWeight: FontWeight.bold,
               color: Theme.of(context).colorScheme.primary,
               letterSpacing: 1.2,
             ),
           ),
           const SizedBox(height: 16),
           ...todaysWorkouts.map((workout) => _WorkoutCard(
             workout: workout,
             isCompleted: todayCompleted.contains(workout.id),
             isActive: false, 
             isLocked: false,
             index: workout.orderIndex,
             total: workouts.length,
             onTap: () => _startWorkout(context, ref, workout),
             onDelete: () => _confirmDelete(context, ref, workout),
           )),
           
           if (tomorrowsWorkouts.isNotEmpty) ...[
             const SizedBox(height: 32),
             Text(
               "TOMORROW'S SPLIT",
               style: TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                 color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                 letterSpacing: 1.2,
               ),
             ),
             const SizedBox(height: 16),
             ...tomorrowsWorkouts.map((workout) => _WorkoutCard(
               workout: workout,
               isCompleted: false,
               isActive: false, 
               isLocked: true, // Dimmed to show it's for tomorrow
               index: workout.orderIndex,
               total: workouts.length,
               onTap: null, // Disable start for tomorrow's workouts
               onDelete: () => _confirmDelete(context, ref, workout),
             )),
           ],

           const SizedBox(height: 32),
           
           // "Manage All" button
           Center(
             child: TextButton(
               onPressed: () => setState(() => _showAllWorkouts = true),
               child: const Text("Manage All Workouts"),
             ),
           ),
           const SizedBox(height: 40), 
        ],
      ),
    );
  }

  Widget _buildWorkoutList(
    BuildContext context,
    WidgetRef ref,
    List<Workout> workouts,
    AsyncValue<List<int>> todayCompletedAsync,
    int totalCount,
    int currentSplitIndex,
  ) {
    // Legacy List View (Management Mode)
    final todayCompleted = todayCompletedAsync.valueOrNull ?? [];
    final activeSession = ref.watch(activeWorkoutSessionProvider);
    
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: workouts.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final reordered = List<Workout>.from(workouts);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);
        ref.read(workoutManagerProvider.notifier).reorderWorkouts(reordered);
      },
      itemBuilder: (context, index) {
        final workout = workouts[index];
        final isCompleted = todayCompleted.contains(workout.id);
        final isActive = activeSession?.workoutId == workout.id;
        
        return _WorkoutCard(
          key: ValueKey(workout.id),
          workout: workout,
          isCompleted: isCompleted,
          isActive: isActive,
          isLocked: false,
          index: workout.orderIndex, 
          total: totalCount,
          onTap: () => _startWorkout(context, ref, workout),
          onDelete: () => _confirmDelete(context, ref, workout),
        );
      },
    );
  }
  
  Future<void> _startWorkout(BuildContext context, WidgetRef ref, Workout workout) async {
    // Rest Day Logic
    if (workout.isRestDay) {
       final colorScheme = Theme.of(context).colorScheme;
       
       final confirm = await showDialog<bool>(
         context: context,
         builder: (ctx) => AlertDialog(
           backgroundColor: colorScheme.surfaceContainerHigh,
           title: Text('Rest Day', style: TextStyle(color: colorScheme.onSurface)),
           content: Text(
             'Mark this days as rested? Proper recovery is key to progress.',
             style: TextStyle(color: colorScheme.onSurfaceVariant),
           ),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(ctx, false),
               child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
             ),
             FilledButton(
               onPressed: () => Navigator.pop(ctx, true),
               style: FilledButton.styleFrom(backgroundColor: colorScheme.primary),
               child: Text('Confirm Rest', style: TextStyle(color: colorScheme.onPrimary)),
             ),
           ],
         ),
       );
       
       if (confirm == true) {
         await ref.read(workoutManagerProvider.notifier).logRestDay(workout);

         if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: const Text('Rest day logged. Recovery mode on!'),
               backgroundColor: colorScheme.primary,
             ),
           );
         }
       }
       return;
    }

    // Standard Workout Logic
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

  

  
  void _confirmDelete(BuildContext context, WidgetRef ref, Workout workout) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        title: Text(
          'Delete Workout?',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to delete "${workout.name}"?',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),

          FilledButton(
            onPressed: () async {
              await ref.read(workoutManagerProvider.notifier).deleteWorkout(workout.id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),

            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final bool isCompleted;
  final bool isActive;
  final bool isLocked;
  final int index;
  final int total;
  final VoidCallback? onTap;
  final VoidCallback onDelete;
  
  const _WorkoutCard({
    super.key,
    required this.workout,
    required this.isCompleted,
    required this.isActive,
    this.isLocked = false,
    required this.index,
    required this.total,
    this.onTap,
    required this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled = isCompleted || isLocked;
    
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary.withValues(alpha: 0.1)
                : colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: isActive ? 2 : 1,
            ),
          ),

          child: Row(
            children: [
            // Gradient thumbnail / icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getGradientColors(index),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(

                workout.isRestDay ? Icons.spa : _getWorkoutIcon(workout.clockType),
                color: Colors.white,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with menu
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          workout.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),

                        ),
                      ),
                      // Edit/Delete Menu (Only if not locked)
                      if (!isLocked)
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant, size: 20),
                            color: colorScheme.surfaceContainerHigh,

                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (value) {
                                if (value == 'edit') {
                                  // Navigate to edit
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => EditWorkoutScreen(
                                        existingWorkout: workout,
                                      ),
                                    ),
                                  );
                              } else if (value == 'delete') {
                                onDelete();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 20, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Edit', style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                    SizedBox(width: 12),
                                    Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Status row
                  Row(
                    children: [
                      if (isActive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'IN PROGRESS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),

                        ),
                        const SizedBox(width: 8),
                      ],
                      if (isCompleted)
                        Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
                          size: 16,
                        ),

                      if (isCompleted) const SizedBox(width: 4),
                      Text(
                        _getSubtitle(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const Spacer(),
                      
                      // Play button (miniature) if not completed/active
                      if (!isCompleted && !isActive)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),

                          child: Icon(
                            Icons.play_arrow,
                            color: colorScheme.onPrimary,
                            size: 16,
                          ),

                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
  
  List<Color> _getGradientColors(int index) {
    final gradients = [
      [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)], // Purple
      [const Color(0xFF00B4DB), const Color(0xFF0083B0)], // Blue
      [const Color(0xFFE91E63), const Color(0xFF9C27B0)], // Pink
      [const Color(0xFF00D9B8), const Color(0xFF00A88A)], // Teal
    ];
    
    if (workout.isRestDay) {
      return [const Color(0xFF56CCF2), const Color(0xFF2F80ED)]; // Light Blue for Rest
    }

    
    return gradients[index % gradients.length];
  }

  
  IconData _getWorkoutIcon(ClockType type) {
    return switch (type) {
      ClockType.none => Icons.fitness_center,
      ClockType.stopwatch => Icons.timer_outlined,
      ClockType.timer => Icons.hourglass_bottom,
      ClockType.alarm => Icons.alarm,
    };
  }
  
  String _getSubtitle() {
    if (isCompleted) return 'Completed';
    if (workout.isRestDay) return 'Rest & Recovery';
    return switch (workout.clockType) {

      ClockType.none => 'Freestyle',
      ClockType.stopwatch => 'Stopwatch',
      ClockType.timer => workout.timerDurationSeconds != null
          ? '${workout.timerDurationSeconds! ~/ 60} min'
          : 'Timer',
      ClockType.alarm => 'Alarm',
    };
  }
}
