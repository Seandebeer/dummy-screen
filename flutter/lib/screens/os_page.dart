import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../store.dart';
import '../format.dart';
import '../models.dart';
import '../phone/catalog.dart';
import '../phone/home_view.dart';
import '../phone/phone_apps.dart';
import '../phone/phone_shell.dart';
import '../phone/prop_apps.dart';
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
  String? _app;
  String? _thread;
  int _shutter = 0;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _toggleFilming() {
    FocusManager.instance.primaryFocus?.unfocus();
    final store = StoreScope.of(context);
    store.setFilming(!store.filming);
  }

  void _home(PropDevice device) {
    final store = StoreScope.of(context);
    if (device.locked) {
      store.setLocked(device.id, false);
      return;
    }
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      device == null ? 'Sandbox' : device.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hide chrome for camera',
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
                      final aspect = 390 / 844;
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
        ],
      ),
    );
  }

  Widget _body(StageStore store, PropDevice device, DateTime now) {
    if (device.locked) {
      return LockView(
        timeLabel: formatClock(now),
        dateLabel: formatDay(now),
        onUnlock: () => store.setLocked(device.id, false),
      );
    }
    final app = _app;
    if (app == null) {
      return PhoneHome(skin: device.skin, onOpen: _open);
    }
    if (app == 'messages') {
      return MessagesApp(
        store: store,
        deviceId: device.id,
        initialThread: _thread,
        onClose: () => setState(() {
          _app = null;
          _thread = null;
        }),
      );
    }
    final title = propAppById(app)?.label ?? 'App';
    return AppScaffold(
      title: title,
      onBack: () => setState(() => _app = null),
      child: _appBody(store, device, app),
    );
  }

  Widget _appBody(StageStore store, PropDevice device, String id) {
    switch (id) {
      case 'phone':
        return PhoneDialer(store: store, deviceId: device.id);
      case 'contacts':
        return ContactsApp(
          onMessage: (contact) => _open('messages', thread: contact.name),
          onCall: (contact) => store.startCall(
            deviceId: device.id,
            contactName: contact.name,
            contactNumber: contact.number,
            direction: 'outgoing',
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
          onShutter: () {
            store.addPhoto(
              device.id,
              _shutterColors[_shutter % _shutterColors.length],
            );
            setState(() => _shutter += 1);
          },
        );
      case 'photos':
        return PhotosApp(photos: store.photos[device.id] ?? const []);
      case 'mail':
        return const MailApp();
      case 'calendar':
        return CalendarApp(offsetMinutes: device.clockOffsetMinutes);
      case 'maps':
        return const MapsApp();
      default:
        final feed = kFeeds[id];
        if (feed != null) {
          return PropFeed(title: feed.$1, accent: feed.$2, posts: feed.$3);
        }
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
