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
    super.dispose();
  }

  void _toggleFilming() {
    FocusManager.instance.primaryFocus?.unfocus();
    final store = StoreScope.of(context);
    store.setFilming(!store.filming);
  }

  void _home(PropDevice device) {
    if (device.locked) return;
    setState(() {
      _app = null;
      _thread = null;
    });
  }

  void _open(String id, {String? thread}) {
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
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          device == null ? 'Sandbox' : device.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (device != null)
                          Text(
                            '${skinDisplayName(device.skin).toUpperCase()} · ${device.os.isLight ? 'LIGHT' : 'DARK'} THEME',
                            style: const TextStyle(
                              color: kMuted,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                      ],
                    ),
                  ),
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
                      final framed = constraints.maxWidth >= 520;
                      final landscape = device.os.autoRotate && _side != 0;
                      final aspect = landscape ? 844 / 390 : 390 / 844;
                      var height = constraints.maxHeight - (framed ? 24 : 0);
                      var width = height * aspect;
                      if (width > constraints.maxWidth - (framed ? 24 : 0)) {
                        width = constraints.maxWidth - (framed ? 24 : 0);
                        height = width / aspect;
                      }
                      final now = propNow(device.clockOffsetMinutes);
                      return Center(
                        child: SizedBox(
                          width: framed ? width : constraints.maxWidth,
                          height: framed ? height : constraints.maxHeight,
                          child: PhoneShell(
                            device: device,
                            framed: framed,
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
    final app = _app;
    if (app == null) {
        return PhoneHome(
        skin: device.skin,
        light: device.os.isLight,
        order: device.os.homeOrder,
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
        return const InboxApp();
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
