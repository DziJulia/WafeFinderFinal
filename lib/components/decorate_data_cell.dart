import 'package:flutter/material.dart';

/// A custom widget that displays a container with a top and bottom margin
/// and a right border.
///
/// This widget can be used as a styled cell in a table or a list to
/// provide a consistent appearance with a grey right border.
///
/// Example usage:
/// ```dart
/// DataTable(
///   columns: const <DataColumn>[
///     DataColumn(label: Text('Name')),
///     DataColumn(label: Text('Age')),
///   ],
///   rows: <DataRow>[
///     DataRow(
///       cells: <DataCell>[
///         DataCell(Text('Alice')),
///         DataCell(DecoratedDataCell()),
///       ],
///     ),
///   ],
/// )
/// ```
class DecoratedDataCell extends StatelessWidget {
  /// Creates a [DecoratedDataCell] widget.
  ///
  /// The [key] parameter is optional and can be used to control the widget's
  /// unique identity.
  const DecoratedDataCell({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 9, bottom: 9),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
      ),
    );
  }
}
