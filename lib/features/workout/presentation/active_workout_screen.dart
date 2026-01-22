import 'dart:async';
import 'dart:ui'; // For FontFeature

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/workout_providers.dart';
import '../../../core/providers/database_providers.dart'; // Import for exercises
import '../../../core/database/app_database.dart';
import '../../../core/services/settings_service.dart';

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

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> with TickerProviderStateMixin {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  Duration _remaining = Duration.zero;
  
  // Rest Timer State
  late AnimationController _restController;
  int? _restingExerciseId;
  String _restTimeDisplay = '';

  // Cooldown Timer State
  late AnimationController _cooldownController;
  int? _cooldownExerciseId;
  String _cooldownTimeDisplay = '';

  bool _isRunning = true;
  bool _timerCompleted = false;
  
  late PageController _pageController;
  int _currentPage = 0;
  
  // Checklist state
  // Key: Exercise ID, Value: Completed sets count
  final Map<int, int> _completedSets = {};
  
  // Key: Exercise ID, Value: Note/Actual reps (transient)
  final Map<int, String> _exerciseNotes = {};
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    
    _restController = AnimationController(vsync: this);
    _restController.addListener(() {
      if (mounted) {
        setState(() {
          // Update display text based on controller value
           final totalSeconds = _restController.duration?.inSeconds ?? 60;
           final remaining = (_restController.value * totalSeconds).ceil();
           _restTimeDisplay = '$remaining';
        });
      }
    });
    _restController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        // Timer complete
        HapticFeedback.mediumImpact();
        setState(() => _restingExerciseId = null);
      }
    });

    _cooldownController = AnimationController(vsync: this, duration: const Duration(minutes: 5));
    _cooldownController.addListener(() {
       if (mounted) {
         setState(() {
            final totalSeconds = _cooldownController.duration?.inSeconds ?? 300;
            final remaining = (_cooldownController.value * totalSeconds).ceil();
            final mins = remaining ~/ 60;
            final secs = (remaining % 60).toString().padLeft(2, '0');
            _cooldownTimeDisplay = '$mins:$secs';
         });
       }
    });
    
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
  }
  
  void _togglePause() {
    setState(() {
      _isRunning = !_isRunning;
    });
    HapticFeedback.lightImpact();
  }
  
  Future<void> _confirmAndCompleteWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Finish Workout?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to mark this workout as complete?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Finish'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _completeWorkout();
    }
  }
  
  Future<void> _completeWorkout() async {
    _timer?.cancel();
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
    _restController.dispose();
    _cooldownController.dispose();
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
            _buildAppBar(theme),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabIndicator(0, 'Checklist', theme),
                const SizedBox(width: 16),
                _buildTabIndicator(1, 'Timer', theme),
              ],
            ),
            const SizedBox(height: 16),
            
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

  Future<void> _startRestTimer(int exerciseId) async {
    final service = ref.read(settingsServiceProvider);
    final restSeconds = await service.getRestTimer();
    if (mounted) {
      setState(() {
        _restingExerciseId = exerciseId;
        _restController.duration = Duration(seconds: restSeconds);
        _restController.value = 1.0;
        _restController.reverse();
      });
    }
  }

  Future<void> _startCooldown(int exerciseId) async {
    if (mounted) {
      setState(() {
        _cooldownExerciseId = exerciseId;
        _cooldownController.value = 1.0;
        _cooldownController.reverse();
      });
    }
  }

  Widget _buildChecklistPage(AsyncValue<List<Exercise>> exercisesAsync, ThemeData theme) {
    return exercisesAsync.when(
      data: (exercisesList) {
        if (exercisesList.isEmpty) {
          return Center(
            child: Text(
              'No exercises configured',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        
        // Sort: Incomplete first, then Fully Completed
        final sortedExercises = List<Exercise>.from(exercisesList);
        sortedExercises.sort((a, b) {
           final aDone = (_completedSets[a.id] ?? 0) >= a.sets;
           final bDone = (_completedSets[b.id] ?? 0) >= b.sets;
           if (aDone == bDone) return a.orderIndex.compareTo(b.orderIndex);
           return aDone ? 1 : -1; // Done goes to bottom
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedExercises.length,
          itemBuilder: (context, index) {
            final ex = sortedExercises[index];
            final completed = _completedSets[ex.id] ?? 0;
            final targetSets = ex.sets;
            final isFullyDone = completed >= targetSets;
            final note = _exerciseNotes[ex.id];
            final isResting = _restingExerciseId == ex.id;
            final isCoolingDown = _cooldownExerciseId == ex.id;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              color: isFullyDone 
                  ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3) 
                  : theme.colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isFullyDone 
                    ? BorderSide.none 
                    : BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  final current = _completedSets[ex.id] ?? 0;
                  // Cycle: 0 -> 1 -> ... -> Max -> 0
                  final next = (current + 1) % (targetSets + 1);
                  
                  setState(() {
                    _completedSets[ex.id] = next;
                  });
                  HapticFeedback.lightImpact();
                  
                  // Logic: 
                  // 1. If Just Finished Exercise (all sets done): Start Cooldown
                  // 2. If Just Finished Set (but not all): Start Rest
                  
                  final newIsFullyDone = next >= targetSets;
                  
                  if (newIsFullyDone) {
                     // Exercise Complete -> Cooldown (Blue/Cyan typically)
                     _startCooldown(ex.id);
                     _restController.stop(); // Stop rest if running
                     setState(() => _restingExerciseId = null);
                  } else if (next > current) {
                     // Set Complete -> Rest
                     _startRestTimer(ex.id);
                     _cooldownController.stop(); // Stop cooldown if running
                     setState(() => _cooldownExerciseId = null);
                  } else if (isResting) {
                     // Cancel rest if clicked again
                     _restController.stop();
                     setState(() => _restingExerciseId = null);
                  }
                },
                onLongPress: () => _showRepInputDialog(ex),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Set Progress Circular
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: completed / targetSets,
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                  color: isFullyDone ? theme.colorScheme.primary : theme.colorScheme.tertiary,
                                  strokeWidth: 4,
                                ),
                                if (isFullyDone)
                                  Icon(Icons.check, size: 24, color: theme.colorScheme.primary)
                                else
                                  Text(
                                    '$completed',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ex.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isFullyDone ? theme.colorScheme.onSurface.withValues(alpha: 0.6) : theme.colorScheme.onSurface,
                                    decoration: isFullyDone ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$targetSets Sets × ${ex.reps} Reps',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (isResting)
                                      Text(
                                        'Rest: $_restTimeDisplay\s',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (isCoolingDown)
                                      Text(
                                        'Cooldown: $_cooldownTimeDisplay',
                                        style: TextStyle(
                                          color: Colors.cyanAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                if (note != null && note.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Log: $note',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Rest Timer Progress Bar (Clipped to rounded corners)
                    if (isResting)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: AnimatedBuilder(
                          animation: _restController,
                          builder: (context, child) {
                            return LinearProgressIndicator(
                              value: _restController.value,
                              backgroundColor: Colors.transparent,
                              color: Color.lerp(Colors.red, Colors.green, _restController.value),
                              minHeight: 6,
                            );
                          },
                        ),
                      ),
                      
                    // Cooldown Timer Progress Bar (Clipped to rounded corners)
                    if (isCoolingDown)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: AnimatedBuilder(
                          animation: _cooldownController,
                          builder: (context, child) {
                            return LinearProgressIndicator(
                              value: _cooldownController.value,
                              backgroundColor: Colors.transparent,
                              color: Color.lerp(Colors.blue, Colors.cyanAccent, _cooldownController.value),
                              minHeight: 6,
                            );
                          },
                        ),
                      ),
                  ],
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

  void _showRepInputDialog(Exercise ex) {
    final controller = TextEditingController(text: _exerciseNotes[ex.id] ?? '${ex.reps}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Reps for ${ex.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Actual Reps performed',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _exerciseNotes[ex.id] = '${controller.text} reps';
              });
              Navigator.pop(context);
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
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
            color: Colors.black.withValues(alpha: 0.1),
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
              onPressed: _confirmAndCompleteWorkout,
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
