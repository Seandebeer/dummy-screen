import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Current Mac desktop: menu bar, dune wallpaper, files on the right, and a dock.
class MacDesktop extends StatefulWidget {
  const MacDesktop({
    super.key,
    required this.appTitle,
    required this.tool,
    required this.onOpen,
    required this.onShell,
    required this.shells,
  });

  final String? appTitle;
  final Widget? tool;
  final ValueChanged<String?> onOpen;
  final ValueChanged<String> onShell;
  final List<(String, String)> shells;

  @override
  State<MacDesktop> createState() => _MacDesktopState();
}

class _MacDesktopState extends State<MacDesktop> {
  String? _folder;
  bool _trash = false;

  static const _folders = [
    ('Documents', _MacFile.page),
    ('Images', _MacFile.image),
    ('Movies', _MacFile.film),
    ('Presentations', _MacFile.slides),
    ('Spreadsheets', _MacFile.sheet),
    ('Work', _MacFile.folder),
    ('Projects', _MacFile.folder),
  ];

  static const _dock = [
    ('call', 'Call', Icons.video_call, Color(0xFF3DDC97)),
    ('tracking', 'Tracking', Icons.center_focus_strong, Color(0xFF5B8DEF)),
    ('markers', 'UI Markers', Icons.grid_on, Color(0xFF7A6FF0)),
    ('video', 'Video', Icons.movie, Color(0xFFE25B5B)),
    ('word', 'Word', Icons.description, Color(0xFF4C8DFF)),
    ('excel', 'Excel', Icons.table_chart, Color(0xFF3EAF6A)),
    ('terminal', 'Terminal', Icons.terminal, Color(0xFF2C2C2E)),
    ('social', 'Social', Icons.forum, Color(0xFF5AC8FA)),
    ('photos', 'Photos', Icons.photo_library, Color(0xFFFFB340)),
    ('music', 'Music', Icons.library_music, Color(0xFFFF375F)),
  ];

  void _openFolder(String name) {
    setState(() {
      _folder = name;
      _trash = false;
    });
    widget.onOpen(null);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final day = const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][now.weekday - 1];
    final clock = '$day $hour:$minute ${now.hour < 12 ? 'AM' : 'PM'}';
    return Stack(
      key: const Key('mac-desktop'),
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _Dunes()),
        Column(
          children: [
            _menu(clock),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final slot = constraints.maxHeight / _folders.length;
                  final glyph = (slot * 0.58).clamp(26.0, 48.0);
                  return Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, right: 14),
                      child: Column(
                        children: [
                          for (final folder in _folders)
                            _DesktopFile(
                              name: folder.$1,
                              kind: folder.$2,
                              glyph: glyph,
                              onTap: () => _openFolder(folder.$1),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _dockBar(),
          ],
        ),
        if (_folder != null)
          Center(
            child: _MacWindow(
              title: _folder!,
              onClose: () => setState(() => _folder = null),
              child: _FolderBody(name: _folder!),
            ),
          ),
        if (_trash)
          Center(
            child: _MacWindow(
              title: 'Trash',
              onClose: () => setState(() => _trash = false),
              child: const Center(
                child: Text(
                  'Trash is empty.',
                  style: TextStyle(color: Color(0xFF3A3A3C)),
                ),
              ),
            ),
          ),
        if (widget.tool != null)
          Center(
            child: _MacWindow(
              title: widget.appTitle ?? '',
              onClose: () => widget.onOpen(null),
              child: widget.tool!,
            ),
          ),
      ],
    );
  }

  Widget _menu(String clock) {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
    return Container(
      key: const Key('mac-menu'),
      height: 26,
      color: const Color(0x8C101418),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 860,
          child: Row(
            children: [
              const Icon(Icons.apple, color: Colors.white, size: 14),
              const SizedBox(width: 12),
              const Text(
                'Finder',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              for (final item in const [
                'File',
                'Edit',
                'View',
                'Go',
                'Window',
                'Help',
              ])
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Text(item, style: style),
                ),
              const Spacer(),
              const Icon(Icons.wifi, color: Colors.white, size: 14),
              const SizedBox(width: 10),
              const Icon(Icons.battery_full, color: Colors.white, size: 15),
              const SizedBox(width: 8),
              Text(clock, style: style),
              const SizedBox(width: 10),
              const Icon(Icons.search, color: Colors.white, size: 15),
              PopupMenuButton<String>(
                tooltip: 'System',
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.settings, color: Colors.white, size: 14),
                onSelected: widget.onShell,
                itemBuilder: (context) => [
                  for (final item in widget.shells)
                    PopupMenuItem(value: item.$1, child: Text(item.$2)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dockBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x66101418),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final app in _dock) ...[
                        _DockTile(
                          label: app.$2,
                          icon: app.$3,
                          color: app.$4,
                          tileKey: Key('mac-dock-${app.$1}'),
                          onTap: () {
                            setState(() {
                              _folder = null;
                              _trash = false;
                            });
                            widget.onOpen(app.$1);
                          },
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                      const SizedBox(width: 6),
                      _DockTile(
                        label: 'Trash',
                        icon: Icons.delete_outline,
                        color: const Color(0xFF8E8E93),
                        tileKey: const Key('mac-trash'),
                        onTap: () {
                          widget.onOpen(null);
                          setState(() {
                            _folder = null;
                            _trash = true;
                          });
                        },
                      ),
                    ],
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

class _DesktopFile extends StatelessWidget {
  const _DesktopFile({
    required this.name,
    required this.kind,
    required this.glyph,
    required this.onTap,
  });

  final String name;
  final _MacFile kind;
  final double glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('mac-file-$name'),
      onTap: onTap,
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            _MacGlyph(kind: kind, size: glyph),
            const SizedBox(height: 3),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(color: Color(0xAA000000), blurRadius: 3)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MacFile { page, image, film, slides, sheet, folder }

class _MacGlyph extends StatelessWidget {
  const _MacGlyph({required this.kind, required this.size});

  final _MacFile kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (kind == _MacFile.folder) {
      final tab = size * 0.42;
      return SizedBox(
        width: size,
        height: size,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: tab,
              height: size * 0.14,
              decoration: const BoxDecoration(
                color: Color(0xFF6CB4F0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
            Container(
              width: size,
              height: size * 0.62,
              decoration: BoxDecoration(
                color: const Color(0xFF4AA3EA),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: size * 0.78,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _pageArt(kind),
    );
  }

  Widget _pageArt(_MacFile kind) {
    switch (kind) {
      case _MacFile.image:
        return const Column(
          children: [
            Expanded(flex: 2, child: ColoredBox(color: Color(0xFFE25B5B))),
            Expanded(flex: 3, child: ColoredBox(color: Colors.white)),
          ],
        );
      case _MacFile.film:
        return const ColoredBox(
          color: Color(0xFF1C1C1E),
          child: Center(
            child: Icon(Icons.movie, color: Colors.white, size: 16),
          ),
        );
      case _MacFile.slides:
        return const Padding(
          padding: EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ColoredBox(
                color: Color(0xFFFF9F0A),
                child: SizedBox(height: 6, width: double.infinity),
              ),
              SizedBox(height: 3),
              ColoredBox(
                color: Color(0xFF64D2FF),
                child: SizedBox(height: 10, width: double.infinity),
              ),
            ],
          ),
        );
      case _MacFile.sheet:
        return Column(
          children: [
            for (var row = 0; row < 4; row++)
              Expanded(
                child: Row(
                  children: [
                    for (var col = 0; col < 3; col++)
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFD1E7D6)),
                            color: const Color(0xFFF4FFF6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      case _MacFile.page:
      case _MacFile.folder:
        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
          child: Column(
            children: [
              for (var line = 0; line < 4; line++)
                Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 3),
                  color: const Color(0xFFD1D1D6),
                ),
            ],
          ),
        );
    }
  }
}

class _DockTile extends StatelessWidget {
  const _DockTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.tileKey,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Key tileKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        key: tileKey,
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _MacWindow extends StatelessWidget {
  const _MacWindow({
    required this.title,
    required this.child,
    required this.onClose,
  });

  final String title;
  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460, maxHeight: 280),
      child: Material(
        color: const Color(0xFFF5F5F7),
        elevation: 16,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 32,
              color: const Color(0xFFE6E6EA),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  GestureDetector(
                    key: const Key('mac-window-close'),
                    onTap: onClose,
                    child: const _Light(Color(0xFFFF5F57)),
                  ),
                  const SizedBox(width: 6),
                  const _Light(Color(0xFFFEBC2E)),
                  const SizedBox(width: 6),
                  const _Light(Color(0xFF28C840)),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1C1C1E),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _Light extends StatelessWidget {
  const _Light(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FolderBody extends StatelessWidget {
  const _FolderBody({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final files = switch (name) {
      'Images' => const ['Dune still.jpg', 'Set photo.jpg'],
      'Movies' => const ['Scene 12.mov', 'Pickup.mov'],
      'Presentations' => const ['Call sheet.key'],
      'Spreadsheets' => const ['Budget.xlsx'],
      'Work' => const ['Notes.txt', 'Sides.pdf'],
      'Projects' => const ['Night Run', 'Harbor'],
      _ => const ['Scene 47.txt', 'Sides.pdf'],
    };
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 6),
      children: [
        for (final file in files)
          ListTile(
            dense: true,
            leading: const Icon(Icons.insert_drive_file_outlined, size: 18),
            title: Text(file, style: const TextStyle(fontSize: 13)),
          ),
      ],
    );
  }
}

class _Dunes extends CustomPainter {
  const _Dunes();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF07111F), Color(0xFF16304F), Color(0xFF1C3A5C)],
        ).createShader(rect),
    );
    final star = Paint()..color = const Color(0x99FFFFFF);
    const stars = <(double, double, double)>[
      (0.08, 0.06, 1.1),
      (0.16, 0.14, 0.7),
      (0.28, 0.05, 0.8),
      (0.41, 0.11, 1.2),
      (0.55, 0.07, 0.6),
      (0.67, 0.15, 0.9),
      (0.78, 0.04, 0.7),
      (0.9, 0.1, 1.0),
      (0.33, 0.18, 0.5),
      (0.62, 0.2, 0.6),
    ];
    for (final item in stars) {
      canvas.drawCircle(
        Offset(size.width * item.$1, size.height * item.$2),
        item.$3,
        star,
      );
    }
    _dune(canvas, size, 0.46, 0.09, const Color(0xFF152C48), 0.15);
    _dune(canvas, size, 0.58, 0.11, const Color(0xFF1E3D5E), 0.85);
    _ridge(canvas, size, 0.58, 0.11, 0.85);
    _dune(canvas, size, 0.74, 0.08, const Color(0xFF2A4E72), 1.35);
    _dune(canvas, size, 0.9, 0.05, const Color(0xFF3C6486), 0.4);
  }

  void _dune(
    Canvas canvas,
    Size size,
    double origin,
    double amplitude,
    Color color,
    double phase,
  ) {
    final path = Path()..moveTo(0, size.height);
    final y = size.height * origin;
    path.lineTo(0, y);
    for (var x = 0.0; x <= size.width; x += 6) {
      final t = x / size.width;
      final wave =
          math.sin((t * 2.4 + phase) * math.pi) * size.height * amplitude +
          math.sin((t * 1.1 + phase * 0.6) * math.pi) *
              size.height *
              amplitude *
              0.28;
      path.lineTo(x, y + wave);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _ridge(
    Canvas canvas,
    Size size,
    double origin,
    double amplitude,
    double phase,
  ) {
    final path = Path();
    final y = size.height * origin;
    for (var x = 0.0; x <= size.width; x += 6) {
      final t = x / size.width;
      final wave =
          math.sin((t * 2.4 + phase) * math.pi) * size.height * amplitude +
          math.sin((t * 1.1 + phase * 0.6) * math.pi) *
              size.height *
              amplitude *
              0.28;
      if (x == 0) {
        path.moveTo(x, y + wave);
      } else {
        path.lineTo(x, y + wave);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x66D5E4F2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _Dunes oldDelegate) => false;
}
