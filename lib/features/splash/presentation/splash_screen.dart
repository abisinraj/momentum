import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/widget_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../app/widgets/permission_bottom_sheet.dart';

/// Splash screen shown while app initializes
/// Design: Ocean Blue logo centered with "Momentum" text below
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

    // Check permissions after initial delay
    _initSequence();
  }

  Future<void> _initSequence() async {
    // 1. Minimum logo display time
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // 2. Check permissions
    if (mounted) {
      await _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final service = ref.read(permissionServiceProvider.notifier);
    
    // Fail-safe: Mark as handled anyway after 45 seconds to ensure app never stays stuck
    Future.delayed(const Duration(seconds: 45), () async {
      if (mounted && !ref.read(permissionsHandledProvider)) {
        debugPrint('[SplashScreen] Permission fail-safe triggered.');
        await ref.read(permissionsHandledProvider.notifier).markAsHandled();
      }
    });

    final status = await service.checkStartupPermissions();
    
    // Identify missing permissions
    final missing = Map<AppPermission, PermissionStatusInfo>.fromEntries(
      status.entries.where((e) => !e.value.isGranted)
    );

    if (missing.isNotEmpty && mounted) {
      // Show elegant bottom sheet
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        enableDrag: false,
        isDismissible: false,
        builder: (context) => PermissionBottomSheet(missingPermissions: missing),
      );

      // Once the sheet is closed (any way), we proceed
      if (mounted) {
        await ref.read(permissionsHandledProvider.notifier).markAsHandled();
      }
    } else {
      // All good, move on
      if (mounted) {
        await ref.read(permissionsHandledProvider.notifier).markAsHandled();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: _buildMomentumLogo(colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // App name
                    Text(
                      'Momentum',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
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
                        colorScheme.primary.withValues(alpha: 0.5),
                      ),
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
                  '  ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
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
  Widget _buildMomentumLogo(Color iconColor) {
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
          return Icon(
            Icons.broken_image_outlined,
            color: iconColor,
            size: 40,
          );
        },
      ),
    );
  }
}

/// Custom painter for the Momentum "M" logo

