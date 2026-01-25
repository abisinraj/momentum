
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/dashboard_providers.dart';
import 'dart:convert';

class ThreeDManWidget extends ConsumerStatefulWidget {
  final double height;
  final bool transparent;

  const ThreeDManWidget({
    super.key,
    this.height = 400,
    this.transparent = true,
  });

  @override
  ConsumerState<ThreeDManWidget> createState() => _ThreeDManWidgetState();
}

class _ThreeDManWidgetState extends ConsumerState<ThreeDManWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isPageLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _isPageLoaded = true;
            if (mounted) {
              setState(() => _isLoading = false);
              _updateHeatmap(); // Initial sync
            }
          },
        ),
      );
      
    _loadHtmlFromAssets();
  }
  
  @override
  void didUpdateWidget(ThreeDManWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If we supported external data passing, we'd check here.
    // Instead we rely on ref.listen in build or ref.watch logic triggering rebuilds that call _updateHeatmap
  }

  Future<void> _loadHtmlFromAssets() async {
    await _controller.loadFlutterAsset('assets/www/index.html');
  }
  
  void _updateHeatmap() {
    if (!_isPageLoaded) return;
    
    final workloadAsync = ref.read(muscleWorkloadProvider);
    
    workloadAsync.whenData((data) {
      // Normalize data (max score = 1.0)
      if (data.isEmpty) return;
      
      final maxScore = data.values.fold<int>(0, (max, v) => v > max ? v : max);
      if (maxScore == 0) return;
      
      final normalized = <String, double>{};
      data.forEach((k, v) {
        // Map simplified muscle names if needed
        // Assuming database uses standard names "Chest", "Back", "Legs"
        normalized[k] = v / maxScore; 
      });
      
      final jsonStr = jsonEncode(normalized);
      _controller.runJavaScript("if (window.resetHeatmap) window.resetHeatmap();");
      _controller.runJavaScript("if (window.setMuscleHeatmap) window.setMuscleHeatmap($jsonStr);");
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in muscle workload
    ref.listen(muscleWorkloadProvider, (previous, next) {
      _updateHeatmap();
    });

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
