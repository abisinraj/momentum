import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers/database_providers.dart';

/// Progress screen - shows contribution grid, charts, and weekly insight
/// Design: 7-column grid, consistency streak, activity log charts
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityGridProvider(days: 42)); // 6 weeks
    final statsAsync = ref.watch(weeklyStatsProvider);
    final insightAsync = ref.watch(weeklyInsightProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: switch ((activityAsync, statsAsync, insightAsync)) {
          (AsyncData(value: final activity), AsyncData(value: final stats), AsyncData(value: final insight)) => 
              _buildContent(context, activity, stats, insight),
          (AsyncError(:final error), _, _) => Center(
              child: Text('Error: $error', style: TextStyle(color: AppTheme.error)),
            ),
           _ => Center(child: CircularProgressIndicator(color: AppTheme.tealPrimary)),
        },
      ),
    );
  }
  
  Widget _buildContent(BuildContext context, Map<DateTime, String> activityMap, Map<String, int> stats, String insight) {
    final streak = _calculateStreak(activityMap);
    final calories = stats['calories'] ?? 0;
    final durationSec = stats['duration'] ?? 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              // Month dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getCurrentMonth(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: AppTheme.textMuted, size: 18),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Consistency section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consistency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              // Streak badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.tealPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.tealPrimary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department, color: AppTheme.tealPrimary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$streak Day Streak',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.tealPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Contribution grid
          _ContributionGrid(activityMap: activityMap),
          
          const SizedBox(height: 8),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Less', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              const SizedBox(width: 8),
              ...AppTheme.gridIntensity.map((color) => Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const SizedBox(width: 8),
              Text('More', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Activity Log section
          Row(
            children: [
              Text(
                'Activity Log',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              // Tabs
              _TabButton(label: 'Calories', isSelected: true),
              const SizedBox(width: 8),
              _TabButton(label: 'Minutes', isSelected: false),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Calories Burned',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '$calories',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    /*
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up, color: AppTheme.success, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '+5%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    */
                  ],
                ),
                const SizedBox(height: 20),
                // Simple chart placeholder - could use real dataPoints if we had daily breakdown
                SizedBox(
                  height: 80,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _ChartPainter(dataPoints: 7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      .map((day) => Text(
                            day,
                            style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Weekly Insight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.tealPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome, color: AppTheme.tealPrimary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Insight',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insight,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Bottom stats row
          Row(
            children: [
              Expanded(child: _buildStatCard(Icons.timer_outlined, '${durationSec ~/ 60}m', 'ACTIVE TIME')),
              const SizedBox(width: 12),
              // Avg BPM removed or mocked as we don't have heart rate data
              Expanded(child: _buildStatCard(Icons.favorite_border, '--', 'AVG BPM')),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.tealPrimary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _getCurrentMonth() {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[DateTime.now().month - 1];
  }
  
  int _calculateStreak(Map<DateTime, String> activityMap) {
    if (activityMap.isEmpty) return 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int streak = 0;
    
    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      if (activityMap.containsKey(DateTime(date.year, date.month, date.day))) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }
  
  // Weekly insight helper removed, replaced by provider
  
  class _TabButton extends StatelessWidget {

  final String label;
  final bool isSelected;
  
  const _TabButton({required this.label, required this.isSelected});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.textPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? AppTheme.darkBackground : AppTheme.textMuted,
        ),
      ),
    );
  }
}

/// 7-column contribution grid widget
class _ContributionGrid extends StatelessWidget {
  final Map<DateTime, String> activityMap;
  
  const _ContributionGrid({required this.activityMap});
  
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Generate 6 weeks of days, arranged in 7-column grid
    final days = List.generate(42, (i) => today.subtract(Duration(days: 41 - i)));
    
    return Column(
      children: [
        // Day labels
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((day) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        // Grid rows
        ...List.generate(6, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIndex) {
                final index = weekIndex * 7 + dayIndex;
                final date = days[index];
                final dateKey = DateTime(date.year, date.month, date.day);
                final activity = activityMap[dateKey];
                final hasActivity = activity != null;
                final isToday = date == today;
                
                // Determine color intensity based on how many workouts
                final colorIndex = hasActivity ? 4 : 0;
                
                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.gridIntensity[colorIndex],
                    borderRadius: BorderRadius.circular(6),
                    border: isToday
                        ? Border.all(color: AppTheme.tealPrimary, width: 2)
                        : null,
                  ),
                  child: hasActivity
                      ? Center(
                          child: Text(
                            activity,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        )
                      : null,
                );
              }),
            ),
          );
        }),
      ],
    );
  }
}

/// Simple chart painter
class _ChartPainter extends CustomPainter {
  final int dataPoints;
  
  _ChartPainter({required this.dataPoints});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.tealPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    final path = Path();
    final points = [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.75];
    
    for (int i = 0; i < points.length; i++) {
      final x = (size.width / (points.length - 1)) * i;
      final y = size.height - (size.height * points[i]);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Create smooth curve
        final prevX = (size.width / (points.length - 1)) * (i - 1);
        final prevY = size.height - (size.height * points[i - 1]);
        final controlX = (prevX + x) / 2;
        path.quadraticBezierTo(controlX, prevY, (prevX + x) / 2, (prevY + y) / 2);
        path.quadraticBezierTo(controlX, y, x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.tealPrimary.withOpacity(0.3),
          AppTheme.tealPrimary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
