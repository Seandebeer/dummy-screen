import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';

/// The device clock, always drawn as digits.
class ClockReadout extends StatelessWidget {
  const ClockReadout({
    super.key,
    required this.os,
    required this.color,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w600,
    this.digitalKey,
  });

  final OsSettings os;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final Key? digitalKey;

  @override
  Widget build(BuildContext context) {
    if (!os.showClock) return const SizedBox.shrink();
    return Text(
      formatOsClock(osNow(os), hour24: os.clockFormat == '24'),
      key: digitalKey,
      style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
    );
  }
}
