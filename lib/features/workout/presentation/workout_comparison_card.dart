import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/comparison_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../home/presentation/widgets/themed_card.dart';

class WorkoutComparisonCard extends ConsumerWidget {
  final int workoutId;
  final VoidCallback onStart;

  const WorkoutComparisonCard({
    super.key,
    required this.workoutId,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(workoutComparisonProvider(workoutId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return comparisonAsync.when(
      data: (data) => _buildCard(context, data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ThemedCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading comparison: $err', style: TextStyle(color: colorScheme.error)),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> data) {
    final workout = data['workout'] as Workout;
    final isFirst = data['isFirst'] as bool;
    final lastSession = data['lastSession'] as Session?;
    final targetExercises = data['targetExercises'] as List<Exercise>; // Placeholder for now

    final colorScheme = Theme.of(context).colorScheme;

    return ThemedCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Section (Gradient)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.8),
                  colorScheme.secondary.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'TODAY\'S SPLIT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!isFirst && lastSession != null)
                      Text(
                        'Last: ${DateFormat('MMM d').format(lastSession.completedAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  workout.name,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${targetExercises.length} Exercises • Focus: ${targetExercises.firstOrNull?.primaryMuscleGroup ?? 'General'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          // 2. Comparison Grid
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (isFirst)
                  _buildFirstSessionView(context)
                else
                  _buildComparisonMetrics(context, data),
                  
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 24),
                
                // 3. Nutrition (Simplified Placeholder)
                _buildNutritionSection(context),
                
                const SizedBox(height: 32),
                
                // 4. Start Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('START SESSION'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstSessionView(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.rocket_launch, size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        const Text(
          "First Time!",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "This is your first session for this split. Use this workout to set your baseline weights.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildComparisonMetrics(BuildContext context, Map<String, dynamic> data) {
    final lastSession = data['lastSession'] as Session;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Example: Intensity Comparison
    final lastIntensity = lastSession.intensity ?? 0;
    
    return Row(
      children: [
        Expanded(
          child: _buildMetricItem(
            context,
            label: 'LAST INTENSITY',
            value: '$lastIntensity/10',
            trendIcon: Icons.bolt,
            trendColor: colorScheme.primary,
          ),
        ),
        Expanded(
          child: _buildMetricItem(
            context,
            label: 'DURATION',
            value: '${(lastSession.durationSeconds ?? 0) ~/ 60}m',
            trendIcon: Icons.timer_outlined,
            trendColor: colorScheme.secondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMetricItem(BuildContext context, {required String label, required String value, IconData? trendIcon, Color? trendColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
             if (trendIcon != null) ...[
               Icon(trendIcon, size: 16, color: trendColor),
               const SizedBox(width: 6),
             ],
             Text(
               value,
               style: const TextStyle(
                 fontSize: 20,
                 fontWeight: FontWeight.bold,
               ),
             ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildNutritionSection(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text('FUELING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
             Text('Tracking coming soon...', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        )
      ],
    );
  }
}
