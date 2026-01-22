import 'dart:math';
import 'package:flutter/material.dart';
import 'package:momentum/app/theme/app_theme.dart';

/// Interactive "Holographic" Particle Body Widget
/// Visualizes muscle workload using a point-cloud style human figure.
/// The particles gently float and react to touch (wave effect).
class ParticleManWidget extends StatefulWidget {
  final Map<String, int> muscleWorkload;

  const ParticleManWidget({
    super.key,
    required this.muscleWorkload,
  });

  @override
  State<ParticleManWidget> createState() => _ParticleManWidgetState();
}

class _ParticleManWidgetState extends State<ParticleManWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();
  
  // Touch interaction
  Offset? _touchPoint;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _generateBodyParticles();
  }
  
  void _generateBodyParticles() {
    // Generate a simplified human shape (2D Projection of "White Dots")
    // We define regions and fill them with dots.
    
    // Head
    _addParticlesInCircle(const Offset(0.5, 0.15), 0.08, 40, "Core");
    
    // Body / Core (Rectangular-ish)
    _addParticlesInRect(const Rect.fromLTWH(0.42, 0.23, 0.16, 0.25), 100, "Core");
    
    // Left Arm
    _addParticlesInLine(const Offset(0.42, 0.25), const Offset(0.3, 0.5), 30, "Arms");
    
    // Right Arm
    _addParticlesInLine(const Offset(0.58, 0.25), const Offset(0.7, 0.5), 30, "Arms");
    
    // Left Leg
    _addParticlesInLine(const Offset(0.45, 0.48), const Offset(0.40, 0.85), 40, "Legs");
    
    // Right Leg
    _addParticlesInLine(const Offset(0.55, 0.48), const Offset(0.60, 0.85), 40, "Legs");
    
    // Chest area override
    _addParticlesInRect(const Rect.fromLTWH(0.42, 0.25, 0.16, 0.12), 40, "Chest");
    
    // Back area (simulated - just mixed in for MVP visual)
    _addParticlesInRect(const Rect.fromLTWH(0.44, 0.28, 0.12, 0.15), 30, "Back");
  }
  
  void _addParticlesInCircle(Offset center, double radius, int count, String muscleGroup) {
    for (int i = 0; i < count; i++) {
       final r = radius * sqrt(_random.nextDouble());
       final theta = _random.nextDouble() * 2 * pi;
       final x = center.dx + r * cos(theta);
       final y = center.dy + r * sin(theta);
       _particles.add(Particle(x: x, y: y, baseX: x, baseY: y, muscleGroup: muscleGroup));
    }
  }
  
  void _addParticlesInRect(Rect rect, int count, String muscleGroup) {
    for (int i = 0; i < count; i++) {
       final x = rect.left + _random.nextDouble() * rect.width;
       final y = rect.top + _random.nextDouble() * rect.height;
       _particles.add(Particle(x: x, y: y, baseX: x, baseY: y, muscleGroup: muscleGroup));
    }
  }
  
  void _addParticlesInLine(Offset start, Offset end, int count, String muscleGroup) {
     for (int i = 0; i < count; i++) {
       final t = _random.nextDouble();
       // Add some perpendicular noise for thickness
       final perpX = -(end.dy - start.dy);
       final perpY = (end.dx - start.dx);
       final len = sqrt(perpX*perpX + perpY*perpY);
       final normalizedPerpX = perpX / len;
       final normalizedPerpY = perpY / len;
       
       final noise = (_random.nextDouble() - 0.5) * 0.08; // Thickness
       
       final x = start.dx + (end.dx - start.dx) * t + normalizedPerpX * noise;
       final y = start.dy + (end.dy - start.dy) * t + normalizedPerpY * noise;
       _particles.add(Particle(x: x, y: y, baseX: x, baseY: y, muscleGroup: muscleGroup));
     }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          // Normalize touch to 0..1 relative to render box
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final local = renderBox.globalToLocal(details.globalPosition);
            _touchPoint = Offset(
              local.dx / renderBox.size.width,
              local.dy / renderBox.size.height,
            );
          }
        });
      },
      onPanEnd: (_) => setState(() => _touchPoint = null),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkSurfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.accessibility_new_outlined, color: AppTheme.tealPrimary, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'MUSCLE RECOVERY (3D)',
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
            
            // The Canvas
            SizedBox(
              height: 300,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ParticleBodyPainter(
                      particles: _particles,
                      animationValue: _controller.value,
                      workload: widget.muscleWorkload,
                      touchPoint: _touchPoint,
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            const Text(
              "Swipe the body to inspect",
              style: TextStyle(fontSize: 10, color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  final double baseX;
  final double baseY;
  final String muscleGroup;
  
  // Dynamic properties
  double phaseOffset;
  
  Particle({
    required this.x,
    required this.y,
    required this.baseX,
    required this.baseY,
    required this.muscleGroup,
  }) : phaseOffset = Random().nextDouble() * 2 * pi;
}

class ParticleBodyPainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final Map<String, int> workload;
  final Offset? touchPoint;

  ParticleBodyPainter({
    required this.particles,
    required this.animationValue,
    required this.workload,
    this.touchPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    for (var p in particles) {
      // Base Color
      Color color = Colors.white.withValues(alpha: 0.2); // Default idle
      
      // Heatmap Logic
      final intensity = workload[p.muscleGroup] ?? 0;
      if (intensity > 0) {
        if (intensity < 3) {
          color = Colors.orangeAccent.withValues(alpha: 0.6);
          // Pulse effect for recovering
          if (sin(animationValue * 2 * pi + p.phaseOffset) > 0.5) {
             color = color.withValues(alpha: 0.8);
          }
        } else {
          color = Colors.redAccent.withValues(alpha: 0.8);
        }
      }

      // Physics / Animation
      // 1. Idle breathing
      double dx = 0;
      double dy = sin(animationValue * 2 * pi + p.phaseOffset) * 0.005;
      
      // 2. Touch interaction (Repulsion / Wavy)
      if (touchPoint != null) {
        final dist = sqrt(pow(touchPoint!.dx - p.baseX, 2) + pow(touchPoint!.dy - p.baseY, 2));
        if (dist < 0.2) {
           // Wavy displacement away from touch
           final angle = atan2(p.baseY - touchPoint!.dy, p.baseX - touchPoint!.dx);
           final force = (0.2 - dist) * 0.5;
           dx += cos(angle) * force;
           dy += sin(angle) * force;
        }
      }

      // Draw
      final drawX = (p.baseX + dx) * size.width;
      final drawY = (p.baseY + dy) * size.height;
      
      paint.color = color;
      canvas.drawCircle(Offset(drawX, drawY), 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticleBodyPainter oldDelegate) => true;
}
