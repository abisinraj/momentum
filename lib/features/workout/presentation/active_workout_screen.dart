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
  // Key: Exercise ID, Value: Completed sets count
  final Map<int, int> _completedSets = {};
  
  // Key: Exercise ID, Value: Note/Actual reps (transient)
  final Map<int, String> _exerciseNotes = {};
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializeClock();
  }
  
  // ... (Keep existing methods until _buildChecklistPage) ...

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
            final completed = _completedSets[ex.id] ?? 0;
            final targetSets = ex.sets;
            final isFullyDone = completed >= targetSets;
            final note = _exerciseNotes[ex.id];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              color: isFullyDone 
                  ? theme.colorScheme.secondaryContainer.withOpacity(0.3) 
                  : theme.colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isFullyDone 
                    ? BorderSide.none 
                    : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    final current = _completedSets[ex.id] ?? 0;
                    // Cycle: 0 -> 1 -> ... -> Max -> 0
                    final next = (current + 1) % (targetSets + 1);
                    _completedSets[ex.id] = next;
                  });
                  HapticFeedback.lightImpact();
                },
                onLongPress: () => _showRepInputDialog(ex),
                child: Padding(
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
                                color: isFullyDone ? theme.colorScheme.onSurface.withOpacity(0.6) : theme.colorScheme.onSurface,
                                decoration: isFullyDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$targetSets Sets × ${ex.reps} Reps',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
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
                      // Helper text?
                      Icon(
                        Icons.touch_app, 
                        size: 16, 
                        color: theme.colorScheme.outline.withOpacity(0.5)
                      ),
                    ],
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
