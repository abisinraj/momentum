import 'package:flutter/material.dart';
import 'package:momentum/app/theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart'; // We can use SVG or CustomPainter. For MVP, CustomPainter is easier without assets.

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
              Icon(Icons.accessibility_new_rounded, color: AppTheme.tealPrimary, size: 20),
              const SizedBox(width: 12),
              const Text(
                'MUSCLE RECOVERY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Simplified Visual Representation (List of bars for MVP)
          // A full 3D body map requires complex assets or painter.
          // Let's do a sleek "Power Bar" list for major groups.
          _buildPowerBar("CHEST", muscleWorkload['Chest'] ?? 0),
          const SizedBox(height: 12),
          _buildPowerBar("BACK", muscleWorkload['Back'] ?? 0),
          const SizedBox(height: 12),
          _buildPowerBar("LEGS", muscleWorkload['Legs'] ?? 0),
          const SizedBox(height: 12),
          _buildPowerBar("ARMS", muscleWorkload['Arms'] ?? 0),
          const SizedBox(height: 12),
          _buildPowerBar("CORE", muscleWorkload['Core'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildPowerBar(String label, int intensity) {
    // Intensity: 0 = Fresh (Green), >0 = Worked (Redder)
    // 1-3 = Recovering, 4+ = Strained/Sore
    
    final Color barColor;
    final String status;
    
    if (intensity == 0) {
      barColor = Colors.greenAccent;
      status = "Fresh";
    } else if (intensity < 3) {
      barColor = Colors.orangeAccent;
      status = "Recovering";
    } else {
      barColor = Colors.redAccent;
      status = "Sore";
    }

    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
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
                  color: Colors.white10,
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
