import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';

/// PlayStation 2 memory-card browser. The plate follows a saved wallpaper.
class Ps2Home extends StatefulWidget {
  const Ps2Home({
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

  @override
  State<Ps2Home> createState() => _Ps2HomeState();
}

class _Ps2HomeState extends State<Ps2Home> {
  static const _shells = [
    ('xbox', 'Xbox Series'),
    ('ps5', 'PlayStation 5'),
    ('ps2', 'PlayStation 2'),
    ('x360', 'Xbox 360'),
  ];

  String _selected = 'steam';

  @override
  Widget build(BuildContext context) {
    final featured = widget.device.os.steamTitle.trim().isEmpty
        ? 'Night Run'
        : widget.device.os.steamTitle.trim();
    final slots = _slots(featured);
    final current = slots.whereType<_Save>().firstWhere(
      (save) => save.id == _selected,
      orElse: () => slots.whereType<_Save>().first,
    );
    return Stack(
      key: const Key('ps2-home'),
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: _Plate(device: widget.device)),
        LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final tight = h < 360 || constraints.maxWidth < 640;
            final pad = tight ? 10.0 : 18.0;
            final header = (h * 0.14).clamp(tight ? 34.0 : 48.0, 72.0);
            final prompts = (h * 0.09).clamp(22.0, 40.0);
            final cursor = (h * 0.045).clamp(10.0, 18.0);
            return Padding(
              padding: EdgeInsets.fromLTRB(pad, pad * 0.7, pad, pad * 0.45),
              child: Column(
                children: [
                  SizedBox(
                    height: header,
                    child: _Header(
                      title: current.title,
                      detail: current.detail,
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final width = math.min(
                          box.maxWidth * 0.82,
                          box.maxHeight * 1.35,
                        );
                        final height = math.min(
                          box.maxHeight * 0.94,
                          width * 0.78,
                        );
                        return Center(
                          child: SizedBox(
                            width: width,
                            height: height,
                            child: _Grid(
                              slots: slots,
                              selected: _selected,
                              onSelect: (id) => setState(() => _selected = id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: cursor,
                    child: const CustomPaint(painter: _CursorPainter()),
                  ),
                  SizedBox(height: tight ? 2 : 6),
                  SizedBox(
                    height: prompts,
                    child: _Prompts(
                      onEnter: () => widget.onOpen(
                        current.id == 'steam' ? 'steam' : current.title,
                      ),
                      onShell: widget.onShell,
                      shells: _shells,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.device});

  final PropDevice device;

  bool get _custom {
    final os = device.os;
    if (os.backgroundType == 'image' && os.backgroundUrl.isNotEmpty) {
      return true;
    }
    return os.backgroundPreset.isNotEmpty && os.backgroundPreset != 'default';
  }

  @override
  Widget build(BuildContext context) {
    if (!_custom) {
      return const DecoratedBox(
        key: Key('ps2-plate'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB4B6B8), Color(0xFF7A7C80), Color(0xFF9A9C9F)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SizedBox.expand(),
      );
    }
    final paper = wallpaperFor(device, locked: false);
    final image = paper.imagePath.isEmpty
        ? null
        : imageProviderForPath(paper.imagePath);
    return DecoratedBox(
      key: const Key('ps2-wallpaper'),
      decoration: BoxDecoration(
        gradient: paper.gradient,
        image: image == null
            ? null
            : DecorationImage(image: image, fit: BoxFit.cover),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    const shadow = [
      Shadow(color: Color(0xCC000000), offset: Offset(1.5, 1.5), blurRadius: 2),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Memory Card (PS2)/1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    shadows: shadow,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '6,144 KB Free',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    shadows: shadow,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FittedBox(
            alignment: Alignment.centerRight,
            fit: BoxFit.scaleDown,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF6DE55),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    shadows: shadow,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFFF6DE55),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    shadows: shadow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.slots,
    required this.selected,
    required this.onSelect,
  });

  final List<_Save?> slots;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 4; row++)
          Expanded(
            child: Row(
              children: [
                for (var col = 0; col < 5; col++)
                  Expanded(child: _cell(slots[row * 5 + col])),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(_Save? save) {
    if (save == null) return const SizedBox.expand();
    final on = save.id == selected;
    return GestureDetector(
      key: Key('ps2-save-${save.id}'),
      onTap: () => onSelect(save.id),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side =
              math.min(constraints.maxWidth, constraints.maxHeight) *
              (on ? 0.9 : 0.78);
          return Center(
            child: _SaveIcon(
              save: save,
              side: math.max(18, side),
              selected: on,
            ),
          );
        },
      ),
    );
  }
}

class _Prompts extends StatelessWidget {
  const _Prompts({
    required this.onEnter,
    required this.onShell,
    required this.shells,
  });

  final VoidCallback onEnter;
  final ValueChanged<String> onShell;
  final List<(String, String)> shells;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            key: const Key('ps2-enter'),
            onTap: onEnter,
            child: const _Prompt(
              mark: _Mark.cross,
              label: 'Enter',
              color: Color(0xFF8EB4FF),
            ),
          ),
        ),
        const Expanded(
          child: _Prompt(
            mark: _Mark.circle,
            label: 'Back',
            color: Color(0xFFF07A8A),
          ),
        ),
        Expanded(
          child: PopupMenuButton<String>(
            tooltip: '',
            padding: EdgeInsets.zero,
            color: const Color(0xFF1C1C1E),
            onSelected: onShell,
            itemBuilder: (context) => [
              for (final item in shells)
                PopupMenuItem(value: item.$1, child: Text(item.$2)),
            ],
            child: const _Prompt(
              mark: _Mark.triangle,
              label: 'Options',
              color: Color(0xFF8FDE6A),
            ),
          ),
        ),
      ],
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.mark, required this.label, required this.color});

  final _Mark mark;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const shadow = [
      Shadow(color: Color(0xCC000000), offset: Offset(1, 1), blurRadius: 1),
    ];
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(16, 16),
            painter: _MarkPainter(mark, color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              shadows: shadow,
            ),
          ),
        ],
      ),
    );
  }
}

enum _Face { card, disc, token, coin, badge, flame, figure, cube }

enum _Mark { cross, circle, triangle }

class _Save {
  const _Save(
    this.id,
    this.title,
    this.detail,
    this.face,
    this.color, {
    this.icon = Icons.circle,
  });

  final String id;
  final String title;
  final String detail;
  final _Face face;
  final Color color;
  final IconData icon;
}

List<_Save?> _slots(String featured) {
  return [
    const _Save(
      'harbor',
      'Harbor',
      'Dock notes',
      _Face.card,
      Color(0xFF1A6898),
      icon: Icons.waves,
    ),
    const _Save('signal', 'Signal', 'Route', _Face.flame, Color(0xFFE08A3A)),
    const _Save('relay', 'Relay', 'Checkpoint', _Face.flame, Color(0xFFE06A2C)),
    const _Save(
      'northline',
      'Northline',
      'Field notes',
      _Face.card,
      Color(0xFF3A4E8A),
      icon: Icons.terrain,
    ),
    const _Save('kiln', 'Kiln', 'Workshop', _Face.badge, Color(0xFF8A8E96)),
    const _Save(
      'glass',
      'Glass',
      'Still',
      _Face.card,
      Color(0xFF243044),
      icon: Icons.diamond,
    ),
    const _Save(
      'mara',
      'Mara',
      'Profile',
      _Face.disc,
      Color(0xFF4A6A9A),
      icon: Icons.person,
    ),
    const _Save(
      'bench',
      'Bench',
      'Promo',
      _Face.card,
      Color(0xFF3A3A42),
      icon: Icons.weekend,
    ),
    const _Save(
      'drift',
      'Drift',
      'Lap',
      _Face.card,
      Color(0xFF2A4060),
      icon: Icons.speed,
    ),
    const _Save(
      'yard',
      'Yard',
      'Shift',
      _Face.card,
      Color(0xFF3A4038),
      icon: Icons.grid_on,
    ),
    const _Save('coin', 'Token', 'Spare', _Face.coin, Color(0xFF6A6258)),
    const _Save('scout', 'Scout', 'Cast', _Face.figure, Color(0xFF2C2C30)),
    null,
    const _Save(
      'still',
      'Still',
      'Frame',
      _Face.card,
      Color(0xFF4A3028),
      icon: Icons.photo,
    ),
    const _Save('pilot', 'Pilot', 'Cast', _Face.figure, Color(0xFF3A3050)),
    _Save(
      'steam',
      featured,
      'Saved progress',
      _Face.token,
      const Color(0xFF4C78B8),
      icon: Icons.album,
    ),
    const _Save(
      'lane',
      'Lane',
      'Notes',
      _Face.card,
      Color(0xFF2C4A6A),
      icon: Icons.alt_route,
    ),
    const _Save(
      'dock',
      'Dock',
      'Notes',
      _Face.card,
      Color(0xFF1A3A4A),
      icon: Icons.anchor,
    ),
    const _Save(
      'gate',
      'Gate',
      'Pass',
      _Face.card,
      Color(0xFF3A3A55),
      icon: Icons.vpn_key,
    ),
    const _Save('block', 'Block', 'Archive', _Face.cube, Color(0xFFE25A2A)),
  ];
}

class _SaveIcon extends StatelessWidget {
  const _SaveIcon({
    required this.save,
    required this.side,
    required this.selected,
  });

  final _Save save;
  final double side;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (selected)
            Positioned(
              bottom: -side * 0.22,
              child: Container(
                width: side * 1.7,
                height: side * 0.85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(side),
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0x88FFFFFF),
                      Color(0x00FFFFFF),
                    ],
                    stops: [0.0, 0.35, 0.75],
                  ),
                ),
              ),
            ),
          _face(),
        ],
      ),
    );
  }

  Widget _face() {
    switch (save.face) {
      case _Face.cube:
        return CustomPaint(
          size: Size.square(side),
          painter: const _CubePainter(),
        );
      case _Face.flame:
        return CustomPaint(
          size: Size.square(side),
          painter: _FlamePainter(save.color),
        );
      case _Face.figure:
        return Icon(
          Icons.person,
          color: const Color(0xFFE8E4DC),
          size: side * 0.8,
        );
      case _Face.card:
        return _panel(BorderRadius.circular(side * 0.08));
      case _Face.badge:
      case _Face.disc:
      case _Face.token:
      case _Face.coin:
        return _panel(null);
    }
  }

  Widget _panel(BorderRadius? radius) {
    final round = radius == null;
    return Container(
      width: side * (round ? 0.86 : 0.95),
      height: side * (round ? 0.86 : 0.72),
      decoration: BoxDecoration(
        shape: round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(save.color, Colors.white, 0.35)!, save.color],
        ),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(save.icon, color: Colors.white, size: side * 0.38),
    );
  }
}

class _CubePainter extends CustomPainter {
  const _CubePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final front = Path()
      ..moveTo(w * 0.18, h * 0.34)
      ..lineTo(w * 0.62, h * 0.34)
      ..lineTo(w * 0.62, h * 0.82)
      ..lineTo(w * 0.18, h * 0.82)
      ..close();
    final side = Path()
      ..moveTo(w * 0.62, h * 0.34)
      ..lineTo(w * 0.86, h * 0.2)
      ..lineTo(w * 0.86, h * 0.68)
      ..lineTo(w * 0.62, h * 0.82)
      ..close();
    final top = Path()
      ..moveTo(w * 0.18, h * 0.34)
      ..lineTo(w * 0.42, h * 0.18)
      ..lineTo(w * 0.86, h * 0.2)
      ..lineTo(w * 0.62, h * 0.34)
      ..close();
    canvas.drawPath(front, Paint()..color = const Color(0xFFE25A2A));
    canvas.drawPath(side, Paint()..color = const Color(0xFFB8431C));
    canvas.drawPath(top, Paint()..color = const Color(0xFFF08A55));
    final mark = Paint()
      ..color = const Color(0xFFF6F1E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.045)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.3, h * 0.58), Offset(w * 0.4, h * 0.68), mark);
    canvas.drawLine(
      Offset(w * 0.4, h * 0.68),
      Offset(w * 0.52, h * 0.46),
      mark,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlamePainter extends CustomPainter {
  const _FlamePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.08)
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.48,
        size.width * 0.62,
        size.height * 0.88,
      )
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.7,
        size.width * 0.38,
        size.height * 0.88,
      )
      ..quadraticBezierTo(
        size.width * 0.1,
        size.height * 0.48,
        size.width * 0.5,
        size.height * 0.08,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.62),
      size.shortestSide * 0.08,
      Paint()..color = const Color(0xFFFFE2A0),
    );
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CursorPainter extends CustomPainter {
  const _CursorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.width / 2;
    final h = size.height;
    final path = Path()
      ..moveTo(mid - h * 0.7, h)
      ..lineTo(mid, 0)
      ..lineTo(mid + h * 0.7, h)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF2F6BFF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.mark, this.color);

  final _Mark mark;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, size.shortestSide * 0.14)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (mark) {
      case _Mark.cross:
        canvas.drawLine(
          Offset(size.width * 0.2, size.height * 0.2),
          Offset(size.width * 0.8, size.height * 0.8),
          paint,
        );
        canvas.drawLine(
          Offset(size.width * 0.8, size.height * 0.2),
          Offset(size.width * 0.2, size.height * 0.8),
          paint,
        );
      case _Mark.circle:
        canvas.drawCircle(
          size.center(Offset.zero),
          size.shortestSide * 0.32,
          paint,
        );
      case _Mark.triangle:
        final path = Path()
          ..moveTo(size.width * 0.5, size.height * 0.16)
          ..lineTo(size.width * 0.84, size.height * 0.82)
          ..lineTo(size.width * 0.16, size.height * 0.82)
          ..close();
        canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) =>
      oldDelegate.mark != mark || oldDelegate.color != color;
}
