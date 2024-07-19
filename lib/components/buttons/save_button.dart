import 'package:flutter/material.dart';
import 'package:wavefinder/components/dialogs/dialog.dart';
import 'package:wavefinder/theme/colors.dart';

/// A `SaveButton` is a stateless widget that displays a button with a save icon.
///
/// This button is styled with a specific background color, elevation, and shape.
/// When pressed, it calls the provided `onPressed` callback.
///
/// The `SaveButton` takes a `VoidCallback` in its constructor which is required
/// and is called when the button is pressed.
///
/// Usage:
/// ```dart
/// SaveButton(
///   onPressed: () {
///     // Handle button press
///   },
/// )
/// ```
class SaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String buttonName;

  const SaveButton({super.key, required this.onPressed, this.buttonName = 'Save'});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(
        Icons.save,
        color: Colors.black
      ),
      label: Text(
        buttonName,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 17,
          color: Colors.black
        ),
      ),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(ThemeColors.themeBlue),
        elevation: MaterialStateProperty.all<double>(4),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: const BorderSide(color: Color.fromARGB(75, 6, 110, 195)),
          ),
        ),
      ),
    );
  }
}

  /// Asynchronously shows a dialog with a custom message.
  ///
  /// This function displays a dialog with a custom message to the user.
  /// The dialog is built using the `DialogPop` widget.
  ///
  /// The function is asynchronous and returns a `Future<void>`. It uses
  /// the `showDialog` function from the Flutter framework, which also
  /// returns a `Future`. This means that the function will not complete
  /// until the dialog is dismissed.
  ///
  /// Parameters:
  ///   `BuildContext context`: The build context in which to show the dialog.
  ///   `String message`: The custom message to display in the dialog.
  ///
  /// Usage:
  /// ```dart
  /// await showSaveDialog(context, 'Your custom message');
  /// ```
  Future<void> showSaveDialog(BuildContext context ,String message) async {
   await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DialogPop(
          errorMessage: message,
          title: '',
        );
      },
    );
  }
