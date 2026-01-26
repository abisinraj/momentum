import 'package:flutter/material.dart';
import 'themed_card.dart';

class ConsistencyGridWidget extends StatelessWidget {
  final Map<DateTime, String> activityData; // Date -> Workout Type (or just presence)

  const ConsistencyGridWidget({super.key, required this.activityData});

  @override
  Widget build(BuildContext context) {
    // Generate last 26 weeks
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    
    // Align to the start of the current week (e.g., Monday)
    // If today is Wednesday, this week starts Monday.
    final currentWeekStart = todayMidnight.subtract(Duration(days: todayMidnight.weekday - 1));
    
    // We want 26 blocks, ending with the current week
    // Block 0 = 25 weeks ago
    // Block 25 = Current Week
    
    final colorScheme = Theme.of(context).colorScheme;

    return ThemedCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_view_week_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEEKLY MOMENTUM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Sessions per Week (Last 6 Months)',
                    style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              const Spacer(),
              _buildLegend(context),
            ],
          ),
          const SizedBox(height: 16),
          
          RepaintBoundary(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: false, // Start from the start (Left)
              child: Row(
                children: List.generate(26, (index) {
                  // Calculate week range
                  // Index 0 = Current Week
                  // Index 1 = Last Week
                  final weeksAgo = index;
                  final weekStart = currentWeekStart.subtract(Duration(days: weeksAgo * 7));
                  final weekEnd = weekStart.add(const Duration(days: 6));
                  
                  // Calculate Score (0-7)
                  int daysActive = 0;
                  for (int i = 0; i < 7; i++) {
                    final date = weekStart.add(Duration(days: i));
                    if (activityData.containsKey(date)) {
                      daysActive++;
                    }
                  }
                  
                  return _buildWeekBlock(context, daysActive, weekStart, weekEnd, index == 0);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text('0', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
        const SizedBox(width: 4),
        Container(width: 8, height: 8, decoration: BoxDecoration(color: _getColor(context, 0), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 2),
        Container(width: 8, height: 8, decoration: BoxDecoration(color: _getColor(context, 7), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text('7 days', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
      ],
    );
  }

  Widget _buildWeekBlock(BuildContext context, int count, DateTime start, DateTime end, bool isCurrentWeek) {
    final color = _getColor(context, count);
    
    // Tooltip logic could go here, for now just the visual block
    
    return Container(
      margin: const EdgeInsets.only(right: 6), // Spacing between weeks
      child: Column(
        children: [
          // The Block
          Container(
            width: 12,     // Wider blocks for weeks
            height: 40,    // Tall bars roughly
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: isCurrentWeek ? Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), width: 1) : null,
              boxShadow: count > 3 ? [
                 BoxShadow(
                   color: color.withValues(alpha: 0.4),
                   blurRadius: 6,
                   offset: const Offset(0, 2),
                 )
              ] : null,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
  
  Color _getColor(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (count == 0) {
      return colorScheme.surfaceContainerHighest.withValues(alpha: 0.5); 
    }
    
    // Dynamic intensity based on Primary color
    // 1 day  -> 0.2
    // 7 days -> 1.0
    // Linear step: (0.8 / 6) = ~0.133 per day + base 0.2
    // Actually simpler: 15% to 100%
    
    const minOpacity = 0.2;
    const maxOpacity = 1.0;
    
    final t = (count - 1) / 6.0; // 0.0 to 1.0 derived from count 1..7
    final opacity = minOpacity + (maxOpacity - minOpacity) * t;
    
    return colorScheme.primary.withValues(alpha: opacity.clamp(0.0, 1.0));
  }
}
