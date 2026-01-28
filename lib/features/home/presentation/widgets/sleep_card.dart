import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momentum/core/database/app_database.dart';
import 'package:momentum/core/providers/database_providers.dart';
import 'package:momentum/core/providers/health_connect_provider.dart';
import 'package:drift/drift.dart' as drift;
import 'themed_card.dart';
import '../../../../core/services/correlation_service.dart';

class SleepCard extends ConsumerWidget {
  const SleepCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepLogsAsync = ref.watch(sleepLogsProvider(days: 7));
    final healthState = ref.watch(healthNotifierProvider);



    return ThemedCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nights_stay_rounded, color: Colors.indigoAccent, size: 22),
              const SizedBox(width: 12),
              const Text(
                'SLEEP TRACKER',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.indigoAccent,
                ),
              ),
              const Spacer(),
              _buildSyncButton(context, ref, healthState),
            ],
          ),
          const SizedBox(height: 24),
          sleepLogsAsync.when(
            data: (logs) => _buildSleepContent(context, ref, logs),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => const Text('Error loading sleep data'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton(BuildContext context, WidgetRef ref, HealthState state) {
    if (state.isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return IconButton(
      icon: const Icon(Icons.sync, size: 18),
      onPressed: () => ref.read(healthNotifierProvider.notifier).syncData(),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: 'Sync with Health Connect',
    );
  }

  Widget _buildSleepContent(BuildContext context, WidgetRef ref, List<SleepLog> logs) {
    final lastNight = logs.isNotEmpty ? logs.first : null;
    
    // Calculate average
    double avgHours = 0;
    if (logs.isNotEmpty) {
      final totalMinutes = logs.fold<int>(0, (sum, log) => sum + log.durationMinutes);
      avgHours = (totalMinutes / logs.length) / 60.0;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "LAST NIGHT",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      lastNight != null ? (lastNight.durationMinutes / 60.0).toStringAsFixed(1) : "0.0",
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "hrs",
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ],
            ),
            _buildStatBox(context, "7D AVG", "${avgHours.toStringAsFixed(1)}h", Icons.trending_up, Colors.indigoAccent),
          ],
        ),
        const SizedBox(height: 16),
        _buildQualityBar(context, lastNight?.quality ?? 0),
        const SizedBox(height: 16),
        _buildCorrelationInsight(context, ref),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showManualLogDialog(context, ref),
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('Log Manually'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorrelationInsight(BuildContext context, WidgetRef ref) {
    final insightAsync = ref.watch(correlationInsightProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    return insightAsync.when(
      data: (text) {
        if (text.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.tertiary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
               Icon(Icons.auto_awesome, size: 16, color: colorScheme.tertiary),
               const SizedBox(width: 12),
               Expanded(
                 child: Text(
                   text,
                   style: TextStyle(
                     fontSize: 12, 
                     color: colorScheme.onSurface,
                     fontStyle: FontStyle.italic,
                   ),
                 ),
               ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatBox(BuildContext context, String label, String value, IconData icon, Color color) {
    // Removed unused colorScheme
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityBar(BuildContext context, int quality) {
    final colorScheme = Theme.of(context).colorScheme;
    final double percent = (quality.toDouble() / 10.0).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "SLEEP QUALITY",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
            Text(
              quality > 0 ? "$quality/10" : "Not set",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: quality > 0 ? percent : 0.05,
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              quality > 7 ? Colors.greenAccent : (quality > 4 ? Colors.orangeAccent : Colors.redAccent)
            ),
          ),
        ),
      ],
    );
  }

  void _showManualLogDialog(BuildContext context, WidgetRef ref) async {
    double duration = 7.0;
    int quality = 7;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Log Sleep'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Duration: ${duration.toStringAsFixed(1)} hours'),
              Slider(
                value: duration,
                min: 0,
                max: 16,
                divisions: 32,
                onChanged: (v) => setState(() => duration = v),
              ),
              const SizedBox(height: 16),
              Text('Quality: $quality/10'),
              Slider(
                value: quality.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (v) => setState(() => quality = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final date = DateTime.now();
                ref.read(appDatabaseProvider).addSleepLog(SleepLogsCompanion(
                  date: drift.Value(DateTime(date.year, date.month, date.day)),
                  durationMinutes: drift.Value((duration * 60).round()),
                  quality: drift.Value(quality),
                  isSynced: const drift.Value(false),
                ));
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
