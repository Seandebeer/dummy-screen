import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../app.dart';
import '../deck/chrome.dart';
import '../store.dart';
import '../format.dart';
import '../models.dart';
import '../phone/catalog.dart';
import '../phone/console_apps.dart';
import '../phone/desk_settings.dart';
import '../phone/home_view.dart';
import '../phone/lock_screen.dart';
import '../phone/os_apps.dart';
import '../phone/phone_shell.dart';
import '../phone/form_factor.dart';
import '../phone/settings_app.dart';
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
    if (device != null &&
        (device.kind == 'phone' || device.kind == 'tablet') &&
        _lockedVisit.add(device.id) &&
        !device.locked) {
      final id = device.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _store?.setLocked(id, true);
      });
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
                      );
                      if (!editing) return screen;
                      final room = constraints.maxWidth - width > 140;
                      return Stack(
                        children: [
                          screen,
                          Positioned(
                            left: 8,
                            bottom: 16,
                            child: _workspaceBack(device),
                          ),
                          if (device.os.showTracking && room)
                            Positioned(
                              right: 8,
                              top: 12,
                              bottom: 12,
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

  Widget _workspaceBack(PropDevice device) {
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
        icon: const Icon(Icons.arrow_back, size: 18),
      ),
    );
  }

  Widget _editHeader(StageStore store, PropDevice? device, DeckPalette palette) {
    final linked = device != null &&
        store.targetDeviceId == device.id &&
        (store.sync?.role ?? LinkRole.solo) != LinkRole.solo;
    final apps = device != null &&
        const {'phone', 'tablet', 'computer', 'tv', 'console'}.contains(device.kind);
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
            icon: const Icon(Icons.home_outlined, size: 20),
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
              tooltip: 'Devices',
              onPressed: () => setState(() => _sheet = _sheet == 'devices' ? null : 'devices'),
              icon: const Icon(Icons.devices, size: 22),
            ),
          if (apps)
            IconButton(
              key: const Key('os-apps'),
              tooltip: 'Apps',
              onPressed: () => setState(() => _sheet = _sheet == 'apps' ? null : 'apps'),
              icon: const Icon(Icons.apps, size: 22),
            ),
          if (device != null)
            IconButton(
              key: const Key('os-settings'),
              tooltip: 'Device settings',
              onPressed: () => setState(() => _sheet = _sheet == 'settings' ? null : 'settings'),
              icon: const Icon(Icons.settings_outlined, size: 22),
            ),
          IconButton(
            tooltip: 'Fullscreen',
            onPressed: device == null ? null : _toggleFilming,
            icon: const Icon(Icons.expand_less),
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
        const Text('Devices', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
    final apps = [
      for (final id in device.os.homeOrder.isEmpty ? kHomeOrder : device.os.homeOrder)
        ?propAppById(id),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${device.name} apps', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 8),
        for (final app in apps)
          ListTile(
            key: Key('os-app-${app.id}'),
            leading: Icon(app.icon, color: app.color),
            title: Text(app.label),
            onTap: () {
              setState(() => _sheet = null);
              _open(app.id);
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
    final style = store.screenConfig['marksId'] as String? ?? 'cross';
    if (!kMarkerKinds.any((item) => item.id == style)) return stage;
    final marks = defaultLayoutFor(style);
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
                  child: MarkGlyph(
                    kind: item.kind,
                    color: Colors.white,
                    scale: 1.1,
                    thickness: 0.6,
                    rotation: item.rot,
                    x: item.x,
                    y: item.y,
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
    return Material(
      color: const Color(0xCC10141A),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 128,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('Tracking', style: TextStyle(fontSize: 11, color: Colors.white70)),
            ),
            for (final style in kMarkerKinds)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: TextButton(
                  key: Key('os-track-${style.id}'),
                  style: TextButton.styleFrom(
                    backgroundColor: selected == style.id
                        ? kSignal.withValues(alpha: 0.25)
                        : Colors.white10,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onPressed: () {
                    final next = Map<String, dynamic>.from(store.screenConfig);
                    next['marksId'] = style.id;
                    store.setScreenConfig(next);
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(style.name, style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(StageStore store, PropDevice device, DateTime now) {
    if (device.locked) {
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
