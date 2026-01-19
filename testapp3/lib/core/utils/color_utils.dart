import 'package:flutter/material.dart';

/// Utility functions for color operations
class ColorUtils {
  /// Convert hex color string to Flutter Color
  static Color fromHex(String hex) {
    final buffer = StringBuffer();
    var cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) {
      buffer.write('ff');
    }
    buffer.write(cleaned);
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Get contrast text color (white or black) based on background color
  static Color getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
