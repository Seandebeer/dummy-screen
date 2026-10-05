import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../app.dart';
import '../image_file.dart';
import '../store.dart';
import '../format.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../phone/app_catalog.dart';
import '../phone/home_view.dart';
import '../phone/library_app.dart';
import '../phone/lock_screen.dart';
import '../phone/phone_apps.dart';
import '../phone/phone_shell.dart';
import '../phone/desk_apps.dart';
import '../phone/prop_apps.dart';
import '../phone/form_factor.dart';
import '../phone/settings_app.dart';
import '../phone/social_apps.dart';
import '../phone/maps_app.dart';
import '../phone/utility_apps.dart';
import '../theme.dart';
import '../widgets/three_finger.dart';

const _shutterColors = [
  0xFF318DF6,
  0xFF30D158,
  0xFFFF9F0A,
  0xFFFF453A,
  0xFF5E5CE6,
];

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
  bool _openingPending = false;
  int _shutter = 0;
  int _side = 0;
  StageStore? _store;

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
    });
  }

  List<Map<String, dynamic>> _mail(StageStore store, String deviceId) {
    final raw = store.pages['mail-$deviceId'];
    if (raw is! Map) return const [];
    return [
      for (final item in jsonList(raw['items']))
        if (item is Map) jsonMap(item),
    ];
  }

  Widget _deviceMenu(StageStore store, PropDevice? device) {
    final projectDevices = store.selectedProjectId == null
        ? const <PropDevice>[]
        : store.activeDevices;
    final sandbox = projectDevices.isEmpty || device?.projectId == 'sandbox';
    if (sandbox) {
      return DropdownButton<String>(
        isExpanded: true,
        value: kSandboxKinds.any((item) => item.$1 == device?.kind)
            ? device!.kind
            : 'phone',
        underline: const SizedBox.shrink(),
        items: [
          for (final item in kSandboxKinds)
            DropdownMenuItem(value: item.$1, child: Text(item.$2)),
        ],
        onChanged: (value) {
          if (value != null) store.openSandbox(value);
        },
      );
    }
    final devices = projectDevices;
    return DropdownButton<String>(
      isExpanded: true,
      value: device != null && devices.any((item) => item.id == device.id)
          ? device.id
          : null,
      hint: Text(device?.name ?? 'Device'),
      underline: const SizedBox.shrink(),
      items: [
        for (final item in devices)
          DropdownMenuItem(value: item.id, child: Text(item.name)),
      ],
      onChanged: (value) {
        if (value != null) store.bindDevice(value);
      },
    );
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
    return ThreeFingerToggle(
      onToggle: _toggleFilming,
      enableKey: false,
      child: Column(
        children: [
          if (!store.filming)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: kLine)),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => store.openTab(0),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back'),
                  ),
                  Expanded(child: _deviceMenu(store, device)),
                  IconButton(
                    tooltip: 'Fullscreen',
                    onPressed: device == null ? null : _toggleFilming,
                    icon: const Icon(Icons.fullscreen),
                  ),
                ],
              ),
            ),
          Expanded(
            child: device == null
                ? const _Sandbox()
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
                      final stage = phone
                          ? PhoneShell(
                          framed: framed && device.kind == 'phone',
                          timeLabel: formatClock(now),
                          onHome: () => _home(device),
                          call: store.callFor(device.id),
                          onAccept: () =>
                              store.setCallStatus(device.id, 'active'),
                          onEnd: () => store.endCall(device.id),
                          alarm: store.alarms[device.id] ?? false,
                          onDismissAlarm: () =>
                              store.setAlarm(device.id, false),
                          banners: store.bannersFor(device.id),
                          onDismissBanner: store.dismissBanner,
                          body: _body(store, device, now),
                          device: device,
                        )
                          : FormOs(store: store, device: device);
                      return Center(
                        child: SizedBox(
                          width: framed ? width : constraints.maxWidth,
                          height: framed ? height : constraints.maxHeight,
                          child: IgnorePointer(
                            ignoring: driven,
                            child: framed && device.kind != 'phone'
                                ? DeviceBezel(frame: metrics.frame, child: stage)
                                : stage,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (!store.filming && device != null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Mock device · control deck can drive calls & messages',
                textAlign: TextAlign.center,
                style: TextStyle(color: kMuted, fontSize: 11),
              ),
            ),
        ],
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
    if (app == 'messages') {
      return Material(
        color: const Color(0xFF0B0B0F),
        child: MessagesApp(
          store: store,
          deviceId: device.id,
          initialThread: _thread,
          onClose: () => setState(() {
            _app = null;
            _thread = null;
          }),
        ),
      );
    }
    return Material(
      color: const Color(0xFF0B0B0F),
      child: _appBody(store, device, app),
    );
  }

  Widget _appBody(StageStore store, PropDevice device, String id) {
    switch (id) {
      case 'phone':
        return Material(
          color: const Color(0xFF0B0B0F),
          child: PhoneDialer(
            store: store,
            deviceId: device.id,
            contacts: contactsFor(device.os),
            language: device.os.language,
          ),
        );
      case 'contacts':
        return Material(
          color: const Color(0xFF0B0B0F),
          child: ContactsApp(
            contacts: contactsFor(device.os),
            onAdd: (person) => store.updateOs(
              device.id,
              (current) => current.copyWith(people: [...current.people, person]),
            ),
            onMessage: (contact) => _open('messages', thread: contact.name),
            onCall: (contact) => store.startCall(
              deviceId: device.id,
              contactName: contact.name,
              contactNumber: contact.number,
              direction: 'outgoing',
            ),
          ),
        );
      case 'settings':
        return SettingsApp(store: store, device: device);
      case 'clock':
        return ClockApp(store: store, device: device);
      case 'notes':
        return NotesApp(store: store, device: device);
      case 'calculator':
        return const CalculatorApp();
      case 'camera':
        return CameraApp(
          photos: store.photos[device.id] ?? const [],
          onShutter: (bytes) async {
            final color = _shutterColors[_shutter % _shutterColors.length];
            var image = '';
            if (bytes != null && bytes.isNotEmpty) {
              image = await persistImageBytes(bytes) ?? '';
            }
            if (!mounted) return;
            store.addPhoto(device.id, color, image: image);
            setState(() => _shutter += 1);
          },
        );
      case 'photos':
        return PhotosApp(photos: store.photos[device.id] ?? const []);
      case 'email':
      case 'mail':
        return InboxApp(extra: _mail(store, device.id));
      case 'calendar':
        return CalendarApp(offsetMinutes: device.clockOffsetMinutes);
      case 'maps':
        return const MapsApp();
      case 'music':
        return const PropMusic();
      case 'browser':
        return const PropBrowser();
      case 'facepage':
        return const GrapevineApp();
      case 'photogram':
        return const LumeApp();
      case 'vidtube':
        return const StreamlyApp();
      case 'quicktok':
        return const FlickdeckApp();
      case 'news':
        return const BulletinApp();
      case 'fitness':
        return const PulseApp();
      case 'property':
        return const RealtyApp();
      case 'webdeck':
        return const WebdeckApp();
      case 'appstore':
        return LibraryApp(store: store, device: device);
      case 'videocall':
        return VidcallApp(contacts: contactsFor(device.os));
      default:
        final feed = kFeeds[id];
        if (feed != null) {
          return PropFeed(title: feed.$1, accent: feed.$2, posts: feed.$3);
        }
        final mock = catalogAppById(id);
        if (mock != null) return MockScreen(app: mock);
        return const Center(
          child: Text('Prop screen', style: TextStyle(color: kMuted)),
        );
    }
  }
}

class _Sandbox extends StatelessWidget {
  const _Sandbox();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This screen is a sandbox.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a device on Home and mark it as this phone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => store.openTab(0),
              child: const Text('Home'),
            ),
          ],
        ),
      ),
    );
  }
}
