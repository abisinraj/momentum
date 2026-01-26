import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:momentum/app/theme/app_theme.dart';
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
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() => _isLoaded = true);
            _updateHeatmap();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.errorCode} - ${error.description}');
          },
          onNavigationRequest: (request) {
            debugPrint('Navigating to: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setOnConsoleMessage((message) {
        debugPrint('WebView Console: ${message.message}');
      })
      ..loadFlutterAsset('assets/3d/index.html');
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
          
          if (!_isLoaded)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.tealPrimary),
            ),
        ],
      ),
    );
  }
}
