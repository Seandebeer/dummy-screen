import 'dart:async';

import 'package:flutter/material.dart';

import '../format.dart';
import '../image_file.dart';
import '../media/live_lens.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import 'app_catalog.dart';
import 'browser_frame.dart';
import 'catalog.dart';
import 'clock_face.dart';
import 'desk_apps.dart';
import 'ios_keyboard.dart';
import 'desk_settings.dart';
import 'library_app.dart';
import 'maps_app.dart';
import 'os_apps.dart';
import 'prop_apps.dart';
import 'social_apps.dart';
import 'utility_apps.dart';

const _page = Color(0xFF1B1B1F);
const _side = Color(0xFF15151A);
const _line = Color(0xFF32323A);
const _ink = Color(0xFFF1F1F4);
const _dim = Color(0xFF9B9BA6);

/// Desktop builds of the apps a phone and a computer share. The phone stacks
/// one column at a time; a window puts the list beside the open item, types on
/// the hardware keyboard, and fills the width it is given.
class DeskAppView extends StatelessWidget {
  const DeskAppView({
    super.key,
    required this.store,
    required this.device,
    required this.appId,
    required this.onOpen,
    this.thread,
  });

  final StageStore store;
  final PropDevice device;
  final String appId;
  final void Function(String id, {String? thread}) onOpen;
  final String? thread;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _page,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final live = store.deviceById(device.id) ?? device;
          return _screen(live);
        },
      ),
    );
  }

  Widget _screen(PropDevice live) {
    switch (appId) {
      case 'messages':
        return _DeskMessages(
          store: store,
          device: live,
          thread: thread,
          key: ValueKey('desk-messages-${live.id}'),
        );
      case 'phone':
        return _DeskPhone(store: store, device: live);
      case 'contacts':
        return _DeskContacts(store: store, device: live, onOpen: onOpen);
      case 'email':
      case 'mail':
        return _DeskMail(store: store, device: live);
      case 'notes':
        return _DeskNotes(store: store, device: live);
      case 'calculator':
        return const _DeskCalculator();
      case 'clock':
        return _DeskClock(store: store, device: live);
      case 'calendar':
        return _DeskCalendar(os: live.os);
      case 'photos':
        return _DeskPhotos(photos: store.photos[live.id] ?? const []);
      case 'camera':
        return _DeskCamera(store: store, device: live);
      case 'music':
        return const _DeskMusic();
      case 'browser':
      case 'webdeck':
        return const _DeskBrowser();
      case 'maps':
        return const MapsApp();
      case 'settings':
        return ComputerSettings(store: store, device: live);
      case 'appstore':
        return LibraryApp(store: store, device: live);
      default:
        return _site(live);
    }
  }

  /// Feed-style apps keep their content and gain the desktop web layout: the
  /// column of posts with a standing information rail beside it.
  Widget _site(PropDevice live) {
    final title = osAppTitle(appId, live.os);
    final accent = propAppById(appId)?.color ?? const Color(0xFF4C6EF5);
    switch (appId) {
      case 'facepage':
        return _DeskSite(
          title: title,
          accent: accent,
          aside: const [
            ('Groups', 'Unit crew, Locations, Second unit'),
            ('Events', 'Night shoot, warehouse, 18:00'),
          ],
          child: const GrapevineApp(),
        );
      case 'photogram':
        return _DeskSite(
          title: title,
          accent: accent,
          aside: const [
            ('Suggested', 'night exterior, call sheet, wardrobe'),
            ('Saved', 'Holding photos for the insert'),
          ],
          child: const LumeApp(),
        );
      case 'vidtube':
        return _DeskSite(
          title: title,
          accent: accent,
          aside: const [
            ('Subscriptions', 'Unit cuts, Post reference'),
            ('Watch later', 'The interview cut, 12 minutes'),
          ],
          child: const StreamlyApp(),
        );
      case 'quicktok':
        return _DeskSite(
          title: title,
          accent: accent,
          aside: const [
            ('Following', 'Sound on set, Hold'),
            ('Sounds', 'The ringtone we cleared'),
          ],
          child: const FlickdeckApp(),
        );
      case 'news':
        return _DeskSite(
          title: title,
          accent: accent,
          aside: const [
            ('Sections', 'Breaking, Local, Culture, Sport'),
            ('Weather', 'Warming trend into Thursday'),
          ],
          child: const BulletinApp(),
        );
      case 'fitness':
        return _DeskSite(
          title: title,
          accent: accent,
          aside: const [
            ('Today', 'Move, exercise, and stand rings'),
            ('Trends', 'Seven day average is steady'),
          ],
          child: const PulseApp(),
        );
      case 'property':
        return _DeskSite(
          title: title,
          accent: accent,
          aside: const [
            ('Saved searches', 'Harbour flats, two bed'),
            ('Agents', 'Northline Property, 034 555 0198'),
          ],
          child: const RealtyApp(),
        );
      case 'videocall':
        return _DeskSite(
          title: title,
          accent: accent,
          aside: const [
            ('Recent', 'Elena Frost, Production Desk'),
            ('Camera', 'The computer lens feeds the call'),
          ],
          child: VidcallApp(contacts: contactsFor(live.os)),
        );
    }
    final feed = kFeeds[appId];
    if (feed != null) {
      return _DeskSite(
        title: feed.$1,
        accent: feed.$2,
        aside: [for (final post in feed.$3) (post.$1, post.$2)],
        child: PropFeed(title: feed.$1, accent: feed.$2, posts: feed.$3),
      );
    }
    final mock = catalogAppById(appId);
    if (mock != null) {
      return _DeskSite(
        title: mock.label,
        accent: mock.color,
        aside: [(mock.sub, mock.categoryName)],
        child: MockScreen(app: mock),
      );
    }
    return const Center(child: Text('Prop screen', style: TextStyle(color: _dim)));
  }
}

/// A list pane beside the open item, the way desktop apps are laid out.
class _Split extends StatelessWidget {
  const _Split({required this.title, required this.list, required this.body});

  final String title;
  final List<Widget> list;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth * 0.36).clamp(132.0, 220.0);
        return Row(
          children: [
            SizedBox(
              width: width,
              child: ColoredBox(
                color: _side,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(padding: EdgeInsets.zero, children: list),
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1, color: _line),
            Expanded(child: body),
          ],
        );
      },
    );
  }
}

class _SideRow extends StatelessWidget {
  const _SideRow({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle = '',
    this.meta = '',
    this.selected = false,
    this.strong = false,
    this.leading,
  });

  final String title;
  final VoidCallback onTap;
  final String subtitle;
  final String meta;
  final bool selected;
  final bool strong;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? const Color(0xFF2E2E36) : null,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ink,
                      fontSize: 12.5,
                      fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _dim, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (meta.isNotEmpty)
              Text(meta, style: const TextStyle(color: _dim, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.title, this.detail = '', this.trailing});

  final String title;
  final String detail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _dim, fontSize: 11),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

InputDecoration _field(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: _dim, fontSize: 12),
  isDense: true,
  filled: true,
  fillColor: const Color(0xFF26262C),
  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: BorderSide.none,
  ),
);

class _DeskMessages extends StatefulWidget {
  const _DeskMessages({
    super.key,
    required this.store,
    required this.device,
    this.thread,
  });

  final StageStore store;
  final PropDevice device;
  final String? thread;

  @override
  State<_DeskMessages> createState() => _DeskMessagesState();
}

class _DeskMessagesState extends State<_DeskMessages> {
  final _reply = TextEditingController();
  String? _thread;

  @override
  void initState() {
    super.initState();
    _thread = widget.thread;
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  void _send(String thread) {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    widget.store.sendMessage(
      deviceId: widget.device.id,
      sender: 'phone',
      text: text,
      senderName: thread,
      thread: thread,
    );
    _reply.clear();
    hideIosKeyboard(context);
  }

  Future<void> _confirmDelete(StageMessage message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) widget.store.deleteMessage(message.id);
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.store.messagesFor(widget.device.id);
    final threads = <String, List<StageMessage>>{};
    for (final message in messages.reversed) {
      threads.putIfAbsent(message.thread, () => []).add(message);
    }
    final names = threads.keys.toList();
    final thread = names.contains(_thread) ? _thread! : (names.firstOrNull ?? '');
    final items = threads[thread] ?? const <StageMessage>[];
    return _Split(
      title: 'Messages',
      list: [
        for (final name in names)
          _SideRow(
            key: Key('desk-thread-$name'),
            title: name,
            subtitle: threads[name]!.last.text,
            meta: formatStamp(threads[name]!.last.sentAt),
            selected: name == thread,
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: colorForName(name),
              child: Text(
                name.characters.first.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
            onTap: () => setState(() => _thread = name),
          ),
      ],
      body: thread.isEmpty
          ? const Center(
              child: Text('No conversations', style: TextStyle(color: _dim)),
            )
          : Column(
              children: [
                _Head(title: thread, detail: '${items.length} messages'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (final message in items)
                        GestureDetector(
                          onLongPress: () => _confirmDelete(message),
                          child: Align(
                          alignment: message.sender == 'phone'
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            constraints: const BoxConstraints(maxWidth: 320),
                            decoration: BoxDecoration(
                              color: message.sender == 'phone'
                                  ? const Color(0xFF0A84FF)
                                  : const Color(0xFF2C2C33),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              message.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('desk-reply'),
                          controller: _reply,
                          style: const TextStyle(color: _ink, fontSize: 13),
                          decoration: _field('Write a message'),
                          onSubmitted: (_) => _send(thread),
                        ),
                      ),
                      IconButton(
                        key: const Key('desk-send'),
                        tooltip: 'Send',
                        onPressed: () => _send(thread),
                        icon: const Icon(Icons.send, size: 16),
                        color: _ink,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _DeskPhone extends StatefulWidget {
  const _DeskPhone({required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<_DeskPhone> createState() => _DeskPhoneState();
}

class _DeskPhoneState extends State<_DeskPhone> {
  String _digits = '';
  bool _recents = false;

  void _call({String? name, String? number}) {
    final dialed = number ?? _digits;
    if (dialed.isEmpty) return;
    widget.store.startCall(
      deviceId: widget.device.id,
      contactName: name ?? dialed,
      contactNumber: dialed,
      direction: 'outgoing',
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = contactsFor(widget.device.os);
    final history = widget.store.callHistory
        .where((record) => record.deviceId == widget.device.id)
        .toList();
    return _Split(
      title: _recents ? 'Recents' : 'Contacts',
      list: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              _Tab(
                label: 'Contacts',
                on: !_recents,
                onTap: () => setState(() => _recents = false),
              ),
              const SizedBox(width: 6),
              _Tab(
                label: 'Recents',
                on: _recents,
                onTap: () => setState(() => _recents = true),
              ),
            ],
          ),
        ),
        if (_recents)
          for (final record in history)
            _SideRow(
              title: record.name.isEmpty ? record.number : record.name,
              subtitle: record.number,
              meta: formatStamp(record.at),
              onTap: () => _call(name: record.name, number: record.number),
            )
        else
          for (final contact in contacts)
            _SideRow(
              key: Key('desk-dial-${contact.name}'),
              title: contact.name,
              subtitle: contact.number,
              onTap: () => setState(() => _digits = contact.number),
            ),
        if (_recents && history.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'No calls yet',
              style: TextStyle(color: _dim, fontSize: 11),
            ),
          ),
      ],
      body: Column(
        children: [
          _Head(
            title: _digits.isEmpty ? 'Dial a number' : _digits,
            detail: 'Keypad',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  for (final row in const [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['*', '0', '#'],
                  ])
                    Expanded(
                      child: Row(
                        children: [
                          for (final key in row)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: _PadKey(
                                  label: key,
                                  onTap: () => setState(() => _digits += key),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Backspace',
                  onPressed: _digits.isEmpty
                      ? null
                      : () => setState(
                          () => _digits = _digits.substring(0, _digits.length - 1),
                        ),
                  icon: const Icon(Icons.backspace_outlined, size: 16),
                  color: _dim,
                ),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('desk-call'),
                    onPressed: _digits.isEmpty ? null : () => _call(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF34C759),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: on ? const Color(0xFF32323C) : null,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _line),
          ),
          child: Text(
            label,
            style: TextStyle(color: on ? _ink : _dim, fontSize: 11),
          ),
        ),
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2A2A31),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeskContacts extends StatefulWidget {
  const _DeskContacts({
    required this.store,
    required this.device,
    required this.onOpen,
  });

  final StageStore store;
  final PropDevice device;
  final void Function(String id, {String? thread}) onOpen;

  @override
  State<_DeskContacts> createState() => _DeskContactsState();
}

class _DeskContactsState extends State<_DeskContacts> {
  final _name = TextEditingController();
  final _number = TextEditingController();
  String? _selected;
  bool _adding = false;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    widget.store.updateOs(
      widget.device.id,
      (current) => current.copyWith(
        people: [
          ...current.people,
          PropPerson(name: name, number: _number.text.trim()),
        ],
      ),
    );
    _name.clear();
    _number.clear();
    setState(() {
      _adding = false;
      _selected = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final contacts = [...contactsFor(widget.device.os)]
      ..sort((a, b) => a.name.compareTo(b.name));
    final card = contacts
        .where((contact) => contact.name == _selected)
        .firstOrNull ??
        contacts.firstOrNull;
    return _Split(
      title: 'Contacts',
      list: [
        for (final contact in contacts)
          _SideRow(
            key: Key('desk-contact-${contact.name}'),
            title: contact.name,
            subtitle: contact.number,
            selected: contact.name == card?.name,
            onTap: () => setState(() {
              _selected = contact.name;
              _adding = false;
            }),
          ),
        _SideRow(
          key: const Key('desk-contact-add'),
          title: 'New contact',
          leading: const Icon(Icons.add, size: 14, color: _dim),
          onTap: () => setState(() => _adding = true),
        ),
      ],
      body: _adding
          ? Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New contact',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const Key('desk-contact-name'),
                    controller: _name,
                    style: const TextStyle(color: _ink, fontSize: 13),
                    decoration: _field('Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _number,
                    style: const TextStyle(color: _ink, fontSize: 13),
                    decoration: _field('Number'),
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    key: const Key('desk-contact-save'),
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            )
          : card == null
              ? const Center(
                  child: Text('No contacts', style: TextStyle(color: _dim)),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: colorForName(card.name),
                            child: Text(
                              card.name.characters.first.toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.name,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  card.number,
                                  style: const TextStyle(
                                    color: _dim,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () => widget.store.startCall(
                              deviceId: widget.device.id,
                              contactName: card.name,
                              contactNumber: card.number,
                              direction: 'outgoing',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF34C759),
                            ),
                            icon: const Icon(Icons.phone, size: 15),
                            label: const Text('Call'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                widget.onOpen('messages', thread: card.name),
                            icon: const Icon(Icons.message, size: 15),
                            label: const Text('Message'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _DeskMail extends StatefulWidget {
  const _DeskMail({required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<_DeskMail> createState() => _DeskMailState();
}

class _DeskMailState extends State<_DeskMail> {
  late final List<Map<String, dynamic>> _mail = [...inboxSeed()];
  int _open = 0;

  @override
  void initState() {
    super.initState();
    _syncPushed();
  }

  @override
  void didUpdateWidget(_DeskMail oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPushed();
  }

  void _syncPushed() {
    final raw = widget.store.pages['mail-${widget.device.id}'];
    final pushed = raw is Map
        ? [
            for (final item in jsonList(raw['items']))
              if (item is Map) {...jsonMap(item), 'pushed': true},
          ]
        : const <Map<String, dynamic>>[];
    final ids = pushed.map((item) => item['id']).toSet();
    _mail.removeWhere((item) => item['pushed'] == true && !ids.contains(item['id']));
    for (final item in pushed.reversed) {
      if (!_mail.any((existing) => existing['id'] == item['id'])) {
        _mail.insert(0, item);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _open.clamp(0, _mail.isEmpty ? 0 : _mail.length - 1);
    final open = _mail.isEmpty ? null : _mail[index];
    final thread = open == null ? const [] : jsonList(open['thread']);
    return _Split(
      title: 'Inbox',
      list: [
        for (var i = 0; i < _mail.length; i++)
          _SideRow(
            key: Key('desk-mail-$i'),
            title: '${_mail[i]['from']}',
            subtitle: '${_mail[i]['subject']}',
            meta: '${_mail[i]['time']}',
            strong: _mail[i]['unread'] == true,
            selected: i == index,
            onTap: () => setState(() {
              _mail[i]['unread'] = false;
              _open = i;
            }),
          ),
      ],
      body: open == null
          ? const Center(child: Text('No mail', style: TextStyle(color: _dim)))
          : Column(
              children: [
                _Head(
                  title: '${open['subject']}',
                  detail: '${open['from']} · ${open['time']}',
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final part in thread)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            '${jsonMap(part)['body']}',
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _DeskNotes extends StatefulWidget {
  const _DeskNotes({required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<_DeskNotes> createState() => _DeskNotesState();
}

class _DeskNotesState extends State<_DeskNotes> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.device.notes,
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _save(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      widget.store.setNotes(widget.device.id, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lines = _controller.text.trim().split('\n');
    return _Split(
      title: 'Notes',
      list: [
        _SideRow(
          title: lines.first.isEmpty ? 'New note' : lines.first,
          subtitle: lines.length > 1 ? lines[1] : 'No extra text',
          selected: true,
          onTap: () {},
        ),
      ],
      body: Column(
        children: [
          _Head(
            title: 'Note',
            detail: formatDay(osNow(widget.device.os)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                key: const Key('desk-note'),
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(color: _ink, fontSize: 13, height: 1.5),
                decoration: const InputDecoration(
                  hintText: 'Start writing',
                  hintStyle: TextStyle(color: _dim),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (value) {
                  _save(value);
                  setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeskCalculator extends StatefulWidget {
  const _DeskCalculator();

  @override
  State<_DeskCalculator> createState() => _DeskCalculatorState();
}

class _DeskCalculatorState extends State<_DeskCalculator> {
  final _calc = CalcEngine();
  final _tape = <String>[];

  void _press(String label) {
    setState(() {
      switch (label) {
        case 'AC':
          _calc.clear();
        case '±':
          _calc.sign();
        case '%':
          _calc.percent();
        case '=':
          final left = _calc.display;
          _calc.equals();
          if (_calc.display != left) _tape.insert(0, '$left = ${_calc.display}');
        case '÷' || '×' || '−' || '+':
          _calc.operate(label);
        default:
          _calc.digit(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['AC', '±', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _calc.display,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 44,
                      fontWeight: FontWeight.w300,
                      height: 1,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Column(
                    children: [
                      for (final row in rows)
                        Expanded(
                          child: Row(
                            children: [
                              for (final label in row)
                                Expanded(
                                  flex: label == '0' ? 2 : 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: _CalcKey(
                                      label: label == 'AC'
                                          ? _calc.clearLabel
                                          : label,
                                      operator: '÷×−+='.contains(label),
                                      onTap: () => _press(label),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1, color: _line),
        SizedBox(
          width: 132,
          child: ColoredBox(
            color: _side,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Text(
                    'Tape',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      if (_tape.isEmpty)
                        const Text(
                          'Sums land here',
                          style: TextStyle(color: _dim, fontSize: 11),
                        ),
                      for (final line in _tape)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            line,
                            style: const TextStyle(color: _dim, fontSize: 11),
                          ),
                        ),
                    ],
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

class _CalcKey extends StatelessWidget {
  const _CalcKey({
    required this.label,
    required this.operator,
    required this.onTap,
  });

  final String label;
  final bool operator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final function = label == 'AC' || label == 'C' || label == '±' || label == '%';
    return Material(
      color: operator
          ? const Color(0xFFFF9F0A)
          : function
              ? const Color(0xFF3A3A42)
              : const Color(0xFF2A2A31),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeskClock extends StatelessWidget {
  const _DeskClock({required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  static const _cities = [
    ('Los Angeles', -7),
    ('New York', -4),
    ('London', 1),
    ('Cape Town', 2),
    ('Tokyo', 9),
  ];

  @override
  Widget build(BuildContext context) {
    final now = osNow(device.os);
    final utc = now.toUtc();
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  child: ClockReadout(
                    os: device.os,
                    color: _ink,
                    fontSize: 64,
                    fontWeight: FontWeight.w200,
                    faceSize: 120,
                  ),
                ),
                Text(
                  formatDay(now),
                  style: const TextStyle(color: _dim, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final shift in const [
                      ('-1h', -60),
                      ('-1m', -1),
                      ('+1m', 1),
                      ('+1h', 60),
                    ])
                      OutlinedButton(
                        onPressed: () => store.updateOs(
                          device.id,
                          (current) => shiftClock(current, shift.$2),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 30),
                        ),
                        child: Text(shift.$1),
                      ),
                    TextButton(
                      onPressed: () => store.updateOs(device.id, followLocalClock),
                      child: const Text('Real time'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1, color: _line),
        SizedBox(
          width: 150,
          child: ColoredBox(
            color: _side,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'World clock',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                for (final city in _cities)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            city.$1,
                            style: const TextStyle(color: _dim, fontSize: 11),
                          ),
                        ),
                        Text(
                          formatOsClock(
                            utc.add(Duration(hours: city.$2)),
                            hour24: device.os.clockFormat == '24',
                          ),
                          style: const TextStyle(color: _ink, fontSize: 12),
                        ),
                      ],
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

class _DeskCalendar extends StatelessWidget {
  const _DeskCalendar({required this.os});

  final OsSettings os;

  static const _agenda = [
    ('07:00', 'Crew call, east lot'),
    ('09:30', 'Blocking, scene 47'),
    ('13:00', 'Company move'),
    ('18:00', 'Night shoot, warehouse'),
  ];

  @override
  Widget build(BuildContext context) {
    final now = osNow(os);
    final first = DateTime(now.year, now.month, 1);
    final days = DateTime(now.year, now.month + 1, 0).day;
    final pad = first.weekday % 7;
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _Head(title: formatDay(now), detail: 'Month'),
              Row(
                children: [
                  for (final label in labels)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Center(
                          child: Text(
                            label,
                            style: const TextStyle(color: _dim, fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 7,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  children: [
                    for (var i = 0; i < pad; i++) const SizedBox.shrink(),
                    for (var day = 1; day <= days; day++)
                      Center(
                        child: Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: day == now.day
                                ? const Color(0xFFFF3B30)
                                : Colors.transparent,
                          ),
                          child: Text(
                            '$day',
                            style: const TextStyle(color: _ink, fontSize: 11),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1, color: _line),
        SizedBox(
          width: 160,
          child: ColoredBox(
            color: _side,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final slot in _agenda)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.$1,
                          style: const TextStyle(color: _dim, fontSize: 10),
                        ),
                        Text(
                          slot.$2,
                          style: const TextStyle(color: _ink, fontSize: 12),
                        ),
                      ],
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

class _DeskPhotos extends StatefulWidget {
  const _DeskPhotos({required this.photos});

  final List<PropPhoto> photos;

  @override
  State<_DeskPhotos> createState() => _DeskPhotosState();
}

class _DeskPhotosState extends State<_DeskPhotos> {
  int _open = 0;

  @override
  Widget build(BuildContext context) {
    final shots = widget.photos.reversed.toList();
    if (shots.isEmpty) {
      return const Center(
        child: Text('The camera roll is empty.', style: TextStyle(color: _dim)),
      );
    }
    final index = _open.clamp(0, shots.length - 1);
    final open = shots[index];
    return Row(
      children: [
        Expanded(
          child: GridView.count(
            crossAxisCount: 4,
            padding: const EdgeInsets.all(8),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (var i = 0; i < shots.length; i++)
                InkWell(
                  onTap: () => setState(() => _open = i),
                  child: _Shot(photo: shots[i], framed: i == index),
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1, color: _line),
        SizedBox(
          width: 170,
          child: ColoredBox(
            color: _side,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _Shot(photo: open, framed: false),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Text(
                    '${index + 1} of ${shots.length} · ${formatStamp(open.createdAt)}',
                    style: const TextStyle(color: _dim, fontSize: 10),
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

class _Shot extends StatelessWidget {
  const _Shot({required this.photo, required this.framed});

  final PropPhoto photo;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final provider = imageProviderForPath(photo.image);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color(photo.color),
        border: framed ? Border.all(color: Colors.white, width: 2) : null,
        image: provider == null
            ? null
            : DecorationImage(image: provider, fit: BoxFit.cover),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _DeskCamera extends StatefulWidget {
  const _DeskCamera({required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<_DeskCamera> createState() => _DeskCameraState();
}

class _DeskCameraState extends State<_DeskCamera> {
  final _lens = LiveLens();
  static const _tints = [0xFF318DF6, 0xFF30D158, 0xFFFF9F0A, 0xFFFF453A];
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _lens.close();
    super.dispose();
  }

  Future<void> _open() async {
    await _lens.open(video: true, audio: false);
    if (mounted) setState(() {});
  }

  Future<void> _capture() async {
    final bytes = await _lens.capture();
    var image = '';
    if (bytes != null && bytes.isNotEmpty) {
      image = await persistImageBytes(bytes) ?? '';
    }
    if (!mounted) return;
    widget.store.addPhoto(
      widget.device.id,
      _tints[_count % _tints.length],
      image: image,
    );
    setState(() => _count += 1);
  }

  @override
  Widget build(BuildContext context) {
    final shots = (widget.store.photos[widget.device.id] ?? const <PropPhoto>[])
        .reversed
        .take(8)
        .toList();
    return Row(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.black),
              LensView(lens: _lens, mirror: false),
              if (_lens.denied)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Allow camera access to use the lens',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _dim, fontSize: 12),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Center(
                  child: FilledButton.icon(
                    key: const Key('desk-shutter'),
                    onPressed: _capture,
                    icon: const Icon(Icons.camera, size: 16),
                    label: const Text('Capture'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1, color: _line),
        SizedBox(
          width: 118,
          child: ColoredBox(
            color: _side,
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Recent',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (shots.isEmpty)
                  const Text(
                    'No shots yet',
                    style: TextStyle(color: _dim, fontSize: 11),
                  ),
                for (final shot in shots)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: _Shot(photo: shot, framed: false),
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

class _DeskMusic extends StatefulWidget {
  const _DeskMusic();

  @override
  State<_DeskMusic> createState() => _DeskMusicState();
}

class _DeskMusicState extends State<_DeskMusic> {
  static const _lists = ['Library', 'Cues', 'Score', 'Source music'];
  static const _tracks = [
    ('Harbour Lights', 'Northline Quartet', '3:12'),
    ('Night Exterior', 'Prop Score', '2:48'),
    ('Second Unit', 'Northline Quartet', '4:05'),
    ('Warehouse Hold', 'Prop Score', '3:33'),
    ('Wrap Walk', 'Rosy and the Bench', '2:57'),
  ];

  String _list = _lists.first;
  int _track = 0;
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    final open = _tracks[_track];
    return _Split(
      title: 'Music',
      list: [
        for (final name in _lists)
          _SideRow(
            title: name,
            selected: name == _list,
            leading: const Icon(Icons.queue_music, size: 14, color: _dim),
            onTap: () => setState(() => _list = name),
          ),
      ],
      body: Column(
        children: [
          _Head(
            title: open.$1,
            detail: '${open.$2} · $_list',
            trailing: Row(
              children: [
                IconButton(
                  onPressed: () => setState(
                    () => _track = (_track - 1 + _tracks.length) % _tracks.length,
                  ),
                  icon: const Icon(Icons.skip_previous, size: 18),
                  color: _ink,
                ),
                IconButton(
                  key: const Key('desk-play'),
                  onPressed: () => setState(() => _playing = !_playing),
                  icon: Icon(
                    _playing ? Icons.pause : Icons.play_arrow,
                    size: 20,
                  ),
                  color: _ink,
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => _track = (_track + 1) % _tracks.length),
                  icon: const Icon(Icons.skip_next, size: 18),
                  color: _ink,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (var i = 0; i < _tracks.length; i++)
                  InkWell(
                    onTap: () => setState(() {
                      _track = i;
                      _playing = true;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      color: i == _track ? const Color(0xFF2A2A31) : null,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            child: i == _track && _playing
                                ? const Icon(
                                    Icons.graphic_eq,
                                    size: 13,
                                    color: Color(0xFFFC3C44),
                                  )
                                : Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: _dim,
                                      fontSize: 11,
                                    ),
                                  ),
                          ),
                          Expanded(
                            child: Text(
                              _tracks[i].$1,
                              style: const TextStyle(color: _ink, fontSize: 12.5),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _tracks[i].$2,
                              style: const TextStyle(color: _dim, fontSize: 11),
                            ),
                          ),
                          Text(
                            _tracks[i].$3,
                            style: const TextStyle(color: _dim, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeskBrowser extends StatefulWidget {
  const _DeskBrowser();

  @override
  State<_DeskBrowser> createState() => _DeskBrowserState();
}

class _DeskBrowserState extends State<_DeskBrowser> {
  final _address = TextEditingController();
  final _history = <String>[];
  int _index = -1;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  String? get _current => _index < 0 ? null : _history[_index];

  String? _normalize(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('http://') || text.startsWith('https://')) return text;
    if (RegExp(r'^[\w-]+(\.[\w-]+)+').hasMatch(text)) return 'https://$text';
    return 'https://en.wikipedia.org/wiki/Special:Search?search='
        '${Uri.encodeQueryComponent(text)}';
  }

  void _go(String raw) {
    final target = _normalize(raw);
    if (target == null) return;
    setState(() {
      _history
        ..removeRange(_index + 1, _history.length)
        ..add(target);
      _index = _history.length - 1;
      _address.text = target;
    });
  }

  void _jump(int index) {
    if (index < 0 || index >= _history.length) return;
    setState(() {
      _index = index;
      _address.text = _history[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    final host = current == null ? 'New tab' : (Uri.tryParse(current)?.host ?? current);
    return Column(
      children: [
        Container(
          color: _side,
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: const BoxDecoration(
                  color: _page,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _ink, fontSize: 11),
                ),
              ),
              IconButton(
                tooltip: 'New tab',
                onPressed: () => setState(() {
                  _history.clear();
                  _index = -1;
                  _address.clear();
                }),
                icon: const Icon(Icons.add, size: 14),
                color: _dim,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _line)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: _index <= 0 ? null : () => _jump(_index - 1),
                icon: const Icon(Icons.arrow_back, size: 16),
                color: _ink,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Forward',
                onPressed: _index >= _history.length - 1
                    ? null
                    : () => _jump(_index + 1),
                icon: const Icon(Icons.arrow_forward, size: 16),
                color: _ink,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: TextField(
                  key: const Key('desk-address'),
                  controller: _address,
                  style: const TextStyle(color: _ink, fontSize: 12),
                  decoration: _field('Search or enter address'),
                  onSubmitted: _go,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: current == null
              ? GridView.count(
                  crossAxisCount: 4,
                  padding: const EdgeInsets.all(14),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1,
                  children: [
                    for (final site in kQuickSites)
                      InkWell(
                        key: Key('desk-site-${site.$1}'),
                        onTap: () => _go(site.$2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: site.$3,
                              child: Text(
                                site.$1[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              site.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _dim, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                  ],
                )
              : ColoredBox(
                  color: Colors.white,
                  child: BrowserFrame(url: current),
                ),
        ),
      ],
    );
  }
}

/// The desktop web layout: the app's own column of content with a standing
/// information rail, instead of the phone's full-width scroll.
class _DeskSite extends StatelessWidget {
  const _DeskSite({
    required this.title,
    required this.accent,
    required this.aside,
    required this.child,
  });

  final String title;
  final Color accent;
  final List<(String, String)> aside;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rail = constraints.maxWidth >= 470;
        return Row(
          children: [
            Expanded(child: child),
            if (rail) ...[
              const VerticalDivider(width: 1, thickness: 1, color: _line),
              SizedBox(
                width: 160,
                child: ColoredBox(
                  color: _side,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final card in aside)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.$1,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                card.$2,
                                style: const TextStyle(
                                  color: _dim,
                                  fontSize: 10,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
