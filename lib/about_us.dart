import 'package:flutter/material.dart';
import 'package:wavefinder/components/bubbles.dart';

/// `AboutUsScreen` is a [StatelessWidget] that displays information about the company.
///
/// It uses a [Scaffold] to create the basic visual layout structure.
/// Inside the [Scaffold], it uses a [Padding] widget to create space around the text.
/// The text is a [Text] widget that displays 'Company Info Here'.
///
/// This widget takes an optional key parameter in its constructor.
class AboutUsScreen extends StatelessWidget {
  /// Creates an instance of `AboutUsScreen`.
  ///
  /// [Key] is an identifier for [AboutUsScreen]. It is optional and
  /// not required if only one instance of this widget is created.
  const AboutUsScreen({super.key});

  /// Builds the widget tree for `AboutUsScreen`.
  ///
  /// This method describes the part of the user interface represented by this widget.
  /// It uses a [BuildContext] to handle the location in the widget tree.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          PositionedBubble(),
          Padding(
            padding: const EdgeInsets.all(26.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60.0),
                const Text(
                  'About WaveFinder',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20.0),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Poppins',
                      fontSize: 18,
                    ),
                    children: <TextSpan>[
                      TextSpan(text: 'WaveFinder is your go-to app for real-time sea condition information.\n\n'
                          'We provide accurate and up-to-date data on wave height, water temperature, wind speed, and tide times, helping you catch the perfect wave every time.\n\n'
                          'To support our services and ensure continuous improvements, we charge a small fee of '),
                      TextSpan(text: '€1.99 per month', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' after a '),
                      TextSpan(text: 'free one-week trial', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '. This fee helps us cover the costs of maintaining the app and providing you with the best possible service.\n\n'),
                      TextSpan(text: 'Please note: We accept only Visa and MasterCard.', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 30.0),
                // WeatherAPI.com logo
               Center(
                  child: Image.network(
                    'https://cdn.weatherapi.com/v4/images/weatherapi_logo.png',
                    height: 40,
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
