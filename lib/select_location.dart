import 'package:flutter/material.dart';

/// A widget that prompts the user to select a location to view the forecast.
///
/// This widget is typically used when no location has been selected yet,
/// guiding the user to choose a location in order to display relevant data.
/// It centers the message and image vertically and horizontally within its container.
class SelectLocationMessage extends StatelessWidget {
  const SelectLocationMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Select a location to view forecast.',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 30),
          Image.asset('assets/images/weather_search.png'),
        ],
      ),
    );
  }
}
