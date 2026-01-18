import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Splash screen shown while app initializes
/// Design: Teal M logo centered with "Momentum" text below
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon - Stylized M in rounded square
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurfaceContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: _buildMomentumLogo(),
                  ),
                ),
                const SizedBox(height: 32),
                // App name
                Text(
                  'Momentum',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.tealPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Bottom tagline
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'DIGITAL ATHLETIC JOURNAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Custom M logo matching the design
  Widget _buildMomentumLogo() {
    return CustomPaint(
      size: const Size(50, 40),
      painter: _MomentumLogoPainter(),
    );
  }
}

/// Custom painter for the Momentum "M" logo
class _MomentumLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.tealPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    final path = Path();
    
    // Draw stylized M shape
    // Left leg
    path.moveTo(size.width * 0.1, size.height * 0.85);
    path.lineTo(size.width * 0.1, size.height * 0.15);
    
    // Top left to center peak
    path.lineTo(size.width * 0.5, size.height * 0.55);
    
    // Center peak to top right
    path.lineTo(size.width * 0.9, size.height * 0.15);
    
    // Right leg
    path.lineTo(size.width * 0.9, size.height * 0.85);
    
    canvas.drawPath(path, paint);
    
    // Draw checkmark/arrow at bottom center
    final arrowPaint = Paint()
      ..color = AppTheme.tealPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    final arrowPath = Path();
    arrowPath.moveTo(size.width * 0.35, size.height * 0.65);
    arrowPath.lineTo(size.width * 0.5, size.height * 0.85);
    arrowPath.lineTo(size.width * 0.65, size.height * 0.65);
    
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
