import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../format.dart';
import '../image_file.dart';
import '../models.dart';
import '../screens/markers_page.dart';
import '../screens/videos_page.dart';
import '../screens/vfx_page.dart';
import '../store.dart';
import 'atm_home.dart';
import 'console_apps.dart';
import 'catalog.dart';
import 'desk_os_apps.dart';
import 'desk_settings.dart';
import 'desk_window.dart';
import 'ios_keyboard.dart';
import 'mac_desk.dart';
import 'mac_desktop.dart';
import 'os_apps.dart';
import 'phone_shell.dart';
import 'win_desktop.dart';
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

/// Phones and tablets start portrait. Everything else starts landscape.
bool kindStartsLandscape(String kind) {
  switch (kind) {
    case 'phone':
    case 'tablet':
    case 'homephone':
      return false;
    default:
      return true;
  }
}

/// [turned] swaps the device between its default orientation and a 90° turn.
DeviceMetrics metricsForTurn(String kind, {required bool turned}) {
  final landscape = kindStartsLandscape(kind) != turned;
  switch (kind) {
    case 'phone':
    case 'homephone':
      return metricsFor('phone', landscape: landscape);
    case 'tablet':
      return metricsFor('tablet', landscape: landscape);
    default:
      final base = metricsFor(kind);
      if (!turned) return base;
      return DeviceMetrics(1 / base.aspect, base.frame);
  }
}

DeviceMetrics metricsFor(String kind, {bool landscape = false}) {
  switch (kind) {
    case 'tablet':
      return DeviceMetrics(landscape ? 4 / 3 : 3 / 4, 'tablet');
    case 'computer':
      return const DeviceMetrics(16 / 10, 'laptop');
    case 'tv':
    case 'console':
      return const DeviceMetrics(16 / 9, 'tv');
    case 'cctv':
      return const DeviceMetrics(16 / 9, 'monitor');
    case 'atm':
    case 'smarthome':
      return const DeviceMetrics(4 / 3, 'tablet');
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
      'phone' => 34.0,
      'tablet' => 18.0,
      'laptop' => 10.0,
      'tv' => 6.0,
      'monitor' => 8.0,
      _ => 12.0,
    };
    final pad = switch (frame) {
      'phone' => 8.0,
      'tablet' => 10.0,
      'tv' => 8.0,
      'laptop' => 8.0,
      _ => 10.0,
    };
    final screen = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: child,
    );
    if (frame == 'laptop') {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C32),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF6A6A72)),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 16)),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: screen,
              ),
            ),
            Container(
              height: 14,
              margin: const EdgeInsets.fromLTRB(18, 0, 18, 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A30),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E34),
        borderRadius: BorderRadius.circular(radius + pad),
        border: Border.all(color: const Color(0xFF8A8A92), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, pad, pad, frame == 'monitor' ? 22 : pad),
        child: Column(
          children: [
            Expanded(child: screen),
            if (frame == 'monitor')
              Container(
                width: 84,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
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
  const FormOs({
    super.key,
    required this.store,
    required this.device,
    this.onOpenBanner,
    this.launchApp,
    this.launchTick = 0,
    this.closeTick = 0,
  });

  final StageStore store;
  final PropDevice device;
  final void Function(BannerNote banner)? onOpenBanner;
  final String? launchApp;
  final int launchTick;
  final int closeTick;

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

  void _open(String? id) {
    setState(() {
      final toggleOff = id != null &&
          id == _app &&
          (id == 'tracking' || id == 'markers');
      _app = toggleOff ? null : id;
    });
  }

  @override
  void didUpdateWidget(FormOs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.closeTick != oldWidget.closeTick) {
      _app = null;
    } else if (widget.launchTick != oldWidget.launchTick &&
        widget.launchApp != null) {
      _app = widget.launchApp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = _app == 'grey-track'
        ? const GreyTrackPage()
        : switch (device.kind) {
      'tv' => _TvOs(
        shell: os.shell.isEmpty ? 'aurora' : os.shell,
        onShell: _shell,
        app: _app,
        onOpen: _open,
      ),
      'console' => _ConsoleOs(
        store: widget.store,
        device: device,
        app: _app,
        onOpen: _open,
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
        store: widget.store,
        device: device,
        shell: computerShell(os.shell),
        onShell: _shell,
        app: _app,
        onOpen: _open,
      ),
    };
    final banners = widget.store.bannersFor(device.id);
    if (banners.isEmpty) return stage;
    return Stack(
      children: [
        stage,
        Positioned(
          top: 8,
          left: 10,
          right: 10,
          child: Column(
            children: [
              for (final banner in banners.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Dismissible(
                    key: ValueKey('banner-${banner.id}'),
                    direction: DismissDirection.horizontal,
                    onDismissed: (_) => widget.store.dismissBanner(banner.id),
                    child: OsBanner(
                      banner: banner,
                      onTap: () => widget.onOpenBanner?.call(banner),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tools that exist only on a computer, shown after the shared apps.
const _toolIcons = <String, (String, IconData)>{
  'call': ('Call', Icons.video_call),
  'tracking': ('Tracking', Icons.center_focus_strong),
  'markers': ('UI Markers', Icons.grid_on),
  'video': ('Video', Icons.movie),
  'word': ('Word', Icons.description),
  'excel': ('Excel', Icons.table_chart),
  'terminal': ('Terminal', Icons.terminal),
};

/// A computer starts with the same apps as a phone, then the desk tools.
List<(String, String, IconData)> deskApps(OsSettings os) {
  final out = <(String, String, IconData)>[];
  for (final id in homePageOne()) {
    final prop = propAppById(id);
    if (prop != null) {
      out.add((id, appLabel(prop, branded: os.branded), brandedGlyph(prop, branded: os.branded).$1));
    }
  }
  for (final entry in _toolIcons.entries) {
    out.add((entry.key, entry.value.$1, entry.value.$2));
  }
  return out;
}

String deskTitle(String id, OsSettings os) {
  final tool = _toolIcons[id];
  if (tool != null) return tool.$1;
  return osAppTitle(id, os);
}

/// Computer shell. Tracking and UI markers cover the desktop; Video uses playback.
class _ComputerOs extends StatelessWidget {
  const _ComputerOs({
    required this.store,
    required this.device,
    required this.shell,
    required this.onShell,
    required this.app,
    required this.onOpen,
  });

  final StageStore store;
  final PropDevice device;
  final String shell;
  final ValueChanged<String> onShell;
  final String? app;
  final ValueChanged<String?> onOpen;

  Widget? _cover() {
    return switch (app) {
      'tracking' => StoreScope(
        store: store,
        child: VfxPage(onExit: () => onOpen(null)),
      ),
      'markers' => StoreScope(
        store: store,
        child: MarkersPage(onExit: () => onOpen(null)),
      ),
      _ => null,
    };
  }

  Widget _window(String id) {
    if (_toolIcons.containsKey(id)) return _DeskTool(id: id, store: store);
    return DeskAppView(
      store: store,
      device: device,
      appId: id,
      onOpen: (next, {String? thread}) => onOpen(next),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apps = deskApps(device.os);
    final cover = _cover();
    final windowId = cover == null ? app : null;
    final folder = windowId != null && windowId.startsWith('folder:');
    if (shell == 'macos') {
      return MacDesktop(
        store: store,
        device: device,
        appTitle: windowId == null || folder
            ? null
            : deskTitle(windowId, device.os),
        tool: windowId == null || folder ? null : _window(windowId),
        onOpen: onOpen,
        onShell: onShell,
        shells: kComputerShells,
        overlay: cover,
      );
    }
    if (shell == 'windows') {
      return WinDesktop(
        store: store,
        device: device,
        apps: apps,
        appId: app,
        appTitle: windowId == null || folder
            ? null
            : deskTitle(windowId, device.os),
        tool: windowId == null || folder ? null : _window(windowId),
        onOpen: onOpen,
        onShell: onShell,
        shells: kComputerShells,
        overlay: cover,
      );
    }
    return _LinuxDesktop(
      store: store,
      device: device,
      apps: apps,
      app: app,
      window: windowId == null || folder ? null : _window(windowId),
      overlay: cover,
      onOpen: onOpen,
      onShell: onShell,
    );
  }
}

class _LinuxDesktop extends StatefulWidget {
  const _LinuxDesktop({
    required this.store,
    required this.device,
    required this.apps,
    required this.app,
    required this.window,
    required this.overlay,
    required this.onOpen,
    required this.onShell,
  });

  final StageStore store;
  final PropDevice device;
  final List<(String, String, IconData)> apps;
  final String? app;
  final Widget? window;
  final Widget? overlay;
  final ValueChanged<String?> onOpen;
  final ValueChanged<String> onShell;

  @override
  State<_LinuxDesktop> createState() => _LinuxDesktopState();
}

class _LinuxDesktopState extends State<_LinuxDesktop> {
  final _rename = TextEditingController();
  String? _renaming;
  bool _activities = false;
  bool _allApps = true;

  @override
  void dispose() {
    _rename.dispose();
    super.dispose();
  }

  String _named(OsSettings os, String id, String fallback) {
    final named = os.deskNames[id]?.trim() ?? '';
    return named.isEmpty ? fallback : named;
  }

  void _beginRename(String id, String label) {
    _rename.text = label;
    _rename.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _rename.text.length,
    );
    setState(() => _renaming = id);
  }

  void _commitRename() {
    final id = _renaming;
    if (id == null) return;
    final name = _rename.text;
    setState(() => _renaming = null);
    widget.store.updateOs(
      widget.device.id,
      (current) => renameDeskItem(current, id, name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = widget.store.deviceById(widget.device.id) ?? widget.device;
    final os = live.os;
    const ink = Colors.white;
    final folder = widget.overlay == null &&
        widget.app != null &&
        widget.app!.startsWith('folder:');
    final title = widget.overlay != null
        ? null
        : folder
        ? _named(os, widget.app!, 'New Folder')
        : widget.app == null
        ? null
        : deskTitle(widget.app!, os);
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final current =
            widget.store.deviceById(widget.device.id) ?? widget.device;
        return Material(
          color: const Color(0xFF12352C),
          child: Column(
            children: [
              _menu(ink, current.os),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        key: const Key('linux-desk-area'),
                        behavior: HitTestBehavior.opaque,
                        onSecondaryTap: () => widget.store.updateOs(
                          widget.device.id,
                          addDeskFolder,
                        ),
                      ),
                    ),
                    if (widget.overlay != null)
                      Positioned.fill(child: widget.overlay!),
                    Positioned.fill(
                      child: Padding(
                      padding: const EdgeInsets.fromLTRB(72, 12, 12, 12),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final id in MacLayout.deskFolders(current.os))
                              _linuxIcon(
                                current.os,
                                id,
                                macGlyph(id, current.os).label,
                                const Icon(
                                  Icons.folder,
                                  color: Color(0xFFE8B931),
                                  size: 28,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    ),
                    if (_activities) _activitiesView(current.os, ink),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: _dock(ink, current.os),
                    ),
                    if (title != null)
                      Center(
                        child: _Window(
                          title: title,
                          onClose: () => widget.onOpen(null),
                          child: folder
                              ? const Center(
                                  child: Text(
                                    'This folder is empty.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                              : widget.window ?? const SizedBox.shrink(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _linuxIcon(OsSettings os, String id, String fallback, Widget mark) {
    final label = _named(os, id, fallback);
    return SizedBox(
      width: 88,
      height: 92,
      child: Column(
        children: [
          GestureDetector(
            key: Key('linux-icon-$id'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() => _activities = false);
              widget.onOpen(id);
            },
            child: SizedBox(width: 72, height: 48, child: Center(child: mark)),
          ),
          DeskIconName(
            label: label,
            labelKey: Key('linux-label-$id'),
            editing: _renaming == id,
            controller: _rename,
            onStart: () => _beginRename(id, label),
            onCommit: _commitRename,
          ),
        ],
      ),
    );
  }

  Widget _menu(Color ink, OsSettings os) {
    final now = osNow(os);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final label =
        '${days[now.weekday - 1]} ${formatOsClock(now, hour24: os.clockFormat == '24')}';
    return Container(
      height: 32,
      color: const Color(0xCC1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          TextButton(
            key: const Key('ubuntu-activities'),
            onPressed: () => setState(() => _activities = !_activities),
            child: Text(
              'Activities',
              style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: os.showClock
                ? Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ink, fontSize: 13),
                  )
                : const SizedBox.shrink(),
          ),
          const Icon(Icons.wifi, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Icon(Icons.volume_up, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Icon(Icons.power_settings_new, color: Colors.white, size: 16),
          PopupMenuButton<String>(
            tooltip: 'System',
            icon: Icon(Icons.arrow_drop_down, size: 18, color: ink),
            onSelected: widget.onShell,
            itemBuilder: (context) => [
              for (final item in kComputerShells)
                PopupMenuItem(value: item.$1, child: Text(item.$2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activitiesView(OsSettings os, Color ink) {
    final apps = _allApps ? widget.apps : widget.apps.take(8).toList();
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xF0122E28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(84, 18, 24, 18),
          child: Column(
            children: [
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.white54, size: 18),
                    SizedBox(width: 8),
                    Text('Type to search…', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final item in apps)
                              _linuxIcon(
                                os,
                                item.$1,
                                item.$2,
                                Icon(
                                  item.$3,
                                  color: os.branded ? (brandMark(item.$1)?.$1 ?? ink) : ink,
                                  size: 32,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _allApps = false),
                    child: Text(
                      'Frequent',
                      style: TextStyle(
                        color: _allApps ? Colors.white54 : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _allApps = true),
                    child: Text(
                      'All',
                      style: TextStyle(
                        color: _allApps ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dock(Color ink, OsSettings os) {
    final docked = [
      for (final id in kDockIds)
        if (propAppById(id) case final prop?)
          (id, appLabel(prop, branded: os.branded), brandedGlyph(prop, branded: os.branded).$1),
      for (final item in widget.apps)
        if (item.$1 == 'settings') item,
    ];
    return Container(
      width: 58,
      color: const Color(0x66111111),
      child: Column(
        children: [
          const SizedBox(height: 8),
          for (final item in docked)
            IconButton(
              tooltip: item.$2,
              onPressed: () {
                setState(() => _activities = false);
                widget.onOpen(item.$1);
              },
              icon: Icon(item.$3, color: ink, size: 22),
            ),
          const Spacer(),
          Container(
            width: 28,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _Window extends StatelessWidget {
  const _Window({
    required this.title,
    required this.child,
    required this.onClose,
  });

  final String title;
  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DeskSizer(
      child: Material(
        color: const Color(0xF016161A),
        elevation: 12,
        child: Column(
          children: [
            Container(
              height: 32,
              color: const Color(0xFF2A2A30),
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
            Expanded(child: DeviceKeyboard(child: child)),
          ],
        ),
      ),
    );
  }
}

class _DeskTool extends StatefulWidget {
  const _DeskTool({required this.id, required this.store});

  final String id;
  final StageStore store;

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
        return StoreScope(
          store: widget.store,
          child: const VideosPage(),
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
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final live = store.deviceById(device.id) ?? device;
        return _scene(live);
      },
    );
  }

  Widget _scene(PropDevice live) {
    final shell = live.os.shell.isEmpty ? 'xbox' : live.os.shell;
    final bg = switch (shell) {
      'ps5' => const Color(0xFF07111F),
      'ps2' => const Color(0xFF8A8C90),
      'x360' => const Color(0xFF6E706F),
      _ => const Color(0xFF061803),
    };
    final cover = imageProviderForPath(live.os.steamCover);
    void onShell(String id) =>
        store.updateOs(live.id, (os) => os.copyWith(shell: id));
    final home = switch (shell) {
      'xbox' => XboxSeriesHome(
        store: store,
        device: live,
        onOpen: onOpen,
        onShell: onShell,
      ),
      'x360' => Xbox360Home(
        store: store,
        device: live,
        onOpen: onOpen,
        onShell: onShell,
      ),
      'ps5' => Ps5Home(
        store: store,
        device: live,
        onOpen: onOpen,
        onShell: onShell,
      ),
      'ps2' => Ps2Home(
        store: store,
        device: live,
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
                      store.updateOs(live.id, (os) => os.copyWith(shell: id)),
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
                    title: live.os.steamTitle.isEmpty
                        ? 'Steam game'
                        : live.os.steamTitle,
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
      child: switch (app) {
        null => home,
        'steam' => _SteamPane(
          store: store,
          device: live,
          onBack: () => onOpen(null),
        ),
        'settings' => ConsoleSettings(
          store: store,
          device: live,
          onClose: () => onOpen(null),
        ),
        'appstore' => ConsoleAppStore(
          store: store,
          device: live,
          onOpen: (id) => onOpen(id),
          onClose: () => onOpen(null),
        ),
        _ => _NowPlaying(
          title: consoleAppLabel(app!, live.os),
          onBack: () => onOpen(null),
        ),
      },
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
