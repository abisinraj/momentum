import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/workout_providers.dart';
import '../../../core/database/app_database.dart';
import 'active_workout_screen.dart';

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
    
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
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
                          color: AppTheme.tealPrimary,
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
                                ? AppTheme.tealPrimary.withOpacity(0.15) 
                                : AppTheme.darkSurfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _showAllWorkouts 
                                  ? AppTheme.tealPrimary 
                                  : AppTheme.darkBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _showAllWorkouts ? Icons.calendar_view_week : Icons.today,
                                size: 16,
                                color: _showAllWorkouts 
                                    ? AppTheme.tealPrimary 
                                    : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _showAllWorkouts ? 'All' : 'Current',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _showAllWorkouts 
                                      ? AppTheme.tealPrimary 
                                      : AppTheme.textMuted,
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
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Focus subtitle
                  Text(
                    'Focus: $userGoal',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Workout list
            Expanded(
              child: switch (workoutsAsync) {
                AsyncData(:final value) => () {
                  // Filter to current split day's workout if not showing all
                  final filtered = _showAllWorkouts 
                      ? value 
                      : value.where((w) => w.orderIndex == currentSplitIndex).toList();
                  
                  if (filtered.isEmpty) {
                    return _buildEmptyState(_showAllWorkouts 
                        ? 'No workouts yet' 
                        : 'No workout for current split day');
                  }
                  return _buildWorkoutList(context, ref, filtered, todayCompletedAsync, value.length, currentSplitIndex);
                }(),
                AsyncError(:final error) => Center(
                    child: Text(
                      'Error: $error',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
                _ => Center(
                    child: CircularProgressIndicator(color: AppTheme.tealPrimary),
                  ),
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWorkoutDialog(context, ref),
        backgroundColor: AppTheme.tealPrimary,
        child: Icon(Icons.add, color: AppTheme.darkBackground),
      ),
    );
  }
  
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 64,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a workout',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
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
        // Lock workouts that don't match current split index (when viewing all)
        final isLocked = _showAllWorkouts && workout.orderIndex != currentSplitIndex;
        
        return _WorkoutCard(
          key: ValueKey(workout.id),
          workout: workout,
          isCompleted: isCompleted,
          isActive: isActive,
          isLocked: isLocked,
          index: workout.orderIndex, // Use actual order index for display
          total: totalCount,
          onTap: isLocked ? null : () => _startWorkout(context, ref, workout),
          onDelete: () => _confirmDelete(context, ref, workout),
        );
      },
    );
  }
  
  Future<void> _startWorkout(BuildContext context, WidgetRef ref, Workout workout) async {
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
  
  void _showAddWorkoutDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    ClockType selectedClockType = ClockType.stopwatch;
    
    // Get user's split days count and current index
    final db = ref.read(appDatabaseProvider);
    final user = await db.getUser();
    final splitDays = user?.splitDays ?? 3;
    int selectedSplitIndex = user?.currentSplitIndex ?? 0;
    
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle and close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppTheme.textMuted),
                  ),
                  Text(
                    'Create Routine',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Workout name
              Text(
                'WORKOUT NAME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkSurfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: nameController,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'High Intensity Interval',
                    hintStyle: TextStyle(color: AppTheme.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Split Day Selector
              Text(
                'ADD TO SPLIT DAY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(splitDays, (index) {
                    final isSelected = selectedSplitIndex == index;
                    final dayLabel = 'Day ${index + 1}';
                    
                    return Padding(
                      padding: EdgeInsets.only(right: index < splitDays - 1 ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => selectedSplitIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.tealPrimary.withOpacity(0.15) : AppTheme.darkSurfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.tealPrimary : AppTheme.darkBorder.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            dayLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppTheme.tealPrimary : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Tracking Mode
              Text(
                'TRACKING MODE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildClockOption(
                    'None',
                    Icons.timer_off_outlined,
                    selectedClockType == ClockType.none,
                    () => setState(() => selectedClockType = ClockType.none),
                  ),
                  const SizedBox(width: 12),
                  _buildClockOption(
                    'Stopwatch',
                    Icons.timer_outlined,
                    selectedClockType == ClockType.stopwatch,
                    () => setState(() => selectedClockType = ClockType.stopwatch),
                  ),
                  const SizedBox(width: 12),
                  _buildClockOption(
                    'Timer',
                    Icons.hourglass_bottom,
                    selectedClockType == ClockType.timer,
                    () => setState(() => selectedClockType = ClockType.timer),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Create button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please enter a workout name'),
                          backgroundColor: AppTheme.darkSurfaceContainerHigh,
                        ),
                      );
                      return;
                    }
                    
                    // Auto-generate short code from first letter
                    final code = name[0].toUpperCase();
                    
                    await ref.read(workoutManagerProvider.notifier).addWorkout(
                      name: name,
                      shortCode: code,
                      clockType: selectedClockType,
                      orderIndex: selectedSplitIndex, // Use selected split day
                    );
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.tealPrimary,
                    foregroundColor: AppTheme.darkBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Create Workout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildClockOption(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.tealPrimary.withOpacity(0.1) : AppTheme.darkSurfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.tealPrimary : AppTheme.darkBorder.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.tealPrimary : AppTheme.textMuted,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppTheme.tealPrimary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _confirmDelete(BuildContext context, WidgetRef ref, Workout workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Delete Workout?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${workout.name}"?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(workoutManagerProvider.notifier).deleteWorkout(workout.id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
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
                ? AppTheme.tealPrimary.withOpacity(0.1)
                : AppTheme.darkSurfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? AppTheme.tealPrimary
                  : AppTheme.darkBorder.withOpacity(0.3),
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
                _getWorkoutIcon(workout.clockType),
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
                  // Title row with play button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          workout.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? AppTheme.textMuted : AppTheme.textPrimary,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (!isCompleted)
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.tealPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: AppTheme.darkBackground,
                            size: 20,
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
                            color: AppTheme.tealPrimary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'IN PROGRESS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkBackground,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (isCompleted)
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.tealPrimary,
                          size: 16,
                        ),
                      if (isCompleted) const SizedBox(width: 4),
                      Text(
                        _getSubtitle(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted ? AppTheme.tealPrimary : AppTheme.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${index + 1}/$total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
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
