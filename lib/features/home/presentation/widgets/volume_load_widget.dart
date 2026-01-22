import 'package:flutter/material.dart';
import 'package:momentum/app/theme/app_theme.dart';

class VolumeLoadWidget extends StatelessWidget {
  final double currentWeekVolume;
  final double lastWeekVolume;

  const VolumeLoadWidget({
    super.key,
    required this.currentWeekVolume,
    required this.lastWeekVolume,
  });

  @override
  Widget build(BuildContext context) {
    final diff = currentWeekVolume - lastWeekVolume;
    final isPositive = diff >= 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_weight_outlined, color: AppTheme.tealPrimary, size: 20),
              const SizedBox(width: 12),
              const Text(
                'VOLUME LOAD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatVolume(currentWeekVolume),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'kg',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? AppTheme.tealPrimary : Colors.orangeAccent,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                "${_formatVolume(diff.abs())} kg vs last week",
                style: TextStyle(
                  fontSize: 12,
                  color: isPositive ? AppTheme.tealPrimary : Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatVolume(double vol) {
    if (vol >= 1000) {
      return '${(vol / 1000).toStringAsFixed(1)}k';
    }
    return vol.toStringAsFixed(0);
  }
}
