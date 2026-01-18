import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';

/// Progress screen - shows contribution grid
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activityAsync = ref.watch(activityGridProvider(days: 30));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 30 Days',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // Contribution grid
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: activityAsync.when(
                  data: (activityMap) => _ContributionGrid(activityMap: activityMap),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Error: $e'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Summary',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            activityAsync.when(
              data: (activityMap) {
                final activeDays = activityMap.length;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _StatItem(
                          label: 'Active Days',
                          value: activeDays.toString(),
                          icon: Icons.calendar_today,
                        ),
                        const SizedBox(width: 24),
                        _StatItem(
                          label: 'This Month',
                          value: _getThisMonthCount(activityMap).toString(),
                          icon: Icons.trending_up,
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
            ),
            const Spacer(),
            // Motivational message
            activityAsync.when(
              data: (activityMap) {
                final message = _getMotivationalMessage(activityMap.length);
                return Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
  
  int _getThisMonthCount(Map<DateTime, String> activityMap) {
    final now = DateTime.now();
    return activityMap.keys
        .where((date) => date.month == now.month && date.year == now.year)
        .length;
  }
  
  String _getMotivationalMessage(int activeDays) {
    if (activeDays == 0) {
      return 'Start your first workout to build momentum!';
    } else if (activeDays < 5) {
      return 'Great start! Keep building that momentum.';
    } else if (activeDays < 15) {
      return 'You\'re building a solid routine. Keep it up!';
    } else if (activeDays < 25) {
      return 'Impressive consistency! You\'re on fire.';
    } else {
      return 'Outstanding! You\'ve been incredibly consistent.';
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Contribution grid widget showing activity for last 30 days
class _ContributionGrid extends StatelessWidget {
  final Map<DateTime, String> activityMap;
  
  const _ContributionGrid({required this.activityMap});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Generate last 30 days
    final days = List.generate(30, (i) => today.subtract(Duration(days: 29 - i)));
    
    return Column(
      children: [
        // Grid
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: days.map((date) {
            final dateKey = DateTime(date.year, date.month, date.day);
            final activity = activityMap[dateKey];
            final hasActivity = activity != null;
            
            return Tooltip(
              message: '${date.day}/${date.month} - ${activity ?? 'Rest'}',
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: hasActivity
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: date == today
                      ? Border.all(color: theme.colorScheme.outline, width: 2)
                      : null,
                ),
                child: hasActivity
                    ? Center(
                        child: Text(
                          activity,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text('Rest', style: theme.textTheme.bodySmall),
            const SizedBox(width: 16),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text('Active', style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
