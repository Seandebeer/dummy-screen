import 'package:flutter/material.dart';

/// Presets that were a flat colour wash. The same drawing is used on the
/// wallpaper and on the settings swatch.
const kDesignedWallpapers = {
  'default',
  'mono',
  'iphoneos',
  'linen',
  'wp',
  'bb',
  'material',
  'holo',
};

class WallpaperMotif extends StatelessWidget {
  const WallpaperMotif({super.key, required this.presetId});

  final String presetId;

  @override
  Widget build(BuildContext context) {
    if (!kDesignedWallpapers.contains(presetId)) {
      return const SizedBox.expand();
    }
    return IgnorePointer(
      child: CustomPaint(
        painter: WallpaperMotifPainter(presetId),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class WallpaperMotifPainter extends CustomPainter {
  const WallpaperMotifPainter(this.presetId);

  final String presetId;

  @override
  void paint(Canvas canvas, Size size) {
    switch (presetId) {
      case 'mono':
        _mono(canvas, size);
      case 'wp':
        _metro(canvas, size);
      case 'iphoneos':
        _gloss(canvas, size);
      case 'linen':
        _weave(canvas, size);
      case 'bb':
        _pearl(canvas, size);
      case 'material':
        _sheets(canvas, size);
      case 'holo':
        _circuit(canvas, size);
      default:
        _aurora(canvas, size);
    }
  }

  void _aurora(Canvas canvas, Size size) {
    _orb(canvas, size, 0.2, 0.18, 0.55, const Color(0x665B7CFA));
    _orb(canvas, size, 0.78, 0.32, 0.42, const Color(0x55C45CFF));
    _orb(canvas, size, 0.55, 0.78, 0.5, const Color(0x332EE6A6));
    final band = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x00FFFFFF), Color(0x33FFFFFF), Color(0x00FFFFFF)],
      ).createShader(Rect.fromLTWH(0, size.height * 0.42, size.width, size.height * 0.08));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.42, size.width, size.height * 0.08),
      band,
    );
  }

  void _mono(Canvas canvas, Size size) {
    final window = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.12, size.height * 0.08, size.width * 0.46, size.height * 0.28),
      Radius.circular(size.shortestSide * 0.04),
    );
    canvas.drawRRect(
      window,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x66FFFFFF), Color(0x11FFFFFF)],
        ).createShader(window.outerRect),
    );
    _orb(canvas, size, 0.78, 0.72, 0.38, const Color(0x33F2C14E));
    final grain = Paint()..color = const Color(0x14FFFFFF);
    for (var y = 0.0; y < size.height; y += 7) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grain);
    }
  }

  void _metro(Canvas canvas, Size size) {
    const colors = [
      Color(0xFF00A4EF),
      Color(0xFF7FBA00),
      Color(0xFFF25022),
      Color(0xFFFFB900),
      Color(0xFF8E44AD),
      Color(0xFF00B294),
    ];
    final gap = size.shortestSide * 0.03;
    final tileW = (size.width - gap * 4) / 3;
    final tileH = size.height * 0.16;
    var n = 0;
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 3; col++) {
        if ((row + col) % 4 == 0) continue;
        final wide = n % 5 == 0;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            gap + col * (tileW + gap),
            size.height * 0.08 + row * (tileH + gap),
            wide ? tileW * 1.4 : tileW,
            tileH,
          ),
          Radius.circular(gap * 0.4),
        );
        canvas.drawRRect(rect, Paint()..color = colors[n % colors.length].withValues(alpha: 0.9));
        canvas.drawRRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0x55FFFFFF),
        );
        n++;
      }
    }
  }

  void _gloss(Canvas canvas, Size size) {
    _orb(canvas, size, 0.5, 0.34, 0.72, const Color(0x33FFFFFF));
    final sheen = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.45), sheen);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.015
      ..color = const Color(0x44FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.38), size.shortestSide * 0.28, ring);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.38), size.shortestSide * 0.18, ring);
  }

  void _weave(Canvas canvas, Size size) {
    final warp = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1;
    final weft = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), warp);
    }
    for (var y = 0.0; y < size.height; y += 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), weft);
    }
    _orb(canvas, size, 0.3, 0.25, 0.3, const Color(0x22C4A574));
  }

  void _pearl(Canvas canvas, Size size) {
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.04
      ..color = const Color(0x55E8F1FF);
    for (var i = 0; i < 5; i++) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width * 0.15, size.height * (0.2 + i * 0.16)),
          radius: size.width * 0.7,
        ),
        -0.6,
        1.4,
        false,
        arc,
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.22),
      size.shortestSide * 0.045,
      Paint()..color = const Color(0xFFE23B3B),
    );
  }

  void _sheets(Canvas canvas, Size size) {
    const tones = [Color(0x33FFFFFF), Color(0x2200BFA5), Color(0x33FFB300)];
    for (var i = 0; i < 3; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * (0.08 + i * 0.06),
          size.height * (0.12 + i * 0.16),
          size.width * 0.72,
          size.height * 0.22,
        ),
        Radius.circular(size.shortestSide * 0.03),
      );
      canvas.drawRRect(rect, Paint()..color = const Color(0x33000000));
      canvas.drawRRect(rect.shift(const Offset(-2, -3)), Paint()..color = tones[i]);
    }
  }

  void _circuit(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x6633E1FF)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.28, size.height * 0.3)
      ..lineTo(size.width * 0.36, size.height * 0.48)
      ..lineTo(size.width * 0.7, size.height * 0.48)
      ..lineTo(size.width * 0.78, size.height * 0.22)
      ..lineTo(size.width, size.height * 0.22);
    canvas.drawPath(path, line);
    final path2 = Path()
      ..moveTo(0, size.height * 0.72)
      ..lineTo(size.width * 0.4, size.height * 0.72)
      ..lineTo(size.width * 0.52, size.height * 0.58)
      ..lineTo(size.width, size.height * 0.58);
    canvas.drawPath(path2, line);
    for (final spot in [
      Offset(size.width * 0.28, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.48),
      Offset(size.width * 0.4, size.height * 0.72),
    ]) {
      canvas.drawCircle(spot, size.shortestSide * 0.02, Paint()..color = const Color(0xFF7AF0FF));
    }
  }

  void _orb(Canvas canvas, Size size, double x, double y, double radius, Color color) {
    final center = Offset(size.width * x, size.height * y);
    final r = size.shortestSide * radius;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
  }

  @override
  bool shouldRepaint(covariant WallpaperMotifPainter oldDelegate) =>
      oldDelegate.presetId != presetId;
}
