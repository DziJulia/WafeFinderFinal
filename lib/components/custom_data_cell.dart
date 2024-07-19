import 'package:flutter/material.dart';

/// A custom widget that displays a row with three pieces of data: wave height, 
/// wave direction, and wave period.
///
/// The [CustomDataRow] widget formats and displays its parameters in a
/// horizontal layout with spacing and a rotated icon.
///
/// Example usage:
/// ```dart
/// CustomDataRow(
///   param1: '3.5',
///   param2: '45',
///   param3: '10.2',
/// )
/// ```
///
/// This will display a row with the wave height as '3.50 ft', an upward arrow
/// icon rotated by 45 degrees, and the wave period as '10.20s'.
class CustomDataRow extends StatelessWidget {
  /// The wave height parameter.
  final String param1;

  /// The wave direction parameter, in degrees.
  final String param2;

  /// The wave period parameter, in seconds.
  final String param3;

  /// Creates a [CustomDataRow] widget.
  ///
  /// The [param1], [param2], and [param3] parameters are required and must
  /// be non-null.
  const CustomDataRow({
    super.key,
    required this.param1,
    required this.param2,
    required this.param3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('${double.parse(param1).toStringAsFixed(2)} ft'),
        const SizedBox(width: 20),
        Transform.rotate(
          angle: double.parse(param2) * (3.1415926535897932 / 180),
          child: const Icon(Icons.arrow_upward),
        ),
        const SizedBox(width: 20),
        Text('${double.parse(param3).toStringAsFixed(2)}s')
      ],
    );
  }
}
