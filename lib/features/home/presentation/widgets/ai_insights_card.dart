import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add riverpod import
import 'package:momentum/core/providers/ai_providers.dart';
import 'package:momentum/features/home/presentation/widgets/themed_card.dart';
import 'package:momentum/features/home/presentation/ai_chat_screen.dart';
import 'package:shimmer/shimmer.dart';

class AIInsightsCard extends ConsumerWidget {
  const AIInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightAsync = ref.watch(dailyInsightProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    // Add import manually at top if not auto-added, but for now assuming context works
    // Actually, I should add the import line first separately or here if included in range?
    // Let's modify the build method to wrap content.

    return ThemedCard(
      onTap: () {
         Navigator.of(context).push(
           MaterialPageRoute(builder: (context) => const AIChatScreen()),
         ); 
      },
      child: Stack(
        children: [
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
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: colorScheme.primary,
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
                        color: colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    // Refresh Button (re-triggers provider)
                    IconButton(
                      icon: Icon(Icons.refresh, color: colorScheme.onSurfaceVariant, size: 20),
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
                Builder(
                  builder: (context) {
                    final insight = insightAsync.valueOrNull;
                    
                    if (insight != null) {
                      return Text(
                        insight,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }
                    
                    if (insightAsync.isLoading) {
                      return _buildLoadingShimmer(context);
                    }
                    
                    if (insightAsync.hasError) {
                      return Row(
                        children: [
                          Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Couldn't generate insight. Check connection.",
                              style: TextStyle(color: colorScheme.error, fontSize: 14),
                            ),
                          ),
                        ],
                      );
                    }
                    
                    return const SizedBox.shrink();
                  }
                ),
                
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                     Navigator.of(context).push(
                       MaterialPageRoute(builder: (context) => const AIChatScreen()),
                     ); 
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                          Text(
                            'Tap to Chat & Analyze Photos',
                            style: TextStyle(
                               fontSize: 10, 
                               color: colorScheme.primary,
                               fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 12, color: colorScheme.primary),
                       ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainer,
      highlightColor: colorScheme.surfaceContainer.withValues(alpha: 0.5),
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
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
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
