import 'package:flutter/material.dart';
import '/constants/platform.dart';
import '/theme/colors.dart';

/// A custom `InputField` widget that creates a text field with padding.
///
/// This widget extends [StatefulWidget] and provides a customizable text field.
/// The text field is wrapped in a [Padding] widget to provide symmetric horizontal and vertical padding.
///
/// The color of the text field and the hint text can be customized.
/// By default, the color of the text field is set to `ThemeColors.themeBlue`.
///
/// The [hintText] parameter must not be null and is required to create an instance of this widget.
///
/// Usage:
/// ```dart
/// InputField(
///   hintText: 'Enter your text here',
///   fieldColor: Colors.red,
/// )
/// ```
class InputField extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final Color? fieldColor;
  final bool isPassword;
  final Future<void> Function(String)? onChanged;


 const InputField({
    super.key,
    this.fieldColor = ThemeColors.bubblesColor,
    required this.hintText,
    this.controller,
    this.validator,
    this.isPassword = false,
    this.onChanged,
  });


 Future<void> defaultOnChanged(String value) async {
    if (validator != null) {
      validator!(value);
    }
  }

  @override
  InputFieldState createState() => InputFieldState();
}

class InputFieldState extends State<InputField> {
    bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    ///  The LayoutBuilder provides the constraints of the parent widget. If the maximum width (maxWidth) is greater
    /// than 800 pixels (which might be the case on a large screen like a Mac), t
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = MediaQuery.of(context).size.width;
        final double inputWidth = isMobile ? maxWidth : (maxWidth > 1000) ? 600 : maxWidth * 0.6;

        return Center(
          child: SizedBox(
            width: inputWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 9),
              child: TextFormField(
                controller: widget.controller,
                obscureText: widget.isPassword ? _obscureText : false,
                validator: widget.validator,
                onChanged: widget.onChanged ?? widget.defaultOnChanged,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: widget.fieldColor,
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w300,
                    color: Colors.black
                  ),
                   suffixIcon: widget.isPassword ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: const Color.fromARGB(146, 11, 11, 11),
                    ),
                    onPressed: _togglePasswordVisibility,
                  ) : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
