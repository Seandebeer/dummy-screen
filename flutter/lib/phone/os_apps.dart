import 'package:flutter/material.dart';

import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import '../theme.dart';
import '../vfx/catalog.dart';
import '../vfx/mark_glyph.dart';
import 'app_catalog.dart';
import 'catalog.dart';
import 'desk_apps.dart';
import 'library_app.dart';
import 'maps_app.dart';
import 'phone_apps.dart';
import 'prop_apps.dart';
import 'settings_app.dart';
import 'social_apps.dart';
import 'utility_apps.dart';

const _shutterColors = [
  0xFF318DF6,
  0xFF30D158,
  0xFFFF9F0A,
  0xFFFF453A,
  0xFF5E5CE6,
];

/// Title shown above an open app, on a phone banner or a desktop window.
String osAppTitle(String id, OsSettings os) {
  final prop = propAppById(id);
  if (prop != null) return appLabel(prop, branded: os.branded);
  final feed = kFeeds[id];
  if (feed != null) return feed.$1;
  final mock = catalogAppById(id);
  if (mock != null) return mock.label;
  return 'App';
}

/// Every Base44 app, drawn the same way on a phone and a tablet.
class OsAppView extends StatefulWidget {
  const OsAppView({
    super.key,
    required this.store,
    required this.device,
    required this.appId,
    required this.onOpen,
    required this.onClose,
    this.thread,
  });

  final StageStore store;
  final PropDevice device;
  final String appId;
  final void Function(String id, {String? thread}) onOpen;
  final VoidCallback onClose;
  final String? thread;

  @override
  State<OsAppView> createState() => _OsAppViewState();
}

class _OsAppViewState extends State<OsAppView> {
  int _shutter = 0;

  StageStore get store => widget.store;
  PropDevice get device => widget.device;

  List<Map<String, dynamic>> get _mail {
    final raw = store.pages['mail-${device.id}'];
    if (raw is! Map) return const [];
    return [
      for (final item in jsonList(raw['items']))
        if (item is Map) jsonMap(item),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Material(color: const Color(0xFF0B0B0F), child: _screen(widget.appId));
  }

  Widget _screen(String id) {
    switch (id) {
      case 'messages':
        return MessagesApp(
          store: store,
          deviceId: device.id,
          initialThread: widget.thread,
          chrome: chromeFor(device.skin),
          onClose: widget.onClose,
        );
      case 'phone':
        return PhoneDialer(
          store: store,
          deviceId: device.id,
          contacts: contactsFor(device.os),
          language: device.os.language,
          chrome: chromeFor(device.skin),
        );
      case 'contacts':
        return ContactsApp(
          contacts: contactsFor(device.os),
          onAdd: (person) => store.updateOs(
            device.id,
            (current) => current.copyWith(people: [...current.people, person]),
          ),
          onMessage: (contact) => widget.onOpen('messages', thread: contact.name),
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
        return CalculatorApp(chrome: chromeFor(device.skin));
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
        return InboxApp(extra: _mail, chrome: chromeFor(device.skin));
      case 'calendar':
        return CalendarApp(os: device.os);
      case 'maps':
        return const MapsApp();
      case 'music':
        return const PropMusic();
      case 'browser':
        return PropBrowser(chrome: chromeFor(device.skin));
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

const _workingApps = {
  'messages',
  'phone',
  'contacts',
  'settings',
  'clock',
  'notes',
  'calculator',
  'camera',
  'photos',
  'email',
  'mail',
  'calendar',
  'maps',
  'music',
  'browser',
  'facepage',
  'photogram',
  'vidtube',
  'quicktok',
  'news',
  'fitness',
  'property',
  'webdeck',
  'appstore',
  'videocall',
};

/// Apps with a real prop screen. Catalog stand-ins and custom icons are not.
bool osAppWorks(String id) => _workingApps.contains(id) || kFeeds.containsKey(id);

/// Grey tracking plate for an app that has no working screen. Marks are fixed.
class GreyTrackPage extends StatelessWidget {
  const GreyTrackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final marks = defaultLayoutFor('cross');
    return ColoredBox(
      color: const Color(0xFF8A8A90),
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (final item in marks)
              Align(
                alignment: Alignment(item.x / 50 - 1, item.y / 50 - 1),
                child: MarkGlyph(
                  kind: item.kind,
                  color: Colors.white,
                  scale: 1.15,
                  thickness: 0.55,
                  rotation: item.rot,
                  x: item.x,
                  y: item.y,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
