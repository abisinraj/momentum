
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import 'themed_card.dart';

class TrendChart extends ConsumerStatefulWidget {
  const TrendChart({super.key});

  @override
  ConsumerState<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends ConsumerState<TrendChart> {
  bool _showReps = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // We want to show Volume Load over time (Last 30 sessions)
    final historyAsync = ref.watch(sessionHistoryProvider(30));

    return ThemedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _showReps ? 'REPS TREND' : 'VOLUME TREND',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              // Toggle Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _showReps = !_showReps),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showReps ? Icons.fitness_center : Icons.repeat,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showReps ? 'SHOW KG' : 'SHOW REPS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                   final value = _showReps 
                      ? (s['totalReps'] as int? ?? 0).toDouble()
                      : (s['totalVolume'] as double? ?? 0.0);
                   spots.add(FlSpot(i.toDouble(), value));
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
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            getTitlesWidget: (value, meta) {
                              String text;
                              if (value >= 1000) {
                                text = '${(value / 1000).toStringAsFixed(1)}k';
                              } else {
                                text = value.toInt().toString();
                              }
                              return Text(
                                text,
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
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${spot.y.toInt()} ${_showReps ? "reps" : "kg"}',
                                TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                        ),
                      ),
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
