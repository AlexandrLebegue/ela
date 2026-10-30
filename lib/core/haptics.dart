import 'package:flutter/services.dart';

/// Retours haptiques doux, « battement de cœur ».
abstract final class ElaHaptics {
  static Future<void> heartbeat() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.lightImpact();
  }

  static Future<void> softTap() async {
    await HapticFeedback.selectionClick();
  }
}
