import 'package:flutter/material.dart';
import 'themed_card.dart';
import 'package:momentum/app/theme/app_theme.dart';
import 'package:percent_indicator/percent_indicator.dart';

class RecoveryScoreCard extends StatelessWidget {
  final int sleepHours; // from Health Connect
  final int workoutsLast3Days;
  final bool isRestDay;

  const RecoveryScoreCard({
    super.key,
    required this.sleepHours,
    required this.workoutsLast3Days,
    this.isRestDay = false,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate Score (Simple Algorithm)
    // Base: 100
    // Sleep Penalty: < 7h -> -10 per hour missing
    // Volume Penalty: > 3 workouts in 3 days -> -20 (need rest)
    // Bonus: Rest day today -> +10
    
    double score = 100;
    
    if (sleepHours < 7) {
      score -= (7 - sleepHours) * 10;
    }
    
    if (workoutsLast3Days >= 3) {
      score -= 20;
    }
    
    if (isRestDay) {
      score += 10;
    }
    
    score = score.clamp(0, 100);
    final isGood = score > 70;
    
    return ThemedCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 36.0,
            lineWidth: 8.0,
            percent: score / 100,
            center: Text(
              "${score.toInt()}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0, color: Colors.white),
            ),
            progressColor: isGood ? AppTheme.tealPrimary : Colors.orange,
            backgroundColor: Colors.white10,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "RECOVERY SCORE",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isGood ? "Ready to Train" : "Prioritize Rest",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isGood ? Colors.white : Colors.orangeAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isGood 
                    ? "Great sleep & volume balance." 
                    : "Sleep is low or volume is high.",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
