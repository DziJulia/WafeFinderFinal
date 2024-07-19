import 'package:flutter/material.dart';

/// A class that holds the custom colors used in the application.
class ThemeColors {
  static const Color themeBlue = Color(0xFF8AC6FD);
  static const Color background = Color(0xFFE5E5E5);
  static const Color deleteRed = Color(0xFFF34A4A);
  static const Color bubblesColor = Color.fromARGB(179, 138, 197, 253);
  static const Color swellBlue = Color(0xFF0057D9);

}

/// Extension on [Color] to add a method that makes the color darker.
extension ColorUtils on Color {
  /// Returns a new color that is a [percent] darker version of this color.
  ///
  /// The [percent] parameter must be between 1 and 100, inclusive. It defaults to 10 if not specified.
  /// The closer the [percent] is to 100, the darker the color. For example, if [percent] is 50,
  /// the method returns a color that is 50% darker.
  ///
  /// This method only affects the RGB channels of the color, so the returned color will have the same opacity (alpha) as the original color.
  ///
  /// @param [percent] The percentage by which to darken the color. Must be between 1 and 100, inclusive.
  ///
  /// @return A new color that is a [percent] darker version of this color.
  Color darker([int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    final p = percent / 100;
    return Color.fromARGB(alpha, (red * (1 - p)).round(), (green * (1 - p)).round(), (blue * (1 - p)).round());
  }
}
