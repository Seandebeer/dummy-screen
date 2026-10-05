import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';

/// Xbox 360 dashboard: gray field, green tiles, and the home tabs.
class Xbox360Home extends StatefulWidget {
  const Xbox360Home({
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
  State<Xbox360Home> createState() => _Xbox360HomeState();
}

class _Xbox360HomeState extends State<Xbox360Home> {
  int _tab = 0;

  static const _shells = [
    ('xbox', 'Xbox Series'),
    ('ps5', 'PlayStation 5'),
    ('ps2', 'PlayStation 2'),
    ('x360', 'Xbox 360'),
  ];

  static const _green = Color(0xFF0E9408);
  static const _gap = 5.0;

  @override
  Widget build(BuildContext context) {
    final tag = widget.store.operatorName.trim().isEmpty ? 'Player' : widget.store.operatorName.trim();
    final featured = widget.device.os.steamTitle.trim().isEmpty ? 'Night Run' : widget.device.os.steamTitle.trim();
    return DecoratedBox(
      key: const Key('xbox360-home'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3C3E3D), Color(0xFF6E706F), Color(0xFFB7B9B8)],
          stops: [0, 0.42, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 0, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final box = _fit(constraints.maxWidth, constraints.maxHeight);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Status(tag: tag, onShell: widget.onShell, shells: _shells),
                const SizedBox(height: 8),
                _Tabs(index: _tab, onSelect: (index) => setState(() => _tab = index)),
                const SizedBox(height: 10),
                if (_tab == 0)
                  _HomeGrid(
                    box: box,
                    featured: featured,
                    onOpen: widget.onOpen,
                    onSeries: () => widget.onShell('xbox'),
                  )
                else if (_tab == 1)
                  _MenuList(
                    width: box.row,
                    items: const [
                      ('Friends', '12 online'),
                      ('Messages', 'No new notes'),
                      ('Parties', 'The bench is quiet'),
                    ],
                    onOpen: widget.onOpen,
                  )
                else
                  _MenuList(
                    width: box.row,
                    items: const [
                      ('Xbox Series', 'Open the Series shell'),
                      ('PlayStation 5', 'Switch shell'),
                      ('PlayStation 2', 'Switch shell'),
                      ('Xbox 360', 'This dashboard'),
                    ],
                    onOpen: (label) {
                      const shells = {
                        'Xbox Series': 'xbox',
                        'PlayStation 5': 'ps5',
                        'PlayStation 2': 'ps2',
                        'Xbox 360': 'x360',
                      };
                      final id = shells[label];
                      if (id != null) widget.onShell(id);
                    },
                  ),
                const SizedBox(height: 12),
                const _SelectHint(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Box {
  const _Box({
    required this.tile,
    required this.play,
    required this.pins,
    required this.peek,
    required this.row,
  });

  final double tile;
  final double play;
  final double pins;
  final double peek;
  final double row;

  double get promoW => tile * 4 + _Xbox360HomeState._gap * 3;
  double get promoH => play + _Xbox360HomeState._gap + pins;
  double get gridH => promoH + _Xbox360HomeState._gap + tile;
}

_Box _fit(double width, double height) {
  const gap = _Xbox360HomeState._gap;
  const chrome = 36.0 + 8 + 28 + 10 + 14 + 24;
  var tile = (width - gap * 5) / 5.46;
  var play = tile * 0.98;
  var pins = tile * 0.7;
  var needed = chrome + play + gap + pins + gap + tile;
  if (needed > height && needed > 0) {
    final scale = ((height - chrome) / (needed - chrome)).clamp(0.42, 1.0);
    tile *= scale;
    play *= scale;
    pins *= scale;
  }
  final peek = tile * 0.46;
  final row = tile * 5 + gap * 4;
  return _Box(tile: tile, play: play, pins: pins, peek: peek, row: row);
}

class _Status extends StatelessWidget {
  const _Status({required this.tag, required this.onShell, required this.shells});

  final String tag;
  final ValueChanged<String> onShell;
  final List<(String, String)> shells;

  @override
  Widget build(BuildContext context) {
    final initial = tag.isEmpty ? 'P' : tag.characters.first.toUpperCase();
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          const Spacer(),
          const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 15),
          const SizedBox(width: 4),
          const Text('3', style: TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(width: 14),
          const Icon(Icons.mail_outline, color: Colors.white, size: 15),
          const SizedBox(width: 4),
          const Text('0', style: TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(width: 14),
          const Text('18,420', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 11,
            backgroundColor: const Color(0xFF2A6A9A),
            child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: 'Console',
            padding: EdgeInsets.zero,
            color: const Color(0xFF1C1C1E),
            onSelected: onShell,
            itemBuilder: (context) => [
              for (final item in shells) PopupMenuItem(value: item.$1, child: Text(item.$2)),
            ],
            icon: const Icon(Icons.settings, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const labels = ['home', 'social', 'settings'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 22),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: i == index ? Colors.white : const Color(0xFFB5B5B5),
                  fontSize: 20,
                  fontWeight: i == index ? FontWeight.w400 : FontWeight.w300,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeGrid extends StatelessWidget {
  const _HomeGrid({
    required this.box,
    required this.featured,
    required this.onOpen,
    required this.onSeries,
  });

  final _Box box;
  final String featured;
  final ValueChanged<String> onOpen;
  final VoidCallback onSeries;

  @override
  Widget build(BuildContext context) {
    final gap = _Xbox360HomeState._gap;
    return SizedBox(
      height: box.gridH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: box.row,
            child: Column(
              children: [
                SizedBox(
                  height: box.promoH,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: box.tile,
                        child: Column(
                          children: [
                            _GreenTile(
                              width: box.tile,
                              height: box.play,
                  label: 'Play $featured',
                  tileKey: const Key('xbox360-play'),
                  maxLines: 2,
                  icon: const _GoldMark(),
                  onTap: () => onOpen('steam'),
                            ),
                            SizedBox(height: gap),
                            _GreenTile(
                              width: box.tile,
                              height: box.pins,
                              label: 'My Pins',
                              icon: const Icon(Icons.push_pin, color: Colors.white, size: 26),
                              onTap: () => onOpen('My Pins'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: gap),
                      _Promo(width: box.promoW, height: box.promoH, onTap: onSeries),
                    ],
                  ),
                ),
                SizedBox(height: gap),
                SizedBox(
                  height: box.tile,
                  child: Row(
                    children: [
                      _GreenTile(
                        width: box.tile,
                        height: box.tile,
                        label: 'Recent',
                        tileKey: const Key('xbox360-recent'),
                        icon: const Icon(Icons.schedule, color: Colors.white, size: 26),
                        onTap: () => onOpen('Recent'),
                      ),
                      SizedBox(width: gap),
                      _GreenTile(
                        width: box.tile,
                        height: box.tile,
                        label: 'My Games',
                        icon: const Icon(Icons.sports_esports, color: Colors.white, size: 28),
                        onTap: () => onOpen('My Games'),
                      ),
                      SizedBox(width: gap),
                      _GreenTile(
                        width: box.tile,
                        height: box.tile,
                        label: 'My Apps',
                        icon: const _AppsMark(),
                        onTap: () => onOpen('My Apps'),
                      ),
                      SizedBox(width: gap),
                      _GreenTile(
                        width: box.tile,
                        height: box.tile,
                        label: 'Profile',
                        icon: const Icon(Icons.badge_outlined, color: Colors.white, size: 26),
                        onTap: () => onOpen('Profile'),
                      ),
                      SizedBox(width: gap),
                      _GreenTile(
                        width: box.tile,
                        height: box.tile,
                        label: 'Account',
                        icon: const Icon(Icons.manage_accounts_outlined, color: Colors.white, size: 26),
                        onTap: () => onOpen('Account'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: gap),
          _Rail(width: box.peek, height: box.gridH),
        ],
      ),
    );
  }
}

class _GreenTile extends StatelessWidget {
  const _GreenTile({
    required this.width,
    required this.height,
    required this.label,
    required this.icon,
    required this.onTap,
    this.tileKey,
    this.maxLines = 1,
  });

  final double width;
  final double height;
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final Key? tileKey;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final labelSize = (height * 0.16).clamp(8.0, 13.0);
    return GestureDetector(
      key: tileKey,
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: _Xbox360HomeState._green,
          child: Padding(
            padding: EdgeInsets.fromLTRB(width * 0.08, height * 0.08, 4, height * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: height * 0.36,
                  child: FittedBox(alignment: Alignment.centerLeft, child: icon),
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: labelSize, height: 1.05),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Promo extends StatelessWidget {
  const _Promo({required this.width, required this.height, required this.onTap});

  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('xbox360-promo'),
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: const ColoredBox(
          color: Color(0xFF101114),
          child: Row(
            children: [
              Expanded(flex: 5, child: CustomPaint(painter: _BenchPainter(), child: SizedBox.expand())),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, 10, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: CustomPaint(painter: _CodePainter(), child: SizedBox.expand())),
                      SizedBox(height: 8),
                      Text(
                        'A Series shell is ready on this bench.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 12, height: 1.15),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    const labels = ['Friends', 'Activity', 'Avatar', 'Sign in'];
    return ClipRect(
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(height: _Xbox360HomeState._gap),
              Expanded(
                child: ColoredBox(
                  color: _Xbox360HomeState._green,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        labels[i],
                        maxLines: 1,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuList extends StatelessWidget {
  const _MenuList({required this.width, required this.items, required this.onOpen});

  final double width;
  final List<(String, String)> items;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          for (final item in items) ...[
            GestureDetector(
              onTap: () => onOpen(item.$1),
              child: ColoredBox(
                color: _Xbox360HomeState._green,
                child: SizedBox(
                  width: width,
                  height: 52,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(item.$1, style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                        Text(item.$2, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: _Xbox360HomeState._gap),
          ],
        ],
      ),
    );
  }
}

class _SelectHint extends StatelessWidget {
  const _SelectHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: _Xbox360HomeState._green, shape: BoxShape.circle),
          child: SizedBox(
            width: 16,
            height: 16,
            child: Center(
              child: Text('A', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        SizedBox(width: 6),
        Text('Select', style: TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }
}

class _GoldMark extends StatelessWidget {
  const _GoldMark();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.star, color: Color(0xFFFFD15A), size: 28);
  }
}

class _AppsMark extends StatelessWidget {
  const _AppsMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 26,
      height: 26,
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: [
          _Dot(),
          _Dot(),
          _Dot(),
          _Dot(),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.white,
      child: SizedBox(width: 10, height: 10),
    );
  }
}

class _BenchPainter extends CustomPainter {
  const _BenchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF121418));
    final floor = Paint()..color = const Color(0xFF2C3138);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.78, size.width, size.height * 0.22), floor);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.16, size.width * 0.22, size.height * 0.58),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFF2F4F6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.4, size.height * 0.28, size.width * 0.24, size.height * 0.46),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF2A2E34),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.68, size.height * 0.36, size.width * 0.2, size.height * 0.38),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF8E949C),
    );
    final pad = Paint()..color = const Color(0xFFE4E8EC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width * 0.34, size.height * 0.84), width: size.width * 0.28, height: size.height * 0.1),
        const Radius.circular(10),
      ),
      pad,
    );
    canvas.drawCircle(Offset(size.width * 0.26, size.height * 0.84), size.height * 0.035, Paint()..color = const Color(0xFF202428));
    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.84), size.height * 0.035, Paint()..color = const Color(0xFF202428));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CodePainter extends CustomPainter {
  const _CodePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final origin = Offset((size.width - side) / 2, 0);
    canvas.drawRect(origin & Size(side, side), Paint()..color = Colors.white);
    const cells = 11;
    final cell = side / cells;
    final ink = Paint()..color = Colors.black;
    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        final finder = (x < 3 && y < 3) || (x > 7 && y < 3) || (x < 3 && y > 7);
        final mark = finder || ((x * 3 + y * 5) % 4 == 0);
        if (!mark) continue;
        canvas.drawRect(Rect.fromLTWH(origin.dx + x * cell, origin.dy + y * cell, cell * 0.86, cell * 0.86), ink);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
