import 'package:flutter/material.dart';
import 'themed_card.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    
    return ThemedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_weight_outlined, color: colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                'VOLUME LOAD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurfaceVariant,
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
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'kg',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? colorScheme.primary : Colors.orangeAccent,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                "${_formatVolume(diff.abs())} kg vs last week",
                style: TextStyle(
                  fontSize: 12,
                  color: isPositive ? colorScheme.primary : Colors.orangeAccent,
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
