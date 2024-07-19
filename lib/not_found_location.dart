import 'package:flutter/material.dart';

/// A widget that displays a message and an image indicating that no data is available.
///
/// This widget is typically used to inform the user that the requested
/// location data could not be found. It centers the message and image
/// vertically and horizontally within its container.
class NotFoundLocationMessage extends StatelessWidget {
  const NotFoundLocationMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text(
            'No data available at the moment.',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 30),
          Image.asset('assets/images/not_found.png'),
        ],
      ),
    );
  }
}
