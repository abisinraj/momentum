import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/three_d_man_widget.dart';

class Recovery3DScreen extends StatelessWidget {
  const Recovery3DScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ThreeDManWidget(
                height: MediaQuery.of(context).size.height * 0.8,
              ),
            ),
          ),
          
          // Custom Back Button Overlay
          Positioned(
            top: 40,
            left: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Icon(Icons.arrow_back, color: colorScheme.onSurface, size: 24),
                ),
              ),
            ),
          ),
          
          // Header Overlay
          Positioned(
            top: 50,
            right: 24,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'MUSCLE STATUS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    'LIVE HEATMAP',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
