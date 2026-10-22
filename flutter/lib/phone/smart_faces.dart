import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Selectable smart-home interfaces. Harbour Glass is drawn by the panel
/// itself; the other seven are the faces below.
class HomeFaceSpec {
  const HomeFaceSpec(this.id, this.name, this.desc, this.preview);

  final String id;
  final String name;
  final String desc;
  final List<Color> preview;
}

const kHomeFaces = <HomeFaceSpec>[
  HomeFaceSpec(
    'glass',
    'Harbour Glass',
    'Frosted panels over a harbour wash.',
    [Color(0xFF12343A), Color(0xFF071816)],
  ),
  HomeFaceSpec(
    'climate',
    'Wall Climate',
    'A temperature slider with four controls.',
    [Color(0xFF2A2926), Color(0xFF0E0E10)],
  ),
  HomeFaceSpec(
    'living',
    'Living Room',
    'Rooms, music, energy, and favourite devices.',
    [Color(0xFF1C3E62), Color(0xFF0C1424)],
  ),
  HomeFaceSpec(
    'board',
    'Night Board',
    'Scenes, lights, security, and cameras.',
    [Color(0xFF243656), Color(0xFF0E1524)],
  ),
  HomeFaceSpec('halo', 'Halo', 'Current and target temperature in a ring.', [
    Color(0xFF1C2838),
    Color(0xFF07080C),
  ]),
  HomeFaceSpec('orbit', 'Orbit', 'A gold ring with a control in each corner.', [
    Color(0xFF3A3428),
    Color(0xFF0C0C0C),
  ]),
  HomeFaceSpec('ivory', 'Ivory', 'The same ring on a light field.', [
    Color(0xFFF7F1E6),
    Color(0xFFE4D8C6),
  ]),
  HomeFaceSpec('linen', 'Linen', 'A pale climate slider and four controls.', [
    Color(0xFFFBF6EE),
    Color(0xFFE7DCCB),
  ]),
];

/// A known interface id, or Harbour Glass when the stored face is missing.
String homeFaceId(String raw) {
  for (final face in kHomeFaces) {
    if (face.id == raw) return raw;
  }
  return 'glass';
}

Color homeFaceFill(String id) {
  for (final face in kHomeFaces) {
    if (face.id == id && face.id != 'glass') return face.preview.last;
  }
  return const Color(0xFF071816);
}

/// Live controls shared by every face other than Harbour Glass.
class HomeChrome {
  const HomeChrome({
    required this.portrait,
    required this.clock24,
    required this.clock12,
    required this.outside,
    required this.temp,
    required this.lightsOn,
    required this.locked,
    required this.garageOpen,
    required this.musicOn,
    required this.alarmOn,
    required this.cameraOn,
    required this.lampOn,
    required this.scene,
    required this.label,
    required this.onLights,
    required this.onSecurity,
    required this.onMusic,
    required this.onCamera,
    required this.onLamp,
    required this.onGarage,
    required this.onScene,
    required this.onCycleScene,
    required this.onTemp,
    required this.onTempDelta,
    required this.onSettings,
  });

  final bool portrait;
  final String clock24;
  final String clock12;
  final String outside;
  final double temp;
  final bool lightsOn;
  final bool locked;
  final bool garageOpen;
  final bool musicOn;
  final bool alarmOn;
  final bool cameraOn;
  final bool lampOn;
  final String scene;
  final String Function(String id) label;
  final VoidCallback onLights;
  final VoidCallback onSecurity;
  final VoidCallback onMusic;
  final VoidCallback onCamera;
  final VoidCallback onLamp;
  final VoidCallback onGarage;
  final void Function(String scene) onScene;
  final VoidCallback onCycleScene;
  final ValueChanged<double> onTemp;
  final void Function(int delta) onTempDelta;
  final VoidCallback onSettings;

  int get lightLevel => lightsOn ? 70 : 0;

  String figureOf(double value) {
    final shown = value.toStringAsFixed(1);
    if (shown.endsWith('.0')) return value.round().toString();
    return shown;
  }

  String get figure => figureOf(temp);

  String get target => figureOf(temp + 1);

  /// A styled scene name, unless the panel was renamed in settings.
  String styledScene(String id, String fallback) {
    const defaults = {
      'home': 'Home',
      'away': 'Away',
      'sleep': 'Sleep',
      'movie': 'Movie',
    };
    final name = label(id);
    if (name == defaults[id]) return fallback;
    return name;
  }
}

Widget homeFace(String id, HomeChrome chrome) {
  return switch (id) {
    'living' => LivingFace(chrome: chrome),
    'board' => BoardFace(chrome: chrome),
    'halo' => HaloFace(chrome: chrome),
    'orbit' => OrbitFace(chrome: chrome, light: false),
    'ivory' => OrbitFace(chrome: chrome, light: true),
    'linen' => LinenFace(chrome: chrome),
    _ => ClimateFace(chrome: chrome),
  };
}

class ClimateFace extends StatelessWidget {
  const ClimateFace({super.key, required this.chrome});

  final HomeChrome chrome;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFFF4EFE8);
    const dim = Color(0xFFB7B1A8);
    final c = chrome;
    return Column(
      key: const Key('home-face-climate'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              c.clock24,
              style: const TextStyle(
                color: ink,
                fontSize: 40,
                fontWeight: FontWeight.w300,
                letterSpacing: -1,
              ),
            ),
            const Spacer(),
            const Icon(Icons.cloud_outlined, color: dim, size: 18),
            const SizedBox(width: 6),
            Text(c.outside, style: const TextStyle(color: dim, fontSize: 16)),
          ],
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'CLIMATE',
                style: TextStyle(
                  color: dim,
                  fontSize: 13,
                  letterSpacing: 3.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                child: Text(
                  '${c.figure}°',
                  style: const TextStyle(
                    color: ink,
                    fontSize: 92,
                    fontWeight: FontWeight.w300,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _TempSlider(
                value: c.temp,
                min: 16,
                max: 28,
                ink: dim,
                active: const Color(0xFFD9CBB8),
                idle: const Color(0xFF3A3834),
                thumb: const Color(0xFFE7D7C4),
                onChanged: c.onTemp,
              ),
            ],
          ),
        ),
        SizedBox(
          height: c.portrait ? 108 : 124,
          child: Row(
            children: [
              _Quad(
                buttonKey: const Key('home-lights'),
                icon: Icons.lightbulb_outline,
                label: c.label('lights'),
                on: c.lightsOn,
                onTap: c.onLights,
                ink: ink,
                fill: const Color(0xFF1A1A1C),
                line: const Color(0xFF3A3834),
              ),
              const SizedBox(width: 10),
              _Quad(
                buttonKey: const Key('home-security'),
                icon: Icons.shield_outlined,
                label: 'Security',
                on: c.alarmOn,
                onTap: c.onSecurity,
                ink: ink,
                fill: const Color(0xFF1A1A1C),
                line: const Color(0xFF3A3834),
              ),
              const SizedBox(width: 10),
              _Quad(
                buttonKey: const Key('home-scenes'),
                icon: Icons.hub_outlined,
                label: 'Scenes',
                on: c.scene != 'home',
                onTap: c.onCycleScene,
                ink: ink,
                fill: const Color(0xFF1A1A1C),
                line: const Color(0xFF3A3834),
              ),
              const SizedBox(width: 10),
              _Quad(
                buttonKey: const Key('home-music'),
                icon: Icons.play_circle_outline,
                label: 'Media',
                on: c.musicOn,
                onTap: c.onMusic,
                ink: ink,
                fill: const Color(0xFF1A1A1C),
                line: const Color(0xFF3A3834),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _IconNav(
          ink: dim,
          items: [
            (
              Icons.home_outlined,
              null,
              () => c.onScene('home'),
              const Key('home-scene-home'),
            ),
            (Icons.grid_view_rounded, null, c.onLights, null),
            (Icons.auto_awesome_outlined, null, c.onCycleScene, null),
            (
              Icons.settings_outlined,
              null,
              c.onSettings,
              const Key('home-settings'),
            ),
          ],
        ),
      ],
    );
  }
}

class LinenFace extends StatelessWidget {
  const LinenFace({super.key, required this.chrome});

  final HomeChrome chrome;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF3E362C);
    const dim = Color(0xFF8A7D6E);
    const card = Color(0xFFFBF7F1);
    const line = Color(0xFFE4D9C8);
    final c = chrome;
    final mode = c.temp >= 23 ? 'Heating' : 'Cooling';
    return Stack(
      key: const Key('home-face-linen'),
      children: [
        const Positioned.fill(child: CustomPaint(painter: _LinenLight())),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  c.clock12,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.wb_sunny_outlined, color: dim, size: 16),
                const SizedBox(width: 6),
                Text(
                  c.outside,
                  style: const TextStyle(color: dim, fontSize: 15),
                ),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'CLIMATE',
                    style: TextStyle(
                      color: dim,
                      fontSize: 12,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  FittedBox(
                    child: Text(
                      '${c.figure}°',
                      style: const TextStyle(
                        color: ink,
                        fontSize: 84,
                        fontWeight: FontWeight.w400,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TempSlider(
                    value: c.temp,
                    min: 18,
                    max: 26,
                    ink: dim,
                    active: const Color(0xFFC4A574),
                    idle: const Color(0xFFE4D3B8),
                    thumb: const Color(0xFFC4A574),
                    onChanged: c.onTemp,
                  ),
                  Text(
                    '$mode to ${c.figure}°',
                    style: const TextStyle(color: dim, fontSize: 13),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: c.portrait ? 108 : 118,
              child: Row(
                children: [
                  _Quad(
                    buttonKey: const Key('home-lights'),
                    icon: Icons.lightbulb_outline,
                    label: c.label('lights'),
                    on: c.lightsOn,
                    onTap: c.onLights,
                    ink: ink,
                    fill: card,
                    line: line,
                    accent: const Color(0xFFC4A574),
                  ),
                  const SizedBox(width: 10),
                  _Quad(
                    buttonKey: const Key('home-security'),
                    icon: Icons.verified_user_outlined,
                    label: 'Security',
                    on: c.alarmOn,
                    onTap: c.onSecurity,
                    ink: ink,
                    fill: card,
                    line: line,
                    accent: const Color(0xFFC4A574),
                  ),
                  const SizedBox(width: 10),
                  _Quad(
                    buttonKey: const Key('home-scenes'),
                    icon: Icons.home_outlined,
                    label: 'Scenes',
                    on: c.scene != 'home',
                    onTap: c.onCycleScene,
                    ink: ink,
                    fill: card,
                    line: line,
                    accent: const Color(0xFFC4A574),
                  ),
                  const SizedBox(width: 10),
                  _Quad(
                    buttonKey: const Key('home-music'),
                    icon: Icons.smart_display_outlined,
                    label: 'Media',
                    on: c.musicOn,
                    onTap: c.onMusic,
                    ink: ink,
                    fill: card,
                    line: line,
                    accent: const Color(0xFFC4A574),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: card.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: line),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  child: _IconNav(
                    ink: dim,
                    items: [
                      (
                        Icons.home_outlined,
                        null,
                        () => c.onScene('home'),
                        const Key('home-scene-home'),
                      ),
                      (Icons.tune, null, c.onTempUpQuiet, null),
                      (Icons.weekend_outlined, null, c.onCycleScene, null),
                      (
                        Icons.more_horiz,
                        null,
                        c.onSettings,
                        const Key('home-settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

extension on HomeChrome {
  void onTempUpQuiet() => onTempDelta(1);
}

class HaloFace extends StatelessWidget {
  const HaloFace({super.key, required this.chrome});

  final HomeChrome chrome;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFFF2F4F8);
    const dim = Color(0xFF9AA3B2);
    const card = Color(0xFF16181E);
    final c = chrome;
    return Column(
      key: const Key('home-face-halo'),
      children: [
        Row(
          children: [
            Text(
              c.clock24,
              style: const TextStyle(
                color: ink,
                fontSize: 28,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            const Icon(Icons.wb_cloudy_outlined, color: dim, size: 16),
            const SizedBox(width: 4),
            Text(c.outside, style: const TextStyle(color: dim, fontSize: 14)),
            const SizedBox(width: 16),
            const Icon(Icons.home_outlined, color: dim, size: 16),
            const SizedBox(width: 4),
            Text(
              c.styledScene('home', 'Home'),
              style: const TextStyle(color: ink, fontSize: 14),
            ),
            const Icon(Icons.chevron_right, color: dim, size: 18),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: c.portrait ? 96 : 108,
          child: Row(
            children: [
              _Quad(
                buttonKey: const Key('home-lights'),
                icon: Icons.lightbulb_outline,
                label: c.label('lights'),
                caption: 'All rooms',
                on: c.lightsOn,
                onTap: c.onLights,
                ink: ink,
                fill: card,
                line: const Color(0xFF2A2E38),
              ),
              const SizedBox(width: 10),
              _Quad(
                buttonKey: const Key('home-security'),
                icon: Icons.shield_outlined,
                label: 'Security',
                caption: c.alarmOn ? 'Armed' : 'Status + arm',
                on: c.alarmOn,
                onTap: c.onSecurity,
                ink: ink,
                fill: card,
                line: const Color(0xFF2A2E38),
              ),
              const SizedBox(width: 10),
              _Quad(
                buttonKey: const Key('home-scenes'),
                icon: Icons.auto_awesome_outlined,
                label: 'Scenes',
                caption: 'Quick access',
                on: c.scene != 'home',
                onTap: c.onCycleScene,
                ink: ink,
                fill: card,
                line: const Color(0xFF2A2E38),
              ),
              const SizedBox(width: 10),
              _Quad(
                buttonKey: const Key('home-music'),
                icon: Icons.smart_display_outlined,
                label: 'Media',
                caption: 'Play / pause',
                on: c.musicOn,
                onTap: c.onMusic,
                ink: ink,
                fill: card,
                line: const Color(0xFF2A2E38),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: _TempRing(
              figure: '${c.figure}°',
              caption: 'CURRENT',
              foot: 'TARGET\n${c.target}°',
              color: const Color(0xFF7EB6FF),
              ink: ink,
              dim: dim,
              onTap: () => c.onTempDelta(1),
              ringKey: const Key('home-temp-up'),
            ),
          ),
        ),
        _IconNav(
          ink: dim,
          items: [
            (
              Icons.grid_view_rounded,
              'Rooms',
              () => c.onScene('home'),
              const Key('home-scene-home'),
            ),
            (
              Icons.photo_camera_outlined,
              'Cameras',
              c.onCamera,
              const Key('home-camera'),
            ),
            (Icons.bolt_outlined, 'Energy', c.onLamp, null),
            (
              Icons.settings_outlined,
              'Settings',
              c.onSettings,
              const Key('home-settings'),
            ),
          ],
        ),
      ],
    );
  }
}

class OrbitFace extends StatelessWidget {
  const OrbitFace({super.key, required this.chrome, required this.light});

  final HomeChrome chrome;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final c = chrome;
    final ink = light ? const Color(0xFF4A433A) : const Color(0xFFE8E0D4);
    final dim = light ? const Color(0xFF9A8F82) : const Color(0xFF9A9186);
    final card = light ? const Color(0xFFF7F3EC) : const Color(0xFF1A1A1A);
    final line = light ? const Color(0xFFE6DDD0) : const Color(0xFF2E2E2E);
    final ring = light ? const Color(0xFFE4C98A) : const Color(0xFFC6B08A);
    return Column(
      key: Key(light ? 'home-face-ivory' : 'home-face-orbit'),
      children: [
        Row(
          children: [
            Text(
              c.clock12,
              style: TextStyle(
                color: dim,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.cloud_outlined, color: dim, size: 16),
            if (light) ...[
              const SizedBox(width: 6),
              Text(c.outside, style: TextStyle(color: dim, fontSize: 14)),
            ],
          ],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = math.min(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final ringSize = (side * (c.portrait ? 0.62 : 0.7)).clamp(
                160.0,
                340.0,
              );
              final button = c.portrait ? 78.0 : 92.0;
              return Stack(
                children: [
                  Center(
                    child: _TempRing(
                      figure: '${c.figure}°',
                      caption: '',
                      foot: 'Target ${c.target}°',
                      color: ring,
                      ink: ink,
                      dim: dim,
                      diameter: ringSize,
                      onTap: () => c.onTempDelta(1),
                      ringKey: const Key('home-temp-up'),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: _CornerButton(
                      buttonKey: const Key('home-lights'),
                      icon: Icons.lightbulb_outline,
                      label: c.label('lights'),
                      on: c.lightsOn,
                      onTap: c.onLights,
                      size: button,
                      ink: ink,
                      fill: card,
                      line: line,
                      accent: ring,
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: _CornerButton(
                      buttonKey: const Key('home-security'),
                      icon: light
                          ? Icons.verified_user_outlined
                          : Icons.lock_outline,
                      label: 'Security',
                      on: c.alarmOn,
                      onTap: c.onSecurity,
                      size: button,
                      ink: ink,
                      fill: card,
                      line: line,
                      accent: ring,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: _CornerButton(
                      buttonKey: const Key('home-scenes'),
                      icon: Icons.home_outlined,
                      label: 'Scenes',
                      on: c.scene != 'home',
                      onTap: c.onCycleScene,
                      size: button,
                      ink: ink,
                      fill: card,
                      line: line,
                      accent: ring,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: _CornerButton(
                      buttonKey: const Key('home-music'),
                      icon: Icons.play_circle_outline,
                      label: 'Media',
                      on: c.musicOn,
                      onTap: c.onMusic,
                      size: button,
                      ink: ink,
                      fill: card,
                      line: line,
                      accent: ring,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        _IconNav(
          ink: dim,
          items: [
            (
              light ? Icons.crop_square_outlined : Icons.grid_view_rounded,
              light ? 'Rooms' : null,
              () => c.onScene('home'),
              const Key('home-scene-home'),
            ),
            (
              Icons.photo_camera_outlined,
              light ? 'Cameras' : null,
              c.onCamera,
              const Key('home-camera'),
            ),
            (
              light ? Icons.energy_savings_leaf_outlined : Icons.bolt_outlined,
              light ? 'Energy' : null,
              c.onLamp,
              null,
            ),
            (
              Icons.settings_outlined,
              light ? 'Settings' : null,
              c.onSettings,
              const Key('home-settings'),
            ),
          ],
        ),
      ],
    );
  }
}

class BoardFace extends StatelessWidget {
  const BoardFace({super.key, required this.chrome});

  final HomeChrome chrome;

  @override
  Widget build(BuildContext context) {
    final c = chrome;
    const ink = Color(0xFFE8EEF8);
    const dim = Color(0xFF93A0B8);
    const card = Color(0xFF162033);
    const line = Color(0xFF2A3850);
    final scenes = [
      ('home', c.styledScene('home', 'Good Morning'), Icons.wb_sunny_outlined),
      ('away', c.styledScene('away', 'Away'), Icons.luggage_outlined),
      ('movie', c.styledScene('movie', 'Movie'), Icons.movie_outlined),
      ('sleep', c.styledScene('sleep', 'Sleep'), Icons.nightlight_outlined),
    ];
    final body = c.portrait
        ? ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              _sceneRow(c, scenes),
              const SizedBox(height: 8),
              SizedBox(
                height: 210,
                child: _climateCard(c, ink, dim, card, line),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 210,
                child: _lightsCard(c, ink, dim, card, line),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: _securityCard(c, ink, dim, card, line),
              ),
              const SizedBox(height: 8),
              SizedBox(height: 160, child: _mediaCard(c, ink, dim, card, line)),
              const SizedBox(height: 8),
              SizedBox(height: 180, child: _energyCard(ink, dim, card, line)),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: _cameraCard(c, ink, dim, card, line),
              ),
            ],
          )
        : Column(
            children: [
              _sceneRow(c, scenes),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _climateCard(c, ink, dim, card, line)),
                    const SizedBox(width: 8),
                    Expanded(child: _lightsCard(c, ink, dim, card, line)),
                    const SizedBox(width: 8),
                    Expanded(child: _securityCard(c, ink, dim, card, line)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _mediaCard(c, ink, dim, card, line)),
                    const SizedBox(width: 8),
                    Expanded(child: _energyCard(ink, dim, card, line)),
                    const SizedBox(width: 8),
                    Expanded(child: _cameraCard(c, ink, dim, card, line)),
                  ],
                ),
              ),
            ],
          );
    return Column(
      key: const Key('home-face-board'),
      children: [
        Row(
          children: [
            Text(
              c.clock24,
              style: const TextStyle(
                color: ink,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.wb_cloudy_outlined, color: dim, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${c.outside}  Partly cloudy',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: dim, fontSize: 12),
              ),
            ),
            _pill(
              c.alarmOn ? 'Armed Stay' : 'Disarmed',
              c.alarmOn ? const Color(0xFF3D7EFF) : line,
              c.onSecurity,
            ),
            const SizedBox(width: 10),
            const Icon(Icons.wifi, color: dim, size: 16),
            const SizedBox(width: 6),
            const Icon(Icons.battery_full, color: dim, size: 16),
            const SizedBox(width: 4),
            const Text('100%', style: TextStyle(color: dim, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(child: body),
        const SizedBox(height: 6),
        _IconNav(
          ink: dim,
          items: [
            (
              Icons.home_outlined,
              'Rooms',
              () => c.onScene('home'),
              const Key('home-scene-home'),
            ),
            (Icons.grid_view_rounded, 'Scenes', c.onCycleScene, null),
            (Icons.devices_outlined, 'Devices', c.onLamp, null),
            (
              Icons.settings_outlined,
              'Settings',
              c.onSettings,
              const Key('home-settings'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sceneRow(HomeChrome c, List<(String, String, IconData)> scenes) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          for (var i = 0; i < scenes.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                key: Key('home-scene-${scenes[i].$1}'),
                onTap: () => c.onScene(scenes[i].$1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.scene == scenes[i].$1
                        ? const Color(0xFF2F6FE0)
                        : const Color(0xFF1A2740),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(scenes[i].$3, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          scenes[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _climateCard(
    HomeChrome c,
    Color ink,
    Color dim,
    Color card,
    Color line,
  ) {
    return _Panel(
      fill: card,
      line: line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.thermostat, color: Color(0xFF8EB4FF), size: 16),
              const SizedBox(width: 6),
              Text(
                'Climate',
                style: TextStyle(color: ink, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _TempRing(
                    figure: '${c.figure}°C',
                    caption: '',
                    foot: 'Heating',
                    color: const Color(0xFF4C8DFF),
                    ink: ink,
                    dim: dim,
                    diameter: 120,
                    onTap: () => c.onTempDelta(1),
                    ringKey: const Key('home-temp-up'),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _roundKey(
                      Icons.add,
                      const Key('home-temp-board-up'),
                      () => c.onTempDelta(1),
                      ink,
                    ),
                    const SizedBox(height: 8),
                    Text('Up', style: TextStyle(color: dim, fontSize: 11)),
                    const SizedBox(height: 8),
                    _roundKey(
                      Icons.remove,
                      const Key('home-temp-down'),
                      () => c.onTempDelta(-1),
                      ink,
                    ),
                    const SizedBox(height: 8),
                    Text('Down', style: TextStyle(color: dim, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Text(
            'Set to ${c.figure}° · Auto',
            style: TextStyle(color: dim, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _lightsCard(
    HomeChrome c,
    Color ink,
    Color dim,
    Color card,
    Color line,
  ) {
    return _Panel(
      fill: card,
      line: line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            key: const Key('home-lights'),
            behavior: HitTestBehavior.opaque,
            onTap: c.onLights,
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: ink, size: 16),
                const SizedBox(width: 6),
                Text(
                  c.label('lights'),
                  style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Icon(Icons.expand_less, color: dim, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _level(
            'Living Room',
            c.lightLevel / 100,
            const Color(0xFF4C8DFF),
            ink,
            dim,
          ),
          _level(
            'Kitchen',
            c.lampOn ? 0.4 : 0,
            const Color(0xFFE7E1D6),
            ink,
            dim,
            onTap: c.onLamp,
          ),
          _level(
            'Bedroom',
            c.musicOn ? 0.2 : 0.2,
            const Color(0xFFB07CFF),
            ink,
            dim,
          ),
        ],
      ),
    );
  }

  Widget _securityCard(
    HomeChrome c,
    Color ink,
    Color dim,
    Color card,
    Color line,
  ) {
    return _Panel(
      fill: card,
      line: line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: ink, size: 16),
              const SizedBox(width: 6),
              Text(
                'Security',
                style: TextStyle(color: ink, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _door('Front Door', c.locked ? 'Closed' : 'Open', c.locked),
          _door('Back Door', 'Closed', true),
          _door('Living Room Window', 'Closed', true),
          _door(
            'Garage Door',
            c.garageOpen ? 'Open' : 'Closed',
            !c.garageOpen,
            onTap: c.onGarage,
          ),
          const Spacer(),
          GestureDetector(
            key: const Key('home-security'),
            onTap: c.onSecurity,
            child: Container(
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF2F6FE0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                c.alarmOn ? 'Armed Stay' : 'Arm stay',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaCard(
    HomeChrome c,
    Color ink,
    Color dim,
    Color card,
    Color line,
  ) {
    return _Panel(
      fill: card,
      line: line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle_outline, color: ink, size: 16),
              const SizedBox(width: 6),
              Text(
                'Media',
                style: TextStyle(color: ink, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2A3D66), Color(0xFF121826)],
                    ),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white70),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Harbour Lights',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Northline Quartet',
                        style: TextStyle(color: dim, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text('1:24', style: TextStyle(color: dim, fontSize: 11)),
              const SizedBox(width: 6),
              const Icon(Icons.skip_previous, color: Colors.white, size: 18),
              GestureDetector(
                key: const Key('home-music'),
                onTap: c.onMusic,
                child: Icon(
                  c.musicOn ? Icons.pause_circle : Icons.play_circle,
                  color: const Color(0xFF4C8DFF),
                  size: 28,
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text('3:12', style: TextStyle(color: dim, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _energyCard(Color ink, Color dim, Color card, Color line) {
    const heights = [0.35, 0.55, 0.4, 0.7, 0.5, 0.85, 0.62, 0.48];
    return _Panel(
      fill: card,
      line: line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: ink, size: 16),
              const SizedBox(width: 6),
              Text(
                'Energy',
                style: TextStyle(color: ink, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text("Today's usage", style: TextStyle(color: dim, fontSize: 11)),
          Row(
            children: [
              Text(
                '18.7 kWh',
                style: TextStyle(
                  color: ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '£3.56',
                style: TextStyle(
                  color: const Color(0xFF7DFFB2),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final h in heights)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FractionallySizedBox(
                        heightFactor: h,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFF4C8DFF),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraCard(
    HomeChrome c,
    Color ink,
    Color dim,
    Color card,
    Color line,
  ) {
    const names = ['Front Door', 'Driveway', 'Back Garden', 'Hallway'];
    return _Panel(
      fill: card,
      line: line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera_outlined, color: ink, size: 16),
              const SizedBox(width: 6),
              Text(
                'Cameras',
                style: TextStyle(color: ink, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.7,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < names.length; i++)
                  GestureDetector(
                    key: i == 0 ? const Key('home-camera') : null,
                    onTap: c.onCamera,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.lerp(
                              const Color(0xFF1C2A22),
                              const Color(0xFF0C1014),
                              i / 4,
                            )!,
                            const Color(0xFF101820),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 6,
                            top: 6,
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: c.cameraOn
                                        ? const Color(0xFFFF5A5A)
                                        : dim,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  names[i],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (c.cameraOn)
                            const Positioned(
                              right: 6,
                              bottom: 4,
                              child: Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _level(
    String name,
    double value,
    Color color,
    Color ink,
    Color dim, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.wb_sunny_outlined, color: dim, size: 14),
            const SizedBox(width: 6),
            SizedBox(
              width: 78,
              child: Text(name, style: TextStyle(color: ink, fontSize: 12)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: const Color(0xFF2A3344),
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(color: dim, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _door(String name, String state, bool closed, {VoidCallback? onTap}) {
    final color = closed ? const Color(0xFF3DDC97) : const Color(0xFFFFB020);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            const Icon(
              Icons.sensor_door_outlined,
              color: Color(0xFF93A0B8),
              size: 14,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(color: Color(0xFFE8EEF8), fontSize: 12),
              ),
            ),
            Text(
              state,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundKey(IconData icon, Key key, VoidCallback onTap, Color ink) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF243044),
        ),
        child: Icon(icon, color: ink, size: 18),
      ),
    );
  }

  Widget _pill(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LivingFace extends StatefulWidget {
  const LivingFace({super.key, required this.chrome});

  final HomeChrome chrome;

  @override
  State<LivingFace> createState() => _LivingFaceState();
}

class _LivingFaceState extends State<LivingFace> {
  int _room = 0;

  static const _rooms = [
    ('Living Room', Color(0xFF4C8DFF)),
    ('Kitchen', Color(0xFFF6C15B)),
    ('Master Bedroom', Color(0xFFB07CFF)),
    ('Kids Room', Color(0xFF3DDC97)),
    ('Garage', Color(0xFF79B4FF)),
    ('Outdoor', Color(0xFF7DFFB2)),
  ];

  @override
  Widget build(BuildContext context) {
    final c = widget.chrome;
    final rooms = [
      for (var i = 0; i < _rooms.length; i++) _roomTile(i),
      _roomTile(-1),
    ];
    if (c.portrait) {
      return Column(
        key: const Key('home-face-living'),
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final tile in rooms)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(width: 168, child: tile),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                Text(
                  _rooms[_room].$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Comfortable · ${c.figure}°',
                  style: const TextStyle(
                    color: Color(0xFF93A0B8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(height: 220, child: _hero(c)),
                const SizedBox(height: 8),
                SizedBox(height: 92, child: _music(c)),
                const SizedBox(height: 8),
                _scenes(c),
                const SizedBox(height: 8),
                _side(c),
              ],
            ),
          ),
        ],
      );
    }
    return Row(
      key: const Key('home-face-living'),
      children: [
        SizedBox(
          width: 168,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'SMART HOME',
                  style: TextStyle(
                    color: Color(0xFF93A0B8),
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final tile in rooms) ...[
                      tile,
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _rooms[_room].$1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Comfortable · ${c.figure}°',
                style: const TextStyle(color: Color(0xFF93A0B8)),
              ),
              const SizedBox(height: 8),
              Expanded(child: _hero(c)),
              const SizedBox(height: 8),
              SizedBox(height: 84, child: _music(c)),
              const SizedBox(height: 8),
              _scenes(c),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 210, child: SingleChildScrollView(child: _side(c))),
      ],
    );
  }

  Widget _roomTile(int index) {
    final settings = index < 0;
    final selected = index == _room;
    final name = settings ? 'Settings' : _rooms[index].$1;
    final dot = settings ? const Color(0xFF93A0B8) : _rooms[index].$2;
    return GestureDetector(
      key: settings ? const Key('home-settings') : null,
      onTap: () {
        if (settings) {
          widget.chrome.onSettings();
          return;
        }
        setState(() => _room = index);
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF16345C) : const Color(0xFF121A2A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF4C8DFF) : const Color(0xFF243044),
          ),
        ),
        child: Row(
          children: [
            Icon(
              settings ? Icons.settings_outlined : Icons.chair_outlined,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(HomeChrome c) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _DuskRoom()),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _glowDial(
                  '${c.lightLevel}%',
                  'Light',
                  c.onLights,
                  const Key('home-lights'),
                ),
                _glowDial(
                  '${c.figure}°',
                  'Thermostat',
                  () => c.onTempDelta(1),
                  const Key('home-temp-up'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowDial(String value, String caption, VoidCallback onTap, Key key) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 116,
        height: 116,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85),
            width: 3,
          ),
          color: Colors.black.withValues(alpha: 0.28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              caption,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _music(HomeChrome c) {
    return _Panel(
      fill: const Color(0xFF121A2A),
      line: const Color(0xFF243044),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF7A4E78), Color(0xFF1C3A4A)],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harbour Lights',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Northline Quartet',
                  style: TextStyle(color: Color(0xFF93A0B8), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('home-music'),
            onPressed: c.onMusic,
            icon: Icon(
              c.musicOn ? Icons.pause_circle : Icons.play_circle,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scenes(HomeChrome c) {
    final items = [
      ('home', c.styledScene('home', 'Relax'), Icons.spa_outlined),
      ('movie', c.styledScene('movie', 'Movie Time'), Icons.movie_outlined),
      (
        'sleep',
        c.styledScene('sleep', 'Good Night'),
        Icons.nightlight_outlined,
      ),
    ];
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  key: Key('home-scene-${item.$1}'),
                  onTap: () => c.onScene(item.$1),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.scene == item.$1
                          ? const Color(0xFF1E3A5C)
                          : const Color(0xFF121A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF243044)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.$3, color: const Color(0xFFC7B6FF), size: 16),
                        const SizedBox(height: 4),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _side(HomeChrome c) {
    return Column(
      children: [
        _infoCard(
          child: Row(
            children: [
              const Icon(
                Icons.wb_cloudy_outlined,
                color: Color(0xFFF6C15B),
                size: 28,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.outside,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Outside',
                    style: TextStyle(color: Color(0xFF93A0B8), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          key: const Key('home-security'),
          onTap: c.onSecurity,
          child: _infoCard(
            child: Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: c.alarmOn
                      ? const Color(0xFF3DDC97)
                      : const Color(0xFF93A0B8),
                  size: 28,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.alarmOn ? 'Armed' : 'Disarmed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      c.alarmOn ? 'System secure' : 'Tap to arm',
                      style: const TextStyle(
                        color: Color(0xFF93A0B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _infoCard(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Energy today',
                style: TextStyle(color: Color(0xFF93A0B8), fontSize: 12),
              ),
              Text(
                '12.4 kWh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '−8% vs yesterday',
                style: TextStyle(color: Color(0xFF3DDC97), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _infoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Favourite devices',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _deviceRow(
                'Ceiling lights',
                '${c.lightLevel}%',
                c.lightsOn,
                c.onLights,
                null,
              ),
              _deviceRow(
                'Floor lamp',
                c.lampOn ? '35%' : 'Off',
                c.lampOn,
                c.onLamp,
                const Key('home-blinds'),
              ),
              _deviceRow(
                'Sound',
                c.musicOn ? 'On' : 'Off',
                c.musicOn,
                c.onMusic,
                null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _deviceRow(
    String name,
    String value,
    bool on,
    VoidCallback onTap,
    Key? key,
  ) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(color: Color(0xFFD5DEEE), fontSize: 12),
              ),
            ),
            Text(
              value,
              style: const TextStyle(color: Color(0xFF93A0B8), fontSize: 12),
            ),
            const SizedBox(width: 6),
            Icon(
              on ? Icons.toggle_on : Icons.toggle_off,
              color: on ? const Color(0xFF4C8DFF) : const Color(0xFF93A0B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required Widget child}) {
    return _Panel(
      fill: const Color(0xFF121A2A),
      line: const Color(0xFF243044),
      child: child,
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.fill, required this.line, required this.child});

  final Color fill;
  final Color line;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
      child: Padding(padding: const EdgeInsets.all(10), child: child),
    );
  }
}

class _Quad extends StatelessWidget {
  const _Quad({
    required this.icon,
    required this.label,
    required this.on,
    required this.onTap,
    required this.ink,
    required this.fill,
    required this.line,
    this.caption,
    this.accent,
    this.buttonKey,
  });

  final IconData icon;
  final String label;
  final String? caption;
  final bool on;
  final VoidCallback onTap;
  final Color ink;
  final Color fill;
  final Color line;
  final Color? accent;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final mark = on ? (accent ?? ink) : ink.withValues(alpha: 0.9);
    return Expanded(
      child: GestureDetector(
        key: buttonKey,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: on ? (accent ?? line) : line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: mark, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.55),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerButton extends StatelessWidget {
  const _CornerButton({
    required this.icon,
    required this.label,
    required this.on,
    required this.onTap,
    required this.size,
    required this.ink,
    required this.fill,
    required this.line,
    required this.accent,
    this.buttonKey,
  });

  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;
  final double size;
  final Color ink;
  final Color fill;
  final Color line;
  final Color accent;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: buttonKey,
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: on ? accent : line),
              ),
              child: Icon(icon, color: on ? accent : ink, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: ink.withValues(alpha: 0.8), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconNav extends StatelessWidget {
  const _IconNav({required this.ink, required this.items});

  final Color ink;
  final List<(IconData, String?, VoidCallback, Key?)> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: items.any((item) => item.$2 != null) ? 52 : 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final item in items)
            GestureDetector(
              key: item.$4,
              onTap: item.$3,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$1, color: ink, size: 20),
                    if (item.$2 != null)
                      Text(
                        item.$2!,
                        style: TextStyle(color: ink, fontSize: 10),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TempSlider extends StatelessWidget {
  const _TempSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.ink,
    required this.active,
    required this.idle,
    required this.thumb,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final Color ink;
  final Color active;
  final Color idle;
  final Color thumb;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('${min.round()}°', style: TextStyle(color: ink, fontSize: 12)),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              activeTrackColor: active,
              inactiveTrackColor: idle,
              thumbColor: thumb,
              overlayColor: Colors.transparent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              min: min,
              max: max,
              value: value.clamp(min, max),
              onChanged: onChanged,
            ),
          ),
        ),
        Text('${max.round()}°', style: TextStyle(color: ink, fontSize: 12)),
      ],
    );
  }
}

class _TempRing extends StatelessWidget {
  const _TempRing({
    required this.figure,
    required this.caption,
    required this.foot,
    required this.color,
    required this.ink,
    required this.dim,
    required this.onTap,
    required this.ringKey,
    this.diameter = 220,
  });

  final String figure;
  final String caption;
  final String foot;
  final Color color;
  final Color ink;
  final Color dim;
  final VoidCallback onTap;
  final Key ringKey;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ringKey,
      onTap: onTap,
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: CustomPaint(
          painter: _RingPainter(color),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (caption.isNotEmpty)
                Text(
                  caption,
                  style: TextStyle(
                    color: dim,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
              Text(
                figure,
                style: TextStyle(
                  color: ink,
                  fontSize: diameter < 150 ? 28 : 48,
                  fontWeight: FontWeight.w400,
                  height: 1.05,
                ),
              ),
              Text(
                foot,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: dim,
                  fontSize: diameter < 150 ? 11 : 13,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2 - 6;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.15),
          color,
          color.withValues(alpha: 0.15),
        ],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LinenLight extends CustomPainter {
  const _LinenLight();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x18C4A574)
      ..strokeWidth = size.height * 0.18
      ..style = PaintingStyle.stroke;
    for (var i = -1; i < 4; i++) {
      final y = size.height * (0.15 + i * 0.28);
      canvas.drawLine(
        Offset(-20, y),
        Offset(size.width + 20, y - size.height * 0.12),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DuskRoom extends CustomPainter {
  const _DuskRoom();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B3358), Color(0xFF0E1830), Color(0xFF1A140F)],
        ).createShader(rect),
    );
    final window = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.08,
      size.width * 0.64,
      size.height * 0.42,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(window, const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8AA4C8), Color(0xFF2C4A6E)],
        ).createShader(window),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.12,
          size.height * 0.52,
          size.width * 0.76,
          size.height * 0.28,
        ),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xFF243044),
    );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.38),
      size.shortestSide * 0.08,
      Paint()..color = const Color(0x66F6C15B),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
