
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/dashboard_providers.dart';
import '../../../../core/services/settings_service.dart';
import 'dart:convert';
import '../../../../core/constants/muscle_data.dart';

class ThreeDManWidget extends ConsumerStatefulWidget {
  final double height;
  final bool transparent;
  final ValueChanged<String>? onMuscleTap;
  final String? focusMuscle;
  final String? heroTag;
  final bool interactive;

  const ThreeDManWidget({
    super.key,
    this.height = 400,
    this.transparent = true,
    this.onMuscleTap,
    this.focusMuscle,
    this.heroTag,
    this.interactive = true,
  });

  @override
  ConsumerState<ThreeDManWidget> createState() => _ThreeDManWidgetState();
}

class _ThreeDManWidgetState extends ConsumerState<ThreeDManWidget> {
  static final Map<String, WebViewController> _persistentControllers = {};
  static final Map<String, bool> _isModelLoaded = {};

  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isPageLoaded = false;

  @override
  void initState() {
    super.initState();
    
    // Check for persistent controller to support Hero transitions
    if (widget.heroTag != null && _persistentControllers.containsKey(widget.heroTag)) {
      _controller = _persistentControllers[widget.heroTag!]!;
      _isLoading = !(_isModelLoaded[widget.heroTag!] ?? false);
      _isPageLoaded = true;
      
      // If we are reusing a controller, we might need to re-sync state
      _initReusedController();
    } else {
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
              } else if (data['type'] == 'model_loaded') {
                if (mounted) {
                  setState(() => _isLoading = false);
                  if (widget.heroTag != null) {
                    _isModelLoaded[widget.heroTag!] = true;
                  }
                }
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
                _injectModel();
                _updateBackgroundColor();
                
                // Fallback: hide loader after 3s if model_loaded doesn't arrive
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted && _isLoading) {
                    setState(() => _isLoading = false);
                  }
                });

                if (widget.focusMuscle != null) {
                  _zoomToMuscle(widget.focusMuscle!);
                }
              }
            },
            onWebResourceError: (error) {
               debugPrint('3D WebView Error: ${error.description}');
            }
          ),
        );
        
      if (widget.heroTag != null) {
        _persistentControllers[widget.heroTag!] = _controller;
      }
      _loadHtmlFromAssets();
    }
  }

  void _initReusedController() {
    // If we're reusing, ensure the theme and heatmap are correct for the current context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateBackgroundColor();
        if (widget.focusMuscle != null) {
          _zoomToMuscle(widget.focusMuscle!);
        }
      }
    });
  }

  void _updateBackgroundColor() {
    if (!_isPageLoaded) return;
    final color = Theme.of(context).scaffoldBackgroundColor;
    final colorHex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    _controller.runJavaScript("if (window.setBackgroundColor) window.setBackgroundColor('$colorHex');");
  }
  
  Future<void> _injectModel() async {
    try {
      // 1. Inject Muscle Definitions (Source of Truth)
      final defsJson = jsonEncode(MuscleData.definitions);
      final mirrorsJson = jsonEncode(MuscleData.mirroredMuscles);
      _controller.runJavaScript("if (window.updateMuscleDefs) window.updateMuscleDefs($defsJson, $mirrorsJson);");

      // 2. Load Model
      final bytes = await rootBundle.load('assets/3d/model.glb');
      final base64String = base64Encode(bytes.buffer.asUint8List());
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
  
  void _updateHeatmap(AsyncValue<Map<String, int>> workloadAsync) {
    if (!_isPageLoaded) return;
    
    workloadAsync.whenData((data) {
      if (data.isEmpty) {
        _controller.runJavaScript("if (window.resetHeatmap) window.resetHeatmap();");
        return;
      }
      
      final maxScore = data.values.fold<int>(0, (max, v) => v > max ? v : max);
      if (maxScore == 0) {
        _controller.runJavaScript("if (window.resetHeatmap) window.resetHeatmap();");
        return;
      }
      
      final normalized = <String, double>{};
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
    // Watch the provider here to ensure rebuilds when data changes
    final workloadAsync = ref.watch(muscleWorkloadProvider);
    
    // Sync heatmap with JS state whenever we build and the page is ready
    if (_isPageLoaded) {
      final rotationModeAsync = ref.watch(modelRotationModeProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateHeatmap(workloadAsync);
          rotationModeAsync.whenData((mode) {
             _controller.runJavaScript("if (window.setRotationMode) window.setRotationMode('$mode');");
          });
        }
      });
    }

    final webView = WebViewWidget(
      controller: _controller,
      gestureRecognizers: widget.interactive ? {
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      } : {},
    );

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: widget.heroTag != null 
        ? Hero(
            tag: widget.heroTag!, 
            flightShuttleBuilder: (flightContext, animation, direction, fromHeroContext, toHeroContext) {
              return _buildStack(webView);
            },
            child: _buildStack(webView)
          )
        : _buildStack(webView),
    );
  }

  Widget _buildStack(Widget webView) {
    return IgnorePointer(
      ignoring: !widget.interactive,
      child: Stack(
        children: [
          webView,
          if (_isLoading)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
