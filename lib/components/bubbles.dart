import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '/theme/colors.dart';

/// A [PositionedBubble] is a widget that displays two colored circles at a specific position.
///
/// {@tool snippet}
///
/// Here is an example of how to create a [PositionedBubble]:
///
/// ```dart
/// PositionedBubble()
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Positioned], which is the widget that positions the bubble on the screen.
///  * [Container], which is the widget that gives the bubble its shape and color.
class PositionedBubble extends StatelessWidget {
  /// The color of the bubbles.
  final Color color = ThemeColors.bubblesColor;
  final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;

  /// Creates a [PositionedBubble] with the given color.
  PositionedBubble({super.key});

  /// Creates a [Positioned] widget that represents a bubble.
  ///
  /// The bubble is a [Container] with a circular shape and a specific color,
  /// positioned at a specific location on the screen.
  ///
  /// The `top` and `left` parameters represent the position of the bubble
  /// relative to the top left corner of the screen. They can be negative,
  /// which means the bubble is partially off the screen.
  ///
  /// The `width` and `height` parameters represent the size of the bubble.
  ///
  /// This method is used in the [build] method to create the bubbles.
  Widget _buildBubble(double top, double left, double width, double height) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: ThemeColors.bubblesColor,
        ),
      ),
    );
  }

  /// Calculates the height of the bubbles based on the current context.
  ///
  /// The height calculation takes into account the screen height and any adjustments
  /// needed for macOS.
  ///
  /// [context]: The build context used to obtain the screen height.
  ///
  /// Returns the calculated height of the bubbles.
  double calculateBubbleHeight(BuildContext context) {
  final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
  final screenHeight = MediaQuery.of(context).size.height;

  // Initial height calculation (33% of screen height)
  double bubbleHeight = 0.33 * screenHeight;

  // Adjusting for macOS scale factor
  if (isMacOS) {
    bubbleHeight *= 1.2;
  }

  // Further adjustments if needed based on positioning

  return bubbleHeight;
}

  ///  This widget is built using the [BuildContext] to obtain the screen size
  /// of the device. The screen width and height are then used to calculate
  /// the size and position of the bubbles.
  ///
  /// The size of the bubbles is set to be a certain percentage of the screen width
  /// and height, ensuring that the bubbles scale appropriately for different
  /// screen sizes. This is achieved by multiplying the screen width and height
  /// by a chosen factor.
  ///
  /// The position of the bubbles is also calculated as a percentage of the screen
  /// width and height. This ensures that the bubbles are positioned consistently
  /// across different screen sizes. The negative values are used to position
  /// the bubbles partially off the screen, creating a visually appealing effect.
  ///
  /// The goal of these computations is to create a responsive design that
  /// looks good on a variety of different screen sizes and orientations.
  /// @return Returns a positioned container with two circular shapes and the specified color.
  @override
  Widget build(BuildContext context) {
    final scaleFactor = isMacOS ? 0.2 : 1.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bubbleWidth = 0.8 * screenWidth;
    double bubbleHeight = 0.33 * screenHeight;

    if (isMacOS) {
      bubbleHeight *= 1.2;
    }

   return Stack(
      children: [
        _buildBubble(
          -0.2 * screenHeight,
          (isMacOS ? -1.32 : -0.06) * screenWidth * scaleFactor,
          bubbleWidth,
          bubbleHeight
        ),
        _buildBubble(
          (isMacOS ? -0.08 * screenHeight + 23 : -0.08 * screenHeight),
          (isMacOS ? -2 : -0.40) * screenWidth * scaleFactor,
          bubbleWidth,
          bubbleHeight
        ),
      ],
    );
  }
}
