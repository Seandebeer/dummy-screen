import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../image_file.dart';
import '../models.dart';
import '../store.dart';
import 'atm_home.dart';
import 'mac_desktop.dart';
import 'ps2_home.dart';
import 'smart_home.dart';
import 'ps5_home.dart';
import 'xbox_360.dart';
import 'xbox_series.dart';

class DeviceMetrics {
  const DeviceMetrics(this.aspect, this.frame);

  /// Width divided by height.
  final double aspect;
  final String frame;
}

DeviceMetrics metricsFor(String kind, {bool landscape = false}) {
  switch (kind) {
    case 'tablet':
      return DeviceMetrics(landscape ? 4 / 3 : 3 / 4, 'tablet');
    case 'computer':
      return const DeviceMetrics(16 / 10, 'monitor');
    case 'tv':
    case 'console':
    case 'cctv':
      return const DeviceMetrics(16 / 9, 'tv');
    case 'atm':
      return const DeviceMetrics(4 / 3, 'kiosk');
    case 'smarthome':
      return const DeviceMetrics(4 / 3, 'panel');
    case 'homephone':
      return const DeviceMetrics(390 / 844, 'phone');
    default:
      return DeviceMetrics(landscape ? 844 / 390 : 390 / 844, 'phone');
  }
}

const kSandboxKinds = [
  ('phone', 'Phone'),
  ('tablet', 'Tablet'),
  ('computer', 'Computer'),
  ('tv', 'Smart TV'),
  ('console', 'Game console'),
  ('atm', 'ATM'),
  ('cctv', 'CCTV'),
  ('smarthome', 'Smart home'),
  ('homephone', 'Smart home phone'),
];

class DeviceBezel extends StatelessWidget {
  const DeviceBezel({super.key, required this.frame, required this.child});

  final String frame;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = switch (frame) {
      'phone' => 36.0,
      'tablet' => 28.0,
      'kiosk' => 18.0,
      'panel' => 16.0,
      _ => 12.0,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(radius + 8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 10, 10, frame == 'monitor' ? 28 : 10),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: child,
              ),
            ),
            if (frame == 'monitor')
              Container(
                width: 72,
                height: 10,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C30),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Computer, TV, console, ATM, CCTV, and smart-home screens.
class FormOs extends StatefulWidget {
  const FormOs({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<FormOs> createState() => _FormOsState();
}

class _FormOsState extends State<FormOs> {
  String? _app;

  PropDevice get device => widget.device;
  OsSettings get os => device.os;

  void _shell(String id) {
    widget.store.updateOs(device.id, (current) => current.copyWith(shell: id));
  }

  @override
  Widget build(BuildContext context) {
    return switch (device.kind) {
      'tv' => _TvOs(
        shell: os.shell.isEmpty ? 'aurora' : os.shell,
        onShell: _shell,
        app: _app,
        onOpen: (id) => setState(() => _app = id),
      ),
      'console' => _ConsoleOs(
        store: widget.store,
        device: device,
        app: _app,
        onOpen: (id) => setState(() => _app = id),
      ),
      'atm' => AtmScreen(store: widget.store, device: device),
      'cctv' => const _CctvOs(),
      'smarthome' => HomePanel(store: widget.store, device: device),
      'homephone' => HomePanel(
        store: widget.store,
        device: device,
        portrait: true,
      ),
      _ => _ComputerOs(
        shell: os.shell.isEmpty ? 'macos' : os.shell,
        onShell: _shell,
        app: _app,
        onOpen: (id) => setState(() => _app = id),
      ),
    };
  }
}

const _computerShells = [
  ('macos', 'macOS'),
  ('windows', 'Windows'),
  ('linux', 'Linux'),
  ('ubuntu', 'Ubuntu'),
  ('system7', 'System 7'),
  ('mac9', 'Mac OS 9'),
  ('tiger', 'OS X Tiger'),
  ('yosemite', 'OS X Yosemite'),
  ('win95', 'Windows 95'),
  ('win98', 'Windows 98'),
  ('winxp', 'Windows XP'),
  ('vista', 'Windows Vista'),
  ('win7', 'Windows 7'),
  ('win8', 'Windows 8'),
];

const _deskApps = [
  ('call', 'Call', Icons.video_call),
  ('tracking', 'Tracking', Icons.center_focus_strong),
  ('markers', 'UI Markers', Icons.grid_on),
  ('video', 'Video', Icons.movie),
  ('word', 'Word', Icons.description),
  ('excel', 'Excel', Icons.table_chart),
  ('terminal', 'Terminal', Icons.terminal),
  ('social', 'Social', Icons.forum),
  ('photos', 'Photos', Icons.photo_library),
  ('music', 'Music', Icons.library_music),
];

class _ComputerOs extends StatelessWidget {
  const _ComputerOs({
    required this.shell,
    required this.onShell,
    required this.app,
    required this.onOpen,
  });

  final String shell;
  final ValueChanged<String> onShell;
  final String? app;
  final ValueChanged<String?> onOpen;

  Color get _desktop {
    switch (shell) {
      case 'windows':
      case 'win7':
      case 'win8':
        return const Color(0xFF0C3B6E);
      case 'winxp':
        return const Color(0xFF245EDC);
      case 'win95':
      case 'win98':
        return const Color(0xFF008080);
      case 'vista':
        return const Color(0xFF1B3A4B);
      case 'ubuntu':
        return const Color(0xFF2C001E);
      case 'linux':
        return const Color(0xFF1C2833);
      case 'system7':
      case 'mac9':
        return const Color(0xFFBFBFBF);
      case 'tiger':
        return const Color(0xFF6FA8D6);
      case 'yosemite':
        return const Color(0xFF3D4F66);
      default:
        return const Color(0xFF1D3E6E);
    }
  }

  bool get _classic =>
      shell == 'system7' ||
      shell == 'mac9' ||
      shell == 'win95' ||
      shell == 'win98';

  @override
  Widget build(BuildContext context) {
    if (shell == 'macos') {
      final open = app == null
          ? null
          : _deskApps.firstWhere((item) => item.$1 == app);
      return MacDesktop(
        appTitle: open?.$2,
        tool: open == null ? null : _DeskTool(id: open.$1),
        onOpen: onOpen,
        onShell: onShell,
        shells: _computerShells,
      );
    }
    final ink = _classic ? Colors.black : Colors.white;
    return Material(
      color: _desktop,
      child: Column(
        children: [
          _menu(ink),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 18,
                    runSpacing: 16,
                    children: [
                      for (final item in _deskApps)
                        _DeskIcon(
                          label: item.$2,
                          icon: item.$3,
                          ink: ink,
                          onTap: () => onOpen(item.$1),
                        ),
                    ],
                  ),
                ),
                if (app != null)
                  Center(
                    child: _Window(
                      title: _deskApps.firstWhere((item) => item.$1 == app).$2,
                      classic: _classic,
                      onClose: () => onOpen(null),
                      child: _DeskTool(id: app!),
                    ),
                  ),
              ],
            ),
          ),
          _dock(ink),
        ],
      ),
    );
  }

  Widget _menu(Color ink) {
    final label = _computerShells
        .firstWhere(
          (item) => item.$1 == shell,
          orElse: () => _computerShells.first,
        )
        .$2;
    return Container(
      height: 28,
      color: _classic
          ? const Color(0xFFF4F4F4)
          : Colors.black.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'System',
            icon: Icon(Icons.settings, size: 14, color: ink),
            onSelected: onShell,
            itemBuilder: (context) => [
              for (final item in _computerShells)
                PopupMenuItem(value: item.$1, child: Text(item.$2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dock(Color ink) {
    return Container(
      height: 54,
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: _classic ? 0.08 : 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final item in _deskApps.take(6))
            IconButton(
              tooltip: item.$2,
              onPressed: () => onOpen(item.$1),
              icon: Icon(item.$3, color: ink, size: 20),
            ),
        ],
      ),
    );
  }
}

class _DeskIcon extends StatelessWidget {
  const _DeskIcon({
    required this.label,
    required this.icon,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Icon(icon, color: ink, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: ink, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _Window extends StatelessWidget {
  const _Window({
    required this.title,
    required this.child,
    required this.onClose,
    required this.classic,
  });

  final String title;
  final Widget child;
  final VoidCallback onClose;
  final bool classic;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 360),
      child: Material(
        color: classic ? const Color(0xFFE8E8E8) : const Color(0xF016161A),
        elevation: 12,
        child: Column(
          children: [
            Container(
              height: 32,
              color: classic
                  ? const Color(0xFF000080)
                  : const Color(0xFF2A2A30),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
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

class _DeskTool extends StatefulWidget {
  const _DeskTool({required this.id});

  final String id;

  @override
  State<_DeskTool> createState() => _DeskToolState();
}

class _DeskToolState extends State<_DeskTool> {
  final _doc = TextEditingController(
    text: 'Scene 47 — the call beats were trimmed.',
  );
  String _term = 'prop@stage:~\$ ';

  @override
  void dispose() {
    _doc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.id) {
      case 'call':
        return const _CallMock();
      case 'tracking':
        return const CustomPaint(
          painter: _CrossPainter(),
          child: SizedBox.expand(),
        );
      case 'markers':
        return const CustomPaint(
          painter: _MarkerPainter(),
          child: SizedBox.expand(),
        );
      case 'video':
        return const Center(
          child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
        );
      case 'word':
        return Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _doc,
            maxLines: null,
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        );
      case 'excel':
        return GridView.count(
          crossAxisCount: 6,
          children: [
            for (var i = 0; i < 24; i++)
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  i == 0 ? '' : '$i',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
          ],
        );
      case 'terminal':
        return ColoredBox(
          color: Colors.black,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: const TextStyle(
                color: Color(0xFF3DDC84),
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: _term,
                hintStyle: const TextStyle(color: Color(0xFF3DDC84)),
              ),
              onSubmitted: (value) => setState(
                () => _term = 'prop@stage:~\$ $value\nprop@stage:~\$ ',
              ),
            ),
          ),
        );
      case 'social':
        return ListView(
          padding: const EdgeInsets.all(12),
          children: const [
            Text(
              'Studio feed',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Call time moved to 18:00. Marks are approved for the insert.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        );
      case 'photos':
        return GridView.count(
          padding: const EdgeInsets.all(8),
          crossAxisCount: 4,
          children: [
            for (final color in [
              0xFF318DF6,
              0xFF30D158,
              0xFFFF9F0A,
              0xFFFF453A,
              0xFF5E5CE6,
              0xFF64D2FF,
              0xFFFFD60A,
              0xFFBF5AF2,
            ])
              ColoredBox(color: Color(color)),
          ],
        );
      default:
        return ListView(
          children: const [
            ListTile(
              title: Text('Night shoot', style: TextStyle(color: Colors.white)),
              subtitle: Text('Studio playlist'),
            ),
            ListTile(
              title: Text(
                'Playback ref',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text('Insert cues'),
            ),
          ],
        );
    }
  }
}

class _CallMock extends StatelessWidget {
  const _CallMock();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF101418),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
          SizedBox(height: 12),
          Text(
            'Video call',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 4),
          Text(
            'Waiting for the far end',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF39FF6A)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      18,
      paint..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MarkerPainter extends CustomPainter {
  const _MarkerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final point in [
      const Offset(0.2, 0.25),
      const Offset(0.8, 0.25),
      const Offset(0.2, 0.75),
      const Offset(0.8, 0.75),
    ]) {
      final c = Offset(point.dx * size.width, point.dy * size.height);
      canvas.drawRect(Rect.fromCenter(center: c, width: 28, height: 28), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TvOs extends StatelessWidget {
  const _TvOs({
    required this.shell,
    required this.onShell,
    required this.app,
    required this.onOpen,
  });

  final String shell;
  final ValueChanged<String> onShell;
  final String? app;
  final ValueChanged<String?> onOpen;

  static const _shells = [
    ('aurora', 'Aurora'),
    ('slate', 'Slate'),
    ('neon', 'Neon'),
  ];
  static const _apps = [
    ('films', 'Films', Icons.movie),
    ('shows', 'Shows', Icons.live_tv),
    ('sport', 'Sport', Icons.sports_soccer),
    ('news', 'News', Icons.newspaper),
    ('music', 'Music', Icons.music_note),
    ('kids', 'Kids', Icons.child_care),
    ('photos', 'Photos', Icons.photo),
    ('cast', 'Cast', Icons.cast),
    ('store', 'Store', Icons.shop),
    ('games', 'Games', Icons.sports_esports),
    ('browser', 'Browser', Icons.language),
    ('tracking', 'Tracking', Icons.center_focus_strong),
    ('markers', 'Markers', Icons.grid_on),
    ('video', 'Video', Icons.play_circle),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = switch (shell) {
      'slate' => const Color(0xFF12141A),
      'neon' => const Color(0xFF140018),
      _ => const Color(0xFF071426),
    };
    return ColoredBox(
      color: bg,
      child: app == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Text(
                        _shells.firstWhere((item) => item.$1 == shell).$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        tooltip: 'TV system',
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onSelected: onShell,
                        itemBuilder: (context) => [
                          for (final item in _shells)
                            PopupMenuItem(value: item.$1, child: Text(item.$2)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.all(20),
                    crossAxisCount: 7,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      for (final item in _apps)
                        InkWell(
                          onTap: () => onOpen(item.$1),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(item.$3, color: Colors.white),
                                const SizedBox(height: 6),
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
                    ],
                  ),
                ),
              ],
            )
          : _TvApp(id: app!, onBack: () => onOpen(null)),
    );
  }
}

class _TvApp extends StatelessWidget {
  const _TvApp({required this.id, required this.onBack});

  final String id;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Text(
                id,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          const Expanded(
            child: Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white54,
                size: 72,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsoleOs extends StatelessWidget {
  const _ConsoleOs({
    required this.store,
    required this.device,
    required this.app,
    required this.onOpen,
  });

  final StageStore store;
  final PropDevice device;
  final String? app;
  final ValueChanged<String?> onOpen;

  static const _shells = [
    ('xbox', 'Xbox Series'),
    ('ps5', 'PlayStation 5'),
    ('ps2', 'PlayStation 2'),
    ('x360', 'Xbox 360'),
  ];

  @override
  Widget build(BuildContext context) {
    final shell = device.os.shell.isEmpty ? 'xbox' : device.os.shell;
    final bg = switch (shell) {
      'ps5' => const Color(0xFF07111F),
      'ps2' => const Color(0xFF8A8C90),
      'x360' => const Color(0xFF6E706F),
      _ => const Color(0xFF061803),
    };
    final cover = imageProviderForPath(device.os.steamCover);
    void onShell(String id) =>
        store.updateOs(device.id, (os) => os.copyWith(shell: id));
    final home = switch (shell) {
      'xbox' => XboxSeriesHome(
        store: store,
        device: device,
        onOpen: onOpen,
        onShell: onShell,
      ),
      'x360' => Xbox360Home(
        store: store,
        device: device,
        onOpen: onOpen,
        onShell: onShell,
      ),
      'ps5' => Ps5Home(
        store: store,
        device: device,
        onOpen: onOpen,
        onShell: onShell,
      ),
      'ps2' => Ps2Home(
        store: store,
        device: device,
        onOpen: onOpen,
        onShell: onShell,
      ),
      _ => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _shells
                      .firstWhere(
                        (item) => item.$1 == shell,
                        orElse: () => _shells.first,
                      )
                      .$2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onSelected: (id) =>
                      store.updateOs(device.id, (os) => os.copyWith(shell: id)),
                  itemBuilder: (context) => [
                    for (final item in _shells)
                      PopupMenuItem(value: item.$1, child: Text(item.$2)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _GameTile(
                    title: device.os.steamTitle.isEmpty
                        ? 'Steam game'
                        : device.os.steamTitle,
                    image: cover,
                    onTap: () => onOpen('steam'),
                  ),
                  for (final title in [
                    'Night Run',
                    'Harbor',
                    'Signal',
                    'Relay',
                  ])
                    _GameTile(title: title, onTap: () => onOpen(title)),
                ],
              ),
            ),
          ],
        ),
      ),
    };
    return Material(
      color: bg,
      child: app == null
          ? home
          : app == 'steam'
          ? _SteamPane(store: store, device: device, onBack: () => onOpen(null))
          : _NowPlaying(title: app!, onBack: () => onOpen(null)),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.title, required this.onTap, this.image});

  final String title;
  final VoidCallback onTap;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 140,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
            image: image == null
                ? null
                : DecorationImage(image: image!, fit: BoxFit.cover),
          ),
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _NowPlaying extends StatelessWidget {
  const _NowPlaying({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SteamPane extends StatefulWidget {
  const _SteamPane({
    required this.store,
    required this.device,
    required this.onBack,
  });

  final StageStore store;
  final PropDevice device;
  final VoidCallback onBack;

  @override
  State<_SteamPane> createState() => _SteamPaneState();
}

class _SteamPaneState extends State<_SteamPane> {
  late final TextEditingController _title = TextEditingController(
    text: widget.device.os.steamTitle,
  );

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1B2838),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Text(
                  'Steam',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Text(
              'One cover is linked at a time. Launch opens the prop game screen on this console.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Game title',
                hintStyle: TextStyle(color: Colors.white38),
              ),
              onSubmitted: (value) => widget.store.updateOs(
                widget.device.id,
                (os) => os.copyWith(steamTitle: value.trim()),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final file = await FilePicker.pickFile(
                      type: FileType.image,
                    );
                    if (file == null) return;
                    final path = await persistPickedImage(file);
                    if (path == null) return;
                    widget.store.updateOs(
                      widget.device.id,
                      (os) => os.copyWith(
                        steamCover: path,
                        steamTitle: _title.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Upload cover'),
                ),
                FilledButton(
                  onPressed: () => widget.store.updateOs(
                    widget.device.id,
                    (os) => os.copyWith(
                      steamTitle: _title.text.trim().isEmpty
                          ? 'Steam game'
                          : _title.text.trim(),
                    ),
                  ),
                  child: const Text('Launch'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CctvOs extends StatefulWidget {
  const _CctvOs();

  @override
  State<_CctvOs> createState() => _CctvOsState();
}

class _CctvOsState extends State<_CctvOs> {
  final _names = ['Gate', 'Lobby', 'Loading bay', 'Stage'];
  int? _full;
  double _zoom = 1;
  double _scrub = 0.7;
  bool _rec = true;
  final int _alert = 2;

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now().format(context);
    return ColoredBox(
      color: const Color(0xFF050607),
      child: _full != null
          ? _camera(_full!, large: true)
          : Column(
              children: [
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    children: [
                      for (var i = 0; i < _names.length; i++) _camera(i),
                    ],
                  ),
                ),
                _bar(now),
              ],
            ),
    );
  }

  Widget _camera(int index, {bool large = false}) {
    return GestureDetector(
      onTap: () => setState(() => _full = large ? null : index),
      child: Container(
        margin: const EdgeInsets.all(4),
        color: Color(0xFF101820 + index * 0x101008),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.videocam,
                color: Colors.white24,
                size: large ? 72 : 36,
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: Text(
                _names[index],
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            if (_rec)
              const Positioned(
                right: 8,
                top: 8,
                child: Text(
                  'REC',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (index == _alert)
              const Positioned(
                left: 8,
                bottom: 8,
                child: Text(
                  'MOTION',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
                ),
              ),
            if (large) ...[
              Positioned(
                right: 8,
                bottom: 48,
                child: Column(
                  children: [
                    IconButton(
                      onPressed: () =>
                          setState(() => _zoom = (_zoom + 0.25).clamp(1, 3)),
                      icon: const Icon(Icons.zoom_in, color: Colors.white),
                    ),
                    Text(
                      '${_zoom.toStringAsFixed(1)}×',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: _bar(TimeOfDay.now().format(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bar(String now) {
    return Row(
      children: [
        Text(now, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Expanded(
          child: Slider(
            value: _scrub,
            onChanged: (value) => setState(() => _scrub = value),
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _rec = !_rec),
          icon: Icon(
            _rec ? Icons.fiber_manual_record : Icons.stop,
            color: Colors.redAccent,
            size: 16,
          ),
        ),
      ],
    );
  }
}
