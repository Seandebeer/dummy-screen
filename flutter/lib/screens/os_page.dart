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
import '../phone/clock_settings.dart';
import '../phone/console_apps.dart';
import '../phone/desk_settings.dart';
import '../phone/home_view.dart';
import '../phone/lock_screen.dart';
import '../phone/os_apps.dart';
import '../phone/phone_shell.dart';
import '../phone/form_factor.dart';
import 'home_page.dart';
import '../phone/settings_app.dart';
import '../phone/smart_home.dart';
import '../theme.dart';
import '../vfx/catalog.dart';
import '../vfx/mark_glyph.dart';
import '../widgets/prompt.dart';
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
  bool _quarter = false;
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
    final entering = !store.filming;
    if (entering && _quarter) setState(() => _quarter = false);
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
                      final turned = !store.filming &&
                          (_quarter || (device.os.autoRotate && _side != 0));
                      final metrics = metricsForTurn(device.kind, turned: turned);
                      // Fit the default orientation first. A 90° turn keeps that
                      // scale and only shrinks when the swapped box leaves the stage.
                      final fit = framed || store.filming;
                      final margin = framed ? 24.0 : 0.0;
                      final maxW = constraints.maxWidth - margin;
                      final maxH = constraints.maxHeight - margin;
                      final base = metricsForTurn(device.kind, turned: false);
                      var baseHeight = maxH;
                      var baseWidth = baseHeight * base.aspect;
                      if (baseWidth > maxW && base.aspect > 0) {
                        baseWidth = maxW;
                        baseHeight = baseWidth / base.aspect;
                      }
                      var width = turned ? baseHeight : baseWidth;
                      var height = turned ? baseWidth : baseHeight;
                      if (width > maxW && width > 0) {
                        final scale = maxW / width;
                        width *= scale;
                        height *= scale;
                      }
                      if (height > maxH && height > 0) {
                        final scale = maxH / height;
                        width *= scale;
                        height *= scale;
                      }
                      final now = osNow(device.os);
                      final phone = device.kind == 'phone' || device.kind == 'tablet';
                      final driven = store.remoteDriving(device.id);
                      final shown = driven ? (store.drivenApp ?? '') : (_app ?? '');
                      final stage = phone
                          ? PhoneShell(
                          framed: false,
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
                          body: _body(
                            store,
                            device,
                            now,
                            wide: device.kind == 'tablet' || metrics.aspect > 1,
                          ),
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
                        child: SizedBox(
                          width: fit ? width : constraints.maxWidth,
                          height: fit ? height : constraints.maxHeight,
                          child: IgnorePointer(
                            ignoring: driven,
                            child: framed
                                ? DeviceBezel(frame: metrics.frame, child: marked)
                                : marked,
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
        _roundTool(
          key: const Key('os-rotate'),
          tooltip: 'Rotate',
          icon: Icons.screen_rotation,
          size: size,
          onPressed: () => setState(() => _quarter = !_quarter),
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
              onPressed: () {
                final next = !device.os.showTracking;
                if (next) {
                  store.setScreenConfig({...store.screenConfig, 'opacity': 1});
                }
                store.updateOs(
                  device.id,
                  (os) => os.copyWith(showTracking: next),
                );
              },
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
        ListTile(
          key: const Key('os-device-new'),
          leading: const Icon(Icons.add),
          title: const Text('New'),
          onTap: () => _createDevice(store, current, duplicate: false),
        ),
        ListTile(
          key: const Key('os-device-duplicate'),
          leading: const Icon(Icons.copy),
          title: const Text('Duplicate'),
          onTap: () => _createDevice(store, current, duplicate: true),
        ),
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
          leading: ClockSettings(store: store, device: live),
        ),
      'atm' => _AtmSettings(store: store, device: live),
      'cctv' => _NoteSettings(
          title: 'CCTV',
          body: 'This camera wall uses one fixed layout.',
          leading: ClockSettings(store: store, device: live),
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
    final fade = _markOpacity(config['opacity']);
    final ink = parseHex(config['markColor'] as String?, Colors.white);
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
                      color: ink,
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

  double _markOpacity(Object? raw) {
    if (raw is! num) return 1;
    final value = raw.toDouble();
    if (value > 1) return (value / 100).clamp(0.15, 1);
    return value.clamp(0.15, 1);
  }

  void _writeScreen(StageStore store, Map<String, dynamic> patch) {
    store.setScreenConfig({...store.screenConfig, ...patch});
  }

  List<StageMark> _marksFor(StageStore store, String style) {
    final raw = store.screenConfig['layouts'];
    if (raw is Map && raw[style] is List) {
      return [
        for (final item in jsonList(raw[style]))
          if (item is Map) StageMark.fromJson(jsonMap(item)),
      ];
    }
    return defaultLayoutFor(style);
  }

  Widget _trackingBar(StageStore store) {
    final selected = store.screenConfig['marksId'] as String? ?? 'cross';
    final addKind = store.screenConfig['addKind'] as String? ?? 'cross';
    final point = isPointStyle(selected);
    final chrome = StageChrome(store.deviceById(store.boundDeviceId)?.os.isLight ?? false);
    final menu = TextStyle(color: chrome.ink);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: chrome.bar,
        borderRadius: BorderRadius.circular(28),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              PopupMenuButton<String>(
                tooltip: 'Colour',
                icon: Icon(Icons.palette_outlined, color: chrome.ink),
                color: chrome.fill,
                onSelected: (hex) => _writeScreen(store, {'markColor': hex}),
                itemBuilder: (context) => [
                  for (final color in kVfxPalette)
                    PopupMenuItem(
                      value: '#${(color.hex.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
                      child: Text(color.name, style: menu),
                    ),
                  PopupMenuItem(value: '#FFFFFF', child: Text('White', style: menu)),
                ],
              ),
              PopupMenuButton<String>(
                key: const Key('os-track-menu'),
                tooltip: 'Tracking marks',
                icon: Icon(Icons.category_outlined, color: chrome.ink),
                color: chrome.fill,
                onSelected: (id) => _writeScreen(store, {'marksId': id}),
                itemBuilder: (context) => [
                  for (final style in kTrackingStyles)
                    PopupMenuItem(
                      key: Key('os-track-${style.id}'),
                      value: style.id,
                      child: Text(style.id == selected ? '${style.name} ·' : style.name, style: menu),
                    ),
                ],
              ),
              PopupMenuButton<String>(
                tooltip: 'New marker type',
                icon: Icon(Icons.my_location, color: chrome.ink),
                color: chrome.fill,
                onSelected: (id) => _writeScreen(store, {'addKind': id, 'marksId': id}),
                itemBuilder: (context) => [
                  for (final kind in kMarkerKinds)
                    PopupMenuItem(
                      value: kind.id,
                      child: Text(kind.id == addKind ? '${kind.name} ·' : kind.name, style: menu),
                    ),
                ],
              ),
              IconButton(
                tooltip: 'Size & thickness',
                onPressed: () => _markSizeSheet(store),
                icon: Icon(Icons.tune, color: chrome.ink),
              ),
              if (point)
                IconButton(
                  tooltip: 'Rotate all markers 45°',
                  onPressed: () {
                    final next = [
                      for (final mark in _marksFor(store, selected))
                        mark.copyWith(rot: (mark.rot + 45) % 360),
                    ];
                    final layouts = Map<String, dynamic>.from(
                      store.screenConfig['layouts'] as Map? ?? {},
                    );
                    layouts[selected] = [for (final mark in next) mark.toJson()];
                    _writeScreen(store, {'layouts': layouts});
                  },
                  icon: Icon(Icons.rotate_right, color: chrome.ink),
                ),
              IconButton(
                tooltip: 'Save screen',
                onPressed: () => _saveTracking(store, selected),
                icon: Icon(Icons.save_outlined, color: chrome.ink),
              ),
              IconButton(
                tooltip: 'Reset tracking marks',
                onPressed: () {
                  final layouts = Map<String, dynamic>.from(
                    store.screenConfig['layouts'] as Map? ?? {},
                  );
                  layouts.remove(selected);
                  _writeScreen(store, {
                    'layouts': layouts,
                    'scale': 1,
                    'thickness': 1,
                    'opacity': 1,
                  });
                },
                icon: Icon(Icons.restart_alt, color: chrome.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markSizeSheet(StageStore store) async {
    final chrome = StageChrome(store.deviceById(store.boundDeviceId)?.os.isLight ?? false);
    var scale = (store.screenConfig['scale'] as num?)?.toDouble() ?? 1;
    var thick = (store.screenConfig['thickness'] as num?)?.toDouble() ?? 1;
    var fade = _markOpacity(store.screenConfig['opacity']);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: chrome.fill,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('SIZE  ${scale.toStringAsFixed(2)}×', style: TextStyle(color: chrome.ink, fontSize: 12, fontWeight: FontWeight.w700)),
                  Slider(
                    value: scale.clamp(0.5, 3),
                    min: 0.5,
                    max: 3,
                    onChanged: (value) {
                      setSheet(() => scale = value);
                      _writeScreen(store, {'scale': value, 'thickness': thick, 'opacity': fade});
                    },
                  ),
                  Text('THICKNESS  ${thick.toStringAsFixed(2)}', style: TextStyle(color: chrome.ink, fontSize: 12, fontWeight: FontWeight.w700)),
                  Slider(
                    value: thick.clamp(0.4, 3),
                    min: 0.4,
                    max: 3,
                    onChanged: (value) {
                      setSheet(() => thick = value);
                      _writeScreen(store, {'scale': scale, 'thickness': value, 'opacity': fade});
                    },
                  ),
                  Text('OPACITY  ${fade.toStringAsFixed(2)}', style: TextStyle(color: chrome.ink, fontSize: 12, fontWeight: FontWeight.w700)),
                  Slider(
                    value: fade.clamp(0.15, 1),
                    min: 0.15,
                    max: 1,
                    onChanged: (value) {
                      setSheet(() => fade = value);
                      _writeScreen(store, {'scale': scale, 'thickness': thick, 'opacity': value});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveTracking(StageStore store, String marksId) async {
    final name = await promptText(
      context,
      title: 'Save screen',
      initial: marksId,
      confirm: 'Save',
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final device = store.deviceById(store.boundDeviceId);
    store.upsertSaved(
      SavedLayout(
        id: 's-${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        skin: device?.skin ?? 'modern',
        clockOffsetMinutes: 0,
        notes: '',
        vfxColor: store.vfxColor,
        vfxMarks: const [],
        uiMarkers: const [],
        kind: 'screen',
        deviceId: store.boundDeviceId ?? '',
        payload: Map<String, dynamic>.from(store.screenConfig),
      ),
    );
  }

  Future<void> _createDevice(StageStore store, PropDevice current, {required bool duplicate}) async {
    final created = await addProjectDevice(
      context,
      store: store,
      projectId: current.projectId,
      copyFrom: duplicate ? current : null,
    );
    if (created == null || !mounted) return;
    store.bindDevice(created.id);
    setState(() {
      _sheet = null;
      _app = null;
      _thread = null;
      _grey = false;
      _launchApp = null;
    });
  }

  Widget _body(StageStore store, PropDevice device, DateTime now, {bool wide = false}) {
    if (device.locked && device.os.lockType != 'off') {
      return LockView(
        device: device,
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
        wide: wide,
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
    this.leading,
  });

  final String title;
  final List<(String, String)> shells;
  final String selected;
  final ValueChanged<String> onSelect;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ?leading,
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
  const _NoteSettings({required this.title, required this.body, this.leading});

  final String title;
  final String body;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ?leading,
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
        ClockSettings(store: store, device: device),
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
        ClockSettings(store: store, device: device),
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
