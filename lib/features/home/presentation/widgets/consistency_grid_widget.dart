import 'package:flutter/material.dart';
import 'themed_card.dart';

class ConsistencyGridWidget extends StatelessWidget {
  final Map<DateTime, String> activityData; // Date -> Workout Type (or just presence)

  const ConsistencyGridWidget({super.key, required this.activityData});

  @override
  Widget build(BuildContext context) {
    // Generate last ~84 days (12 weeks)
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = endDate.subtract(const Duration(days: 83)); // 12 weeks * 7 - 1
    
    // We want to render columns (Weeks) of rows (Days: Mon-Sun)
    // Actually, GitHub grid is Rows (Days) x Columns (Weeks) mostly, 
    // but typically rendered as Column of 7 Rows (days) or Row of X Columns (weeks).
    // Let's do Row of Columns (Weeks).
    
    // Adjust start date to previous Monday to align grid?
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
                'Last 12 Weeks',
                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // Show newest on right? Standard is usually left-to-right history.
            // But if we want to see "Today" at the end, standard is LTR.
            child: Row(
              children: List.generate(12, (weekIndex) {
                 final weekStart = alignedStartDate.add(Duration(days: weekIndex * 7));
                 return Padding(
                   padding: const EdgeInsets.only(right: 4.0),
                   child: Column(
                     children: List.generate(7, (dayIndex) {
                       final date = weekStart.add(Duration(days: dayIndex));
                       // Check if date is in future
                       if (date.isAfter(endDate)) {
                         return _buildCell(context, null); // Future
                       }
                       
                       // Check activity
                       // precise lookup
                       final dateKey = DateTime(date.year, date.month, date.day);
                       final hasActivity = activityData.containsKey(dateKey);
                       
                       return _buildCell(context, hasActivity);
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

  Widget _buildCell(BuildContext context, bool? active) {
    Color color;
    if (active == null) {
      color = Colors.transparent; // Future
    } else if (active) {
      color = Theme.of(context).colorScheme.primary;
    } else {
      color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
