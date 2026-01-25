import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/widget_service.dart';
import '../../../app/theme/app_theme.dart';

/// Splash screen shown while app initializes
/// Design: Teal M logo centered with \"Momentum\" text below
/// Animation: Fade-in with 1.5s minimum display
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Fade-in animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    // Start animation
    _controller.forward();
    
    // Sync widget data in background
    ref.read(widgetSyncProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
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
                  const Text(
                    'Momentum',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.tealPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtle loading indicator
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.tealPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom tagline
            const Positioned(
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
          debugPrint('Error loading logo: $error');
          return const Icon(
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

