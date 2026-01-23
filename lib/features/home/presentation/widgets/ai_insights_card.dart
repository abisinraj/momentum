import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add riverpod import
import 'package:momentum/app/theme/app_theme.dart';
import 'package:momentum/core/providers/ai_providers.dart';
import 'package:shimmer/shimmer.dart';

class AIInsightsCard extends ConsumerWidget {
  const AIInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightAsync = ref.watch(dailyInsightProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.tealPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.tealPrimary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.tealPrimary.withValues(alpha: 0.05),
                    Colors.transparent,
                    AppTheme.tealPrimary.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.tealPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: AppTheme.tealPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "MOMENTUM AI",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.tealPrimary,
                      ),
                    ),
                    const Spacer(),
                    // Refresh Button (re-triggers provider)
                    IconButton(
                      icon: Icon(Icons.refresh, color: AppTheme.textMuted, size: 20),
                      onPressed: () {
                         // ignore: unused_result
                         ref.refresh(dailyInsightProvider);
                      },
                      splashRadius: 20,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

                // Insight Text
                insightAsync.when(
                  data: (insight) => Text(
                    insight,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  loading: () => _buildLoadingShimmer(),
                  error: (err, stack) => Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Couldn't generate insight. Check connection.",
                          style: TextStyle(color: AppTheme.error, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: AppTheme.darkSurface,
      highlightColor: AppTheme.darkSurface.withValues(alpha: 0.5), // Lighter highlight
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
