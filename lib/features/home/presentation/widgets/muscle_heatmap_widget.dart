import 'package:flutter/material.dart';
import 'themed_card.dart';

/// Muscle Heatmap Widget
/// Visualizes which body parts have been trained recently.
class MuscleHeatmapWidget extends StatelessWidget {
  final Map<String, int> muscleWorkload; // e.g., {'Chest': 5, 'Legs': 0}

  const MuscleHeatmapWidget({
    super.key,
    required this.muscleWorkload,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ThemedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.accessibility_new_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                'MUSCLE RECOVERY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Simplified Visual Representation (List of bars for MVP)
          // A full 3D body map requires complex assets or painter.
          // Let's do a sleek "Power Bar" list for major groups.
          _buildPowerBar(context, "CHEST", muscleWorkload['Chest'] ?? 0),
          const SizedBox(height: 12),
          _buildPowerBar(context, "BACK", muscleWorkload['Back'] ?? 0),
          const SizedBox(height: 12),
          _buildPowerBar(context, "LEGS", muscleWorkload['Legs'] ?? 0),
          const SizedBox(height: 12),
          _buildPowerBar(context, "ARMS", muscleWorkload['Arms'] ?? 0),
          const SizedBox(height: 12),
          _buildPowerBar(context, "CORE", muscleWorkload['Core'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildPowerBar(BuildContext context, String label, int intensity) {
    final colorScheme = Theme.of(context).colorScheme;
    // Intensity: 0 = Fresh (Green/Primary), >0 = Worked (Redder/Error)
    // 1-3 = Recovering, 4+ = Strained/Sore
    
    final Color barColor;
    final String status;
    
    if (intensity == 0) {
      barColor = colorScheme.primary;
      status = "Fresh";
    } else if (intensity < 3) {
      barColor = Colors.orangeAccent;
      status = "Recovering";
    } else {
      barColor = colorScheme.error;
      status = "Sore";
    }

    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (intensity / 10).clamp(0.1, 1.0), // Min 10% width
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          status,
          style: TextStyle(
            fontSize: 10,
            color: barColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
