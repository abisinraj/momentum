import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BodyModelViewer extends StatefulWidget {
  final Map<String, double> heatmap;

  const BodyModelViewer({super.key, required this.heatmap});

  @override
  State<BodyModelViewer> createState() => _BodyModelViewerState();
}

class _BodyModelViewerState extends State<BodyModelViewer> {
  late final WebViewController _controller;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoaded = true);
              _updateHeatmap();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.errorCode} - ${error.description}');
          },
        ),
      );

    // Delay loading to prioritize main UI rendering
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.loadFlutterAsset('assets/3d/index.html');
      }
    });
  }

  @override
  void didUpdateWidget(covariant BodyModelViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.heatmap != oldWidget.heatmap) {
      _updateHeatmap();
    }
  }

  void _updateHeatmap() {
    if (!_isLoaded) return;
    final json = jsonEncode(widget.heatmap);
    _controller.runJavaScript('setMuscleHeatmap($json)');
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Stack(
        children: [
          // WebView
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: WebViewWidget(controller: _controller),
          ),
          
          // Labels / Legend
          Positioned(
            top: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MUSCLE FATIGUE',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 12, 
                      height: 12, 
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Fresh', 
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 12, 
                      height: 12, 
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Fatigued', 
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (!_isLoaded)
            Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
        ],
      ),
    );
  }
}
