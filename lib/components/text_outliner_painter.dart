import 'package:flutter/material.dart';


/// A custom painter that draws a text with an outline.
///
/// The [text], [fontSize], [textColor], [outlineColor], and [outlineWidth] must not be null.
class TextOutlinePainter extends CustomPainter {
/// The text to draw.
  final String text;

  /// The size of the text to draw.
  final double fontSize;

  /// The color of the text.
  final Color textColor;

  /// The color of the outline.
  final Color outlineColor;

  /// The thickness of the outline.
  final double outlineWidth;

  /// Creates a text outline painter.
  ///
  /// The [text], [fontSize], [textColor], [outlineColor], and [outlineWidth] must not be null.
  TextOutlinePainter({
    required this.text,
    required this.fontSize,
    required this.textColor,
    required this.outlineColor,
    required this.outlineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    TextSpan span = TextSpan(
      style: TextStyle(
        fontSize: fontSize,
        color: textColor,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w900,
      ),
      text: text,
    );

    TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    tp.layout();

    // Paint the outline first.
    tp.text = TextSpan(
      style: span.style!.copyWith(color: outlineColor),
      text: span.text,
    );
  
    tp.getOffsetForCaret(const TextPosition(offset: 0), Rect.zero);
    tp.computeLineMetrics();
    tp.paint(canvas, Offset.zero);


    tp.layout();

    for (double dx = -outlineWidth; dx <= outlineWidth; dx += outlineWidth) {
      for (double dy = -outlineWidth; dy <= outlineWidth; dy += outlineWidth) {
        tp.paint(canvas, Offset(dx, dy));
      }
    }

    tp.text = span;
    tp.layout();
    tp.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
