import 'package:flutter/material.dart';
import 'package:wavefinder/components/text_outliner_painter.dart';
import 'package:wavefinder/theme/colors.dart';

/// A widget that displays a profile header with a back button and a title.
///
/// The [headerText] argument must not be null.
class SettingHeader extends StatelessWidget {
  /// The text to display as the title of the profile header.
  final String headerText;

  /// Creates a profile header.
  ///
  /// The [headerText] argument must not be null.
  const SettingHeader({super.key, required this.headerText});

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).size.height * 0.24;
    final double fontSize = MediaQuery.of(context).size.width * 0.07;

    return Positioned(
      top: topPadding,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center, // This aligns the children vertically
        children: <Widget>[
          const Spacer(flex: 1),
          IconButton(
            padding:const EdgeInsets.only(bottom: 29, right: 50),
            icon: CustomPaint(
              painter: TextOutlinePainter(
                text: '<',
                fontSize: fontSize,
                textColor: ThemeColors.themeBlue,
                outlineColor: const Color.fromARGB(255, 1, 52, 93),
                outlineWidth: 0.3,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const Spacer(flex: 1),
          Text(
            headerText,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
