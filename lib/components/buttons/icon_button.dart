import 'package:flutter/material.dart';

/// A stateless widget representing a customizable button.
///
/// This widget can be customized with different icons and colors for different third-party services.
class IconButton extends StatelessWidget {
  /// The icon for the button.
  final IconData icon;

  /// The color of the button.
  final Color color;

  /// The function to be executed when the button is pressed.
  final VoidCallback onPressed;

  /// Creates a IconButton widget.
  ///
  /// The [icon], [color], and [onPressed] arguments are required and must not be null.
  const IconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  /// Builds the widget tree for the IconButton.
  ///
  /// The widget tree includes an ElevatedButton with a custom icon and color.
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: const Text(''),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
      ),
    );
  }
}
