import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../image_file.dart';

import '../app.dart';
import '../deck/chrome.dart';
import '../store.dart';
import '../format.dart';
import '../models.dart';
import '../phone/app_catalog.dart';
import '../phone/app_place.dart';
import '../phone/catalog.dart';
import '../phone/cues.dart';
import '../phone/clock_settings.dart';
import '../phone/console_apps.dart';
import '../phone/desk_settings.dart';
import '../phone/flight_board.dart';
import '../phone/home_view.dart';
import '../phone/transport.dart';
import '../phone/lock_screen.dart';
import '../phone/os_apps.dart';
import '../phone/phone_shell.dart';
import '../phone/device_marks.dart';
import '../phone/form_factor.dart';
import '../phone/game_catalog.dart';
import 'home_page.dart';
import '../os_catalog.dart';
import '../phone/atm_os_settings.dart';
import '../phone/cctv_wall.dart';
import '../phone/language_settings.dart';
import '../phone/place_settings.dart';
import '../phone/settings_app.dart';
import '../phone/settings_kit.dart';
import '../phone/smart_faces.dart';
import '../phone/smart_home.dart';
import '../theme.dart';
import '../vfx/catalog.dart';
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
                          device.kind != 'phone' &&
                          (_quarter || (device.os.autoRotate && _side != 0));
                      final metrics = metricsForTurn(device.kind, turned: turned);
                      // Fit the default orientation first. A 90° turn keeps that
                      // scale and only shrinks when the swapped box leaves the stage.
                      final fit = framed || store.filming;
                      final roomy = framed &&
                          constraints.maxWidth > 480 &&
                          constraints.maxHeight > 420;
                      // Halfway between the old 12px edge and the roomier inset.
                      final inset = roomy
                          ? const EdgeInsets.fromLTRB(42, 30, 42, 54)
                          : (framed ? const EdgeInsets.all(20) : EdgeInsets.zero);
                      final maxW = constraints.maxWidth - inset.horizontal;
                      final maxH = constraints.maxHeight - inset.vertical;
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
                      final cued = PhoneCueLayer(
                        cue: store.cueFor(device.id),
                        skin: device.skin,
                        child: stage,
                      );
                      final marked = _withMarks(cued, device, store);
                      final screen = Padding(
                        padding: inset,
                        child: Center(
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
        if (device.kind != 'phone')
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
    if (device.kind == 'console') return _gameList(store, device);
    final shown = appSurfaceIds(device);
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
        Text(
          device.kind == 'computer'
              ? 'Categories start closed. Show or hide an app on the desktop.'
              : device.kind == 'tv'
              ? 'Categories start closed. Show or hide an app on the home row.'
              : 'Categories start closed. Show or hide an app on the home screen.',
          style: const TextStyle(color: kMuted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        for (final section in sections)
          _AppCategory(
            name: section.$1,
            apps: section.$2,
            shown: shown,
            onOpen: (id) {
              setState(() => _sheet = null);
              _open(id);
            },
            onToggle: (id) {
              final visible = shown.contains(id);
              store.updateOs(
                device.id,
                (os) => placeShownApp(os, id, kind: device.kind, shown: !visible),
              );
            },
          ),
      ],
    );
  }

  Widget _gameList(StageStore store, PropDevice device) {
    final pins = device.os.consolePins.toSet();
    final shelves = <String, List<MockGame>>{};
    for (final game in mockGames) {
      shelves.putIfAbsent(game.shelf, () => []).add(game);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${device.name} games', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 4),
        const Text(
          'Categories start closed. Show or hide a game on the home screen.',
          style: TextStyle(color: kMuted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        for (final entry in shelves.entries)
          _AppCategory(
            name: entry.key,
            apps: [
              for (final game in entry.value)
                (game.id, game.title, game.mark, game.colors.first),
            ],
            shown: pins,
            onOpen: (id) {
              setState(() => _sheet = null);
              _open(id);
            },
            onToggle: (id) {
              final next = [...device.os.consolePins];
              if (next.contains(id)) {
                next.remove(id);
              } else {
                next.add(id);
              }
              store.updateOs(device.id, (os) => os.copyWith(consolePins: next));
            },
          ),
      ],
    );
  }

  _DevicePage _languagePage(StageStore store, PropDevice live) {
    return _DevicePage(
      id: 'language',
      icon: Icons.language,
      title: 'Language',
      detail: languageByCode(live.os.language).native,
      children: [
        LanguageChoices(
          store: store,
          device: live,
          keyPrefix: 'device-language-${live.kind}',
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
          bare: true,
        ),
      'flight' => _DeviceMenu(
          store: store,
          device: live,
          pages: [
            _DevicePage(
              id: 'board',
              icon: transportMark(live.os.face),
              title: 'Board',
              detail: 'Place, heading, and the second board',
              children: [
                SettingsSection(
                  title: 'Place',
                  child: SettingsOptions(
                    prefix: 'transport-mode',
                    options: const [
                      ('flight', 'Flights'),
                      ('train', 'Train'),
                      ('bus', 'Bus'),
                      ('ferry', 'Ferry'),
                    ],
                    selected: transportMode(live.os.face),
                    onSelect: (value) => store.updateOs(
                      live.id,
                      (os) => applyTransport(os, value),
                    ),
                  ),
                ),
                SettingsSection(
                  title: 'Names',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SettingsChoice(
                              label: 'Generic',
                              active: !live.os.branded,
                              onTap: () => store.updateOs(
                                live.id,
                                (os) => os.copyWith(branded: false),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SettingsChoice(
                              label: 'Branded',
                              active: live.os.branded,
                              onTap: () => store.updateOs(
                                live.id,
                                (os) => os.copyWith(branded: true),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const SettingsHint(
                        'Generic uses fictional operator names and matching letter codes. Branded uses the real names.',
                      ),
                    ],
                  ),
                ),
                SettingsSection(
                  title: 'Heading',
                  child: SettingsOptions(
                    prefix: 'flight-heading',
                    options: [
                      (
                        'departures',
                        transportMode(live.os.face) == 'ferry' ? 'Sailings' : 'Departures',
                      ),
                      ('arrivals', 'Arrivals'),
                      ('none', 'No heading'),
                    ],
                    selected: live.os.flightHeading,
                    onSelect: (value) {
                      final mode = transportMode(live.os.face);
                      final columns = [
                        for (var i = 0; i < 7; i++)
                          i < live.os.flightColumns.length
                              ? live.os.flightColumns[i]
                              : transportColumns(mode, value)[i],
                      ];
                      const places = {
                        'DEPARTING TO',
                        'ARRIVING FROM',
                        'DESTINATION',
                        'ORIGIN',
                      };
                      if (places.contains(columns[1])) {
                        columns[1] = transportColumns(mode, value)[1];
                      }
                      store.updateOs(
                        live.id,
                        (os) => os.copyWith(
                          flightHeading: value,
                          flightTitle: transportHeading(mode, value),
                          flightColumns: columns,
                        ),
                      );
                    },
                  ),
                ),
                SettingsSection(
                  title: 'Colours',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FlightSwatches(
                        label: 'Header text',
                        prefix: 'flight-header',
                        selected: live.os.flightHeaderColor,
                        choices: const ['FFD400', 'FFFFFF', '7DDBFF', 'FF8A00'],
                        onSelect: (value) => store.updateOs(
                          live.id,
                          (os) => os.copyWith(flightHeaderColor: value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FlightSwatches(
                        label: 'Body text',
                        prefix: 'flight-body',
                        selected: live.os.flightBodyColor,
                        choices: const ['FFFFFF', 'FFD400', '111111', '7DDBFF'],
                        onSelect: (value) => store.updateOs(
                          live.id,
                          (os) => os.copyWith(flightBodyColor: value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FlightSwatches(
                        label: 'Background',
                        prefix: 'flight-board',
                        selected: live.os.flightBoardColor,
                        choices: const ['0A3C8C', '061428', '0E3B2E', '4A1018', '1C1C1E'],
                        onSelect: (value) => store.updateOs(
                          live.id,
                          (os) => os.copyWith(flightBoardColor: value),
                        ),
                      ),
                    ],
                  ),
                ),
                SettingsSection(
                  title: 'Two boards',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KeyedSubtree(
                        key: const Key('flight-flip'),
                        child: SettingsToggle(
                          label: '2 board flip',
                          hint: 'Switches between two boards.',
                          value: live.os.flightFlip,
                          onChanged: (value) => store.updateOs(
                            live.id,
                            (os) => os.copyWith(flightFlip: value),
                          ),
                        ),
                      ),
                      if (live.os.flightFlip) ...[
                        const SizedBox(height: 8),
                        SettingsStepRow(
                          name: 'Flip duration',
                          label: '${live.os.flightFlipSeconds}s',
                          minusKey: const Key('flight-flip-minus'),
                          plusKey: const Key('flight-flip-plus'),
                          onMinus: live.os.flightFlipSeconds <= 2
                              ? null
                              : () => store.updateOs(
                                  live.id,
                                  (os) => os.copyWith(flightFlipSeconds: os.flightFlipSeconds - 1),
                                ),
                          onPlus: live.os.flightFlipSeconds >= 120
                              ? null
                              : () => store.updateOs(
                                  live.id,
                                  (os) => os.copyWith(flightFlipSeconds: os.flightFlipSeconds + 1),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            _DevicePage(
              id: 'status',
              icon: Icons.schedule,
              title: 'Time',
              detail: 'Current time, stopped, or running',
              children: [
                SettingsSection(
                  title: 'Clock',
                  child: ClockSettings(store: store, device: live),
                ),
              ],
            ),
            _languagePage(store, live),
          ],
        ),
      'tv' => _DeviceMenu(
          store: store,
          device: live,
          pages: [
            _DevicePage(
              id: 'display',
              icon: Icons.tv,
              title: 'Display',
              detail: 'Interface',
              children: [
                SettingsSection(
                  title: 'Wallpaper',
                  child: Column(
                    children: [
                      for (final paper in const [
                        ('aurora', 'Aurora'),
                        ('dusk', 'Dusk'),
                        ('ember', 'Ember'),
                        ('slate', 'Slate'),
                        ('neon', 'Neon'),
                      ])
                        ListTile(
                          key: Key('tv-paper-${paper.$1}'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(paper.$2),
                          trailing: (live.os.backgroundPreset.isEmpty ? 'aurora' : live.os.backgroundPreset) == paper.$1 &&
                                  live.os.backgroundType != 'image'
                              ? const Icon(Icons.check, color: kAccent, size: 18)
                              : null,
                          onTap: () => store.updateOs(
                            live.id,
                            (os) => os.copyWith(backgroundType: 'preset', backgroundPreset: paper.$1),
                          ),
                        ),
                      SettingsUploadRow(
                        uploading: false,
                        showRemove: live.os.backgroundType == 'image' && live.os.backgroundUrl.isNotEmpty,
                        uploadKey: const Key('tv-upload-background'),
                        removeKey: const Key('tv-remove-background'),
                        onUpload: () async {
                          final file = await FilePicker.pickFile(type: FileType.image);
                          if (file == null) return;
                          final path = await persistPickedImage(file);
                          if (path == null) return;
                          store.updateOs(
                            live.id,
                            (os) => os.copyWith(backgroundType: 'image', backgroundUrl: path),
                          );
                        },
                        onRemove: () => store.updateOs(
                          live.id,
                          (os) => os.copyWith(backgroundType: 'preset', backgroundUrl: ''),
                        ),
                      ),
                    ],
                  ),
                ),
                SettingsSection(
                  title: 'Interface',
                  child: Column(
                    children: [
                      for (final shell in const [
                        ('aurora', 'Aurora', 'Soft bands across the screen.', [Color(0xFF1B3A4B), Color(0xFF0E2430)]),
                        ('slate', 'Slate', 'Flat grey panels.', [Color(0xFF3A4250), Color(0xFF1C222C)]),
                        ('neon', 'Neon', 'Bright edge light.', [Color(0xFF123C34), Color(0xFF061814)]),
                      ]) ...[
                        SettingsTile(
                          tileKey: Key('shell-${shell.$1}'),
                          name: shell.$2,
                          desc: shell.$3,
                          preview: shell.$4,
                          active: (live.os.shell.isEmpty ? 'aurora' : live.os.shell) == shell.$1,
                          onTap: () => store.updateOs(live.id, (os) => os.copyWith(shell: shell.$1)),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            _DevicePage(
              id: 'status',
              icon: Icons.schedule,
              title: 'Status',
              detail: 'Clock, place, and temperature',
              children: [
                SettingsSection(title: 'Clock', child: ClockSettings(store: store, device: live)),
                PlaceSettings(store: store, device: live),
              ],
            ),
            _languagePage(store, live),
          ],
        ),
      'atm' => AtmOsSettings(store: store, device: live),
      'cctv' => _DeviceMenu(
          store: store,
          device: live,
          pages: [
            _DevicePage(
              id: 'display',
              icon: Icons.videocam_outlined,
              title: 'Display',
              detail: 'Cameras, names, and footage',
              children: [
                CctvSettingsBody(store: store, device: live),
              ],
            ),
            _languagePage(store, live),
          ],
        ),
      'smarthome' || 'homephone' => _DeviceMenu(
          store: store,
          device: live,
          pages: [
            _DevicePage(
              id: 'display',
              icon: Icons.dashboard_customize_outlined,
              title: 'Display',
              detail: 'Interface',
              children: [
                SettingsSection(
                  title: 'Interface',
                  child: Column(
                    children: [
                      for (final face in kHomeFaces) ...[
                        SettingsTile(
                          tileKey: Key('os-home-face-${face.id}'),
                          name: face.name,
                          desc: face.desc,
                          preview: face.preview,
                          active: homeFaceId(live.os.face) == face.id,
                          onTap: () => store.updateOs(live.id, (os) => os.copyWith(face: face.id)),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            _DevicePage(
              id: 'panels',
              icon: Icons.dashboard_outlined,
              title: 'Panels',
              detail: live.kind == 'homephone' ? 'Smart home phone labels' : 'Panel labels',
              children: [
                SettingsSection(
                  title: 'Panels',
                  child: Column(
                    children: [
                      for (final id in homePanelOrder(live.os))
                        SettingsField(
                          fieldKey: Key('os-home-panel-$id'),
                          label: homePanelFieldLabel(id),
                          value: homePanelName(live.os, id),
                          onChanged: (value) {
                            final names = {...live.os.panelNames, id: value.trim()};
                            store.updateOs(live.id, (current) => current.copyWith(panelNames: names));
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
            _DevicePage(
              id: 'status',
              icon: Icons.schedule,
              title: 'Status',
              detail: 'Clock, place, and temperature',
              children: [
                SettingsSection(title: 'Clock', child: ClockSettings(store: store, device: live)),
                PlaceSettings(store: store, device: live),
              ],
            ),
            _languagePage(store, live),
          ],
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
    final config = store.screenConfig;
    final style = config['marksId'] as String? ?? 'cross';
    if (!kMarkerKinds.any((item) => item.id == style) && style != 'checkerboard' && style != 'dots') {
      return stage;
    }
    final marks = _deviceMarks(store, device, style);
    final scale = (config['scale'] as num?)?.toDouble() ?? 1;
    final thick = (config['thickness'] as num?)?.toDouble() ?? 1;
    final fade = _markOpacity(config['opacity']);
    final ink = parseHex(config['markColor'] as String?, Colors.white);
    final addKind = config['addKind'] as String? ?? style;
    return Stack(
      fit: StackFit.expand,
      children: [
        stage,
        DeviceMarks(
          marks: marks,
          editing: !store.filming,
          scale: scale,
          thickness: thick,
          opacity: fade,
          color: ink,
          addKind: addKind,
          onChange: (next) => store.updateOs(
            device.id,
            (os) => os.copyWith(trackOwned: true, trackMarks: encodeStageMarks(next)),
          ),
        ),
      ],
    );
  }

  List<StageMark> _deviceMarks(StageStore store, PropDevice device, String style) {
    if (device.os.trackOwned) return decodeStageMarks(device.os.trackMarks);
    return _marksFor(store, style);
  }

  void _saveDeviceMarks(StageStore store, PropDevice device, List<StageMark> marks) {
    store.updateOs(
      device.id,
      (os) => os.copyWith(trackOwned: true, trackMarks: encodeStageMarks(marks)),
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
                onSelected: (id) {
                  _writeScreen(store, {'marksId': id});
                  final bound = store.deviceById(store.boundDeviceId);
                  if (bound != null) _saveDeviceMarks(store, bound, defaultLayoutFor(id));
                },
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
                key: const Key('os-track-add'),
                tooltip: 'Add marker',
                onPressed: () {
                  final bound = store.deviceById(store.boundDeviceId);
                  if (bound == null) return;
                  final marks = _deviceMarks(store, bound, selected);
                  final mark = StageMark(
                    id: 'm-${DateTime.now().microsecondsSinceEpoch}',
                    kind: addKind,
                    x: 50,
                    y: marks.length.isEven ? 50 : 62.5,
                  );
                  _saveDeviceMarks(store, bound, [...marks, mark]);
                },
                icon: Icon(Icons.add_location_alt_outlined, color: chrome.ink),
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
                    final bound = store.deviceById(store.boundDeviceId);
                    if (bound == null) return;
                    final next = [
                      for (final mark in _deviceMarks(store, bound, selected))
                        mark.copyWith(rot: (mark.rot + 45) % 360),
                    ];
                    _saveDeviceMarks(store, bound, next);
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
                  final bound = store.deviceById(store.boundDeviceId);
                  if (bound != null) {
                    store.updateOs(
                      bound.id,
                      (os) => os.copyWith(trackOwned: false, trackMarks: const []),
                    );
                  }
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
        onOrder: (order) => store.updateOs(
          device.id,
          (current) => current.copyWith(homeOrder: order),
        ),
        onDock: (dock) => store.updateOs(
          device.id,
          (current) => current.copyWith(dockOrder: dock),
        ),
        onHide: (id) => store.updateOs(device.id, (current) {
          if (current.homeHidden.contains(id)) return current;
          return current.copyWith(homeHidden: [...current.homeHidden, id]);
        }),
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
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: app.$4,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(app.$3, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(app.$2)),
                    IconButton(
                      tooltip: widget.shown.contains(app.$1) ? 'Hide' : 'Show',
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

class _DevicePage {
  const _DevicePage({
    required this.id,
    required this.icon,
    required this.title,
    required this.detail,
    required this.children,
  });

  final String id;
  final IconData icon;
  final String title;
  final String detail;
  final List<Widget> children;
}

/// Category index shared with the phone Settings app, filled with the
/// controls that belong to this device.
class _DeviceMenu extends StatefulWidget {
  const _DeviceMenu({
    required this.store,
    required this.device,
    required this.pages,
  });

  final StageStore store;
  final PropDevice device;
  final List<_DevicePage> pages;

  @override
  State<_DeviceMenu> createState() => _DeviceMenuState();
}

class _DeviceMenuState extends State<_DeviceMenu> {
  String? _page;

  @override
  Widget build(BuildContext context) {
    final page = _page == null
        ? null
        : widget.pages.where((item) => item.id == _page).firstOrNull;
    return SettingsPage(
      listKey: Key('device-settings-${widget.device.kind}'),
      title: page?.title ?? 'Settings',
      onBack: _page == null ? null : () => setState(() => _page = null),
      onReset: () => widget.store.factoryResetDevice(widget.device.id),
      children: [
        if (page == null)
          SettingsGroup(
            children: [
              for (final item in widget.pages)
                SettingsCategory(
                  categoryKey: Key('device-cat-${widget.device.kind}-${item.id}'),
                  icon: item.icon,
                  title: item.title,
                  detail: item.detail,
                  onOpen: () => setState(() => _page = item.id),
                ),
            ],
          )
        else
          ...page.children,
      ],
    );
  }
}

class _FlightSwatches extends StatelessWidget {
  const _FlightSwatches({
    required this.label,
    required this.prefix,
    required this.selected,
    required this.choices,
    required this.onSelect,
  });

  final String label;
  final String prefix;
  final String selected;
  final List<String> choices;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final hex in choices)
              GestureDetector(
                key: Key('$prefix-$hex'),
                onTap: () => onSelect(hex),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(0xFF000000 | (int.tryParse(hex, radix: 16) ?? 0)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected.toUpperCase() == hex ? Colors.white : Colors.white24,
                      width: selected.toUpperCase() == hex ? 2 : 1,
                    ),
                  ),
                ),
              ),
          ],
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
    'flight' => 'Transport Info',
    'console' => 'Game console',
    'atm' => 'ATM',
    'cctv' => 'CCTV',
    'smarthome' => 'Smart home',
    'homephone' => 'Smart home phone',
    _ => 'Phone',
  };
}
