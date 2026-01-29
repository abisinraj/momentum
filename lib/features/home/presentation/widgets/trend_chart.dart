
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/database_providers.dart';
import 'themed_card.dart';

class TrendChart extends ConsumerWidget {
  const TrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // We want to show Volume Load over time (Last 30 sessions)
    // We need a provider that gives us completed sessions with their Volume.
    // Let's rely on sessionHistoryProvider for now.
    final historyAsync = ref.watch(sessionHistoryProvider(30));

    return ThemedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'VOLUME TREND',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.7,
            child: historyAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return Center(child: Text('No data yet', style: TextStyle(color: colorScheme.onSurfaceVariant)));
                }

                // Prepare Data: Sort by date
                final sorted = List.of(sessions);
                sorted.sort((a, b) {
                  final dtA = a['completedAt'] as DateTime;
                  final dtB = b['completedAt'] as DateTime;
                  return dtA.compareTo(dtB);
                });
                
                // Take last 20 for readability
                final recent = sorted.length > 20 ? sorted.sublist(sorted.length - 20) : sorted;
                
                List<FlSpot> spots = [];
                for (int i = 0; i < recent.length; i++) {
                   final s = recent[i];
                   final durationMins = (s['durationSeconds'] as int) / 60.0;
                   spots.add(FlSpot(i.toDouble(), durationMins));
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 16, top: 16, bottom: 0),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Too crowded usually
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (recent.length - 1).toDouble(),
                      minY: 0,
                      // Add buffer to Y
                      maxY: spots.isEmpty ? 10.0 : (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2), 
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: colorScheme.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading chart', style: TextStyle(color: colorScheme.error))),
            ),
          ),
        ],
      ),
    );
  }
}
