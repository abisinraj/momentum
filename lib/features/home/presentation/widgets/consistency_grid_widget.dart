import 'package:flutter/material.dart';
import 'themed_card.dart';

class ConsistencyGridWidget extends StatelessWidget {
  final Map<DateTime, String> activityData; // Date -> Workout Type (or just presence)

  const ConsistencyGridWidget({super.key, required this.activityData});

  @override
  Widget build(BuildContext context) {
    // Generate last ~140 days (20 weeks)
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = endDate.subtract(const Duration(days: 139)); // 20 weeks * 7 - 1
    
    // Adjust start date to previous Monday to align grid
    final weekday = startDate.weekday; // 1=Mon, 7=Sun
    final alignedStartDate = startDate.subtract(Duration(days: weekday - 1));

    final colorScheme = Theme.of(context).colorScheme;

    return ThemedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                'CONSISTENCY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Last 20 Weeks',
                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // Standard heatmap: Today is on the far right
            child: Row(
              children: List.generate(20, (weekIndex) {
                 final weekStart = alignedStartDate.add(Duration(days: weekIndex * 7));
                 return Padding(
                   padding: const EdgeInsets.only(right: 4.0),
                   child: Column(
                     children: List.generate(7, (dayIndex) {
                       final date = weekStart.add(Duration(days: dayIndex));
                       
                       // Check if date is in future
                       if (date.isAfter(endDate)) {
                         return _buildCell(context, -1); // Future
                       }
                       
                       // Momentum Logic: How many workouts in the 7 days inclusive of this day?
                       int score = 0;
                       for (int i = 0; i < 7; i++) {
                         final checkDate = date.subtract(Duration(days: i));
                         final key = DateTime(checkDate.year, checkDate.month, checkDate.day);
                         if (activityData.containsKey(key)) {
                           score++;
                         }
                       }
                       
                       return _buildCell(context, score);
                     }),
                   ),
                 );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(BuildContext context, int score) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color;

    if (score == -1) {
      color = Colors.transparent; // Future
    } else if (score == 0) {
      // No workouts in last 7 days - cold
      color = colorScheme.onSurface.withValues(alpha: 0.05);
    } else {
      // 1-7 scale: Red to Green
      // We'll use HSL for a smooth transition: 0 is Red, 120 is Green
      // Score 1 -> ~0 (Red)
      // Score 7 -> ~120 (Green)
      final hue = ((score - 1) / 6.0) * 120.0;
      color = HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
      
      // Fine-tune: Make it slightly translucent for that "glass" feel
      color = color.withValues(alpha: 0.9);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: score > 0 ? Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5) : null,
      ),
    );
  }
}
