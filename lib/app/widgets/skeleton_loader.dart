import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Skeleton shimmer widget for loading states
/// Provides a pulsing animation placeholder
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  
  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: AppTheme.darkSurfaceContainer.withValues(alpha: _animation.value),
          ),
        );
      },
    );
  }
}

/// Skeleton card for workout loading state
class WorkoutCardSkeleton extends StatelessWidget {
  const WorkoutCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final responsiveMinHeight = (screenHeight * 0.55).clamp(350.0, 550.0);
        
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(minHeight: responsiveMinHeight),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail skeleton
              SkeletonLoader(width: double.infinity, height: 180, borderRadius: 12),
              SizedBox(height: 16),
              // Title skeleton
              SkeletonLoader(width: 200, height: 40, borderRadius: 4),
              SizedBox(height: 12),
              // Subtitle skeleton
              SkeletonLoader(width: 150, height: 16, borderRadius: 4),
              SizedBox(height: 48), // Padding instead of Spacer for unbounded containers
              // Button skeleton
              SkeletonLoader(width: double.infinity, height: 56, borderRadius: 12),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton for stats row
class StatsRowSkeleton extends StatelessWidget {
  const StatsRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              children: [
                SkeletonLoader(width: 40, height: 40, borderRadius: 20),
                SizedBox(height: 8),
                SkeletonLoader(width: 60, height: 24, borderRadius: 4),
                SizedBox(height: 4),
                SkeletonLoader(width: 80, height: 12, borderRadius: 4),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: AppTheme.darkBorder),
          const Expanded(
            child: Column(
              children: [
                SkeletonLoader(width: 40, height: 40, borderRadius: 20),
                SizedBox(height: 8),
                SkeletonLoader(width: 60, height: 24, borderRadius: 4),
                SizedBox(height: 4),
                SkeletonLoader(width: 80, height: 12, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for progress grid
class ProgressGridSkeleton extends StatelessWidget {
  const ProgressGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header skeleton
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(width: 100, height: 20, borderRadius: 4),
              SkeletonLoader(width: 60, height: 20, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 16),
          // Grid skeleton (7 columns, 5 rows)
          ...List.generate(5, (row) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (col) => const SkeletonLoader(
                width: 32,
                height: 32,
                borderRadius: 6,
              )),
            ),
          )),
        ],
      ),
    );
  }
}
