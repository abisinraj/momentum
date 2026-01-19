import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/widget_service.dart';
import '../../../app/theme/app_theme.dart';

/// Splash screen shown while app initializes
/// Design: Teal M logo centered with "Momentum" text below
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync widget data in background
    ref.read(widgetSyncProvider);

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
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Image.asset(
        'assets/images/app_logo.jpg',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading logo: $error');
          return Icon(
            Icons.broken_image_outlined,
            color: AppTheme.tealPrimary,
            size: 40,
          );
        },
      ),
    );
  }
}

/// Custom painter for the Momentum "M" logo

