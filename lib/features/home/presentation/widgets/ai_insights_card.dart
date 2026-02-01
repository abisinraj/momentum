import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add riverpod import
import 'package:momentum/core/providers/ai_providers.dart';
import 'package:momentum/features/home/presentation/ai_chat_screen.dart';
import 'package:momentum/core/services/settings_service.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class AIInsightsCard extends ConsumerWidget {
  const AIInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightAsync = ref.watch(dailyInsightProvider);
    final apiKeyAsync = ref.watch(geminiApiKeyProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    final insight = insightAsync.valueOrNull;
    final mood = insight?.mood ?? 'hero';
    final type = insight?.type ?? 'general';

    // Premium Gradient Card Design
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _getMoodColor(mood, colorScheme).withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getMoodColor(mood, colorScheme).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // BACKGROUND DECORATION: Subtle Gradient Blob
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AIChatScreen()),
                    ); 
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                           ShaderMask(
                             shaderCallback: (bounds) => LinearGradient(
                               colors: _getMoodGradient(mood, colorScheme),
                             ).createShader(bounds),
                             child: Icon(_getMoodIcon(type), size: 24, color: Colors.white), 
                           ),
                           const SizedBox(width: 12),
                           Text(
                             "MOMENTUM AI",
                             style: TextStyle(
                               fontSize: 14,
                               fontWeight: FontWeight.w800,
                               letterSpacing: 1.5,
                               color: colorScheme.onSurface,
                             ),
                           ),
                           const Spacer(),
                           // Subtle Refresh
                           SizedBox(
                             width: 32,
                             height: 32,
                             child: IconButton(
                               icon: const Icon(Icons.refresh, size: 18),
                               padding: EdgeInsets.zero,
                               style: IconButton.styleFrom(
                                 backgroundColor: colorScheme.surfaceContainerHighest,
                                 foregroundColor: colorScheme.onSurfaceVariant,
                               ),
                               onPressed: () => ref.refresh(dailyInsightProvider),
                             ),
                           ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),

                      // Insight Content
                      Builder(
                        builder: (context) {
                          // Check API Key first
                          final apiKey = apiKeyAsync.valueOrNull;
                          final hasKey = apiKey != null && apiKey.isNotEmpty && !apiKey.contains('YOUR_API_KEY');

                          if (!hasKey) {
                            return Center(
                              child: Column(
                                children: [
                                  Text(
                                    "Unlock personalized coaching insights.",
                                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: () => context.push('/api-settings'),
                                    icon: const Icon(Icons.key, size: 16),
                                    label: const Text("Connect Gemini API"),
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (insight != null) {
                            // Also filter out the specific service message just in case
                            if (insight.text.contains("Configure your Gemini API Key")) {
                               return const SizedBox.shrink(); // Should remain hidden or use above logic
                            }
                            
                            return Text(
                              insight.text,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }
                          if (insightAsync.isLoading) return _buildLoadingShimmer(context);
                          return Text(
                            "Ready to analyze your training data. Tap to generate insights.",
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          );
                        }
                      ),

                      const SizedBox(height: 24),
                      
                      // Call to Action
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface, // Darker input-like background
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 18, color: colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              "Ask me about your diet or recovery...",
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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

  Color _getMoodColor(String mood, ColorScheme colorScheme) {
    switch (mood) {
      case 'fire': return Colors.orange;
      case 'calm': return Colors.blue;
      case 'warning': return Colors.amber;
      case 'hero': return colorScheme.primary;
      default: return colorScheme.primary;
    }
  }

  List<Color> _getMoodGradient(String mood, ColorScheme colorScheme) {
    switch (mood) {
      case 'fire': return [Colors.orange, Colors.red];
      case 'calm': return [Colors.blue, Colors.cyan];
      case 'warning': return [Colors.amber, Colors.orange];
      case 'hero': return [colorScheme.primary, colorScheme.tertiary];
      default: return [colorScheme.primary, colorScheme.tertiary];
    }
  }

  IconData _getMoodIcon(String type) {
    switch (type) {
      case 'trend': return Icons.trending_up;
      case 'milestone': return Icons.emoji_events;
      case 'recovery': return Icons.self_improvement;
      case 'diet_prompt': return Icons.restaurant;
      default: return Icons.auto_awesome;
    }
  }
}
