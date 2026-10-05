import 'dart:ui';

import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';

/// Smart home control panel.
///
/// [portrait] is the phone mounted as the screen. The wall panel is landscape.
/// Panels are frosted glass over a colored wash.
class HomePanel extends StatefulWidget {
  const HomePanel({
    super.key,
    required this.store,
    required this.device,
    this.portrait = false,
  });

  final StageStore store;
  final PropDevice device;
  final bool portrait;

  @override
  State<HomePanel> createState() => _HomePanelState();
}

class _HomePanelState extends State<HomePanel> {
  String _scene = 'home';
  bool _lights = true;
  double _temp = 21;
  bool _locked = true;
  bool _garage = false;
  bool _music = false;
  double _blinds = 0.6;
  bool _oven = false;
  bool _alarm = false;
  bool _camera = false;

  void _apply(String scene) {
    setState(() {
      _scene = scene;
      switch (scene) {
        case 'away':
          _lights = false;
          _locked = true;
          _music = false;
          _oven = false;
          _alarm = true;
        case 'sleep':
          _lights = false;
          _locked = true;
          _music = false;
          _blinds = 0;
          _alarm = true;
        case 'movie':
          _lights = false;
          _blinds = 0;
          _music = true;
          _alarm = false;
        default:
          _lights = true;
          _locked = true;
          _music = false;
          _alarm = false;
          _blinds = 0.6;
      }
    });
    widget.store.setAlarm(widget.device.id, _alarm);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const Key('home-panel'),
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _HarborWash()),
        LayoutBuilder(
          builder: (context, constraints) {
            final portrait =
                widget.portrait || constraints.maxWidth < constraints.maxHeight;
            return Padding(
              padding: EdgeInsets.all(portrait ? 16 : 22),
              child: portrait ? _phone() : _wall(),
            );
          },
        ),
      ],
    );
  }

  Widget _phone() {
    return Column(
      children: [
        _mast(compact: true),
        const SizedBox(height: 12),
        _climate(wide: true),
        const SizedBox(height: 12),
        _scenes(),
        const SizedBox(height: 12),
        Expanded(child: _grid(columns: 2)),
      ],
    );
  }

  Widget _wall() {
    return Column(
      children: [
        _mast(compact: false),
        const SizedBox(height: 16),
        _scenes(),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 4, child: _climate(wide: false)),
              const SizedBox(width: 16),
              Expanded(flex: 8, child: _grid(columns: 4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mast({required bool compact}) {
    return Column(
      children: [
        Text(
          compact ? 'Phone' : 'Panel',
          key: Key(compact ? 'home-phone' : 'home-wall'),
          style: const TextStyle(
            color: Color(0xFFD7E7E2),
            fontSize: 12,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const _ColorThread(),
        const SizedBox(height: 8),
        Text(
          'Smart home',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 28 : 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Living room · control',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFD5E4DE), fontSize: 13),
        ),
      ],
    );
  }

  Widget _scenes() {
    const scenes = [
      ('home', 'Home', Color(0xFFF6C15B)),
      ('away', 'Away', Color(0xFF79B4FF)),
      ('sleep', 'Sleep', Color(0xFFD59BFF)),
      ('movie', 'Movie', Color(0xFFFF8D72)),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final scene in scenes)
          GestureDetector(
            key: Key('home-scene-${scene.$1}'),
            onTap: () => _apply(scene.$1),
            child: _Glass(
              radius: 22,
              tint: scene.$3,
              lit: _scene == scene.$1,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                scene.$2,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _climate({required bool wide}) {
    final figure = Text(
      '${_temp.toStringAsFixed(0)}°',
      style: TextStyle(
        color: Colors.white,
        fontSize: wide ? 36 : 52,
        fontWeight: FontWeight.w700,
        height: 1,
        shadows: const [Shadow(color: Color(0xAA7EE0D2), blurRadius: 18)],
      ),
    );
    final down = _round(
      '−',
      () => setState(() => _temp -= 1),
      const Key('home-temp-down'),
    );
    final up = _round(
      '+',
      () => setState(() => _temp += 1),
      const Key('home-temp-up'),
    );
    return _Glass(
      tint: const Color(0xFF7EE0D2),
      lit: true,
      expand: true,
      padding: EdgeInsets.symmetric(vertical: wide ? 12 : 18, horizontal: 12),
      child: wide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Climate',
                  style: TextStyle(color: Color(0xFFD7FFF6), fontSize: 13),
                ),
                const SizedBox(width: 16),
                figure,
                const SizedBox(width: 16),
                down,
                const SizedBox(width: 8),
                up,
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Climate',
                  style: TextStyle(color: Color(0xFFD7FFF6), fontSize: 13),
                ),
                const SizedBox(height: 6),
                figure,
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [down, const SizedBox(width: 16), up],
                ),
              ],
            ),
    );
  }

  Widget _round(String label, VoidCallback onTap, Key key) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: _Glass(
        radius: 18,
        tint: const Color(0xFF7EE0D2),
        lit: true,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFEFFEFB),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _grid({required int columns}) {
    final tiles = [
      _Tile(
        name: 'Lights',
        status: _lights ? 'On' : 'Off',
        icon: Icons.lightbulb_outline,
        on: _lights,
        tint: const Color(0xFFF6C15B),
        tileKey: const Key('home-lights'),
        onTap: () => setState(() => _lights = !_lights),
      ),
      _Tile(
        name: 'Front door',
        status: _locked ? 'Locked' : 'Open',
        icon: Icons.lock_outline,
        on: _locked,
        tint: const Color(0xFF6FE3C2),
        tileKey: const Key('home-lock'),
        onTap: () => setState(() => _locked = !_locked),
      ),
      _Tile(
        name: 'Garage',
        status: _garage ? 'Open' : 'Closed',
        icon: Icons.garage_outlined,
        on: _garage,
        tint: const Color(0xFF79B4FF),
        tileKey: const Key('home-garage'),
        onTap: () => setState(() => _garage = !_garage),
      ),
      _Tile(
        name: 'Music',
        status: _music ? 'Playing' : 'Off',
        icon: Icons.music_note_outlined,
        on: _music,
        tint: const Color(0xFFD59BFF),
        tileKey: const Key('home-music'),
        onTap: () => setState(() => _music = !_music),
      ),
      _Tile(
        name: 'Blinds',
        status: '${(100 * _blinds).round()}%',
        icon: Icons.blinds,
        on: _blinds > 0.05,
        tint: const Color(0xFFE7C99A),
        tileKey: const Key('home-blinds'),
        onTap: () => setState(() {
          _blinds = _blinds > 0.9 ? 0 : (_blinds + 0.3).clamp(0, 1);
        }),
      ),
      _Tile(
        name: 'Oven',
        status: _oven ? 'On' : 'Off',
        icon: Icons.countertops_outlined,
        on: _oven,
        tint: const Color(0xFFFF8D72),
        tileKey: const Key('home-oven'),
        onTap: () => setState(() => _oven = !_oven),
      ),
      _Tile(
        name: 'Alarm',
        status: _alarm ? 'Armed' : 'Off',
        icon: Icons.shield_outlined,
        on: _alarm,
        tint: const Color(0xFFFF7D95),
        tileKey: const Key('home-alarm'),
        onTap: () {
          setState(() => _alarm = !_alarm);
          widget.store.setAlarm(widget.device.id, _alarm);
        },
      ),
      _Tile(
        name: 'Door camera',
        status: _camera ? 'Live' : 'Idle',
        icon: Icons.videocam_outlined,
        on: _camera,
        tint: const Color(0xFF8EE7FF),
        tileKey: const Key('home-camera'),
        onTap: () => setState(() => _camera = !_camera),
      ),
    ];
    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: columns == 4 ? 1.15 : 1.35,
      physics: const ClampingScrollPhysics(),
      children: tiles,
    );
  }
}

class _ColorThread extends StatelessWidget {
  const _ColorThread();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: const LinearGradient(
          colors: [Color(0xFFF6C15B), Color(0xFF6FE3C2), Color(0xFFD59BFF)],
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    this.radius = 22,
    this.tint = Colors.white,
    this.lit = false,
    this.expand = false,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final Color tint;
  final bool lit;
  final bool expand;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final panel = Stack(
      children: [
        Positioned(
          left: 14,
          right: 14,
          top: 0,
          height: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: lit ? 0.7 : 0.4),
            ),
          ),
        ),
        Padding(padding: padding, child: child),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: (lit ? tint : const Color(0xFF04110F)).withValues(
              alpha: lit ? 0.32 : 0.22,
            ),
            blurRadius: lit ? 20 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: shape,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    tint.withValues(alpha: lit ? 0.38 : 0.12),
                    Colors.white.withValues(alpha: 0.16),
                  ),
                  Color.alphaBlend(
                    tint.withValues(alpha: lit ? 0.18 : 0.05),
                    Colors.white.withValues(alpha: 0.05),
                  ),
                ],
              ),
              border: Border.all(
                color: (lit ? tint : Colors.white).withValues(
                  alpha: lit ? 0.62 : 0.22,
                ),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fill =
                    expand &&
                    constraints.hasBoundedWidth &&
                    constraints.hasBoundedHeight;
                return fill ? SizedBox.expand(child: panel) : panel;
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.name,
    required this.status,
    required this.icon,
    required this.on,
    required this.tint,
    required this.tileKey,
    required this.onTap,
  });

  final String name;
  final String status;
  final IconData icon;
  final bool on;
  final Color tint;
  final Key tileKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: tileKey,
      onTap: onTap,
      child: _Glass(
        tint: tint,
        lit: on,
        expand: true,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: on ? 0.34 : 0.14),
                border: Border.all(
                  color: tint.withValues(alpha: on ? 0.85 : 0.35),
                ),
              ),
              child: Icon(icon, color: on ? Colors.white : tint, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: on ? tint : const Color(0xFFD5E4DE),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HarborWash extends CustomPainter {
  const _HarborWash();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF12343A), Color(0xFF071816), Color(0xFF10182A)],
        ).createShader(rect),
    );
    _bloom(
      canvas,
      Offset(size.width * 0.08, size.height * 0.02),
      size.shortestSide * 0.72,
      const Color(0x88F6C15B),
    );
    _bloom(
      canvas,
      Offset(size.width * 0.96, size.height * 0.18),
      size.shortestSide * 0.62,
      const Color(0x7736D6C6),
    );
    _bloom(
      canvas,
      Offset(size.width * 0.62, size.height * 1.05),
      size.shortestSide * 0.8,
      const Color(0x668A6CFF),
    );
    _bloom(
      canvas,
      Offset(size.width * 0.18, size.height * 0.92),
      size.shortestSide * 0.46,
      const Color(0x55FF8D72),
    );
  }

  void _bloom(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
