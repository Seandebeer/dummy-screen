import 'dart:math' as math;
import 'dart:ui';

/// Composite tracking marks from `CompositeMarks.jsx`.
///
/// The drawing uses a 100×100 view box, then scales to [size]. Holes are
/// punched out so a black mark never shows a contrasting patch.
void paintCompositeMark(
  Canvas canvas,
  Size size, {
  required String kind,
  required Color color,
  required double thickness,
}) {
  if (size.width <= 0 || size.height <= 0) return;
  final unit = size.width / 100;
  canvas.save();
  canvas.scale(unit);
  final strokeWidth = math.max(2.0, 20 * thickness);
  final stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeJoin = StrokeJoin.miter
    ..isAntiAlias = false;
  final rounded = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = false;
  final fill = Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..isAntiAlias = false;

  void masked(void Function() draw, void Function(Paint punch) holes) {
    canvas.saveLayer(const Rect.fromLTWH(-40, -40, 180, 180), Paint());
    draw();
    final punch = Paint()
      ..blendMode = BlendMode.dstOut
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFFFFF)
      ..isAntiAlias = false;
    holes(punch);
    canvas.restore();
  }

  switch (kind) {
    case 'circtriplus':
      canvas.drawCircle(const Offset(50, 50), 38, stroke);
      canvas.drawPath(_tri(50, 53, 19, 25, 1), rounded);
      _plus(canvas, 50, 53, 11, 3.5, fill);
      for (final corner in _corners) {
        _plus(canvas, corner.$1, corner.$2, 11, 3.5, fill);
      }
    case 'solidtri':
      masked(() {
        canvas.drawCircle(const Offset(50, 50), 38, stroke);
        canvas.drawPath(_tri(50, 54, 21, 30, 1), fill);
        canvas.drawCircle(const Offset(7, 7), 5, fill);
        canvas.drawPath(_tri(93, 7, 4.5, 8, 1), fill);
        canvas.drawPath(_tri(7, 93, 4.5, 8, -1), fill);
        canvas.drawCircle(const Offset(93, 93), 5, fill);
      }, (punch) {
        canvas.drawCircle(const Offset(50, 52), 5, punch);
      });
    case 'squaretri':
      masked(() {
        canvas.drawRect(const Rect.fromLTWH(7, 7, 86, 86), stroke);
        canvas.drawPath(_tri(50, 52, 22, 30, 1), fill);
      }, (punch) {
        canvas.drawPath(_tri(50, 56, 11, 15, -1), punch);
        for (final corner in const [(12.0, 12.0), (88.0, 12.0), (12.0, 88.0), (88.0, 88.0)]) {
          canvas.drawRect(
            Rect.fromCenter(center: Offset(corner.$1, corner.$2), width: 9, height: 9),
            punch,
          );
        }
      });
    case 'invtri':
      masked(() {
        canvas.drawCircle(const Offset(50, 50), 38, stroke);
        canvas.drawPath(_tri(50, 50, 24, 34, -1), fill);
        for (final corner in _corners) {
          _plus(canvas, corner.$1, corner.$2, 11, 3.5, fill);
        }
      }, (punch) {
        canvas.drawPath(_tri(50, 52, 12, 17, 1), punch);
      });
    case 'plusgrid':
      _plus(canvas, 50, 50, 66, 20, fill);
      for (final tip in _tips) {
        _plus(canvas, tip.$1, tip.$2, 11, 3.5, fill);
      }
    case 'dotcircle':
      canvas.drawCircle(const Offset(50, 50), 38, stroke);
      canvas.drawCircle(const Offset(50, 50), 10, fill);
    case 'quads':
      canvas.drawCircle(const Offset(50, 50), 38, stroke);
      canvas.drawPath(_pie(38, -math.pi / 2, math.pi / 2), fill);
      canvas.drawPath(_pie(38, math.pi / 2, math.pi / 2), fill);
    case 'squads':
      masked(() {
        canvas.drawRect(const Rect.fromLTWH(8, 8, 84, 84), stroke);
        canvas.drawCircle(const Offset(50, 50), 27, stroke);
        canvas.drawPath(_pie(27, -math.pi / 2, math.pi / 2), fill);
        canvas.drawPath(_pie(27, math.pi / 2, math.pi / 2), fill);
      }, (punch) {
        for (final corner in const [(13.0, 13.0), (87.0, 13.0), (13.0, 87.0), (87.0, 87.0)]) {
          canvas.drawRect(
            Rect.fromCenter(center: Offset(corner.$1, corner.$2), width: 9, height: 9),
            punch,
          );
        }
      });
    case 'crosshair':
      canvas.drawCircle(const Offset(50, 50), 38, stroke);
      canvas.drawRect(const Rect.fromLTWH(12, 44, 76, 12), fill);
      canvas.drawRect(const Rect.fromLTWH(44, 12, 12, 76), fill);
    default:
      break;
  }
  canvas.restore();
}

const _corners = <(double, double)>[
  (8, 8),
  (92, 8),
  (8, 92),
  (92, 92),
];

const _tips = <(double, double)>[
  (50, 6),
  (50, 94),
  (6, 50),
  (94, 50),
];

Path _tri(double cx, double cy, double hw, double h, int dir) {
  return Path()
    ..moveTo(cx, cy - (dir * 2 * h) / 3)
    ..lineTo(cx + hw, cy + (dir * h) / 3)
    ..lineTo(cx - hw, cy + (dir * h) / 3)
    ..close();
}

void _plus(Canvas canvas, double x, double y, double length, double width, Paint paint) {
  canvas.drawRect(Rect.fromLTWH(x - length / 2, y - width / 2, length, width), paint);
  canvas.drawRect(Rect.fromLTWH(x - width / 2, y - length / 2, width, length), paint);
}

/// Pie slice of a circle centred on (50, 50), matching the SVG arc flags.
Path _pie(double radius, double start, double sweep) {
  return Path()
    ..moveTo(50, 50)
    ..arcTo(
      Rect.fromCircle(center: const Offset(50, 50), radius: radius),
      start,
      sweep,
      false,
    )
    ..close();
}
