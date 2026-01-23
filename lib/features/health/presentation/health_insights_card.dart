import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/health_connect_provider.dart';
import '../../health/presentation/heart_rate_measure_screen.dart';
import '../../home/presentation/widgets/themed_card.dart';

/// Card widget displaying health insights on the home screen.
class HealthInsightsCard extends ConsumerWidget {
  const HealthInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If Health Connect is not available, don't show the card
    if (!healthState.isAvailable) {
      return const SizedBox.shrink();
    }

    return ThemedCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Health Insights',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (healthState.hasPermissions)
                  IconButton(
                    icon: healthState.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.sync_rounded,
                            color: colorScheme.primary,
                          ),
                    onPressed: healthState.isLoading
                        ? null
                        : () => ref.read(healthNotifierProvider.notifier).syncData(),
                    tooltip: 'Sync Health Data',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Content based on permission state
            if (!healthState.hasPermissions)
              _buildConnectPrompt(context, ref, colorScheme)
            else
              _buildHealthData(context, healthState, colorScheme),

            // Error message
            if (healthState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  healthState.error!,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),

            // Last sync time
            if (healthState.lastSyncTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Last synced: ${_formatTime(healthState.lastSyncTime!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
      ),
    );
  }

  Widget _buildConnectPrompt(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          'Connect to Health Connect to see your fitness data from other apps and wearables.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => ref.read(healthNotifierProvider.notifier).requestPermissions(),
          icon: const Icon(Icons.link_rounded),
          label: const Text('Connect Health'),
        ),
      ],
    );
  }

  Widget _buildHealthData(BuildContext context, HealthState state, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetric(
          context,
          icon: Icons.directions_walk_rounded,
          value: _formatSteps(state.todaySteps),
          label: 'Steps',
          color: colorScheme.primary,
        ),
        InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HeartRateMeasureScreen()),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildMetric(
              context,
              icon: Icons.favorite_rounded,
              value: state.latestHeartRate != null ? '${state.latestHeartRate}' : '--',
              label: 'BPM (Tap to Measure)',
              color: Colors.red,
            ),
          ),
        ),
        _buildMetric(
          context,
          icon: Icons.bedtime_rounded,
          value: state.lastNightSleep != null ? _formatSleep(state.lastNightSleep!) : '--',
          label: 'Sleep',
          color: Colors.indigo,
        ),
        _buildMetric(
          context,
          icon: Icons.monitor_weight_rounded,
          value: state.latestWeight != null ? state.latestWeight!.toStringAsFixed(1) : '--',
          label: 'kg',
          color: colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return steps.toString();
  }

  String _formatSleep(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }
}
