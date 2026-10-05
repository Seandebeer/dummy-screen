import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';

/// Windows desktop: bloom wallpaper, left-hand icons, and a centered taskbar.
class WinDesktop extends StatefulWidget {
  const WinDesktop({
    super.key,
    required this.store,
    required this.device,
    required this.apps,
    required this.appId,
    required this.appTitle,
    required this.tool,
    required this.onOpen,
    required this.onShell,
    required this.shells,
  });

  final StageStore store;
  final PropDevice device;
  final List<(String, String, IconData)> apps;
  final String? appId;
  final String? appTitle;
  final Widget? tool;
  final ValueChanged<String?> onOpen;
  final ValueChanged<String> onShell;
  final List<(String, String)> shells;

  @override
  State<WinDesktop> createState() => _WinDesktopState();
}

class _WinDesktopState extends State<WinDesktop> {
  bool _start = false;
  bool _search = false;
  bool _tasks = false;

  void _open(String? id) {
    setState(() {
      _start = false;
      _search = false;
      _tasks = false;
    });
    widget.onOpen(id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final live = widget.store.deviceById(widget.device.id) ?? widget.device;
        return _scene(live);
      },
    );
  }

  Widget _scene(PropDevice live) {
    final now = propNow(live.clockOffsetMinutes);
    final bloom = !live.os.isLight &&
        live.os.backgroundPreset == 'default' &&
        live.os.backgroundType != 'image';
    final paper = wallpaperFor(live, locked: false);
    final image = paper.imagePath.isEmpty
        ? null
        : imageProviderForPath(paper.imagePath);
    final title = _title(widget.appId, widget.appTitle);
    return Material(
      key: const Key('win-desktop'),
      color: const Color(0xFFA9CFF2),
      child: Stack(
      fit: StackFit.expand,
      children: [
        if (bloom)
          const CustomPaint(painter: _BloomPainter(), child: SizedBox.expand())
        else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: paper.gradient,
              image: image == null
                  ? null
                  : DecorationImage(image: image, fit: BoxFit.cover),
            ),
            child: const SizedBox.expand(),
          ),
        Positioned(
          left: 10,
          top: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DesktopIcon(
                label: 'Recycle Bin',
                iconKey: const Key('win-recycle'),
                onTap: () => _open('recycle'),
                child: const CustomPaint(
                  painter: _BinPainter(),
                  child: SizedBox(width: 36, height: 36),
                ),
              ),
              const SizedBox(height: 10),
              _DesktopIcon(
                label: 'Edge',
                iconKey: const Key('win-edge'),
                onTap: () => _open('edge'),
                child: const CustomPaint(
                  painter: _WavePainter(),
                  child: SizedBox(width: 36, height: 36),
                ),
              ),
            ],
          ),
        ),
        if (title != null)
          Center(
            child: _WinWindow(
              title: title,
              onClose: () => _open(null),
              child: _body(widget.appId),
            ),
          ),
        if (_start)
          Positioned(
            left: 0,
            right: 0,
            bottom: 52,
            child: Center(
              child: _StartMenu(
                apps: widget.apps,
                onOpen: _open,
                onShell: widget.onShell,
                shells: widget.shells,
              ),
            ),
          ),
        if (_search)
          Positioned(
            left: 0,
            right: 0,
            bottom: 52,
            child: const Center(child: _SearchPane()),
          ),
        if (_tasks)
          Positioned(
            left: 0,
            right: 0,
            bottom: 52,
            child: Center(child: _TaskPane(title: title)),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _Taskbar(
            now: now,
            os: live.os,
            startOpen: _start,
            onStart: () => setState(() {
              _start = !_start;
              _search = false;
              _tasks = false;
            }),
            onSearch: () => setState(() {
              _search = !_search;
              _start = false;
              _tasks = false;
            }),
            onTasks: () => setState(() {
              _tasks = !_tasks;
              _start = false;
              _search = false;
            }),
            onFiles: () => _open('files'),
            onEdge: () => _open('edge'),
            onShell: widget.onShell,
            shells: widget.shells,
          ),
        ),
      ],
      ),
    );
  }

  String? _title(String? id, String? appTitle) {
    return switch (id) {
      null => null,
      'recycle' => 'Recycle Bin',
      'edge' => 'Edge',
      'files' => 'File Explorer',
      _ => appTitle,
    };
  }

  Widget _body(String? id) {
    return switch (id) {
      'recycle' => const _EmptyFolder(label: 'This folder is empty.'),
      'edge' => const _Browser(),
      'files' => const _Files(),
      _ => widget.tool ?? const SizedBox.shrink(),
    };
  }
}

class _Taskbar extends StatelessWidget {
  const _Taskbar({
    required this.now,
    required this.os,
    required this.startOpen,
    required this.onStart,
    required this.onSearch,
    required this.onTasks,
    required this.onFiles,
    required this.onEdge,
    required this.onShell,
    required this.shells,
  });

  final DateTime now;
  final OsSettings os;
  final bool startOpen;
  final VoidCallback onStart;
  final VoidCallback onSearch;
  final VoidCallback onTasks;
  final VoidCallback onFiles;
  final VoidCallback onEdge;
  final ValueChanged<String> onShell;
  final List<(String, String)> shells;

  @override
  Widget build(BuildContext context) {
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final suffix = now.hour >= 12 ? 'PM' : 'AM';
    final clock = '$hour:$minute $suffix';
    final date = '${now.month}/${now.day}/${now.year}';
    return DecoratedBox(
      key: const Key('win-taskbar'),
      decoration: const BoxDecoration(
        color: Color(0xF2F3F3F3),
        border: Border(top: BorderSide(color: Color(0xFFE4E4E4))),
      ),
      child: SizedBox(
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BarButton(
                  key: const Key('win-start'),
                  tooltip: 'Start',
                  selected: startOpen,
                  onTap: onStart,
                  child: const CustomPaint(
                    painter: _PanesPainter(),
                    child: SizedBox(width: 18, height: 18),
                  ),
                ),
                _BarButton(
                  key: const Key('win-search'),
                  tooltip: 'Search',
                  onTap: onSearch,
                  child: const Icon(Icons.search, size: 20, color: Color(0xFF1A1A1A)),
                ),
                _BarButton(
                  key: const Key('win-taskview'),
                  tooltip: 'Task view',
                  onTap: onTasks,
                  child: const Icon(Icons.view_quilt_outlined, size: 20, color: Color(0xFF1A1A1A)),
                ),
                _BarButton(
                  key: const Key('win-files'),
                  tooltip: 'File Explorer',
                  onTap: onFiles,
                  child: const Icon(Icons.folder, size: 20, color: Color(0xFFE8B931)),
                ),
                _BarButton(
                  tooltip: 'Edge',
                  onTap: onEdge,
                  child: const CustomPaint(
                    painter: _WavePainter(),
                    child: SizedBox(width: 18, height: 18),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Row(
                children: [
                  const Icon(Icons.expand_less, size: 16, color: Color(0xFF1A1A1A)),
                  const SizedBox(width: 8),
                  Icon(
                    os.wifi ? Icons.wifi : Icons.wifi_off,
                    size: 15,
                    color: const Color(0xFF1A1A1A),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.volume_up, size: 15, color: Color(0xFF1A1A1A)),
                  const SizedBox(width: 8),
                  Icon(_battery(os.battery), size: 16, color: const Color(0xFF1A1A1A)),
                  const SizedBox(width: 10),
                  Column(
                    key: const Key('win-clock'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(clock, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 11, height: 1.1)),
                      Text(date, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 11, height: 1.1)),
                    ],
                  ),
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
                    key: const Key('win-system'),
                    tooltip: 'System',
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF1C1C1E),
                    onSelected: onShell,
                    itemBuilder: (context) => [
                      for (final item in shells)
                        PopupMenuItem(value: item.$1, child: Text(item.$2)),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.keyboard_outlined, size: 16, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _battery(int level) {
    if (level >= 90) return Icons.battery_full;
    if (level >= 60) return Icons.battery_5_bar;
    if (level >= 30) return Icons.battery_3_bar;
    return Icons.battery_1_bar;
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    super.key,
    required this.tooltip,
    required this.onTap,
    required this.child,
    this.selected = false,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0x14000000) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DesktopIcon extends StatelessWidget {
  const _DesktopIcon({
    required this.label,
    required this.iconKey,
    required this.onTap,
    required this.child,
  });

  final String label;
  final Key iconKey;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: iconKey,
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            child,
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                height: 1.15,
                shadows: [Shadow(color: Color(0xCC000000), blurRadius: 3)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WinWindow extends StatelessWidget {
  const _WinWindow({
    required this.title,
    required this.onClose,
    required this.child,
  });

  final String title;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 360),
      child: Material(
        color: Colors.white,
        elevation: 16,
        child: Column(
          children: [
            Container(
              height: 36,
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 12),
                    ),
                  ),
                  const Icon(Icons.horizontal_rule, size: 16, color: Color(0xFF1A1A1A)),
                  const SizedBox(width: 14),
                  const Icon(Icons.crop_square, size: 14, color: Color(0xFF1A1A1A)),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const Key('win-window-close'),
                    tooltip: 'Close',
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFF1A1A1A)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE6E6E6)),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _StartMenu extends StatelessWidget {
  const _StartMenu({
    required this.apps,
    required this.onOpen,
    required this.onShell,
    required this.shells,
  });

  final List<(String, String, IconData)> apps;
  final ValueChanged<String?> onOpen;
  final ValueChanged<String> onShell;
  final List<(String, String)> shells;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('win-start-menu'),
      color: const Color(0xF2F7F7F7),
      elevation: 12,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 420,
        height: 280,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pinned',
                style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 5,
                  mainAxisSpacing: 6,
                  children: [
                    for (final app in apps)
                      InkWell(
                        key: Key('win-pin-${app.$1}'),
                        onTap: () => onOpen(app.$1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(app.$3, size: 22, color: const Color(0xFF1A1A1A)),
                            const SizedBox(height: 4),
                            Text(
                              app.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Text('Shell', style: TextStyle(color: Color(0xFF5A5A5A), fontSize: 12)),
                  const Spacer(),
                  for (final shell in shells)
                    TextButton(
                      onPressed: () => onShell(shell.$1),
                      child: Text(shell.$2),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchPane extends StatelessWidget {
  const _SearchPane();

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('win-search-pane'),
      color: const Color(0xF2F7F7F7),
      elevation: 12,
      borderRadius: BorderRadius.circular(8),
      child: const SizedBox(
        width: 420,
        height: 160,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            key: Key('win-search-field'),
            decoration: InputDecoration(
              hintText: 'Type here to search',
              prefixIcon: Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskPane extends StatelessWidget {
  const _TaskPane({required this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF2F7F7F7),
      elevation: 12,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 280,
        height: 120,
        child: Center(
          child: Text(
            title == null ? 'No open windows' : title!,
            style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
          ),
        ),
      ),
    );
  }
}

class _EmptyFolder extends StatelessWidget {
  const _EmptyFolder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(label, style: const TextStyle(color: Color(0xFF5A5A5A), fontSize: 14)),
    );
  }
}

class _Browser extends StatelessWidget {
  const _Browser();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'northline.example',
            style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 12),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Edge',
              style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _Files extends StatelessWidget {
  const _Files();

  @override
  Widget build(BuildContext context) {
    const names = ['Documents', 'Downloads', 'Pictures', 'Desktop'];
    return ListView(
      children: [
        for (final name in names)
          ListTile(
            dense: true,
            leading: const Icon(Icons.folder, color: Color(0xFFE8B931)),
            title: Text(name, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13)),
          ),
      ],
    );
  }
}

class _BloomPainter extends CustomPainter {
  const _BloomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFFD3E4F6));
    final center = Offset(size.width * 0.50, size.height * 0.40);
    final scale = math.min(size.width, size.height);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    const ribbons = <(double, Color, Color, double, double)>[
      (0.2, Color(0xFF163E9A), Color(0xFF3E78D8), 0.62, 0.075),
      (1.05, Color(0xFF1E56C4), Color(0xFF7EB6F6), 0.70, 0.082),
      (1.85, Color(0xFF0E327C), Color(0xFF2F66C8), 0.58, 0.07),
      (2.55, Color(0xFF4C92EA), Color(0xFFD4E8FC), 0.66, 0.078),
      (3.35, Color(0xFF2158C0), Color(0xFF6AABF0), 0.74, 0.09),
      (4.15, Color(0xFF12357A), Color(0xFF3A72D2), 0.52, 0.064),
      (4.9, Color(0xFF5AA0F2), Color(0xFFE4F2FE), 0.60, 0.072),
      (5.6, Color(0xFF1848B0), Color(0xFF4E8CE4), 0.48, 0.06),
    ];
    for (final ribbon in ribbons) {
      canvas.save();
      canvas.rotate(ribbon.$1);
      final length = scale * ribbon.$4;
      final path = Path()
        ..moveTo(-length * 0.08, length * 0.02)
        ..cubicTo(
          -length * 0.72,
          -length * 0.18,
          -length * 0.15,
          -length * 0.95,
          length * 0.42,
          -length * 0.62,
        )
        ..cubicTo(
          length * 0.78,
          -length * 0.42,
          length * 0.28,
          length * 0.08,
          -length * 0.02,
          length * 0.22,
        );
      final bounds = Rect.fromCenter(
        center: Offset.zero,
        width: scale,
        height: scale,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = scale * ribbon.$5
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            begin: const Alignment(-0.8, -1),
            end: const Alignment(0.6, 0.4),
            colors: [ribbon.$3, ribbon.$2],
          ).createShader(bounds),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = scale * ribbon.$5 * 0.28
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x66FFFFFF),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PanesPainter extends CustomPainter {
  const _PanesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF0067C0);
    final gap = size.width * 0.12;
    final side = (size.width - gap) / 2;
    final radius = Radius.circular(size.width * 0.08);
    for (final origin in [
      Offset.zero,
      Offset(side + gap, 0),
      Offset(0, side + gap),
      Offset(side + gap, side + gap),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(origin & Size(side, side), radius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BinPainter extends CustomPainter {
  const _BinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.22, size.height * 0.28, size.width * 0.56, size.height * 0.58),
      const Radius.circular(3),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xE6F4F8FC));
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFF3A6EA5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.3, size.height * 0.16, size.width * 0.4, size.height * 0.1),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF5B8FC4),
    );
    final arrow = Paint()
      ..color = const Color(0xFF2F6FE0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.32, size.height * 0.4, size.width * 0.36, size.height * 0.32),
      0.4,
      4.6,
      false,
      arrow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(
      rect.deflate(1),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3DDCFF), Color(0xFF1A6FE0), Color(0xFF12B886)],
        ).createShader(rect),
    );
    final wave = Path()
      ..moveTo(size.width * 0.12, size.height * 0.58)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.28,
        size.width * 0.55,
        size.height * 0.82,
        size.width * 0.88,
        size.height * 0.42,
      );
    canvas.drawPath(
      wave,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, size.width * 0.08)
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
