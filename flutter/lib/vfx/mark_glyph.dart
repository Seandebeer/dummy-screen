import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'catalog.dart';

class MarkGlyph extends StatelessWidget {
  const MarkGlyph({
    super.key,
    required this.kind,
    required this.color,
    this.scale = 1,
    this.thickness = 1,
    this.rotation = 0,
    this.x = 50,
    this.y = 50,
  });

  final String kind;
  final Color color;
  final double scale;
  final double thickness;
  final int rotation;
  final double x;
  final double y;

  @override
  Widget build(BuildContext context) {
    final side = 48 * scale;
    var turns = rotation / 360;
    if (kind == 'brackets') {
      final dx = x <= 50 ? 1 : -1;
      final dy = y <= 50 ? 1 : -1;
      final base = dx > 0 ? (dy > 0 ? 0 : 270) : (dy > 0 ? 90 : 180);
      turns = (base + rotation) / 360;
    } else if (kind == 'diamond') {
      turns += 0.125;
    }
    return Transform.rotate(
      angle: turns * math.pi * 2,
      child: CustomPaint(
        size: Size.square(side),
        painter: _GlyphPainter(kind, color, thickness, scale),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.kind, this.color, this.thickness, this.scale);

  final String kind;
  final Color color;
  final double thickness;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, 10 * thickness)
      ..strokeJoin = StrokeJoin.miter;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final c = Offset(size.width / 2, size.height / 2);
    final arm = size.width;
    switch (kind) {
      case 'circles':
      case 'dotcircle':
        canvas.drawCircle(c, size.width * 0.38, paint);
        canvas.drawCircle(
          c,
          kind == 'dotcircle' ? size.width * 0.12 : math.max(1, 5 * scale),
          fill,
        );
      case 'squares':
      case 'diamond':
        final inset = size.width * 0.12;
        canvas.drawRect(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - inset * 2,
            size.height - inset * 2,
          ),
          paint,
        );
      case 'triangle':
        final path = Path()
          ..moveTo(c.dx, size.height * 0.08)
          ..lineTo(size.width * 0.92, size.height * 0.9)
          ..lineTo(size.width * 0.08, size.height * 0.9)
          ..close();
        canvas.drawPath(path, paint);
      case 'brackets':
        final th = math.max(1.0, 10 * thickness);
        canvas.drawRect(Rect.fromLTWH(0, 0, arm * 0.7, th), fill);
        canvas.drawRect(Rect.fromLTWH(0, 0, th, arm * 0.7), fill);
      case 'cross':
      case 'plusgrid':
      case 'crosshair':
        final th = kind == 'cross'
            ? math.max(1.0, 10 * thickness)
            : size.width * (kind == 'crosshair' ? 0.12 : 0.2);
        canvas.drawRect(
          Rect.fromCenter(
            center: c,
            width: arm * (kind == 'cross' ? 1 : 0.86),
            height: th,
          ),
          fill,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: c,
            width: th,
            height: arm * (kind == 'cross' ? 1 : 0.86),
          ),
          fill,
        );
        if (kind == 'crosshair' || kind == 'plusgrid') {
          canvas.drawCircle(c, size.width * 0.38, paint);
        }
      default:
        if (kCompositeIds.contains(kind)) {
          _composite(canvas, size, paint, fill);
        } else {
          final th = math.max(1.0, 10 * thickness);
          canvas.drawRect(
            Rect.fromCenter(center: c, width: arm, height: th),
            fill,
          );
          canvas.drawRect(
            Rect.fromCenter(center: c, width: th, height: arm),
            fill,
          );
        }
    }
  }

  void _composite(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, size.width * 0.38, stroke);
    final tri = Path()
      ..moveTo(c.dx, size.height * 0.22)
      ..lineTo(size.width * 0.72, size.height * 0.74)
      ..lineTo(size.width * 0.28, size.height * 0.74)
      ..close();
    if (kind == 'solidtri' || kind == 'squaretri' || kind == 'invtri') {
      canvas.drawPath(tri, fill);
    } else if (kind == 'quads' || kind == 'squads') {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: size.width * 0.28),
        -math.pi / 2,
        math.pi / 2,
        true,
        fill,
      );
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: size.width * 0.28),
        math.pi / 2,
        math.pi / 2,
        true,
        fill,
      );
    } else {
      canvas.drawPath(tri, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.color != color ||
      oldDelegate.thickness != thickness ||
      oldDelegate.scale != scale;
}

class PatternFill extends StatelessWidget {
  const PatternFill({
    super.key,
    required this.type,
    required this.color,
    required this.scale,
    required this.thickness,
  });

  final String type;
  final Color color;
  final double scale;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PatternPainter(type, color, scale, thickness),
      child: const SizedBox.expand(),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter(this.type, this.color, this.scale, this.thickness);

  final String type;
  final Color color;
  final double scale;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    if (type == 'checkerboard') {
      final cell = math.max(2.0, 128 * scale);
      final black = Paint()..color = const Color(0xFF000000);
      final white = Paint()..color = const Color(0xFFFFFFFF);
      canvas.drawRect(Offset.zero & size, white);
      for (var y = 0.0; y < size.height; y += cell) {
        for (var x = 0.0; x < size.width; x += cell) {
          final alt = ((x / cell).floor() + (y / cell).floor()).isOdd;
          if (alt) {
            canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), black);
          }
        }
      }
      return;
    }
    final cell = math.max(4.0, 40 * scale);
    final radius = math.max(1.0, 3 * thickness);
    final paint = Paint()..color = color;
    for (var y = cell / 2; y < size.height; y += cell) {
      for (var x = cell / 2; x < size.width; x += cell) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.color != color ||
      oldDelegate.scale != scale ||
      oldDelegate.thickness != thickness;
}
