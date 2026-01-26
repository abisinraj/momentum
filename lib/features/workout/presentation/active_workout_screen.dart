import 'dart:async'; // For FontFeature

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/workout_providers.dart';
import '../../../core/providers/database_providers.dart'; // Import for exercises
import '../../../core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
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
  
  // Stopwatch State
  // _activeSetExerciseId is now "inferred" or "auto-detected"
  int? _currentWorkExerciseId; 
  Timer? _workTimer;
  Duration _currentWorkElapsed = Duration.zero;
  final Map<int, int> _accumulatedDurations = {}; // Exercise ID -> Total Seconds
  
  // Cached list to determine active exercise efficiently
  List<Exercise> _cachedExercises = [];

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
        // Auto-resume work timer happens in _workTimer tick
      }
    });
    
    // Cooldown setup...
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
    _startWorkTimer();
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
  
  // New Global Work Timer (Automated)
  void _startWorkTimer() {
    _workTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isRunning) return;
      
      // Safety check: Do we have exercises loaded?
      if (_cachedExercises.isEmpty) return;
      
      // Determine Active Exercise (First incomplete one)
      int? activeId;
      for (final ex in _cachedExercises) {
         final completed = _completedSets[ex.id] ?? 0;
         if (completed < ex.sets) {
           activeId = ex.id;
           break;
         }
      }
      
      // If we found an active exercise, and we ARE NOT resting or cooling down
      if (activeId != null) {
         if (_restingExerciseId == null && _cooldownExerciseId == null) {
            setState(() {
               _currentWorkExerciseId = activeId;
               _currentWorkElapsed += const Duration(seconds: 1);
            });
         } 
      } else {
         // All done?
         if (_currentWorkExerciseId != null) {
            setState(() => _currentWorkExerciseId = null);
         }
      }
    });
  }

  // Handle "Check" tap (Set Complete)
  Future<void> _incrementSet(int exerciseId, int targetSets, AsyncValue<List<Exercise>> exercisesAsync) async {
    // Capture Duration!
    if (_currentWorkExerciseId == exerciseId) {
       final seconds = _currentWorkElapsed.inSeconds;
       setState(() {
         _accumulatedDurations[exerciseId] = (_accumulatedDurations[exerciseId] ?? 0) + seconds;
         _currentWorkElapsed = Duration.zero; // Reset for next set
       });
    }

    final current = _completedSets[exerciseId] ?? 0;
    final next = (current + 1) % (targetSets + 1);
    
    setState(() {
      _completedSets[exerciseId] = next;
    });
    HapticFeedback.lightImpact();
    
    final newIsFullyDone = next >= targetSets;
                  
    if (newIsFullyDone) {
       _startCooldown(exerciseId);
       _restController.stop(); 
       setState(() => _restingExerciseId = null);
       
       // Check all done
       final exercisesList = exercisesAsync.valueOrNull ?? [];
       final allDone = exercisesList.every((e) {
          final sets = e.id == exerciseId ? next : (_completedSets[e.id] ?? 0);
          return sets >= e.sets;
       });
       
       if (allDone) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
             _confirmAndCompleteWorkout();
          }
       }
       
    } else if (next > current) {
       // Only start rest if we haven't just finished the last set
       _startRestTimer(exerciseId);
       _cooldownController.stop();
       setState(() => _cooldownExerciseId = null);
    }
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
    int intensity = 5; // Default moderate

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            backgroundColor: colorScheme.surface,
            title: Text('Finish Workout?', style: TextStyle(color: colorScheme.onSurface)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Great job! How intense was this session?',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RPE: $intensity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary)),
                    Text(
                      _getIntensityLabel(intensity),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getIntensityColor(intensity),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: intensity.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: intensity.toString(),
                  onChanged: (value) {
                    setDialogState(() => intensity = value.round());
                  },
                ),
                Text(
                  '1 (Easy) - 10 (Max Effort)',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Finish'),
              ),
            ],
          );
        }
      ),
    );
    
    if (confirmed == true) {
      await _completeWorkout(intensity);
    }
  }

  String _getIntensityLabel(int rpe) {
    if (rpe <= 3) return 'Easy Recovery';
    if (rpe <= 6) return 'Moderate';
    if (rpe <= 8) return 'Hard';
    return 'Max Effort';
  }

  Color _getIntensityColor(int rpe) {
    if (rpe <= 3) return Colors.green;
    if (rpe <= 6) return Colors.amber;
    if (rpe <= 8) return Colors.orange;
    return Colors.red;
  }

  
  Future<void> _completeWorkout(int intensity) async {
    _timer?.cancel();
    _workTimer?.cancel();
    
    // Gather exercise data
    final exercises = <SessionExercisesCompanion>[];
    
    // We need to iterate over known exercises. 
    // Since we don't have the list here easily without async, 
    // let's rely on _completedSets keys? No, some might be 0.
    // Better to fetch exercises again or pass them?
    // Let's assume _completedSets contains keys for touched exercises, 
    // but untouched ones (0 sets) should technically be 0.
    // Let's grab the IDs from _completedSets keys union _accumulatedDurations keys
    final excIds = {..._completedSets.keys, ..._accumulatedDurations.keys, ..._exerciseNotes.keys}.toList();
    
    // For proper recording, we should ideally record ALL exercises in the workout, even if 0 sets.
    // But since we don't have the full list in this method scope easily, let's record what we touched.
    // (Or simpler: Refactor to allow access to exercise list logic, but sticking to this for now).
    
    for (final id in excIds) {
       // Total duration = Accumulated + Current (if active and not finished)
       // But usually we finish via `_incrementSet` which flushes Current -> Accumulated.
       // Exception: User confirms workout without finishing last set?
       // Let's flush current if any.
       int totalSeconds = _accumulatedDurations[id] ?? 0;
       if (_currentWorkExerciseId == id) {
          totalSeconds += _currentWorkElapsed.inSeconds;
       }

       exercises.add(SessionExercisesCompanion.insert(
         sessionId: widget.session.sessionId,
         exerciseId: id,
         completedSets: Value(_completedSets[id] ?? 0),
         completedReps: const Value(0), 
         notes: Value(_exerciseNotes[id]),
         durationSeconds: Value(totalSeconds),
       ));
    }
    
    await ref.read(activeWorkoutSessionProvider.notifier).completeWorkout(
      intensity: intensity,
      exercises: exercises,
    );

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
              _workTimer?.cancel();
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
    _workTimer?.cancel();
    _restController.dispose();
    _cooldownController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercisesAsync = ref.watch(exercisesForWorkoutProvider(widget.session.workoutId));
    
    // Update cache for work timer
    if (exercisesAsync.hasValue) {
       _cachedExercises = exercisesAsync.value!;
       
       // Sort matching UI logic so 'active' calculation matches visual order
       _cachedExercises.sort((a, b) {
            final aDone = (_completedSets[a.id] ?? 0) >= a.sets;
            final bDone = (_completedSets[b.id] ?? 0) >= b.sets;
            if (aDone == bDone) return a.orderIndex.compareTo(b.orderIndex);
            return aDone ? 1 : -1; 
       });
    }
    
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
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _incrementSet(ex.id, targetSets, exercisesAsync),

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
                                    // Active Timer Display (Automated)
                                    if (!isFullyDone) ...[
                                       const Spacer(),
                                       Builder(
                                         builder: (context) {
                                            // Calculate total time to display
                                            int totalSeconds = _accumulatedDurations[ex.id] ?? 0;
                                            final isActive = _currentWorkExerciseId == ex.id;
                                            
                                            // Add current elapsed if active
                                            if (isActive) {
                                               totalSeconds += _currentWorkElapsed.inSeconds;
                                            }
                                            
                                            if (totalSeconds > 0) {
                                               final mins = totalSeconds ~/ 60;
                                               final secs = (totalSeconds % 60).toString().padLeft(2, '0');
                                               return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                     color: isActive ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                                                     borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                     mainAxisSize: MainAxisSize.min,
                                                     children: [
                                                        Icon(
                                                           Icons.timer, 
                                                           size: 14, 
                                                           color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                           '$mins:$secs',
                                                           style: TextStyle(
                                                              fontFamily: 'monospace',
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 12,
                                                              color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                                           ),
                                                        ),
                                                     ],
                                                  ),
                                               );
                                            } else if (isActive) {
                                               // Just started, show "Active" badge
                                               return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                     color: theme.colorScheme.primaryContainer,
                                                     borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                     'Active',
                                                     style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: theme.colorScheme.primary,
                                                     ),
                                                  ),
                                               );
                                            }
                                            return const SizedBox.shrink();
                                         }
                                       ),
                                    ],
                                    
                                    if (isResting) ...[
                                      const Spacer(),
                                      Text(
                                        'Rest: $_restTimeDisplay s',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    if (isCoolingDown)
                                      Text(
                                        'Cooldown: $_cooldownTimeDisplay',
                                        style: const TextStyle(
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
                      AnimatedBuilder(
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
                      
                    // Cooldown Timer Progress Bar (Clipped to rounded corners)
                    if (isCoolingDown)
                      AnimatedBuilder(
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
