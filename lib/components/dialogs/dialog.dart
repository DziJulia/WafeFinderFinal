import 'package:flutter/material.dart';

/// A [Dialog] widget that displays an error message.
///
/// This widget builds an [AlertDialog] with a single "OK" button to dismiss it.
/// The error message to be displayed is passed to this widget through the
/// `errorMessage` parameter.
///
/// {@tool snippet}
///
/// Here is an example of how to use this widget:
///
/// ```dart
/// showDialog(
///   context: context,
///   builder: (BuildContext context) {
///     return Dialog(errorMessage: 'An error occurred.');
///   },
/// );
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [AlertDialog], which this widget displays.
class DialogPop extends StatelessWidget {
  final String errorMessage;
  final String title;

  /// Creates a [Dialog] widget.
  ///
  /// The [errorMessage] argument must not be null.
  const DialogPop({super.key, required this.errorMessage, required this.title});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(218, 138, 197, 253),
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
            'OK',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              color: Colors.black
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}