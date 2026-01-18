import 'dart:async';
import 'dart:ui'; // For FontFeature

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/workout_providers.dart';
import '../../../core/providers/database_providers.dart'; // Import for exercises
import '../../../core/database/app_database.dart';

/// Active workout screen 
/// Supports two views:
/// 1. Checklist View (Manual logging)
/// 2. Timer View (Clock focus)
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final ActiveSession session;
  
  const ActiveWorkoutScreen({
    super.key,
    required this.session,
  });
  
  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  Duration _remaining = Duration.zero;
  bool _isRunning = true;
  bool _timerCompleted = false;
  
  late PageController _pageController;
  int _currentPage = 0;
  
  // Checklist state
  final Set<int> _completedExercises = {}; // Store completed exercise IDs locally for session
  
  @override
  void initState() {
    super.initState();
    // Default to Checklist view for None/Stopwatch, Timer view for others?
    // User requested Checklist for None.
    // Let's default to Checklist (Page 0) generally, Timer (Page 1).
    // Unless logic suggests otherwise.
    _pageController = PageController(initialPage: 0);
    _initializeClock();
  }
  
  void _initializeClock() {
    switch (widget.session.clockType) {
      case ClockType.none:
      case ClockType.stopwatch:
      case ClockType.alarm:
        _startElapsedTimer();
        break;
      case ClockType.timer:
        _remaining = widget.session.timerDuration ?? const Duration(minutes: 30);
        _startCountdownTimer();
        // If it's a timer, maybe default to Timer view?
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _pageController.jumpToPage(1);
        });
        break;
    }
  }
  
  void _startElapsedTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning && mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.session.startedAt);
        });
      }
    });
  }
  
  void _startCountdownTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning && mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.session.startedAt);
          final targetDuration = widget.session.timerDuration ?? const Duration(minutes: 30);
          _remaining = targetDuration - _elapsed;
          
          if (_remaining.isNegative) {
            _remaining = Duration.zero;
            if (!_timerCompleted) {
              _timerCompleted = true;
              _onTimerComplete();
            }
          }
        });
      }
    });
  }
  
  void _onTimerComplete() {
    HapticFeedback.heavyImpact();
    // Show simplified toast/dialog?
  }
  
  void _togglePause() {
    setState(() {
      _isRunning = !_isRunning;
    });
    HapticFeedback.lightImpact();
  }
  
  Future<void> _completeWorkout() async {
    _timer?.cancel();
    // Logic to mark all as done? Or just finish time.
    await ref.read(activeWorkoutSessionProvider.notifier).completeWorkout();
    if (mounted) {
      Navigator.pop(context);
    }
  }
  
  void _cancelWorkout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Workout?'),
        content: const Text('Progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Resume'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              _timer?.cancel();
              ref.read(activeWorkoutSessionProvider.notifier).cancelWorkout();
              Navigator.pop(this.context); // Screen
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercisesAsync = ref.watch(exercisesForWorkoutProvider(widget.session.workoutId));
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar with Timer
            _buildAppBar(theme),
            
            // Tab Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabIndicator(0, 'Checklist', theme),
                const SizedBox(width: 16),
                _buildTabIndicator(1, 'Timer', theme),
              ],
            ),
            const SizedBox(height: 16),
            
            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildChecklistPage(exercisesAsync, theme),
                  _buildTimerPage(theme),
                ],
              ),
            ),
            
            // Controls
            _buildControls(theme),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTabIndicator(int index, String label, ThemeData theme) {
    final isActive = _currentPage == index;
    return GestureDetector(
      onTap: () => _pageController.animateToPage(
        index, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppBar(ThemeData theme) {
    // Mini timer display
    final displayDuration = widget.session.clockType == ClockType.timer 
        ? _remaining 
        : _elapsed;
    final hours = displayDuration.inHours;
    final minutes = (displayDuration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (displayDuration.inSeconds % 60).toString().padLeft(2, '0');
    final timeString = hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelWorkout,
          ),
          Column(
            children: [
              Text(
                widget.session.workoutName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                timeString,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: widget.session.clockType == ClockType.timer && _remaining.inSeconds < 60
                      ? theme.colorScheme.error 
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 48), // Balance for icon
        ],
      ),
    );
  }
  
  Widget _buildChecklistPage(AsyncValue<List<Exercise>> exercisesAsync, ThemeData theme) {
    return exercisesAsync.when(
      data: (exercises) {
        if (exercises.isEmpty) {
          return Center(
            child: Text(
              'No exercises configured',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final ex = exercises[index];
            final isDone = _completedExercises.contains(ex.id);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              color: isDone ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5) : theme.colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isDone ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: CheckboxListTile(
                value: isDone,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _completedExercises.add(ex.id);
                    } else {
                      _completedExercises.remove(ex.id);
                    }
                  });
                  HapticFeedback.lightImpact();
                },
                title: Text(
                  ex.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text('${ex.sets} Sets × ${ex.reps} Reps'),
                activeColor: theme.colorScheme.primary,
                checkColor: theme.colorScheme.onPrimary,
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ),
              ),
            );
          },
        );
      },
      error: (e, st) => Center(child: Text('Error: $e')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
  
  Widget _buildTimerPage(ThemeData theme) {
    // Re-use previous big timer layout
    final displayDuration = widget.session.clockType == ClockType.timer 
        ? _remaining 
        : _elapsed;
    
    final hours = displayDuration.inHours;
    final minutes = (displayDuration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (displayDuration.inSeconds % 60).toString().padLeft(2, '0');
    
    final timeString = hours > 0 
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
        
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
             widget.session.clockType == ClockType.none 
                ? 'Manual Mode' 
                : (widget.session.clockType == ClockType.timer ? 'Remaining' : 'Elapsed'),
            style: TextStyle(
              letterSpacing: 2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            timeString,
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w200,
              color: theme.colorScheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Pause/Resume button
          FloatingActionButton(
            heroTag: 'pause',
            onPressed: _togglePause,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Icon(
              _isRunning ? Icons.pause : Icons.play_arrow,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          
          // Complete button
          SizedBox(
            width: 160,
            height: 56,
            child: FilledButton.icon(
              onPressed: _completeWorkout,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.check),
              label: const Text('FINISH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
