import 'package:flutter/material.dart';
import 'themed_card.dart';

class ConsistencyGridWidget extends StatelessWidget {
  final Map<DateTime, String> activityData; // Date -> Workout Type (or just presence)

  const ConsistencyGridWidget({super.key, required this.activityData});

  @override
  Widget build(BuildContext context) {
    // Generate last ~182 days (26 weeks)
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    
    // We want to show 26 full columns (weeks)
    // To align correctly, we start from the current week's Sunday (end) back to 26 weeks ago Monday (start)
    final daysSinceMonday = todayMidnight.weekday - 1;
    final thisMonday = todayMidnight.subtract(Duration(days: daysSinceMonday));
    final alignedStartDate = thisMonday.subtract(const Duration(days: (26 - 1) * 7));

    final colorScheme = Theme.of(context).colorScheme;

    return ThemedCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONSISTENCY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Last 6 Months',
                    style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              const Spacer(),
              // Legend
              _buildLegend(context),
            ],
          ),
          const SizedBox(height: 16),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // Latest week on the right
            child: Row(
              children: List.generate(26, (weekIndex) {
                 final weekStart = alignedStartDate.add(Duration(days: weekIndex * 7));
                 return Padding(
                   padding: const EdgeInsets.only(right: 5.0),
                   child: Column(
                     children: List.generate(7, (dayIndex) {
                       final date = weekStart.add(Duration(days: dayIndex));
                       
                       // Check if date is in future
                       if (date.isAfter(todayMidnight)) {
                         return _buildCell(context, -1); // Future (transparent)
                       }
                       
                       // Score: Workouts in the 7-day window ending on 'date'
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

  Widget _buildLegend(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text('Cold', style: TextStyle(fontSize: 8, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
        const SizedBox(width: 4),
        Container(width: 8, height: 8, decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 2),
        Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text('Peak', style: TextStyle(fontSize: 8, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
      ],
    );
  }

  Widget _buildCell(BuildContext context, int score) {
    Color color;
    final colorScheme = Theme.of(context).colorScheme;

    if (score == -1) {
      color = Colors.transparent; // Future
    } else if (score == 0) {
      color = colorScheme.onSurface.withValues(alpha: 0.1);
    } else {
      // 1-7 Scale: Build Momentum
      // 1 = Starting (Orange/Red)
      // 7 = Peak (Vibrant Green)
      // Transitioning through HSL: Hue 15 (Orange) to Hue 130 (Green)
      final double t = (score - 1) / 6.0;
      final double hue = 15 + (t * 115); // 15 to 130
      final double saturation = 0.7 + (t * 0.3); // 0.7 to 1.0
      final double lightness = 0.5 + (t * 0.1); // 0.5 to 0.6
      
      color = HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.5),
        boxShadow: score >= 6 ? [
          BoxShadow(
             color: color.withValues(alpha: 0.4),
             blurRadius: 4,
             spreadRadius: 1,
          )
        ] : null,
      ),
    );
  }
}
