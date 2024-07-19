import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '/theme/colors.dart';

/// A stateless widget that represents a sign in screens button.
///
/// This button is created with a name and a function to be executed when pressed.
/// The properties of this button are set at the time of creation and cannot be changed afterwards.
/// This design allows for better performance and predictability.
///
/// The `SignInSignUpButton` is a StatelessWidget, which means it describes part of the user interface which can depend on configuration information in the constructor and ambient state from widgets higher in the tree.
///
/// {@tool snippet}
///
/// Here's an example of how to use this button:
///
/// ```dart
/// SignInSignUpButton(
///   key: Key('signInButton'),
///   onPressed: () {
///     // Define what happens when the button is pressed
///   },
///   child: Text('Sign In'),
/// )
/// ```
/// {@end-tool}
///
/// @param          onPressed The function that will be executed when the button is pressed. This function is set at the time of creation and cannot be changed afterwards.
/// @param [Key]    key       that will be used to reference this widget in tests. This key is set at the time of creation and cannot be changed afterwards.
/// @param [Widget] child     that will be displayed inside the button. This widget is set at the time of creation and cannot be changed afterwards.
class SignInSignUpButton extends StatelessWidget {
  final Function onPressed;
  final String buttonText;
  final Color? buttonColor;
  final IconData? icon;

  /// Creates a const instance of [SignInSignUpButton].
 const SignInSignUpButton({
    super.key,
    this.buttonColor = ThemeColors.themeBlue,
    required this.onPressed,
    required this.buttonText,
    this.icon,
  });


  @override
  Widget build(BuildContext context) {
    double buttonWidth = MediaQuery.of(context).size.width;

    // If the platform is macOS, set the button width to a specific value.
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      buttonWidth = 500;
    }

    return SizedBox(
      // This will make the button take up all available horizontal space.
      width: buttonWidth,
      child: Padding(
        // This adds 16 pixels of space on the left and right of the button.
        padding: const EdgeInsets.symmetric(horizontal: 75.0),
        child: ElevatedButton(
          onPressed: onPressed as void Function()?,
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(buttonColor),
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.pressed)) {
                  // This makes the button color a bit darker when it's pressed.
                  return buttonColor?.darker();
                }
                // Use the default overlay color (theme color) in other states.
                return null;
              },
            ),
            padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 9.0))
          ),
          child: Text(
              buttonText,
            style: const TextStyle(
              fontSize: 30.0,
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w900,
            ),
          ),
        )
      )
    );
  }
}
