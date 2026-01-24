
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      );
      
    _loadHtmlFromAssets();
  }

  Future<void> _loadHtmlFromAssets() async {
    // Load the HTML file from assets
    String fileHtmlContents = await rootBundle.loadString('assets/www/index.html');
    
    // Load it into the webview
    // We use loadHtmlString because loadFlutterAsset is sometimes tricky with relative paths in JS modules
    // but here we are using a CDN for Three.js so loadHtmlString is safest.
    _controller.loadHtmlString(fileHtmlContents);
  }

  @override
  Widget build(BuildContext context) {
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
