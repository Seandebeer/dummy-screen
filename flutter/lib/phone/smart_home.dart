import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';

/// Harbor house control panel.
///
/// [portrait] is the phone mounted as the screen. The wall panel is landscape.
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
    return ColoredBox(
      key: const Key('home-panel'),
      color: const Color(0xFF101614),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final portrait =
              widget.portrait || constraints.maxWidth < constraints.maxHeight;
          return Padding(
            padding: EdgeInsets.all(portrait ? 16 : 22),
            child: portrait ? _phone() : _wall(),
          );
        },
      ),
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
            color: Color(0xFF8FA399),
            fontSize: 12,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Harbor',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 28 : 34,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Living room · control',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFB7C4BC), fontSize: 13),
        ),
      ],
    );
  }

  Widget _scenes() {
    const scenes = [
      ('home', 'Home'),
      ('away', 'Away'),
      ('sleep', 'Sleep'),
      ('movie', 'Movie'),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _scene == scene.$1
                    ? const Color(0xFFE7B15A)
                    : const Color(0xFF1C2622),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                scene.$2,
                style: TextStyle(
                  color: _scene == scene.$1
                      ? const Color(0xFF1A140C)
                      : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _climate({required bool wide}) {
    final body = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Climate',
          style: TextStyle(color: Color(0xFFB7C4BC), fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          '${_temp.toStringAsFixed(0)}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _round(
              '−',
              () => setState(() => _temp -= 1),
              const Key('home-temp-down'),
            ),
            const SizedBox(width: 16),
            _round(
              '+',
              () => setState(() => _temp += 1),
              const Key('home-temp-up'),
            ),
          ],
        ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2622),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: wide ? 12 : 18, horizontal: 12),
        child: wide
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Climate',
                    style: TextStyle(color: Color(0xFFB7C4BC), fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_temp.toStringAsFixed(0)}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _round(
                    '−',
                    () => setState(() => _temp -= 1),
                    const Key('home-temp-down'),
                  ),
                  const SizedBox(width: 8),
                  _round(
                    '+',
                    () => setState(() => _temp += 1),
                    const Key('home-temp-up'),
                  ),
                ],
              )
            : body,
      ),
    );
  }

  Widget _round(String label, VoidCallback onTap, Key key) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE7B15A)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE7B15A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
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
        tileKey: const Key('home-lights'),
        onTap: () => setState(() => _lights = !_lights),
      ),
      _Tile(
        name: 'Front door',
        status: _locked ? 'Locked' : 'Open',
        icon: Icons.lock_outline,
        on: _locked,
        tileKey: const Key('home-lock'),
        onTap: () => setState(() => _locked = !_locked),
      ),
      _Tile(
        name: 'Garage',
        status: _garage ? 'Open' : 'Closed',
        icon: Icons.garage_outlined,
        on: _garage,
        tileKey: const Key('home-garage'),
        onTap: () => setState(() => _garage = !_garage),
      ),
      _Tile(
        name: 'Music',
        status: _music ? 'Playing' : 'Off',
        icon: Icons.music_note_outlined,
        on: _music,
        tileKey: const Key('home-music'),
        onTap: () => setState(() => _music = !_music),
      ),
      _Tile(
        name: 'Blinds',
        status: '${(100 * _blinds).round()}%',
        icon: Icons.blinds,
        on: _blinds > 0.05,
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
        tileKey: const Key('home-oven'),
        onTap: () => setState(() => _oven = !_oven),
      ),
      _Tile(
        name: 'Alarm',
        status: _alarm ? 'Armed' : 'Off',
        icon: Icons.shield_outlined,
        on: _alarm,
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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.name,
    required this.status,
    required this.icon,
    required this.on,
    required this.tileKey,
    required this.onTap,
  });

  final String name;
  final String status;
  final IconData icon;
  final bool on;
  final Key tileKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = on ? const Color(0xFF1A140C) : Colors.white;
    final wash = on ? const Color(0xFFE7B15A) : const Color(0xFF1C2622);
    return GestureDetector(
      key: tileKey,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: wash,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: ink, size: 22),
              const SizedBox(height: 6),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: on ? const Color(0xFF3A2E18) : const Color(0xFFB7C4BC),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
