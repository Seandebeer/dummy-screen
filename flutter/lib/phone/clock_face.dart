import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';

/// Digital text, or a face when this is the on-screen clock.
/// A header clock stays digital even when the screen clock is analog.
class ClockReadout extends StatelessWidget {
  const ClockReadout({
    super.key,
    required this.os,
    required this.color,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w600,
    this.faceSize,
    this.digitalKey,
    this.header = false,
  });

  final OsSettings os;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final double? faceSize;
  final Key? digitalKey;

  /// Status bars, menu bars, and other chrome. Always digital.
  final bool header;

  @override
  Widget build(BuildContext context) {
    if (!os.showClock) return const SizedBox.shrink();
    final time = osNow(os);
    if (!header && os.clockStyle == 'analog') {
      return ClockFace(time: time, color: color, size: faceSize ?? fontSize + 6);
    }
    return Text(
      formatClock(time),
      key: digitalKey,
      style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
    );
  }
}

class ClockFace extends StatelessWidget {
  const ClockFace({
    super.key,
    required this.time,
    required this.color,
    this.size = 18,
  });

  final DateTime time;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FacePainter(time: time, color: color),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  const _FacePainter({required this.time, required this.color});

  final DateTime time;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, size.width * 0.06);
    canvas.drawCircle(center, radius - ring.strokeWidth, ring);
    final dot = Paint()..color = color;
    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2 - math.pi / 2;
      final at = center + Offset(
        (radius - ring.strokeWidth * 2.2) * math.cos(angle),
        (radius - ring.strokeWidth * 2.2) * math.sin(angle),
      );
      canvas.drawCircle(at, i % 3 == 0 ? radius * 0.06 : radius * 0.035, dot);
    }
    void hand(double turns, double length, double width) {
      final angle = turns * math.pi * 2 - math.pi / 2;
      final paint = Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center,
        center + Offset(radius * length * math.cos(angle), radius * length * math.sin(angle)),
        paint,
      );
    }

    final hour = (time.hour % 12) + time.minute / 60;
    hand(hour / 12, 0.48, math.max(1.4, size.width * 0.08));
    hand(time.minute / 60, 0.72, math.max(1, size.width * 0.05));
    if (size.width >= 48) {
      hand(time.second / 60, 0.78, math.max(1, size.width * 0.025));
    }
    canvas.drawCircle(center, math.max(1.2, radius * 0.06), dot);
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.color != color;
}
