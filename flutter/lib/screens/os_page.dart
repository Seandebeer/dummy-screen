import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../app.dart';
import '../deck/chrome.dart';
import '../store.dart';
import '../format.dart';
import '../models.dart';
import '../phone/app_catalog.dart';
import '../phone/catalog.dart';
import '../phone/console_apps.dart';
import '../phone/desk_settings.dart';
import '../phone/home_view.dart';
import '../phone/lock_screen.dart';
import '../phone/os_apps.dart';
import '../phone/phone_shell.dart';
import '../phone/form_factor.dart';
import '../phone/settings_app.dart';
import '../phone/smart_home.dart';
import '../theme.dart';
import '../vfx/catalog.dart';
import '../vfx/mark_glyph.dart';
import '../widgets/three_finger.dart';

class OsPage extends StatefulWidget {
  const OsPage({super.key});

  @override
  State<OsPage> createState() => _OsPageState();
}

class _OsPageState extends State<OsPage> {
  Timer? _clock;
  StreamSubscription<AccelerometerEvent>? _tilt;
  String? _app;
  String? _thread;
  bool _grey = false;
  String? _launchApp;
  int _launchTick = 0;
  int _closeTick = 0;
  bool _openingPending = false;
  int _side = 0;
  StageStore? _store;
  final Set<String> _lockedVisit = {};
  String? _sheet;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) StoreScope.of(context).beginOsSession();
    });
    try {
      _tilt = accelerometerEventStream().listen(
        (event) {
          if (!mounted) return;
          final side = event.x.abs() > 6 && event.x.abs() > event.y.abs()
              ? (event.x > 0 ? 1 : -1)
              : 0;
          if (side != _side) setState(() => _side = side);
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _store = StoreScope.of(context);
    final device = _store!.deviceById(_store!.boundDeviceId);
    if (device != null && (device.kind == 'phone' || device.kind == 'tablet')) {
      final id = device.id;
      final skip = _store!.bypassLock || device.os.lockType == 'off';
      if (skip) {
        _store!.bypassLock = false;
        if (device.locked) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _store?.setLocked(id, false);
          });
        }
      } else if (_lockedVisit.add(id) && !device.locked) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _store?.setLocked(id, true);
        });
      }
    }
    final pending = StoreScope.of(context).pendingApp;
    if (pending == null || _openingPending) return;
    _openingPending = true;
    StoreScope.of(context).pendingApp = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openingPending = false;
      if (mounted) _open(pending);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _tilt?.cancel();
    final id = _store?.boundDeviceId;
    if (id != null) _store!.driveOs(id, null);
    _store?.endOsSession();
    super.dispose();
  }

  void _toggleFilming() {
    FocusManager.instance.primaryFocus?.unfocus();
    final store = StoreScope.of(context);
    store.setFilming(!store.filming);
  }

  void _home(PropDevice device) {
    if (device.locked) return;
    StoreScope.of(context).driveOs(device.id, '');
    setState(() {
      _app = null;
      _thread = null;
      _grey = false;
      _launchApp = null;
      _closeTick++;
    });
  }

  void _openBanner(BannerNote banner) {
    final store = StoreScope.of(context);
    store.dismissBanner(banner.id);
    final device = store.deviceById(store.boundDeviceId);
    if (device == null) return;
    if (device.locked) store.setLocked(device.id, false);
    final id = banner.appId.isNotEmpty ? banner.appId : _idForLabel(banner.appLabel);
    final works = osAppWorks(id);
    final phone = device.kind == 'phone' || device.kind == 'tablet';
    if (phone) {
      if (!works) {
        setState(() {
          _grey = true;
          _app = null;
          _thread = null;
        });
        return;
      }
      setState(() => _grey = false);
      _open(id);
      return;
    }
    setState(() {
      _grey = false;
      _launchTick++;
      _launchApp = works ? id : 'grey-track';
    });
  }

  String _idForLabel(String label) {
    for (final app in kPropApps) {
      if (app.label == label) return app.id;
    }
    if (label == 'Mail') return 'email';
    if (label == 'Messages') return 'messages';
    return '';
  }

  void _open(String id, {String? thread}) {
    final store = StoreScope.of(context);
    final deviceId = store.boundDeviceId;
    if (deviceId != null && !store.remoteDriving(deviceId)) {
      store.driveOs(deviceId, id);
    }
    if (id == 'messages') {
      final store = StoreScope.of(context);
      final deviceId = store.boundDeviceId;
      if (deviceId != null) {
        for (final banner in List<BannerNote>.of(store.bannersFor(deviceId))) {
          store.dismissBanner(banner.id);
        }
      }
    }
    setState(() {
      _app = id;
      _thread = thread ?? (id == 'messages' ? _thread : null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final device = store.deviceById(store.boundDeviceId);
    final palette = paletteFor(store.appTheme);
    final editing = !store.filming;
    return ThreeFingerToggle(
      onToggle: _toggleFilming,
      enableKey: false,
      child: GridFill(
        palette: palette,
        child: Column(
        children: [
          if (editing) _editHeader(store, device, palette),
          Expanded(
            child: device == null
                ? const _PickDevice()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final framed = constraints.maxWidth >= 520 && !store.filming;
                      final landscape = device.os.autoRotate && _side != 0;
                      final metrics = metricsFor(device.kind, landscape: landscape);
                      final aspect = metrics.aspect;
                      var height = constraints.maxHeight - (framed ? 24 : 0);
                      var width = height * aspect;
                      if (width > constraints.maxWidth - (framed ? 24 : 0)) {
                        width = constraints.maxWidth - (framed ? 24 : 0);
                        height = width / aspect;
                      }
                      final now = propNow(device.clockOffsetMinutes);
                      final phone = device.kind == 'phone' || device.kind == 'tablet';
                      final driven = store.remoteDriving(device.id);
                      final shown = driven ? (store.drivenApp ?? '') : (_app ?? '');
                      final stage = phone
                          ? PhoneShell(
                          framed: false,
                          timeLabel: formatClock(now),
                          keyboardRoute: _grey ? 'grey' : '$shown:${_thread ?? ''}',
                          onHome: () => _home(device),
                          onStatusTap: editing && device.kind == 'phone'
                              ? () => _cycleRadio(store, device)
                              : null,
                          call: store.callFor(device.id),
                          onAccept: () =>
                              store.setCallStatus(device.id, 'active'),
                          onEnd: () => store.endCall(device.id),
                          alarm: store.alarms[device.id] ?? false,
                          onDismissAlarm: () =>
                              store.setAlarm(device.id, false),
                          banners: store.bannersFor(device.id),
                          onDismissBanner: store.dismissBanner,
                          onOpenBanner: _openBanner,
                          body: _body(store, device, now),
                          device: device,
                        )
                          : FormOs(
                              store: store,
                              device: device,
                              onOpenBanner: _openBanner,
                              launchApp: _launchApp,
                              launchTick: _launchTick,
                              closeTick: _closeTick,
                            );
                      final marked = _withMarks(stage, device, store);
                      final screen = Center(
                        child: DecoratedBox(
                          decoration: framed
                              ? const BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x66FFFFFF),
                                      blurRadius: 36,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Color(0x332A6CFF),
                                      blurRadius: 64,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                )
                              : const BoxDecoration(),
                          child: SizedBox(
                            width: framed ? width : constraints.maxWidth,
                            height: framed ? height : constraints.maxHeight,
                            child: IgnorePointer(
                              ignoring: driven,
                              child: framed
                                  ? DeviceBezel(frame: metrics.frame, child: marked)
                                  : marked,
                            ),
                          ),
                        ),
                      );
                      if (!editing) return screen;
                      return Stack(
                        children: [
                          screen,
                          Positioned(
                            left: 8,
                            top: 8,
                            child: _workspaceTools(device, store),
                          ),
                          if (store.osFlash != null)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 72,
                              child: Center(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xE610141A),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    child: Text(
                                      store.osFlash!,
                                      key: const Key('os-undo-flash'),
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (device.os.showTracking)
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 16,
                              child: _trackingBar(store),
                            ),
                          if (_sheet != null)
                            Positioned.fill(
                              child: _headerSheet(store, device),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      ),
    );
  }

  void _cycleRadio(StageStore store, PropDevice device) {
    final current = device.os.cellular;
    final index = kCellularRadios.indexOf(current);
    final next = kCellularRadios[(index + 1) % kCellularRadios.length];
    store.updateOs(device.id, (os) => os.copyWith(cellular: next));
  }

  Widget _workspaceTools(PropDevice device, StageStore store) {
    final wide = MediaQuery.sizeOf(context).width >= 768;
    final size = wide ? 28.0 : 18.0;
    return Row(
      children: [
        _workspaceBack(device, size),
        const SizedBox(width: 4),
        _roundTool(
          key: const Key('os-undo'),
          tooltip: 'Undo',
          icon: Icons.undo,
          size: size,
          onPressed: store.undoOs,
        ),
        _roundTool(
          key: const Key('os-redo'),
          tooltip: 'Redo',
          icon: Icons.redo,
          size: size,
          onPressed: store.redoOs,
        ),
      ],
    );
  }

  Widget _roundTool({
    required Key key,
    required String tooltip,
    required IconData icon,
    required double size,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: IconButton(
        key: key,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: size),
      ),
    );
  }

  Widget _workspaceBack(PropDevice device, double size) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: IconButton(
        key: const Key('os-workspace-back'),
        tooltip: 'Back on this device',
        onPressed: () {
          if (_app == null && _thread == null && !_grey && _launchApp == null) {
            return;
          }
          StoreScope.of(context).driveOs(device.id, '');
          setState(() {
            _thread = null;
            _app = null;
            _grey = false;
            _launchApp = null;
            _closeTick++;
          });
        },
        icon: Icon(Icons.arrow_back, size: size),
      ),
    );
  }

  Widget _editHeader(StageStore store, PropDevice? device, DeckPalette palette) {
    final wide = MediaQuery.sizeOf(context).width >= 768;
    final iconSize = wide ? 32.0 : 22.0;
    final linked = device != null &&
        store.targetDeviceId == device.id &&
        (store.sync?.role ?? LinkRole.solo) != LinkRole.solo;
    final apps = device != null &&
        const {'phone', 'tablet', 'computer', 'tv', 'console'}.contains(device.kind);
    final project = _projectName(store, device);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Home',
            onPressed: () => store.openTab(0),
            icon: Icon(Icons.home_outlined, size: iconSize),
          ),
          Expanded(
            child: device == null
                ? Text('OS edit', style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _kindLabel(device.kind),
                        style: TextStyle(color: palette.muted, fontSize: 12),
                      ),
                    ],
                  ),
          ),
          if (linked)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'Linked',
                key: const Key('os-link-status'),
                style: TextStyle(color: kSignal, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          if (device != null)
            IconButton(
              key: const Key('os-devices'),
              tooltip: '$project devices',
              onPressed: () => setState(() => _sheet = _sheet == 'devices' ? null : 'devices'),
              icon: Icon(Icons.devices, size: iconSize),
            ),
          if (apps)
            IconButton(
              key: const Key('os-apps'),
              tooltip: 'Apps',
              onPressed: () => setState(() => _sheet = _sheet == 'apps' ? null : 'apps'),
              icon: Icon(Icons.apps, size: iconSize),
            ),
          if (device != null)
            IconButton(
              key: const Key('os-settings'),
              tooltip: 'Device settings',
              onPressed: () => setState(() => _sheet = _sheet == 'settings' ? null : 'settings'),
              icon: Icon(Icons.settings_outlined, size: iconSize),
            ),
          if (device != null)
            IconButton(
              key: const Key('os-tracking'),
              tooltip: 'Tracking marks',
              onPressed: () => store.updateOs(
                device.id,
                (os) => os.copyWith(showTracking: !os.showTracking),
              ),
              icon: Icon(
                Icons.center_focus_strong,
                size: iconSize,
                color: device.os.showTracking ? kSignal : null,
              ),
            ),
          IconButton(
            tooltip: 'Fullscreen',
            onPressed: device == null ? null : _toggleFilming,
            icon: Icon(Icons.fullscreen, size: iconSize),
          ),
        ],
      ),
    );
  }

  Widget _headerSheet(StageStore store, PropDevice device) {
    final live = store.deviceById(device.id) ?? device;
    return GestureDetector(
      onTap: () => setState(() => _sheet = null),
      child: ColoredBox(
        color: const Color(0x88000000),
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: Material(
              color: const Color(0xF010141A),
              child: SizedBox(
                width: 380,
                child: switch (_sheet) {
                  'devices' => _deviceList(store, live),
                  'apps' => _appList(live),
                  'settings' => _settingsFor(store, live),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _deviceList(StageStore store, PropDevice current) {
    final devices = store.selectedProjectId == null
        ? store.devices.where((item) => item.projectId != 'sandbox').toList()
        : store.activeDevices;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${_projectName(store, current)} Devices',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 8),
        if (devices.isEmpty)
          const Text('No devices in this project yet.', style: TextStyle(color: kMuted)),
        for (final item in devices)
          ListTile(
            key: Key('os-device-${item.id}'),
            selected: item.id == current.id,
            title: Text(item.name),
            subtitle: Text(_kindLabel(item.kind)),
            onTap: () {
              store.bindDevice(item.id);
              setState(() {
                _sheet = null;
                _app = null;
                _thread = null;
              });
            },
          ),
      ],
    );
  }

  Widget _appList(PropDevice device) {
    final store = StoreScope.of(context);
    final order = device.os.homeOrder.isEmpty ? kHomeOrder : device.os.homeOrder;
    final sections = <(String, List<(String, String, IconData, Color)>)>[
      (
        'Functional',
        [
          for (final app in kPropApps)
            (app.id, app.label, app.icon, app.color),
        ],
      ),
      for (final section in mockCatalog)
        (
          section.name,
          [
            for (final app in section.apps)
              (app.id, app.label, app.icon, app.color),
          ],
        ),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${device.name} apps', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 4),
        const Text(
          'Categories start closed. Show or hide an app on the home screen.',
          style: TextStyle(color: kMuted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        for (final section in sections)
          _AppCategory(
            name: section.$1,
            apps: section.$2,
            shown: order.toSet(),
            onOpen: (id) {
              setState(() => _sheet = null);
              _open(id);
            },
            onToggle: (id) {
              if (kDockIds.contains(id)) return;
              final next = [...order];
              if (next.contains(id)) {
                next.remove(id);
              } else {
                next.add(id);
              }
              store.updateOs(device.id, (os) => os.copyWith(homeOrder: next));
            },
          ),
      ],
    );
  }

  Widget _settingsFor(StageStore store, PropDevice device) {
    final live = store.deviceById(device.id) ?? device;
    final body = switch (live.kind) {
      'computer' => ComputerSettings(store: store, device: live),
      'console' => ConsoleSettings(
          store: store,
          device: live,
          onClose: () => setState(() => _sheet = null),
        ),
      'tv' => _ShellSettings(
          title: 'Smart TV',
          shells: const [('aurora', 'Aurora'), ('slate', 'Slate'), ('neon', 'Neon')],
          selected: live.os.shell.isEmpty ? 'aurora' : live.os.shell,
          onSelect: (id) => store.updateOs(live.id, (os) => os.copyWith(shell: id)),
        ),
      'atm' => _AtmSettings(store: store, device: live),
      'cctv' => const _NoteSettings(
          title: 'CCTV',
          body: 'This camera wall uses one fixed layout.',
        ),
      'smarthome' || 'homephone' => _PanelSettings(store: store, device: live),
      _ => SettingsApp(store: store, device: live),
    };
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: 'Close',
            onPressed: () => setState(() => _sheet = null),
            icon: const Icon(Icons.close),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _withMarks(Widget stage, PropDevice device, StageStore store) {
    if (!device.os.showTracking) return stage;
    final config = store.screenConfig;
    final style = config['marksId'] as String? ?? 'cross';
    if (!kMarkerKinds.any((item) => item.id == style) && style != 'checkerboard' && style != 'dots') {
      return stage;
    }
    final raw = config['layouts'];
    List<StageMark> marks = defaultLayoutFor(style);
    if (raw is Map && raw[style] is List) {
      marks = [
        for (final item in jsonList(raw[style]))
          if (item is Map) StageMark.fromJson(jsonMap(item)),
      ];
    }
    final scale = (config['scale'] as num?)?.toDouble() ?? 1;
    final thick = (config['thickness'] as num?)?.toDouble() ?? 1;
    final fade = (config['opacity'] as num?)?.toDouble() ?? 1;
    return Stack(
      fit: StackFit.expand,
      children: [
        stage,
        IgnorePointer(
          child: Stack(
            children: [
              for (final item in marks)
                Align(
                  alignment: Alignment(item.x / 50 - 1, item.y / 50 - 1),
                  child: Opacity(
                    opacity: fade.clamp(0.15, 1),
                    child: MarkGlyph(
                      kind: item.kind,
                      color: Colors.white,
                      scale: 1.1 * scale,
                      thickness: 0.6 * thick,
                      rotation: item.rot,
                      x: item.x,
                      y: item.y,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _trackingBar(StageStore store) {
    final selected = store.screenConfig['marksId'] as String? ?? 'cross';
    final addKind = store.screenConfig['addKind'] as String? ?? 'cross';
    void write(Map<String, dynamic> patch) {
      store.setScreenConfig({...store.screenConfig, ...patch});
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: const Color(0xCC10141A),
        borderRadius: BorderRadius.circular(28),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              PopupMenuButton<String>(
                tooltip: 'New marker type',
                icon: const Icon(Icons.my_location, color: Colors.white),
                onSelected: (id) => write({'addKind': id}),
                itemBuilder: (context) => [
                  for (final kind in kMarkerKinds)
                    PopupMenuItem(
                      value: kind.id,
                      child: Text(kind.id == addKind ? '${kind.name} ·' : kind.name),
                    ),
                ],
              ),
              PopupMenuButton<String>(
                key: const Key('os-track-menu'),
                tooltip: 'Tracking marks',
                icon: const Icon(Icons.category_outlined, color: Colors.white),
                onSelected: (id) => write({'marksId': id}),
                itemBuilder: (context) => [
                  for (final style in kTrackingStyles)
                    PopupMenuItem(
                      key: Key('os-track-${style.id}'),
                      value: style.id,
                      child: Text(style.id == selected ? '${style.name} ·' : style.name),
                    ),
                ],
              ),
              IconButton(
                tooltip: 'Reset tracking marks',
                onPressed: () {
                  final layouts = Map<String, dynamic>.from(
                    store.screenConfig['layouts'] as Map? ?? {},
                  );
                  layouts.remove(selected);
                  write({'layouts': layouts, 'scale': 1, 'thickness': 1, 'opacity': 1});
                },
                icon: const Icon(Icons.restart_alt, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(StageStore store, PropDevice device, DateTime now) {
    if (device.locked && device.os.lockType != 'off') {
      return LockView(
        device: device,
        timeLabel: formatClock(now),
        dateLabel: formatDay(now),
        onUnlock: () => store.setLocked(device.id, false),
        onSetPasscode: (code) => store.updateOs(
          device.id,
          (current) => current.copyWith(passcode: code),
        ),
        onSetPattern: (code) => store.updateOs(
          device.id,
          (current) => current.copyWith(pattern: code),
        ),
      );
    }
    if (_grey) return const GreyTrackPage();
    final app = store.remoteDriving(device.id) ? store.drivenApp : _app;
    if (app == null) {
        return PhoneHome(
        skin: device.skin,
        os: device.os,
        wide: device.kind == 'tablet',
        light: device.os.isLight,
        onOpen: _open,
      );
    }
    return OsAppView(
      store: store,
      device: device,
      appId: app,
      thread: _thread,
      onOpen: _open,
      onClose: () => setState(() {
        _app = null;
        _thread = null;
        _grey = false;
      }),
    );
  }

}

class _PickDevice extends StatelessWidget {
  const _PickDevice();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Center(
      child: InkWell(
        key: const Key('os-pick-device'),
        onTap: store.openHomeProjects,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select or add new device',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'Home > New Project > New Device',
                textAlign: TextAlign.center,
                style: TextStyle(color: kMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _projectName(StageStore store, PropDevice? device) {
  final id = device?.projectId ?? store.selectedProjectId;
  for (final project in store.projects) {
    if (project.id == id) return project.name;
  }
  return 'Project';
}

class _AppCategory extends StatefulWidget {
  const _AppCategory({
    required this.name,
    required this.apps,
    required this.shown,
    required this.onOpen,
    required this.onToggle,
  });

  final String name;
  final List<(String, String, IconData, Color)> apps;
  final Set<String> shown;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onToggle;

  @override
  State<_AppCategory> createState() => _AppCategoryState();
}

class _AppCategoryState extends State<_AppCategory> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(_open ? Icons.expand_less : Icons.expand_more, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          for (final app in widget.apps)
            InkWell(
              key: Key('os-app-${app.$1}'),
              onTap: () => widget.onOpen(app.$1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(app.$3, color: app.$4, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(app.$2)),
                    IconButton(
                      tooltip: widget.shown.contains(app.$1) ? 'Hide on home' : 'Show on home',
                      onPressed: () => widget.onToggle(app.$1),
                      icon: Icon(
                        widget.shown.contains(app.$1) ? Icons.visibility : Icons.visibility_off,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _ShellSettings extends StatelessWidget {
  const _ShellSettings({
    required this.title,
    required this.shells,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final List<(String, String)> shells;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Interface', style: TextStyle(color: kMuted)),
        for (final shell in shells)
          ListTile(
            key: Key('shell-${shell.$1}'),
            title: Text(shell.$2),
            trailing: selected == shell.$1 ? const Icon(Icons.check, color: kSignal) : null,
            onTap: () => onSelect(shell.$1),
          ),
      ],
    );
  }
}

class _NoteSettings extends StatelessWidget {
  const _NoteSettings({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(color: kMuted)),
      ],
    );
  }
}

class _AtmSettings extends StatelessWidget {
  const _AtmSettings({required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  Widget build(BuildContext context) {
    final os = device.os;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('ATM', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        TextFormField(
          initialValue: os.bankName,
          decoration: const InputDecoration(labelText: 'Bank name'),
          onFieldSubmitted: (value) => store.updateOs(
            device.id,
            (current) => current.copyWith(bankName: value.trim()),
          ),
        ),
        TextFormField(
          initialValue: os.bankHolder,
          decoration: const InputDecoration(labelText: 'Account holder'),
          onFieldSubmitted: (value) => store.updateOs(
            device.id,
            (current) => current.copyWith(bankHolder: value.trim()),
          ),
        ),
        TextFormField(
          initialValue: '${os.bankBalance}',
          decoration: const InputDecoration(labelText: 'Balance'),
          keyboardType: TextInputType.number,
          onFieldSubmitted: (value) => store.updateOs(
            device.id,
            (current) => current.copyWith(bankBalance: int.tryParse(value) ?? current.bankBalance),
          ),
        ),
      ],
    );
  }
}

class _PanelSettings extends StatelessWidget {
  const _PanelSettings({required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  Widget build(BuildContext context) {
    final os = device.os;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          device.kind == 'homephone' ? 'Smart home phone' : 'Smart home',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final id in homePanelOrder(os))
          TextFormField(
            initialValue: homePanelName(os, id),
            decoration: InputDecoration(labelText: kHomePanelDefaults[id] ?? id),
            onFieldSubmitted: (value) {
              final names = {...os.panelNames, id: value.trim()};
              store.updateOs(device.id, (current) => current.copyWith(panelNames: names));
            },
          ),
      ],
    );
  }
}

String _kindLabel(String kind) {
  return switch (kind) {
    'tablet' => 'Tablet',
    'computer' => 'Computer',
    'tv' => 'Smart TV',
    'console' => 'Game console',
    'atm' => 'ATM',
    'cctv' => 'CCTV',
    'smarthome' => 'Smart home',
    'homephone' => 'Smart home phone',
    _ => 'Phone',
  };
}
