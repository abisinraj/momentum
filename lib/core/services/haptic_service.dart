import 'package:flutter/services.dart';

/// Service for providing haptic feedback throughout the app
class HapticService {
  /// Light impact - for tab changes, minor interactions
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }
  
  /// Medium impact - for completing sets, confirming actions
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }
  
  /// Heavy impact - for workout start/stop, major milestones
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }
  
  /// Selection click - subtle feedback for selections
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
  
  /// Success pattern - for completing workout
  static void success() {
    HapticFeedback.mediumImpact();
  }
  
  /// Error/warning pattern
  static void warning() {
    HapticFeedback.heavyImpact();
  }
}
