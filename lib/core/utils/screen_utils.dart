import 'package:flutter/widgets.dart';

class ScreenUtils {
  static void printScreenInfo(BuildContext context) {
    // Media Query data
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final pixelRatio = mediaQuery.devicePixelRatio;
    
    // Physical pixels
    final widthPx = size.width * pixelRatio;
    final heightPx = size.height * pixelRatio;
    
    debugPrint('--- SCREEN INFO ---');
    debugPrint('Logical Size: ${size.width.toStringAsFixed(1)} x ${size.height.toStringAsFixed(1)}');
    debugPrint('Pixel Ratio:  ${pixelRatio.toStringAsFixed(2)}');
    debugPrint('Physical Px:  ${widthPx.toStringAsFixed(0)} x ${heightPx.toStringAsFixed(0)}');
    debugPrint('Orientation:  ${mediaQuery.orientation.name}');
    debugPrint('Text Scale:   ${mediaQuery.textScaler.scale(10)/10}'); // Approx scale factor
    debugPrint('-------------------');
  }
  
  static String getResolutionString(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final pixelRatio = mediaQuery.devicePixelRatio;
    final widthPx = (size.width * pixelRatio).round();
    final heightPx = (size.height * pixelRatio).round();
    
    return '$widthPx x $heightPx';
  }
}
