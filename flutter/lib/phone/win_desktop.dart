import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import 'catalog.dart';

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
          left: 2,
          top: 2,
          bottom: 48,
          width: 246,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final count = _shortcuts.length + widget.apps.length;
              final rows = (count / 3).ceil().clamp(1, 99);
              final cellH = constraints.maxHeight / rows;
              return Wrap(
                key: const Key('win-icons'),
                direction: Axis.vertical,
                spacing: 0,
                runSpacing: 0,
                children: [
                  for (final shortcut in _shortcuts)
                    _DesktopIcon(
                      label: shortcut.label,
                      iconKey: shortcut.key,
                      height: cellH,
                      onTap: () => _open(shortcut.id),
                      child: shortcut.mark,
                    ),
                  for (final app in widget.apps)
                    _DesktopIcon(
                      label: app.$2,
                      iconKey: Key('win-icon-${app.$1}'),
                      height: cellH,
                      onTap: () => _open(app.$1),
                      child: _Tile(_tint(app.$1), app.$3),
                    ),
                ],
              );
            },
          ),
        ),
        if (title != null)
          Center(
            child: _WinWindow(
              title: title,
              tall: !_native.contains(widget.appId),
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
            onPinned: _open,
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

/// Shortcuts Windows draws itself, rather than from the shared app set.
const _native = {'recycle', 'edge', 'files'};

class _Shortcut {
  const _Shortcut(this.id, this.label, this.mark, {this.key});

  final String id;
  final String label;
  final Widget mark;
  final Key? key;
}

class _Tile extends StatelessWidget {
  const _Tile(this.color, this.icon);

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}

/// Windows keeps its own shortcuts; the shared apps follow them.
const _shortcuts = <_Shortcut>[
  _Shortcut(
    'recycle',
    'Recycle Bin',
    CustomPaint(painter: _BinPainter(), child: SizedBox(width: 30, height: 30)),
    key: Key('win-recycle'),
  ),
  _Shortcut(
    'edge',
    'Edge',
    CustomPaint(painter: _WavePainter(), child: SizedBox(width: 30, height: 30)),
    key: Key('win-edge'),
  ),
  _Shortcut(
    'files',
    'File Explorer',
    _Tile(Color(0xFFE8B931), Icons.folder_outlined),
    key: Key('win-files-icon'),
  ),
];

Color _tint(String id) =>
    propAppById(id)?.color ?? const Color(0xFF4C6EF5);

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
    required this.onPinned,
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
  final ValueChanged<String> onPinned;
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
                  child: const Icon(Icons.view_quilt_outlined, size: 18, color: Color(0xFF1A1A1A)),
                ),
                _BarButton(
                  tooltip: 'Edge',
                  onTap: onEdge,
                  child: const CustomPaint(
                    painter: _WavePainter(),
                    child: SizedBox(width: 18, height: 18),
                  ),
                ),
                _BarButton(
                  key: const Key('win-files'),
                  tooltip: 'File Explorer',
                  onTap: onFiles,
                  child: const Icon(Icons.folder, size: 18, color: Color(0xFFE8B931)),
                ),
                for (final id in kDockIds)
                  if (propAppById(id) case final prop?)
                    _BarButton(
                      key: Key('win-bar-$id'),
                      tooltip: appLabel(prop, branded: os.branded),
                      onTap: () => onPinned(id),
                      child: Icon(prop.icon, size: 18, color: prop.color),
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
          width: 36,
          height: 36,
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
    required this.height,
    required this.onTap,
    required this.child,
  });

  final String label;
  final Key? iconKey;
  final double height;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: iconKey,
      onTap: onTap,
      child: SizedBox(
        width: 78,
        height: height,
        child: Column(
          children: [
            child,
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                height: 1.05,
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
    required this.tall,
  });

  final String title;
  final VoidCallback onClose;
  final Widget child;

  /// Shared apps are phone shaped, so they get a narrow, tall window.
  final bool tall;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: tall
          ? const BoxConstraints(maxWidth: 420, maxHeight: 720)
          : const BoxConstraints(maxWidth: 560, maxHeight: 360),
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
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFC5D9F2), Color(0xFFD7E8F8), Color(0xFFE9F3FC)],
        ).createShader(rect),
    );
    final origin = Offset(size.width * 0.40, size.height * 0.46);
    final unit = math.min(size.width, size.height);
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(unit * 0.04, unit * 0.08), width: unit * 0.95, height: unit * 0.7),
      Paint()
        ..color = const Color(0x220A2A66)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    const sheets = <(Offset, Offset, Offset, Offset, Color, Color, double)>[
      (Offset(-0.15, -0.5), Offset(-0.62, -0.05), Offset(0.42, -0.58), Offset(0.28, 0.22), Color(0xFFD7EBFC), Color(0xFF3D7AD8), 0.26),
      (Offset(-0.48, -0.18), Offset(-0.05, 0.42), Offset(0.55, 0.05), Offset(0.22, -0.28), Color(0xFF8EBEF4), Color(0xFF14367C), 0.22),
      (Offset(-0.32, -0.32), Offset(0.18, -0.5), Offset(0.05, 0.28), Offset(-0.22, 0.46), Color(0xFFB9D7FA), Color(0xFF1C4EAE), 0.24),
      (Offset(-0.08, -0.22), Offset(0.38, 0.02), Offset(0.12, 0.38), Offset(-0.28, 0.08), Color(0xFFE7F4FE), Color(0xFF5C9AEE), 0.16),
      (Offset(-0.5, 0.08), Offset(-0.12, 0.48), Offset(0.32, 0.42), Offset(0.48, 0.02), Color(0xFF6FA6EA), Color(0xFF0E2C68), 0.2),
      (Offset(0.02, 0.02), Offset(0.48, -0.22), Offset(0.78, 0.28), Offset(0.62, 0.48), Color(0xFFC5DFF8), Color(0xFF2458C0), 0.2),
      (Offset(-0.22, 0.18), Offset(0.15, 0.55), Offset(0.55, 0.18), Offset(0.18, -0.12), Color(0xFF9CC6F6), Color(0xFF184494), 0.18),
      (Offset(0.12, -0.38), Offset(0.45, -0.12), Offset(0.2, 0.18), Offset(-0.08, 0.28), Color(0xFFF2F8FE), Color(0xFF4E8CE4), 0.14),
      (Offset(-0.38, -0.42), Offset(0.05, -0.08), Offset(-0.15, 0.32), Offset(0.28, 0.38), Color(0xFF2E66C8), Color(0xFF102A60), 0.17),
    ];
    for (final sheet in sheets) {
      final spine = <Offset>[
        for (var i = 0; i <= 36; i++)
          _cubic(sheet.$1, sheet.$2, sheet.$3, sheet.$4, i / 36) * unit,
      ];
      final path = _band(spine, unit * sheet.$7);
      final bounds = Rect.fromCenter(center: Offset.zero, width: unit * 1.6, height: unit * 1.6);
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: const Alignment(-0.6, -1),
            end: const Alignment(0.8, 0.7),
            colors: [sheet.$5, sheet.$6],
          ).createShader(bounds),
      );
    }
    canvas.restore();
  }

  Offset _cubic(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    return (p0 * (u * u * u)) + (p1 * (3 * u * u * t)) + (p2 * (3 * u * t * t)) + (p3 * (t * t * t));
  }

  Path _band(List<Offset> spine, double width) {
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i < spine.length; i++) {
      final prev = spine[math.max(0, i - 1)];
      final next = spine[math.min(spine.length - 1, i + 1)];
      final dir = next - prev;
      final len = dir.distance;
      if (len == 0) continue;
      final normal = Offset(-dir.dy / len, dir.dx / len);
      final t = i / (spine.length - 1);
      final taper = 0.62 + 0.38 * math.sin(t * math.pi);
      left.add(spine[i] + normal * (width * taper));
      right.add(spine[i] - normal * (width * taper * 0.72));
    }
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (final point in left.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    for (final point in right.reversed) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    return path;
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
