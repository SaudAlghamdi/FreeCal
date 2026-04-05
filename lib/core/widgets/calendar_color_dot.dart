import 'package:flutter/material.dart';

/// A small colored circle representing a calendar.
class CalendarColorDot extends StatelessWidget {
  final int colorValue;
  final double size;

  const CalendarColorDot({
    super.key,
    required this.colorValue,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(colorValue),
        shape: BoxShape.circle,
      ),
    );
  }
}
