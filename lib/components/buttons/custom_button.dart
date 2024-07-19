import 'package:flutter/material.dart';

/// A `CustomButton` is a stateless widget that displays a button with a custom icon and text.
///
/// This button is styled with a specific font size and color. When pressed, it calls the provided `onPressed` callback.
///
/// The `CustomButton` takes an `IconData` for the icon, a `String` for the text, a `double` for the font size, 
/// and a `VoidCallback` in its constructor which are all required and are used to customize the button.
///
/// Usage:
/// ```dart
/// CustomButton(
///   icon: Icons.save,
///   text: 'Save',
///   fontSize: 20.0,
///   onPressed: () {
///     // Handle button press
///   },
/// )
/// ```
class CustomButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final double fontSize;
  final VoidCallback onPressed;

  const CustomButton({super.key, 
    required this.icon,
    required this.text,
    required this.fontSize,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        children: <Widget>[
          Icon(icon, size: fontSize, color: Colors.black),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: Colors.black,
              fontSize: fontSize
            ),
          ),
        ],
      ),
    );
  }
}
