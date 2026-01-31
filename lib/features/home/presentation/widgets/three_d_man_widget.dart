
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/dashboard_providers.dart';
import 'dart:convert';

class ThreeDManWidget extends ConsumerStatefulWidget {
  final double height;
  final bool transparent;
  final ValueChanged<String>? onMuscleTap;
  final String? focusMuscle;

  const ThreeDManWidget({
    super.key,
    this.height = 400,
    this.transparent = true,
    this.onMuscleTap,
    this.focusMuscle,
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
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message);
            if (data['type'] == 'muscle_tap' && widget.onMuscleTap != null) {
              widget.onMuscleTap!(data['name']);
            }
          } catch (e) {
            debugPrint('Error parsing 3D message: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _isPageLoaded = true;
            if (mounted) {
              // Inject model via Base64 to bypass CORS/File restrictions
              _injectModel();
              
              _updateBackgroundColor(); // SYNC THEME COLOR
              
              setState(() => _isLoading = false);
              _updateHeatmap(); // Initial sync
              if (widget.focusMuscle != null) {
                 _zoomToMuscle(widget.focusMuscle!);
              }
            }
          },
        ),
      );
      
    _loadHtmlFromAssets();
  }

  void _updateBackgroundColor() {
    if (!_isPageLoaded) return;
    final color = Theme.of(context).scaffoldBackgroundColor;
    final colorHex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    _controller.runJavaScript("if (window.setBackgroundColor) window.setBackgroundColor('$colorHex');");
  }
  
  Future<void> _injectModel() async {
    try {
      final bytes = await rootBundle.load('assets/3d/model.glb');
      final base64String = base64Encode(bytes.buffer.asUint8List());
      
      // Send to JS
      _controller.runJavaScript("if (window.loadGLTFFromBase64) window.loadGLTFFromBase64('$base64String');");
    } catch (e) {
      debugPrint('Error loading/injecting model: $e');
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateBackgroundColor();
  }

  @override
  void didUpdateWidget(ThreeDManWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusMuscle != oldWidget.focusMuscle) {
      if (widget.focusMuscle != null) {
        _zoomToMuscle(widget.focusMuscle!);
      } else {
        _resetCamera();
      }
    }
  }

  void _zoomToMuscle(String muscle) {
    if (!_isPageLoaded) return;
    _controller.runJavaScript("if (window.zoomToMuscle) window.zoomToMuscle('$muscle');");
  }

  void _resetCamera() {
    if (!_isPageLoaded) return;
    _controller.runJavaScript("if (window.resetCamera) window.resetCamera();");
  }

  Future<void> _loadHtmlFromAssets() async {
    await _controller.loadFlutterAsset('assets/3d/index.html');
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
      
      // Pass raw data to JS. The 3D model (v2) now handles hierarchy and aggregation.
      data.forEach((k, v) {
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
