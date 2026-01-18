import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/workout_providers.dart';
import '../../../core/database/app_database.dart';

/// Active workout screen with clock display
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
  
  @override
  void initState() {
    super.initState();
    _initializeClock();
  }
  
  void _initializeClock() {
    switch (widget.session.clockType) {
      case ClockType.none:
        // No clock, just show elapsed time
        _startElapsedTimer();
        break;
      case ClockType.stopwatch:
        _startElapsedTimer();
        break;
      case ClockType.timer:
        _remaining = widget.session.timerDuration ?? const Duration(minutes: 30);
        _startCountdownTimer();
        break;
      case ClockType.alarm:
        _startElapsedTimer();
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
    // Haptic feedback
    HapticFeedback.heavyImpact();
    
    // Show completion dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.timer_off, size: 48),
        title: const Text('Time\'s Up!'),
        content: Text('${widget.session.workoutName} timer completed.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _completeWorkout();
            },
            child: const Text('Complete Workout'),
          ),
        ],
      ),
    );
  }
  
  void _togglePause() {
    setState(() {
      _isRunning = !_isRunning;
    });
    HapticFeedback.lightImpact();
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
        content: const Text('Your progress will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Going'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _timer?.cancel();
              ref.read(activeWorkoutSessionProvider.notifier).cancelWorkout();
              Navigator.pop(this.context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancelWorkout,
        ),
        title: Text(widget.session.workoutName),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              
              // Clock display
              _buildClockDisplay(theme),
              
              const SizedBox(height: 48),
              
              // Clock type indicator
              _buildClockTypeChip(theme),
              
              const Spacer(),
              
              // Control buttons
              _buildControls(theme),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildClockDisplay(ThemeData theme) {
    final displayDuration = widget.session.clockType == ClockType.timer 
        ? _remaining 
        : _elapsed;
    
    final hours = displayDuration.inHours;
    final minutes = (displayDuration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (displayDuration.inSeconds % 60).toString().padLeft(2, '0');
    
    final timeString = hours > 0 
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
    
    // Color based on timer state
    Color textColor = theme.colorScheme.onSurface;
    if (widget.session.clockType == ClockType.timer) {
      if (_remaining.inSeconds <= 10 && !_timerCompleted) {
        textColor = theme.colorScheme.error;
      } else if (_remaining.inSeconds <= 60) {
        textColor = theme.colorScheme.tertiary;
      }
    }
    
    return Column(
      children: [
        // Main time display
        Text(
          timeString,
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.w200,
            color: textColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        
        // Timer progress indicator
        if (widget.session.clockType == ClockType.timer) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: _calculateProgress(),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: _timerCompleted 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.tertiary,
            ),
          ),
        ],
        
        // Paused indicator
        if (!_isRunning) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'PAUSED',
              style: TextStyle(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  double _calculateProgress() {
    final total = widget.session.timerDuration ?? const Duration(minutes: 30);
    if (total.inSeconds == 0) return 0;
    final progress = 1 - (_remaining.inSeconds / total.inSeconds);
    return progress.clamp(0.0, 1.0);
  }
  
  Widget _buildClockTypeChip(ThemeData theme) {
    final (icon, label) = switch (widget.session.clockType) {
      ClockType.none => (Icons.timer_off_outlined, 'Free Session'),
      ClockType.stopwatch => (Icons.timer_outlined, 'Stopwatch'),
      ClockType.timer => (Icons.hourglass_bottom, 'Countdown Timer'),
      ClockType.alarm => (Icons.alarm, 'Alarm'),
    };
    
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    );
  }
  
  Widget _buildControls(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
        FloatingActionButton.large(
          heroTag: 'complete',
          onPressed: _completeWorkout,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.check,
            size: 36,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        
        // Cancel button
        FloatingActionButton(
          heroTag: 'cancel',
          onPressed: _cancelWorkout,
          backgroundColor: theme.colorScheme.errorContainer,
          child: Icon(
            Icons.close,
            color: theme.colorScheme.onErrorContainer,
          ),
        ),
      ],
    );
  }
}
