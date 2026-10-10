import 'package:flutter/material.dart';

import '../format.dart';
import '../image_file.dart';
import '../models.dart';
import '../store.dart';
import 'console_apps.dart';

/// Xbox Series dashboard: green ribbon, a featured tile, and the home rows.
class XboxSeriesHome extends StatelessWidget {
  const XboxSeriesHome({
    super.key,
    required this.store,
    required this.device,
    required this.onOpen,
    required this.onShell,
  });

  final StageStore store;
  final PropDevice device;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onShell;

  static const _shells = [
    ('xbox', 'Xbox Series'),
    ('ps5', 'PlayStation 5'),
    ('ps2', 'PlayStation 2'),
    ('x360', 'Xbox 360'),
  ];

  @override
  Widget build(BuildContext context) {
    final now = osNow(device.os);
    final featured = device.os.steamTitle.trim().isEmpty ? 'Night Run' : device.os.steamTitle.trim();
    final cover = imageProviderForPath(device.os.steamCover);
    final tag = store.operatorName.trim().isEmpty ? 'Player' : store.operatorName.trim();
    final shown = device.os;
    return Stack(
      key: const Key('xbox-home'),
      fit: StackFit.expand,
      children: [
        ConsoleWallpaper(
          device: device,
          fallback: const CustomPaint(
            painter: _WavePainter(),
            child: SizedBox.expand(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final box = _fit(constraints.maxWidth, constraints.maxHeight);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    tag: tag,
                    time: formatOsClock(now, hour24: shown.clockFormat == '24'),
                    os: shown,
                  ),
                  SizedBox(height: box.gap),
                  SizedBox(
                    height: box.featured,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _Featured(
                          title: featured,
                          side: box.featured,
                          image: cover,
                          onTap: () => onOpen('steam'),
                        ),
                        SizedBox(width: box.tileGap + 4),
                        _SquareTile(
                          side: box.small,
                          scene: _Scene.harbor,
                          gamePass: true,
                          tileKey: const Key('xbox-tile-harbor'),
                          onTap: () => onOpen('Harbor'),
                        ),
                        _SquareTile(
                          side: box.small,
                          scene: _Scene.signal,
                          gap: box.tileGap,
                          onTap: () => onOpen('Signal'),
                        ),
                        _SquareTile(
                          side: box.small,
                          scene: _Scene.relay,
                          gamePass: true,
                          gap: box.tileGap,
                          onTap: () => onOpen('Relay'),
                        ),
                        _PassTile(side: box.small, gap: box.tileGap, onTap: () => onOpen('Game Pass')),
                        _SquareTile(
                          side: box.small,
                          scene: _Scene.drift,
                          gamePass: true,
                          gap: box.tileGap,
                          onTap: () => onOpen('Drift'),
                        ),
                        _StoreTile(
                          side: box.small,
                          gap: box.tileGap,
                          tileKey: const Key('xbox-appstore'),
                          onTap: () => onOpen('appstore'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: box.gap),
                  SizedBox(
                    height: box.promo,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _Promo(
                            title: 'My games & apps',
                            scene: _Scene.library,
                            onTap: () => onOpen('Library'),
                          ),
                        ),
                        SizedBox(width: box.tileGap),
                        Expanded(
                          flex: 3,
                          child: _Promo(
                            title: 'New message',
                            scene: _Scene.message,
                            onTap: () => onOpen('Messages'),
                          ),
                        ),
                        SizedBox(width: box.tileGap),
                        Expanded(
                          flex: 3,
                          child: _Promo(
                            title: 'Play Harbor now',
                            scene: _Scene.play,
                            onTap: () => onOpen('Harbor'),
                          ),
                        ),
                        SizedBox(width: box.tileGap),
                        Expanded(
                          flex: 4,
                          child: _Promo(
                            title: 'Night Operation',
                            caption: 'Sponsored',
                            scene: _Scene.ad,
                            onTap: () => onOpen('Night Operation'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: box.gap * 0.7),
                  Text(
                    'Game Pass',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: box.featured < 120 ? 13 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cap = box.small * 0.34;
                        final visible = constraints.maxHeight < cap ? constraints.maxHeight : cap;
                        if (visible < 8 || box.small < 8) return const SizedBox.shrink();
                        return Align(
                          alignment: Alignment.bottomLeft,
                          child: SizedBox(
                            height: visible,
                            child: ClipRect(
                              child: OverflowBox(
                                alignment: Alignment.topLeft,
                                minHeight: box.small,
                                maxHeight: box.small,
                                child: SizedBox(
                                  height: box.small,
                                  child: Row(
                                    children: [
                                      _SquareTile(side: box.small, scene: _Scene.night, onTap: () {}),
                                      _SquareTile(side: box.small, scene: _Scene.signal, gap: box.tileGap, onTap: () {}),
                                      _SquareTile(
                                        side: box.small,
                                        scene: _Scene.harbor,
                                        gap: box.tileGap,
                                        gamePass: true,
                                        onTap: () {},
                                      ),
                                      _PassTile(side: box.small, gap: box.tileGap, onTap: () {}),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Positioned(
          left: 18,
          right: 220,
          bottom: 58,
          child: ConsolePinStrip(os: device.os, onOpen: onOpen),
        ),
        Positioned(
          right: 16,
          bottom: 18,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
            children: [
              GestureDetector(
                key: const Key('xbox-settings'),
                onTap: () => onOpen('settings'),
                child: const _Pill(mark: _PillMark.guide, label: 'Settings'),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Customize',
                onSelected: onShell,
                color: const Color(0xFF1C1C1E),
                itemBuilder: (context) => [
                  for (final item in _shells)
                    PopupMenuItem(value: item.$1, child: Text(item.$2)),
                ],
                child: const _Pill(mark: _PillMark.guide, label: 'Customize'),
              ),
              const SizedBox(width: 8),
              const _Pill(mark: _PillMark.y, label: 'Search'),
            ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Box {
  const _Box({
    required this.featured,
    required this.small,
    required this.promo,
    required this.gap,
    required this.tileGap,
    required this.peek,
  });

  final double featured;
  final double small;
  final double promo;
  final double gap;
  final double tileGap;
  final double peek;
}

_Box _fit(double width, double height) {
  const ratio = 0.54;
  var gap = 12.0;
  var tileGap = 8.0;
  final chromeW = 16 + tileGap * 5;
  var featured = (width - chromeW) / (1 + 6 * ratio);
  var small = featured * ratio;
  var promo = small;
  const header = 32.0;
  const label = 24.0;
  var needed = header + gap * 2.7 + featured + promo + label;
  if (needed > height && needed > 0) {
    final scale = ((height - header - label) / (needed - header - label)).clamp(0.35, 1.0);
    featured *= scale;
    small *= scale;
    promo *= scale;
    gap *= scale;
    tileGap *= scale;
    needed = header + gap * 2.7 + featured + promo + label;
  }
  final peek = (height - needed).clamp(0.0, small * 0.34);
  return _Box(
    featured: featured,
    small: small,
    promo: promo,
    gap: gap,
    tileGap: tileGap,
    peek: peek,
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.tag, required this.time, required this.os});

  final String tag;
  final String time;
  final OsSettings os;

  @override
  Widget build(BuildContext context) {
    final initial = tag.isEmpty ? 'P' : tag.characters.first.toUpperCase();
    final level = os.battery.clamp(0, 100);
    final battery = level >= 90
        ? Icons.battery_full
        : level >= 60
        ? Icons.battery_5_bar
        : level >= 30
        ? Icons.battery_3_bar
        : Icons.battery_1_bar;
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          if (ConsoleLayout.shows(os, 'tag')) ...[
            CircleAvatar(
              radius: 13,
              backgroundColor: const Color(0xFFD05A28),
              child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text(tag, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
          const Spacer(),
          const Icon(Icons.notifications_off_outlined, color: Colors.white, size: 16),
          if (ConsoleLayout.shows(os, 'battery')) ...[
            const SizedBox(width: 12),
            Icon(battery, color: Colors.white, size: 18, key: const Key('xbox-battery')),
            const SizedBox(width: 4),
            Text('$level%', style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
          if (ConsoleLayout.shows(os, 'clock') && os.showClock) ...[
            const SizedBox(width: 8),
            Text(time, key: const Key('xbox-clock'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}

class _Featured extends StatelessWidget {
  const _Featured({
    required this.title,
    required this.side,
    required this.onTap,
    this.image,
  });

  final String title;
  final double side;
  final VoidCallback onTap;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final titleSize = (side * 0.07).clamp(11.0, 16.0);
    return SizedBox(
      key: const Key('xbox-featured'),
      width: side,
      height: side,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFC6F04A), width: side < 90 ? 2 : 3),
            boxShadow: const [
              BoxShadow(color: Color(0x5596D020), blurRadius: 8),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _SceneArt(scene: _Scene.night),
                  if (image != null) Image(image: image!, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.transparent, Color(0xE610120C)],
                        stops: [0.45, 0.62, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 8,
                    bottom: 8,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: titleSize, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareTile extends StatelessWidget {
  const _SquareTile({
    required this.side,
    required this.scene,
    required this.onTap,
    this.gamePass = false,
    this.gap = 0,
    this.tileKey,
  });

  final double side;
  final _Scene scene;
  final VoidCallback onTap;
  final bool gamePass;
  final double gap;
  final Key? tileKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: gap),
      child: SizedBox(
        key: tileKey,
        width: side,
        height: side,
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _SceneArt(scene: scene),
                if (gamePass) const Positioned(left: 6, bottom: 6, child: _PassBadge()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PassTile extends StatelessWidget {
  const _PassTile({required this.side, required this.onTap, this.gap = 0});

  final double side;
  final VoidCallback onTap;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final size = (side * 0.16).clamp(8.0, 18.0);
    return Padding(
      padding: EdgeInsets.only(left: gap),
      child: SizedBox(
        width: side,
        height: side,
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: ColoredBox(
              color: const Color(0xFF107C10),
              child: Center(
                child: Text(
                  'GAME\nPASS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({
    required this.side,
    required this.onTap,
    this.gap = 0,
    this.tileKey,
  });

  final double side;
  final VoidCallback onTap;
  final double gap;
  final Key? tileKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: gap),
      child: SizedBox(
        width: side,
        height: side,
        child: Tooltip(
          message: 'App Store',
          child: GestureDetector(
            key: tileKey,
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ColoredBox(
                color: const Color(0xFFF4F6F1),
                child: Center(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: const Color(0xFF1A1A1A),
                    size: side * 0.42,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Promo extends StatelessWidget {
  const _Promo({
    required this.title,
    required this.scene,
    required this.onTap,
    this.caption,
  });

  final String title;
  final _Scene scene;
  final VoidCallback onTap;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _SceneArt(scene: scene),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x99000000)],
                  stops: [0.4, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (caption != null)
              Positioned(
                right: 8,
                bottom: 6,
                child: Text(
                  caption!.toUpperCase(),
                  style: const TextStyle(color: Colors.white70, fontSize: 8, letterSpacing: 0.6, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PassBadge extends StatelessWidget {
  const _PassBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: const Text(
        'GAME\nPASS',
        style: TextStyle(color: Colors.black, fontSize: 7, height: 1.0, fontWeight: FontWeight.w800),
      ),
    );
  }
}

enum _PillMark { guide, y }

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.mark});

  final String label;
  final _PillMark mark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE6181A18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
        child: Row(
          children: [
            if (mark == _PillMark.guide)
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.4),
                ),
              )
            else
              Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFFF6C445), shape: BoxShape.circle),
                child: const Text('Y', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

enum _Scene { night, harbor, signal, relay, drift, library, message, play, ad }

class _SceneArt extends StatelessWidget {
  const _SceneArt({required this.scene});

  final _Scene scene;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ScenePainter(scene), child: const SizedBox.expand());
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.scene);

  final _Scene scene;

  @override
  void paint(Canvas canvas, Size size) {
    switch (scene) {
      case _Scene.night:
        _night(canvas, size);
      case _Scene.harbor:
        _harbor(canvas, size);
      case _Scene.signal:
        _signal(canvas, size);
      case _Scene.relay:
        _relay(canvas, size);
      case _Scene.drift:
        _drift(canvas, size);
      case _Scene.library:
        _library(canvas, size);
      case _Scene.message:
        _message(canvas, size);
      case _Scene.play:
        _play(canvas, size);
      case _Scene.ad:
        _ad(canvas, size);
    }
  }

  void _fill(Canvas canvas, Size size, List<Color> colors) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(Offset.zero & size),
    );
  }

  void _night(Canvas canvas, Size size) {
    _fill(canvas, size, const [Color(0xFF3A4630), Color(0xFF1A2418), Color(0xFF0C100C)]);
    canvas.drawOval(
      Rect.fromLTWH(-size.width * 0.1, size.height * 0.48, size.width * 1.2, size.height * 0.4),
      Paint()..color = const Color(0x2A9AA888),
    );
    final plate = Paint()..color = const Color(0xFF2C3330);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.58), width: size.width * 0.46, height: size.height * 0.5),
        Radius.circular(size.width * 0.04),
      ),
      plate,
    );
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.28), size.width * 0.09, Paint()..color = const Color(0xFF3A4038));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width * 0.32, size.height * 0.42), width: size.width * 0.16, height: size.height * 0.1),
        const Radius.circular(4),
      ),
      plate,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width * 0.68, size.height * 0.42), width: size.width * 0.16, height: size.height * 0.1),
        const Radius.circular(4),
      ),
      plate,
    );
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.34),
      Offset(size.width * 0.78, size.height * 0.22),
      Paint()
        ..color = const Color(0xFF6A5844)
        ..strokeWidth = size.width * 0.035
        ..strokeCap = StrokeCap.round,
    );
  }

  void _harbor(Canvas canvas, Size size) {
    _fill(canvas, size, const [Color(0xFF7EC8E4), Color(0xFF1568A0), Color(0xFF082848)]);
    final ray = Paint()..color = const Color(0x30FFFFFF);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.18, 0, size.width * 0.05, size.height * 0.7), ray);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.42, 0, size.width * 0.08, size.height * 0.55), ray);
    final diver = Paint()..color = const Color(0xFF102433);
    canvas.drawCircle(Offset(size.width * 0.46, size.height * 0.32), size.width * 0.08, diver);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width * 0.46, size.height * 0.58), width: size.width * 0.16, height: size.height * 0.34),
        const Radius.circular(8),
      ),
      diver,
    );
    final fin = Path()
      ..moveTo(size.width * 0.38, size.height * 0.7)
      ..lineTo(size.width * 0.22, size.height * 0.86)
      ..lineTo(size.width * 0.46, size.height * 0.74)
      ..close();
    canvas.drawPath(fin, Paint()..color = const Color(0xFF1C4A62));
    final bubble = Paint()..color = const Color(0x66FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.4), 3, bubble);
    canvas.drawCircle(Offset(size.width * 0.74, size.height * 0.28), 2, bubble);
  }

  void _signal(Canvas canvas, Size size) {
    _fill(canvas, size, const [Color(0xFFF0B429), Color(0xFFD2541A), Color(0xFF6A2010)]);
    canvas.drawOval(
      Rect.fromLTWH(-size.width * 0.1, size.height * 0.62, size.width * 0.7, size.height * 0.3),
      Paint()..color = const Color(0x55F2D2A0),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.16, size.height * 0.48, size.width * 0.68, size.height * 0.22),
        Radius.circular(size.width * 0.04),
      ),
      Paint()..color = const Color(0xFFF7F3EA),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.34, size.height * 0.34, size.width * 0.28, size.height * 0.18),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF243040),
    );
    final wheel = Paint()..color = const Color(0xFF161616);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7), size.width * 0.08, wheel);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.7), size.width * 0.08, wheel);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7), size.width * 0.03, Paint()..color = const Color(0xFFC8C8C8));
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.7), size.width * 0.03, Paint()..color = const Color(0xFFC8C8C8));
  }

  void _relay(Canvas canvas, Size size) {
    _fill(canvas, size, const [Color(0xFF2A0A08), Color(0xFF8A220E), Color(0xFF1A0806)]);
    void flame(double x, double y, double w, double h, Color color) {
      final path = Path()
        ..moveTo(x, y + h)
        ..quadraticBezierTo(x - w * 0.15, y + h * 0.45, x + w * 0.35, y)
        ..quadraticBezierTo(x + w * 0.7, y + h * 0.4, x + w, y + h)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    flame(size.width * 0.18, size.height * 0.28, size.width * 0.64, size.height * 0.62, const Color(0xFFE25812));
    flame(size.width * 0.32, size.height * 0.4, size.width * 0.36, size.height * 0.48, const Color(0xFFFFB03A));
  }

  void _drift(Canvas canvas, Size size) {
    _fill(canvas, size, const [Color(0xFF8EC8EA), Color(0xFFD8C48A), Color(0xFF6A8A48)]);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.46), size.width * 0.07, Paint()..color = const Color(0xFF1C2430));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.68), width: size.width * 0.16, height: size.height * 0.28),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF243044),
    );
  }

  void _library(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF141414));
    final panels = [
      (0.0, const [Color(0xFF243044), Color(0xFF3A6A8A)]),
      (1 / 3, const [Color(0xFFE2B43A), Color(0xFF8A5A18)]),
      (2 / 3, const [Color(0xFF1A1A1A), Color(0xFF4A3028)]),
    ];
    for (final panel in panels) {
      final rect = Rect.fromLTWH(size.width * panel.$1, 0, size.width / 3, size.height);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: panel.$2).createShader(rect),
      );
    }
    final icon = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final origin = Offset(size.width * 0.08, size.height * 0.18);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(origin.dx, origin.dy, 16, 18), const Radius.circular(2)), icon);
    canvas.drawLine(origin + const Offset(5, 0), origin + const Offset(5, 18), icon);
    canvas.drawLine(origin + const Offset(10, 0), origin + const Offset(10, 18), icon);
  }

  void _message(Canvas canvas, Size size) {
    _fill(canvas, size, const [Color(0xFF10283A), Color(0xFF0C1A16)]);
    final dot = Paint()..color = const Color(0x55FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.28), 3, dot);
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.2), 2, dot);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.34), 2.5, dot);
    final bubble = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.42), width: size.width * 0.28, height: size.height * 0.32),
      const Radius.circular(8),
    );
    canvas.drawRRect(bubble, Paint()..color = const Color(0xFFD7E4EA));
    final tail = Path()
      ..moveTo(size.width * 0.42, size.height * 0.52)
      ..lineTo(size.width * 0.36, size.height * 0.66)
      ..lineTo(size.width * 0.5, size.height * 0.54)
      ..close();
    canvas.drawPath(tail, Paint()..color = const Color(0xFFD7E4EA));
  }

  void _play(Canvas canvas, Size size) {
    _fill(canvas, size, const [Color(0xFF1A4A78), Color(0xFF2E6B4F), Color(0xFF123024)]);
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.38), size.shortestSide * 0.12, Paint()..color = const Color(0xFFE2B090));
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.36), size.shortestSide * 0.13, Paint()..color = const Color(0xFF3A6EA5));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width * 0.42, size.height * 0.68), width: size.width * 0.4, height: size.height * 0.36),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF1A3050),
    );
  }

  void _ad(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF8A2A22));
    canvas.drawRect(Rect.fromLTWH(size.width * 0.46, 0, size.width * 0.54, size.height), Paint()..color = const Color(0xFFF2E6D4));
    canvas.drawCircle(Offset(size.width * 0.24, size.height * 0.4), size.height * 0.12, Paint()..color = const Color(0xFFC48A62));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width * 0.24, size.height * 0.72), width: size.width * 0.22, height: size.height * 0.4),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF24344A),
    );
    canvas.drawRect(Rect.fromLTWH(size.width * 0.55, size.height * 0.22, size.width * 0.32, size.height * 0.08), Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawRect(Rect.fromLTWH(size.width * 0.55, size.height * 0.36, size.width * 0.28, size.height * 0.05), Paint()..color = const Color(0xFF8A3030));
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) => oldDelegate.scene != scene;
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  Path _swoosh(Size size, double dy) {
    return Path()
      ..moveTo(-size.width * 0.06, size.height * (0.08 + dy))
      ..cubicTo(
        size.width * 0.12, size.height * (0.58 + dy),
        size.width * 0.24, size.height * (-0.12 + dy),
        size.width * 0.46, size.height * (0.2 + dy),
      )
      ..cubicTo(
        size.width * 0.64, size.height * (0.46 + dy),
        size.width * 0.72, size.height * (-0.02 + dy),
        size.width * 1.1, size.height * (0.18 + dy),
      );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF061803));
    canvas.drawPath(
      _swoosh(size, 0.02),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height * 0.42
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF146B1C)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawPath(
      _swoosh(size, -0.02),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height * 0.14
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF8FDE55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    final shade = Rect.fromLTWH(0, size.height * 0.46, size.width, size.height * 0.54);
    canvas.drawRect(
      shade,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00061803), Color(0xF2061803)],
        ).createShader(shade),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

