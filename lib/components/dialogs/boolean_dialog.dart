import 'package:flutter/material.dart';

/// A `BooleanDialogPop` is a stateless widget that displays a dialog with a custom title and error message.
///
/// This dialog is styled with a specific background color, font family, and font size. It contains two buttons: 'No' and 'Yes'.
/// When the 'No' button is pressed, it pops the dialog and returns false.
/// When the 'Yes' button is pressed, it pops the dialog and returns true.
///
/// The `BooleanDialogPop` takes a `String` for the error message and a `String` for the title in its constructor which are both required.
///
/// Usage:
/// ```dart
/// BooleanDialogPop(
///   errorMessage: 'This is an error message.',
///   title: 'This is a title',
/// )
/// ```
class BooleanDialogPop extends StatelessWidget {
  final String errorMessage;
  final String title;

  /// Creates a [Dialog] widget.
  ///
  /// The [errorMessage] argument must not be null.
  const BooleanDialogPop({super.key, required this.errorMessage, required this.title});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(198, 138, 197, 253),
      contentTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        color: Colors.black,
      ),
      title: Text(title),
      content: Container(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          errorMessage,
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: const Text(
            'No',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              color: Colors.black
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: const Text(
            'Yes',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              color: Colors.black
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}
