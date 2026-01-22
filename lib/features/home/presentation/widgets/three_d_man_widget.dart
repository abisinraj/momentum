import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ThreeDManWidget extends StatefulWidget {
  final double height;
  final bool transparent;

  const ThreeDManWidget({
    super.key,
    this.height = 400,
    this.transparent = true,
  });

  @override
  State<ThreeDManWidget> createState() => _ThreeDManWidgetState();
}

class _ThreeDManWidgetState extends State<ThreeDManWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ModelViewer(
        // Placeholder humanoid model (Robot) that is public and reliable.
        // User should replace this with 'assets/3d/human.glb' when available.
        src: 'https://modelviewer.dev/shared-assets/models/RobotExpressive.glb',
        alt: 'A 3D model of a human',
        ar: false,
        autoRotate: true,
        cameraControls: true,
        backgroundColor: widget.transparent ? Colors.transparent : Colors.black,
        disableZoom: false,
        interactionPrompt: InteractionPrompt.auto,
      ),
    );
  }
}
