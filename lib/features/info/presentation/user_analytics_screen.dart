import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/dashboard_providers.dart';
import '../../../core/providers/database_providers.dart';
import '../../home/presentation/widgets/themed_card.dart';
import '../../home/presentation/widgets/trend_chart.dart';

class UserAnalyticsScreen extends ConsumerWidget {
  const UserAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activityAsync = ref.watch(activityGridProvider(365));
    final analyticsAsync = ref.watch(analyticsSummaryProvider);
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Workout Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Info
            activityAsync.when(
              data: (activity) {
                final totalWorkouts = activity.length;
                final activeHours = (totalWorkouts * 0.75).toStringAsFixed(1);
                final totalCalories = totalWorkouts * 85;

                return Row(
                  children: [
                    _buildSummaryCard(context, 'Workouts', totalWorkouts.toString(), Icons.fitness_center, colorScheme.primary),
                    const SizedBox(width: 12),
                    _buildSummaryCard(context, 'Hours', activeHours, Icons.timer, colorScheme.secondary),
                    const SizedBox(width: 12),
                    _buildSummaryCard(context, 'Calories', totalCalories.toString(), Icons.local_fire_department, Colors.orangeAccent),
                  ],
                );
              },
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            
            const SizedBox(height: 24),
            
            // Volume Trend Chart
            const TrendChart(),
            
            const SizedBox(height: 24),
            
            // Muscle Focus Section
            Text(
              'MUSCLE PRIORITY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            
            analyticsAsync.when(
              data: (data) {
                final muscleFocus = data['muscleFocus'] as List<dynamic>? ?? [];
                if (muscleFocus.isEmpty) {
                  return const ThemedCard(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('Not enough data to calculate focus')),
                  );
                }

                return Column(
                  children: muscleFocus.map((entry) {
                    final e = entry as MapEntry<String, double>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMuscleFocusBar(context, e.key, e.value),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            
            const SizedBox(height: 32),
            
            // Consistency Insight
            ThemedCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_awesome, color: colorScheme.onPrimary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Consistency Insight',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You are in the top 15% of active users this month. Keep building that momentum!',
                            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: ThemedCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleFocusBar(BuildContext context, String muscle, double percentage) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(muscle.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Text('${(percentage * 100).toInt()}%', style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
