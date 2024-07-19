import 'package:flutter/material.dart';

/// A custom flat button widget.
///
/// This is a [FlatButton] widget that takes a [VoidCallback] and a [String]
/// as parameters. The [VoidCallback] is the function that will be executed
/// when the button is pressed. The [String] is the text that will be displayed
/// on the button.
class FlatButton extends StatefulWidget {
  /// The callback that is called when the button is tapped or otherwise activated.
  final VoidCallback onPressed;

  /// The text that is displayed on the button.
  final String buttonText;

  /// Creates a FlatButton.
  ///
  /// The [onPressed] and [buttonText] arguments must not be null.
  const FlatButton({super.key, required this.onPressed, required this.buttonText});

  @override
  FlatButtonState createState() => FlatButtonState();
}

/// The [State] for a [FlatButton].
///
/// When Flutter builds a [FlatButton], it creates a separate [State] object.
/// Then it calls [build] in which you can access [onPressed] and [buttonText] 
/// via the [widget] property.
class FlatButtonState extends State<FlatButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
  return Container(
      color: Colors.transparent,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        /// The [GestureDetector] widget is used to detect gestures.
        ///
        /// It is a non-visual widget that provides gesture recognition. In this case, it is used to detect
        /// a tap gesture, which triggers the [onPressed] callback of the [FlatButton].
        ///
        /// The [GestureDetector] also changes the style of the text when the mouse hovers over it. This is
        /// achieved by changing the font weight of the text between normal and bold, depending on whether
        /// the mouse is hovering over the text or not.
        ///
        /// This implementation resolves the issue of the background getting darker on hover by using a
        /// [MouseRegion] widget. The [MouseRegion] widget calls [setState] to update the [_hovering]
        /// state when the mouse enters or exits its region. This state is then used to update the font
        /// weight of the text, giving a visual indication of the hover state without darkening the
        /// background.
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              widget.buttonText,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: _hovering ? FontWeight.bold : FontWeight.w300,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
