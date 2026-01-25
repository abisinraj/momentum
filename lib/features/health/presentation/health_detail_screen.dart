import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import '../../../core/providers/health_connect_provider.dart';
import '../../../core/services/settings_service.dart';


/// Screen showing detailed health data from Health Connect.
class HealthDetailScreen extends ConsumerWidget {
  const HealthDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Connect'),
        actions: [
          if (healthState.hasPermissions)
            IconButton(
              icon: healthState.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onSurface,
                      ),
                    )
                  : const Icon(Icons.sync_rounded),
              onPressed: healthState.isLoading
                  ? null
                  : () => ref.read(healthNotifierProvider.notifier).syncData(),
              tooltip: 'Sync Now',
            ),
        ],
      ),
      body: !healthState.isAvailable
          ? _buildNotAvailable(context)
          : !healthState.hasPermissions
              ? _buildPermissionsRequired(context, ref)
               : _buildHealthDetails(context, ref, healthState),
    );
  }

  Widget _buildNotAvailable(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Health Connect Not Available',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please install the Health Connect app from the Play Store to sync your health data.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsRequired(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Connect to Health Connect',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Allow Momentum to read your health data from other apps and wearables.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.read(healthNotifierProvider.notifier).requestPermissions(),
              icon: const Icon(Icons.link_rounded),
              label: const Text('Grant Access'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthDetails(BuildContext context, WidgetRef ref, HealthState state) {

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final weightUnitAsync = ref.watch(weightUnitProvider);
    final weightUnit = weightUnitAsync.valueOrNull ?? 'kg';

    return ListView(

      padding: const EdgeInsets.all(16),
      children: [
        // Today's Summary
        _buildSectionHeader(context, 'Today\'s Summary'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.directions_walk_rounded,
                value: state.todaySteps.toString(),
                label: 'Steps',
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.favorite_rounded,
                value: state.latestHeartRate?.toString() ?? '--',
                label: 'Heart Rate (BPM)',
                color: colorScheme.error,
              ),
            ),

          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.bedtime_rounded,
                value: state.lastNightSleep != null
                    ? '${state.lastNightSleep!.inHours}h ${state.lastNightSleep!.inMinutes % 60}m'
                    : '--',
                label: 'Last Night Sleep',
                color: colorScheme.secondary,
              ),
            ),

            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.monitor_weight_rounded,
                value: state.latestWeight != null 
                    ? (weightUnit == 'lbs' 
                        ? (state.latestWeight! * 2.20462).toStringAsFixed(1)
                        : state.latestWeight!.toStringAsFixed(1))
                    : '--',
                label: 'Weight ($weightUnit)',
                color: colorScheme.tertiary,
              ),
            ),

          ],
        ),

        const SizedBox(height: 24),

        // Recent Workouts
        if (state.recentWorkouts.isNotEmpty) ...[
          _buildSectionHeader(context, 'Recent Workouts (from Health Connect)'),
          const SizedBox(height: 8),
          ...state.recentWorkouts.map((workout) => _buildWorkoutTile(context, workout)),
        ],

        // Error
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Card(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Last sync time
        if (state.lastSyncTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Text(
                'Last synced: ${_formatDateTime(state.lastSyncTime!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutTile(BuildContext context, HealthDataPoint workout) {
    final theme = Theme.of(context);
    final workoutValue = workout.value;
    
    String workoutType = 'Workout';
    if (workoutValue is WorkoutHealthValue) {
      workoutType = workoutValue.workoutActivityType.name.replaceAll('_', ' ');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.fitness_center_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(workoutType),
        subtitle: Text(
          '${_formatDate(workout.dateFrom)} • ${_formatDuration(workout.dateTo.difference(workout.dateFrom))}',
        ),
        trailing: Text(
          workout.sourceName,
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}';
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m';
  }
}
