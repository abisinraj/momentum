import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:momentum/app/theme/app_theme.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class BodyModelViewer extends StatefulWidget {
  final Map<String, double> heatmap;

  const BodyModelViewer({super.key, required this.heatmap});

  @override
  State<BodyModelViewer> createState() => _BodyModelViewerState();
}

class _BodyModelViewerState extends State<BodyModelViewer> {
  // We can inject JS to color muscles if we know their material names
  // For now, we just display the model as requested
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Stack(
        children: [
          // GLB Viewer
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ModelViewer(
              src: 'assets/3d/human.glb',
              alt: '3D Body Model',
              autoRotate: true,
              cameraControls: true,
              backgroundColor: Colors.transparent,
              // interactionPrompt: InteractionPrompt.none,
              ar: false,
              disableZoom: false,
            ),
          ),
          
          // Labels / Legend
          Positioned(
            top: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MUSCLE FATIGUE',
                  style: TextStyle(
                    color: AppTheme.tealPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(width: 12, height: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    const Text('Fresh', style: TextStyle(color: Colors.white, fontSize: 10)),
                    const SizedBox(width: 12),
                    Container(width: 12, height: 12, color: Colors.red),
                    const SizedBox(width: 4),
                    const Text('Fatigued', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
