import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../theme.dart';
import 'control_page.dart';
import 'home_page.dart';
import 'markers_page.dart';
import 'os_page.dart';
import 'vfx_page.dart';
import 'videos_page.dart';

class _NavItem {
  const _NavItem(this.id, this.label, this.icon, this.index);

  final String id;
  final String label;
  final IconData icon;
  final int index;
}

const _items = [
  _NavItem('home', 'Home', Icons.home_outlined, 0),
  _NavItem('os', 'OS', Icons.smartphone_outlined, 1),
  _NavItem('screens', 'Screens', Icons.crop_square, 2),
  _NavItem('markers', 'Markers', Icons.grid_on, 3),
  _NavItem('playback', 'Playback', Icons.play_circle_outline, 4),
  _NavItem('control', 'Control', Icons.settings_remote, 5),
];

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  bool _hint = false;
  bool _wasFilming = false;
  Timer? _hintTimer;

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _armHint() {
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _hint = false);
    });
  }

  Widget _page(int index) {
    switch (index) {
      case 1:
        return const OsPage();
      case 2:
        return const VfxPage();
      case 3:
        return const MarkersPage();
      case 4:
        return const VideosPage();
      case 5:
        return const ControlPage();
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    if (store.filming && !_wasFilming) {
      _wasFilming = true;
      _hint = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _armHint();
      });
    } else if (!store.filming && _wasFilming) {
      _wasFilming = false;
      _hint = false;
      _hintTimer?.cancel();
    }

    final page = _page(store.lastTab.clamp(0, 5));
    if (store.filming) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyL): () =>
                store.setFilming(false),
          },
          child: Focus(
            autofocus: true,
            child: Stack(
              children: [
                page,
                if (_hint)
                  const Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Text(
                        'Three-finger tap or L unlocks',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final nav = _NavRail(vertical: wide);
          final body = SafeArea(
            child: wide
                ? Row(
                    children: [
                      nav,
                      Expanded(child: page),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(child: page),
                      nav,
                    ],
                  ),
          );
          return body;
        },
      ),
    );
  }
}

class _NavRail extends StatelessWidget {
  const _NavRail({required this.vertical});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final buttons = [
      for (final item in _items)
        _NavButton(
          key: Key('nav-${item.id}'),
          label: item.label,
          icon: item.icon,
          selected: store.lastTab == item.index,
          onTap: () => store.openTab(item.index),
        ),
    ];
    if (vertical) {
      return Material(
        color: kSurface,
        child: SizedBox(
          width: 96,
          child: Column(
            children: [
              const SizedBox(height: 18),
              const Text(
                'D',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kAccent,
                ),
              ),
              const SizedBox(height: 12),
              ...buttons,
            ],
          ),
        ),
      );
    }
    return Material(
      color: kSurface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [for (final button in buttons) Expanded(child: button)],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? kAccent : kMuted;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            FittedBox(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
