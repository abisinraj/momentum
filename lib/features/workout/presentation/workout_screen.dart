import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/providers/workout_providers.dart';
import '../../../core/database/app_database.dart';

/// Workout screen - shows list of workouts with completion states
class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workoutsAsync = ref.watch(workoutsStreamProvider);
    final todayCompletedAsync = ref.watch(todayCompletedWorkoutIdsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWorkoutDialog(context, ref),
          ),
        ],
      ),
      body: workoutsAsync.when(
        data: (workouts) {
          if (workouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No workouts yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first workout',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          
          final todayCompleted = todayCompletedAsync.valueOrNull ?? [];
          
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
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
              
              return _WorkoutCard(
                key: ValueKey(workout.id),
                workout: workout,
                isCompleted: isCompleted,
                onDelete: () => _confirmDelete(context, ref, workout),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
  
  void _showAddWorkoutDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    ClockType selectedClockType = ClockType.stopwatch;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Workout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Workout Name',
                  hintText: 'e.g., Push, Pull, Legs',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Short Code (1 letter)',
                  hintText: 'e.g., P, L, G',
                  border: OutlineInputBorder(),
                ),
                maxLength: 1,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ClockType>(
                value: selectedClockType,
                decoration: const InputDecoration(
                  labelText: 'Clock Type',
                  border: OutlineInputBorder(),
                ),
                items: ClockType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_clockTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedClockType = value!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final code = codeController.text.trim().toUpperCase();
                
                if (name.isEmpty || code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }
                
                await ref.read(workoutManagerProvider.notifier).addWorkout(
                  name: name,
                  shortCode: code,
                  clockType: selectedClockType,
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmDelete(BuildContext context, WidgetRef ref, Workout workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout?'),
        content: Text('Are you sure you want to delete "${workout.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(workoutManagerProvider.notifier)
                  .deleteWorkout(workout.id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  String _clockTypeLabel(ClockType type) {
    return switch (type) {
      ClockType.none => 'None',
      ClockType.stopwatch => 'Stopwatch',
      ClockType.timer => 'Timer',
      ClockType.alarm => 'Alarm',
    };
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final bool isCompleted;
  final VoidCallback onDelete;
  
  const _WorkoutCard({
    super.key,
    required this.workout,
    required this.isCompleted,
    required this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: isCompleted
              ? Icon(Icons.check, color: theme.colorScheme.primary)
              : Text(
                  workout.shortCode,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(workout.name),
        subtitle: Text(_clockTypeLabel(workout.clockType)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCompleted)
              Chip(
                label: const Text('Done'),
                backgroundColor: theme.colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 12,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )
            else
              const Icon(Icons.drag_handle),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _clockTypeLabel(ClockType type) {
    return switch (type) {
      ClockType.none => 'No timer',
      ClockType.stopwatch => 'Stopwatch',
      ClockType.timer => 'Timer',
      ClockType.alarm => 'Alarm',
    };
  }
}
