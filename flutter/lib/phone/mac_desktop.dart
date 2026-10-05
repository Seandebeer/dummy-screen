import 'dart:ui';

import 'package:flutter/material.dart';

/// macOS desktop matched to the night-dune layout: a full-width menu bar,
/// one moonlit dune, a compact file column, and a shelf dock.
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
    'call',
    'tracking',
    'markers',
    'video',
    'word',
    'excel',
    'terminal',
    'social',
    'photos',
    'music',
  ];

  static const _labels = {
    'call': 'Call',
    'tracking': 'Tracking',
    'markers': 'UI Markers',
    'video': 'Video',
    'word': 'Word',
    'excel': 'Excel',
    'terminal': 'Terminal',
    'social': 'Social',
    'photos': 'Photos',
    'music': 'Music',
  };

  void _openFolder(String name) {
    setState(() {
      _folder = name;
      _trash = false;
    });
    widget.onOpen(null);
  }

  void _openApp(String id) {
    setState(() {
      _folder = null;
      _trash = false;
    });
    widget.onOpen(id);
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
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        key: const Key('mac-desktop'),
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _Dunes(), child: SizedBox.expand()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _menu(clock),
              Expanded(child: _files()),
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
      ),
    );
  }

  Widget _files() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const block = 64.0;
        final gaps = _folders.length - 1;
        final free = constraints.maxHeight - 12 - block * _folders.length;
        final gap = gaps == 0 ? 0.0 : (free / gaps).clamp(12.0, 30.0);
        return Padding(
          padding: const EdgeInsets.only(top: 8, right: 18),
          child: Align(
            alignment: Alignment.topRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _folders.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == _folders.length - 1 ? 0 : gap,
                      ),
                      child: _DesktopFile(
                        name: _folders[i].$1,
                        kind: _folders[i].$2,
                        onTap: () => _openFolder(_folders[i].$1),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _menu(String clock) {
    const itemStyle = TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1,
    );
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          key: const Key('mac-menu'),
          decoration: const BoxDecoration(color: Color(0xC0121418)),
          child: SizedBox(
            height: 24,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Icon(Icons.apple, color: Colors.white, size: 15),
                  const SizedBox(width: 14),
                  const Text(
                    'Finder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: const SizedBox(
                        height: 24,
                        child: Row(
                          children: [
                            _MenuItem('File'),
                            _MenuItem('Edit'),
                            _MenuItem('View'),
                            _MenuItem('Go'),
                            _MenuItem('Window'),
                            _MenuItem('Help'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const CustomPaint(
                    size: Size(15, 12),
                    painter: _WifiPainter(),
                  ),
                  const SizedBox(width: 8),
                  const CustomPaint(
                    size: Size(23, 11),
                    painter: _BatteryPainter(),
                  ),
                  const SizedBox(width: 8),
                  Text(clock, style: itemStyle.copyWith(fontSize: 12)),
                  const SizedBox(width: 8),
                  const Icon(Icons.search, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
                    tooltip: 'Control Center',
                    padding: EdgeInsets.zero,
                    splashRadius: 12,
                    offset: const Offset(0, 18),
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: WidgetStatePropertyAll(EdgeInsets.zero),
                      minimumSize: WidgetStatePropertyAll(Size(18, 18)),
                    ),
                    onSelected: widget.onShell,
                    itemBuilder: (context) => [
                      for (final item in widget.shells)
                        PopupMenuItem(value: item.$1, child: Text(item.$2)),
                    ],
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CustomPaint(painter: _ControlPainter()),
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

  Widget _dockBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 5),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x66404448),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x28FFFFFF)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final id in _dock)
                      _DockButton(
                        label: _labels[id]!,
                        tileKey: Key('mac-dock-$id'),
                        onTap: () => _openApp(id),
                        child: CustomPaint(
                          painter: _DockGlyph(id),
                          size: const Size(36, 36),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 28,
                      color: const Color(0x66FFFFFF),
                    ),
                    const SizedBox(width: 8),
                    _DockButton(
                      label: 'Downloads',
                      tileKey: const Key('mac-dock-folder'),
                      onTap: () => _openFolder('Downloads'),
                      child: const CustomPaint(
                        painter: _FolderPainter(),
                        size: Size(34, 28),
                      ),
                    ),
                    _DockButton(
                      label: 'Trash',
                      tileKey: const Key('mac-trash'),
                      onTap: () {
                        widget.onOpen(null);
                        setState(() {
                          _folder = null;
                          _trash = true;
                        });
                      },
                      child: const CustomPaint(
                        painter: _TrashPainter(),
                        size: Size(28, 32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1,
        ),
      ),
    );
  }
}

class _DesktopFile extends StatelessWidget {
  const _DesktopFile({
    required this.name,
    required this.kind,
    required this.onTap,
  });

  final String name;
  final _MacFile kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('mac-file-$name'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 108,
        child: Column(
          children: [
            SizedBox(
              width: 52,
              height: 46,
              child: CustomPaint(painter: _FilePainter(kind)),
            ),
            const SizedBox(height: 3),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                height: 1.1,
                shadows: [Shadow(color: Color(0xE6000000), blurRadius: 3)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MacFile { page, image, film, slides, sheet, folder }

class _FilePainter extends CustomPainter {
  const _FilePainter(this.kind);

  final _MacFile kind;

  @override
  void paint(Canvas canvas, Size size) {
    if (kind == _MacFile.folder) {
      _FolderPainter().paint(canvas, size);
      return;
    }
    if (kind == _MacFile.film) {
      _film(canvas, size);
      return;
    }
    _page(canvas, size);
  }

  void _page(Canvas canvas, Size size) {
    final width = size.width * 0.72;
    final height = size.height * 0.96;
    final left = (size.width - width) / 2;
    final top = size.height - height;
    final rect = Rect.fromLTWH(left, top, width, height);
    final page = RRect.fromRectAndRadius(rect, Radius.circular(width * 0.08));
    canvas.drawRRect(
      page.shift(const Offset(0, 1.5)),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawRRect(page, Paint()..color = Colors.white);
    final ear = width * 0.32;
    final fold = Path()
      ..moveTo(rect.right - ear, rect.top)
      ..lineTo(rect.right, rect.top + ear)
      ..lineTo(rect.right - ear, rect.top + ear)
      ..close();
    canvas.save();
    canvas.clipRRect(page);
    canvas.drawPath(fold, Paint()..color = const Color(0xFFE4E6EA));
    canvas.drawLine(
      Offset(rect.right - ear, rect.top),
      Offset(rect.right, rect.top + ear),
      Paint()
        ..color = const Color(0xFFC8CCD2)
        ..strokeWidth = 0.8,
    );
    switch (kind) {
      case _MacFile.image:
        _photo(canvas, rect, ear);
      case _MacFile.slides:
        _slides(canvas, rect, ear);
      case _MacFile.sheet:
        _sheet(canvas, rect, ear);
      case _MacFile.page:
      case _MacFile.film:
      case _MacFile.folder:
        _lines(canvas, rect, ear);
    }
    canvas.restore();
  }

  void _lines(Canvas canvas, Rect rect, double ear) {
    final paint = Paint()..color = const Color(0xFF7EAEF0);
    var y = rect.top + ear * 0.85;
    final widths = [0.72, 0.86, 0.64, 0.8, 0.5];
    for (final factor in widths) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left + 4, y, (rect.width - 8) * factor, 2.2),
          const Radius.circular(1),
        ),
        paint,
      );
      y += 5.2;
    }
  }

  void _photo(Canvas canvas, Rect rect, double ear) {
    final photo = Rect.fromLTRB(
      rect.left + 3,
      rect.top + ear * 0.72,
      rect.right - 3,
      rect.bottom - 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(photo, const Radius.circular(1.5)),
      Paint()..color = const Color(0xFFE15B55),
    );
    canvas.drawCircle(
      Offset(photo.left + photo.width * 0.28, photo.top + photo.height * 0.32),
      photo.width * 0.12,
      Paint()..color = const Color(0xFFF3C7A2),
    );
    final hill = Path()
      ..moveTo(photo.left, photo.bottom)
      ..lineTo(photo.left + photo.width * 0.35, photo.top + photo.height * 0.55)
      ..lineTo(photo.left + photo.width * 0.62, photo.bottom)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFF8E2E32));
  }

  void _slides(Canvas canvas, Rect rect, double ear) {
    final slide = Rect.fromLTRB(
      rect.left + 3,
      rect.top + ear * 0.7,
      rect.right - 3,
      rect.bottom - 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(slide, const Radius.circular(1.5)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7C56B), Color(0xFFE8883A)],
        ).createShader(slide),
    );
    final bars = [0.35, 0.62, 0.48];
    final colors = [
      const Color(0xFFFFFFFF),
      const Color(0xFF7EC8F0),
      const Color(0xFFFFFFFF),
    ];
    for (var i = 0; i < bars.length; i++) {
      final bar = Rect.fromLTWH(
        slide.left + 4 + i * 8,
        slide.bottom - 4 - slide.height * bars[i] * 0.55,
        5,
        slide.height * bars[i] * 0.55,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bar, const Radius.circular(1)),
        Paint()..color = colors[i],
      );
    }
  }

  void _sheet(Canvas canvas, Rect rect, double ear) {
    final grid = Rect.fromLTRB(
      rect.left + 3,
      rect.top + ear * 0.7,
      rect.right - 3,
      rect.bottom - 3,
    );
    canvas.drawRect(grid, Paint()..color = const Color(0xFFF4FBF6));
    canvas.drawRect(
      Rect.fromLTWH(grid.left, grid.top, grid.width, grid.height * 0.22),
      Paint()..color = const Color(0xFFB7E2C4),
    );
    final line = Paint()
      ..color = const Color(0xFFC5DECC)
      ..strokeWidth = 0.7;
    for (var i = 1; i < 4; i++) {
      final y = grid.top + grid.height * i / 4;
      canvas.drawLine(Offset(grid.left, y), Offset(grid.right, y), line);
    }
    for (var i = 1; i < 3; i++) {
      final x = grid.left + grid.width * i / 3;
      canvas.drawLine(Offset(x, grid.top), Offset(x, grid.bottom), line);
    }
  }

  void _film(Canvas canvas, Size size) {
    final width = size.width * 0.7;
    final height = size.height * 0.92;
    final left = (size.width - width) / 2;
    final top = size.height - height;
    final rect = Rect.fromLTWH(left, top, width, height);
    final body = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    canvas.drawRRect(
      body.shift(const Offset(0, 1.5)),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF1C1C1E));
    final hole = Paint()..color = const Color(0xFFE6E6EA);
    for (var i = 0; i < 4; i++) {
      final y = rect.top + 5 + i * (rect.height - 8) / 4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left + 2, y, 3.2, 4),
          const Radius.circular(0.6),
        ),
        hole,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.right - 5.2, y, 3.2, 4),
          const Radius.circular(0.6),
        ),
        hole,
      );
    }
    final frame = Rect.fromLTRB(
      rect.left + 7,
      rect.top + 8,
      rect.right - 7,
      rect.bottom - 8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(1)),
      Paint()..color = const Color(0xFF8E9BB0),
    );
  }

  @override
  bool shouldRepaint(covariant _FilePainter oldDelegate) =>
      oldDelegate.kind != kind;
}

class _FolderPainter extends CustomPainter {
  const _FolderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width * 0.94;
    final height = size.height * 0.62;
    final left = (size.width - width) / 2;
    final top = size.height * 0.3;
    final tabWidth = width * 0.46;
    final tabHeight = height * 0.28;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, width, height),
        const Radius.circular(3),
      ).shift(const Offset(0, 1.5)),
      Paint()
        ..color = const Color(0x44000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final tab = RRect.fromRectAndCorners(
      Rect.fromLTWH(left, top - tabHeight * 0.85, tabWidth, tabHeight + 3),
      topLeft: const Radius.circular(3),
      topRight: const Radius.circular(2),
    );
    canvas.drawRRect(tab, Paint()..color = const Color(0xFF8FCEEA));
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, width, height),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7EC8EA), Color(0xFF3AA3D4)],
        ).createShader(body.outerRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 1, top + 1, width - 2, height * 0.22),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0x33FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _FolderPainter oldDelegate) => false;
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.label,
    required this.tileKey,
    required this.onTap,
    required this.child,
  });

  final String label;
  final Key tileKey;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        key: tileKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(width: 42, height: 40, child: Center(child: child)),
      ),
    );
  }
}

class _DockGlyph extends CustomPainter {
  const _DockGlyph(this.id);

  final String id;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.width * 0.24);
    switch (id) {
      case 'call':
        _fill(canvas, rect, radius, const [
          Color(0xFF5DDE8A),
          Color(0xFF1E9E4A),
        ]);
        _video(canvas, rect);
      case 'tracking':
        _circle(canvas, rect, const [Color(0xFF64D2FF), Color(0xFF0A84FF)]);
        _crosshair(canvas, rect);
      case 'markers':
        _fill(canvas, rect, radius, const [
          Color(0xFF9B94FF),
          Color(0xFF5E5CE6),
        ]);
        _dots(canvas, rect);
      case 'video':
        _fill(canvas, rect, radius, const [
          Color(0xFF3A3A3C),
          Color(0xFF1C1C1E),
        ]);
        _sprockets(canvas, rect);
      case 'word':
        _fill(canvas, rect, radius, const [
          Color(0xFF64A0FF),
          Color(0xFF2F6FE0),
        ]);
        _document(canvas, rect);
      case 'excel':
        _fill(canvas, rect, radius, const [
          Color(0xFF4ADE80),
          Color(0xFF178A45),
        ]);
        _grid(canvas, rect);
      case 'terminal':
        _fill(canvas, rect, radius, const [
          Color(0xFF2C2C2E),
          Color(0xFF1C1C1E),
        ]);
        _prompt(canvas, rect);
      case 'social':
        _fill(canvas, rect, radius, const [
          Color(0xFF64D2FF),
          Color(0xFF0A84FF),
        ]);
        _bubbles(canvas, rect);
      case 'photos':
        _picture(canvas, rect, radius);
      case 'music':
        _fill(canvas, rect, radius, const [
          Color(0xFFFF6482),
          Color(0xFFFF375F),
        ]);
        _note(canvas, rect);
      default:
        _fill(canvas, rect, radius, const [
          Color(0xFF8E8E93),
          Color(0xFF636366),
        ]);
    }
  }

  void _fill(Canvas canvas, Rect rect, Radius radius, List<Color> colors) {
    final box = RRect.fromRectAndRadius(rect.deflate(1), radius);
    canvas.drawRRect(
      box,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(box.outerRect),
    );
  }

  void _circle(Canvas canvas, Rect rect, List<Color> colors) {
    final circle = rect.deflate(1);
    canvas.drawOval(
      circle,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(circle),
    );
  }

  void _video(Canvas canvas, Rect rect) {
    final paint = Paint()..color = Colors.white;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: rect.center.translate(-2, 0),
        width: rect.width * 0.38,
        height: rect.height * 0.26,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(body, paint);
    final lens = Path()
      ..moveTo(rect.center.dx + rect.width * 0.12, rect.center.dy - 5)
      ..lineTo(rect.center.dx + rect.width * 0.30, rect.center.dy - 8)
      ..lineTo(rect.center.dx + rect.width * 0.30, rect.center.dy + 8)
      ..lineTo(rect.center.dx + rect.width * 0.12, rect.center.dy + 5)
      ..close();
    canvas.drawPath(lens, paint);
  }

  void _crosshair(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final center = rect.center;
    canvas.drawCircle(center, rect.width * 0.18, paint);
    canvas.drawCircle(center, 1.4, Paint()..color = Colors.white);
    canvas.drawLine(
      center.translate(-rect.width * 0.32, 0),
      center.translate(-rect.width * 0.22, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(rect.width * 0.22, 0),
      center.translate(rect.width * 0.32, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(0, -rect.width * 0.32),
      center.translate(0, -rect.width * 0.22),
      paint,
    );
    canvas.drawLine(
      center.translate(0, rect.width * 0.22),
      center.translate(0, rect.width * 0.32),
      paint,
    );
  }

  void _dots(Canvas canvas, Rect rect) {
    final paint = Paint()..color = Colors.white;
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 2; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              rect.left + rect.width * 0.26 + col * 10,
              rect.top + rect.height * 0.26 + row * 10,
              7,
              7,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
    }
  }

  void _sprockets(Canvas canvas, Rect rect) {
    final hole = Paint()..color = const Color(0xFFE5E5EA);
    for (var i = 0; i < 3; i++) {
      final y = rect.top + rect.height * 0.24 + i * 7;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left + 5, y, 3, 4),
          const Radius.circular(0.5),
        ),
        hole,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.right - 8, y, 3, 4),
          const Radius.circular(0.5),
        ),
        hole,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          rect.left + 11,
          rect.top + 8,
          rect.right - 11,
          rect.bottom - 8,
        ),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF8E9BB0),
    );
  }

  void _document(Canvas canvas, Rect rect) {
    final page = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: rect.center,
        width: rect.width * 0.46,
        height: rect.height * 0.62,
      ),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(page, Paint()..color = Colors.white);
    final line = Paint()..color = const Color(0xFF2F6FE0);
    final bounds = page.outerRect;
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(bounds.left + 3, bounds.top + 6 + i * 4),
        Offset(bounds.right - 3, bounds.top + 6 + i * 4),
        line..strokeWidth = 1.1,
      );
    }
  }

  void _grid(Canvas canvas, Rect rect) {
    final grid = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.52,
      height: rect.height * 0.52,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(grid, const Radius.circular(1.5)),
      Paint()..color = Colors.white,
    );
    final line = Paint()
      ..color = const Color(0xFF178A45)
      ..strokeWidth = 0.8;
    for (var i = 1; i < 3; i++) {
      final y = grid.top + grid.height * i / 3;
      canvas.drawLine(Offset(grid.left, y), Offset(grid.right, y), line);
      final x = grid.left + grid.width * i / 3;
      canvas.drawLine(Offset(x, grid.top), Offset(x, grid.bottom), line);
    }
  }

  void _prompt(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xFF32D74B)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final origin = rect.center.translate(-8, 1);
    canvas.drawLine(origin, origin.translate(5, -5), paint);
    canvas.drawLine(origin, origin.translate(5, 5), paint);
    canvas.drawLine(origin.translate(8, 5), origin.translate(16, 5), paint);
  }

  void _bubbles(Canvas canvas, Rect rect) {
    final paint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 6, rect.top + 8, 16, 11),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.drawCircle(Offset(rect.left + 10, rect.top + 20), 2, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 14, rect.top + 16, 16, 11),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFD6F3FF),
    );
  }

  void _picture(Canvas canvas, Rect rect, Radius radius) {
    final box = RRect.fromRectAndRadius(rect.deflate(1), radius);
    canvas.save();
    canvas.clipRRect(box);
    canvas.drawRect(
      Rect.fromLTRB(rect.left, rect.top, rect.right, rect.center.dy + 2),
      Paint()..color = const Color(0xFF5AC8FA),
    );
    canvas.drawRect(
      Rect.fromLTRB(rect.left, rect.center.dy + 2, rect.right, rect.bottom),
      Paint()..color = const Color(0xFF34C759),
    );
    canvas.drawCircle(
      Offset(rect.left + 11, rect.top + 11),
      4,
      Paint()..color = const Color(0xFFFFD60A),
    );
    final hill = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left + rect.width * 0.4, rect.center.dy)
      ..lineTo(rect.left + rect.width * 0.7, rect.bottom)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFF248A3D));
    canvas.restore();
    canvas.drawRRect(
      box,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x33FFFFFF),
    );
  }

  void _note(Canvas canvas, Rect rect) {
    final paint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(rect.center.dx - 4, rect.center.dy + 6),
      4.2,
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.center.dx - 1, rect.center.dy - 10, 2, 16),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.center.dx - 1, rect.center.dy - 12, 10, 4),
        const Radius.circular(1),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DockGlyph oldDelegate) => oldDelegate.id != id;
}

class _TrashPainter extends CustomPainter {
  const _TrashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E5EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.28,
        size.width * 0.64,
        size.height * 0.62,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(body, paint);
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.26),
      Offset(size.width * 0.88, size.height * 0.26),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.16),
          width: size.width * 0.28,
          height: 3.5,
        ),
        const Radius.circular(1),
      ),
      paint,
    );
    final slot = Paint()
      ..color = const Color(0xFFE5E5EA)
      ..strokeWidth = 1.2;
    for (final factor in [0.38, 0.5, 0.62]) {
      canvas.drawLine(
        Offset(size.width * factor, size.height * 0.38),
        Offset(size.width * factor, size.height * 0.76),
        slot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrashPainter oldDelegate) => false;
}

class _WifiPainter extends CustomPainter {
  const _WifiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height * 0.86);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.46),
      3.5,
      2.4,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.3),
      3.55,
      2.3,
      false,
      paint,
    );
    canvas.drawCircle(
      center.translate(0, -1),
      1.15,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _WifiPainter oldDelegate) => false;
}

class _BatteryPainter extends CustomPainter {
  const _BatteryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 1, size.width - 3, size.height - 2),
      const Radius.circular(2),
    );
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(body, stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 3, 14, 5),
        const Radius.circular(0.8),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width - 2.4,
          size.height * 0.32,
          1.6,
          size.height * 0.36,
        ),
        const Radius.circular(0.6),
      ),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) => false;
}

class _ControlPainter extends CustomPainter {
  const _ControlPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()..color = Colors.white;
    final knob = Paint()..color = const Color(0xFF2C2C2E);
    void pill(double y, bool on) {
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(1, y, size.width - 2, 5),
        const Radius.circular(3),
      );
      canvas.drawRRect(bar, track);
      canvas.drawCircle(
        Offset(on ? size.width - 4.5 : 4.5, y + 2.5),
        1.7,
        knob,
      );
    }

    pill(2, true);
    pill(size.height - 7, false);
  }

  @override
  bool shouldRepaint(covariant _ControlPainter oldDelegate) => false;
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
        elevation: 18,
        shadowColor: const Color(0x88000000),
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 32,
              color: const Color(0xFFE8E8EC),
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
            const Divider(height: 1, thickness: 1, color: Color(0xFFD2D2D7)),
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
      'Downloads' => const ['Call sheet.pdf', 'Still 12.jpg'],
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

  /// Top of the moonlit face, where the dune meets the sky.
  double _lit(double t) => _curve(t, const [
    (0.00, 0.50),
    (0.20, 0.46),
    (0.38, 0.40),
    (0.54, 0.33),
    (0.66, 0.30),
    (0.80, 0.37),
    (0.92, 0.43),
    (1.00, 0.48),
  ]);

  /// Crest, where the lit face drops into the dark slip face.
  double _shadow(double t) => _curve(t, const [
    (0.00, 0.78),
    (0.18, 0.72),
    (0.34, 0.58),
    (0.48, 0.42),
    (0.60, 0.34),
    (0.74, 0.39),
    (0.88, 0.46),
    (1.00, 0.53),
  ]);

  double _curve(double t, List<(double, double)> points) {
    if (t <= points.first.$1) return points.first.$2;
    for (var i = 1; i < points.length; i++) {
      final next = points[i];
      if (t <= next.$1) {
        final previous = points[i - 1];
        final span = next.$1 - previous.$1;
        final u = span == 0 ? 0.0 : (t - previous.$1) / span;
        final smooth = u * u * (3 - 2 * u);
        return previous.$2 + (next.$2 - previous.$2) * smooth;
      }
    }
    return points.last.$2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF07111E),
            Color(0xFF10243E),
            Color(0xFF3A5676),
            Color(0xFF243C5C),
            Color(0xFF101C30),
          ],
          stops: [0.0, 0.18, 0.34, 0.52, 1.0],
        ).createShader(rect),
    );
    _stars(canvas, size);
    _hills(canvas, size);
    final face = _band(size, _lit, _shadow);
    canvas.drawPath(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFB4C2D2),
            Color(0xFF8B9DB3),
            Color(0xFF5C7590),
            Color(0xFF2C445F),
          ],
          stops: const [0.0, 0.22, 0.55, 1.0],
        ).createShader(face.getBounds()),
    );
    canvas.drawPath(
      _below(size, _shadow),
      Paint()..color = const Color(0xFF0C1526),
    );
    _stroke(
      canvas,
      size,
      _shadow,
      const Color(0x88D5DEE8),
      size.shortestSide * 0.004,
      1.2,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0x00000000), Color(0x99060B14)],
          stops: [0.0, 0.72, 1.0],
        ).createShader(rect),
    );
  }

  void _stars(Canvas canvas, Size size) {
    const stars = <(double, double, double, int)>[
      (0.04, 0.06, 0.7, 150),
      (0.08, 0.12, 0.5, 110),
      (0.12, 0.04, 0.9, 190),
      (0.16, 0.16, 0.45, 90),
      (0.21, 0.08, 0.6, 140),
      (0.25, 0.18, 0.4, 80),
      (0.29, 0.05, 1.0, 200),
      (0.33, 0.13, 0.5, 120),
      (0.37, 0.07, 0.7, 160),
      (0.41, 0.17, 0.4, 90),
      (0.46, 0.04, 0.8, 180),
      (0.50, 0.11, 0.5, 110),
      (0.54, 0.19, 0.45, 80),
      (0.58, 0.06, 0.9, 200),
      (0.63, 0.14, 0.5, 120),
      (0.67, 0.03, 0.6, 150),
      (0.71, 0.10, 0.8, 170),
      (0.76, 0.17, 0.4, 90),
      (0.80, 0.05, 0.7, 160),
      (0.84, 0.12, 0.5, 120),
      (0.88, 0.08, 0.9, 190),
      (0.92, 0.16, 0.45, 100),
      (0.96, 0.04, 0.6, 140),
      (0.18, 0.22, 0.4, 70),
      (0.48, 0.22, 0.35, 60),
      (0.74, 0.24, 0.4, 70),
      (0.10, 0.26, 0.35, 50),
      (0.62, 0.22, 0.3, 55),
    ];
    for (final star in stars) {
      canvas.drawCircle(
        Offset(size.width * star.$1, size.height * star.$2),
        star.$3,
        Paint()..color = Color.fromARGB(star.$4, 255, 255, 255),
      );
    }
  }

  void _hills(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.1,
        size.height * 0.36,
        size.width * 0.22,
        size.height * 0.41,
      )
      ..lineTo(0, size.height * 0.46)
      ..close();
    final right = Path()
      ..moveTo(size.width * 0.78, size.height * 0.44)
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.37,
        size.width,
        size.height * 0.42,
      )
      ..lineTo(size.width, size.height * 0.48)
      ..lineTo(size.width * 0.78, size.height * 0.48)
      ..close();
    final paint = Paint()..color = const Color(0xFF243E5E);
    canvas
      ..drawPath(path, paint)
      ..drawPath(right, paint);
  }

  Path _band(
    Size size,
    double Function(double t) top,
    double Function(double t) bottom,
  ) {
    final path = Path();
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final point = Offset(size.width * t, size.height * top(t));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    for (var i = steps; i >= 0; i--) {
      final t = i / steps;
      path.lineTo(size.width * t, size.height * bottom(t));
    }
    path.close();
    return path;
  }

  Path _below(Size size, double Function(double t) edge) {
    final path = Path()..moveTo(0, size.height);
    for (var i = 0; i <= 48; i++) {
      final t = i / 48;
      path.lineTo(size.width * t, size.height * edge(t));
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    return path;
  }

  void _stroke(
    Canvas canvas,
    Size size,
    double Function(double t) edge,
    Color color,
    double width,
    double blur,
  ) {
    final path = Path();
    for (var i = 0; i <= 48; i++) {
      final t = i / 48;
      final point = Offset(size.width * t, size.height * edge(t));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
  }

  @override
  bool shouldRepaint(covariant _Dunes oldDelegate) => false;
}
