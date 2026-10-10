import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import 'catalog.dart';
import 'ios_keyboard.dart';
import 'phone_copy.dart';

const _phoneGreen = Color(0xFF34C759);
const _missedRed = Color(0xFFFF3B30);

class PhoneDialer extends StatefulWidget {
  const PhoneDialer({
    super.key,
    required this.store,
    required this.deviceId,
    this.contacts = kContacts,
    this.language = 'en',
    this.chrome = SkinChrome.modern,
  });

  final StageStore store;
  final String deviceId;
  final List<ContactCard> contacts;
  final String language;
  final SkinChrome chrome;

  @override
  State<PhoneDialer> createState() => _PhoneDialerState();
}

class _PhoneDialerState extends State<PhoneDialer> {
  String _digits = '';
  String _tab = 'keypad';
  String _recentFilter = 'all';
  bool _refreshing = false;

  void _call({String? name, String? number}) {
    final dialed = number ?? _digits;
    if (dialed.isEmpty) return;
    final match = widget.contacts
        .where(
          (contact) =>
              contact.number.replaceAll(' ', '') == dialed.replaceAll(' ', ''),
        )
        .firstOrNull;
    widget.store.startCall(
      deviceId: widget.deviceId,
      contactName: name ?? match?.name ?? dialed,
      contactNumber: dialed,
      direction: 'outgoing',
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = phoneCopy(widget.language);
    final tab = switch (widget.chrome) {
      SkinChrome.android || SkinChrome.tiles
          when _tab == 'favorites' || _tab == 'voicemail' =>
        'keypad',
      _ => _tab,
    };
    final body = switch (tab) {
      'favorites' => _favorites(),
      'recents' => _recentFilter == 'log' ? _history(copy) : _recents(copy),
      'contacts' => _people(),
      'voicemail' => _voicemail(),
      _ => _keypad(),
    };
    final tiles = widget.chrome == SkinChrome.tiles;
    return Material(
      color: Colors.black,
      child: Column(
        children: [
          if (tiles) _phoneTabs(),
          Expanded(child: body),
          if (!tiles) _phoneTabs(),
        ],
      ),
    );
  }

  Widget _phoneTabs() {
    final items = switch (widget.chrome) {
      SkinChrome.android => [
          ('keypad', Icons.dialpad, 'Keypad'),
          ('recents', Icons.history, 'Recents'),
          ('contacts', Icons.person_outline, 'Contacts'),
        ],
      SkinChrome.tiles => [
          ('keypad', Icons.dialpad, 'keypad'),
          ('recents', Icons.access_time, 'history'),
          ('contacts', Icons.person_outline, 'people'),
        ],
      SkinChrome.classic => [
          ('favorites', Icons.star, 'Favorites'),
          ('recents', Icons.access_time, 'Recents'),
          ('contacts', Icons.person_outline, 'Contacts'),
          ('keypad', Icons.dialpad, 'Keypad'),
          ('voicemail', Icons.voicemail, 'Voicemail'),
        ],
      SkinChrome.modern => [
          ('favorites', Icons.star, 'Favourites'),
          ('recents', Icons.access_time, 'Recents'),
          ('contacts', Icons.person_outline, 'Contacts'),
          ('keypad', Icons.dialpad, 'Keypad'),
          ('voicemail', Icons.voicemail, 'Voicemail'),
        ],
    };
    final selected = switch (widget.chrome) {
      SkinChrome.android => _phoneGreen,
      SkinChrome.tiles => const Color(0xFF1BA1E2),
      _ => const Color(0xFF0A84FF),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.chrome == SkinChrome.tiles ? Colors.black : const Color(0xF01C1C1E),
        border: Border(
          top: BorderSide(color: widget.chrome == SkinChrome.tiles ? Colors.transparent : const Color(0x33FFFFFF)),
          bottom: BorderSide(color: widget.chrome == SkinChrome.tiles ? const Color(0x33FFFFFF) : Colors.transparent),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final item in items)
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _tab = item.$1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.$2,
                          size: 22,
                          color: _tab == item.$1 ? selected : const Color(0xFF8E8E93),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: TextStyle(
                            fontSize: widget.chrome == SkinChrome.tiles ? 16 : 10,
                            color: _tab == item.$1 ? selected : const Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _favorites() {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text('Favourites', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
        ),
        for (final contact in widget.contacts)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorForName(contact.name),
              child: Text(contact.name.characters.first),
            ),
            title: Text(contact.name),
            subtitle: const Text('mobile', style: TextStyle(color: Color(0xFF8E8E93))),
            trailing: IconButton(
              onPressed: () => _call(name: contact.name, number: contact.number),
              icon: const Icon(Icons.phone, color: _phoneGreen),
            ),
          ),
      ],
    );
  }

  Widget _people() {
    final sorted = [...widget.contacts]..sort((a, b) => a.name.compareTo(b.name));
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text('Contacts', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
        ),
        for (final contact in sorted)
          ListTile(
            onTap: () => _call(name: contact.name, number: contact.number),
            title: Text(contact.name),
            subtitle: Text(contact.number, style: const TextStyle(color: Color(0xFF8E8E93))),
          ),
      ],
    );
  }

  Widget _voicemail() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.voicemail, color: Color(0xFF8E8E93), size: 42),
          SizedBox(height: 8),
          Text('No Voicemail', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Visual voicemail is empty.', style: TextStyle(color: Color(0xFF8E8E93))),
        ],
      ),
    );
  }

  Widget _recents(PhoneCopy copy) {
    final rows = widget.store.callHistory
        .where((record) => record.deviceId == widget.deviceId)
        .take(100)
        .toList();
    final visible = _recentFilter == 'missed'
        ? rows.where((record) => record.type == 'missed').toList()
        : rows;
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Recents', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('All')),
              ButtonSegment(value: 'missed', label: Text('Missed')),
              ButtonSegment(value: 'log', label: Text('Log')),
            ],
            selected: {_recentFilter},
            onSelectionChanged: (value) => setState(() => _recentFilter = value.first),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    copy.noCalls,
                    style: const TextStyle(color: Colors.white30, fontSize: 14),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final record in visible) _callRow(copy, record, showNumber: true),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _history(PhoneCopy copy) {
    final rows = widget.store.callHistory;
    final count = rows.length;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'On this device · $count call${count == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
              TextButton.icon(
                onPressed: _refreshing
                    ? null
                    : () async {
                        setState(() => _refreshing = true);
                        await Future<void>.delayed(
                          const Duration(milliseconds: 350),
                        );
                        if (mounted) setState(() => _refreshing = false);
                      },
                icon: _refreshing
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: _phoneGreen,
                        ),
                      )
                    : const Icon(Icons.refresh, size: 13, color: _phoneGreen),
                label: const Text(
                  'Sync',
                  style: TextStyle(color: _phoneGreen, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? const Center(
                  child: Text(
                    'No calls on this device yet',
                    style: TextStyle(color: Colors.white30, fontSize: 14),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final record in rows)
                      _callRow(copy, record, showNumber: false),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _callRow(PhoneCopy copy, CallRecord record, {required bool showNumber}) {
    final missed = record.type == 'missed';
    final meta = switch (record.type) {
      'missed' => (Icons.phone_missed, _missedRed),
      'incoming' => (Icons.call_received, _phoneGreen),
      _ => (Icons.call_made, const Color(0xFF8E8E93)),
    };
    final detail = showNumber
        ? [
            record.number,
            copy.typeLabel(record.type),
            _clock(record.at),
          ].where((part) => part.isNotEmpty).join(' · ')
        : [
            copy.typeLabel(record.type),
            _when(record.at),
            record.deviceName,
          ].where((part) => part.isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.name.isEmpty
                      ? (record.number.isEmpty ? 'Unknown' : record.number)
                      : record.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: missed ? _missedRed : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(meta.$1, size: 12, color: meta.$2),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.white38),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _call(
              name: record.name.isEmpty ? null : record.name,
              number: record.number,
            ),
            icon: const Icon(Icons.phone, color: _phoneGreen, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _keypad() {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#'];
    return LayoutBuilder(
      builder: (context, constraints) {
        final key = ((constraints.maxWidth - 48) / 3).clamp(44.0, 68.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 24, 12, 28),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Text(
                  _digits,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              for (var row = 0; row < 4; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var col = 0; col < 3; col++) ...[
                        if (col > 0) const SizedBox(width: 12),
                        _key(keys[row * 3 + col], key),
                      ],
                    ],
                  ),
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 64),
                  Material(
                    color: _phoneGreen,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _digits.isEmpty ? null : () => _call(),
                      child: const SizedBox(
                        width: 72,
                        height: 72,
                        child: Icon(Icons.phone, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: IconButton(
                      onPressed: _digits.isEmpty
                          ? null
                          : () => setState(
                              () => _digits = _digits.substring(
                                0,
                                _digits.length - 1,
                              ),
                            ),
                      onLongPress: _digits.isEmpty ? null : () => setState(() => _digits = ''),
                      icon: const Icon(
                        Icons.backspace_outlined,
                        color: Colors.white60,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _key(String label, double size) {
    const letters = {
      '2': 'ABC',
      '3': 'DEF',
      '4': 'GHI',
      '5': 'JKL',
      '6': 'MNO',
      '7': 'PQRS',
      '8': 'TUV',
      '9': 'WXYZ',
      '0': '+',
    };
    final sub = letters[label];
    final tiles = widget.chrome == SkinChrome.tiles;
    final classic = widget.chrome == SkinChrome.classic;
    final shape = tiles
        ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))
        : const CircleBorder();
    return Material(
      color: tiles
          ? const Color(0xFF1A1A1A)
          : classic
              ? const Color(0xFF5A5A5E)
              : const Color(0xFF333333),
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: () => setState(() => _digits += label),
        onLongPress: label == '0' ? () => setState(() => _digits += '+') : null,
        child: SizedBox(
          width: size,
          height: size,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300, height: 1),
              ),
              if (sub != null)
                Text(
                  sub,
                  style: const TextStyle(fontSize: 9, letterSpacing: 1.2, color: Colors.white70),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _clock(int millis) {
  final time = DateTime.fromMillisecondsSinceEpoch(millis);
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _when(int millis) {
  final time = DateTime.fromMillisecondsSinceEpoch(millis);
  final now = DateTime.now();
  final clock = _clock(millis);
  final today =
      time.year == now.year && time.month == now.month && time.day == now.day;
  if (today) return 'Today $clock';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[time.month - 1]} ${time.day} $clock';
}

class MessagesApp extends StatefulWidget {
  const MessagesApp({
    super.key,
    required this.store,
    required this.deviceId,
    required this.onClose,
    this.initialThread,
    this.chrome = SkinChrome.modern,
  });

  final StageStore store;
  final String deviceId;
  final VoidCallback onClose;
  final String? initialThread;
  final SkinChrome chrome;

  @override
  State<MessagesApp> createState() => _MessagesAppState();
}

class _MessagesAppState extends State<MessagesApp> {
  final _reply = TextEditingController();
  String? _thread;

  @override
  void initState() {
    super.initState();
    _thread = widget.initialThread;
  }

  @override
  void didUpdateWidget(MessagesApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialThread != null &&
        widget.initialThread != oldWidget.initialThread) {
      _thread = widget.initialThread;
    }
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Map<String, List<StageMessage>> _grouped(List<StageMessage> messages) {
    final grouped = <String, List<StageMessage>>{};
    for (final message in messages.reversed) {
      grouped.putIfAbsent(message.thread, () => []).add(message);
    }
    return grouped;
  }

  Color get _page => widget.chrome == SkinChrome.tiles ? Colors.black : Colors.white;

  Color get _ink => widget.chrome == SkinChrome.tiles ? Colors.white : Colors.black;

  Color get _sent => switch (widget.chrome) {
        SkinChrome.android => const Color(0xFF0B57D0),
        SkinChrome.classic => _phoneGreen,
        SkinChrome.tiles => const Color(0xFF1BA1E2),
        SkinChrome.modern => const Color(0xFF0A84FF),
      };

  String get _composerHint => switch (widget.chrome) {
        SkinChrome.android => 'Text message',
        SkinChrome.classic => 'Text Message',
        SkinChrome.tiles => 'message',
        SkinChrome.modern => 'iMessage',
      };

  String get _listTitle => widget.chrome == SkinChrome.tiles ? 'messages' : 'Messages';

  void _send() {
    final thread = _thread;
    final text = _reply.text.trim();
    if (thread == null || text.isEmpty) return;
    widget.store.sendMessage(
      deviceId: widget.deviceId,
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
    final messages = widget.store.messagesFor(widget.deviceId);
    final grouped = _grouped(messages);
    final thread = _thread;
    if (thread == null) {
      final names = <String>[];
      for (final message in messages) {
        if (!names.contains(message.thread)) names.add(message.thread);
      }
      return Material(
        color: _page,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      hideIosKeyboard(context);
                      widget.onClose();
                    },
                    icon: Icon(Icons.chevron_left, color: _sent, size: 28),
                  ),
                  Text(_listTitle, style: TextStyle(color: _ink, fontSize: 32, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: names.isEmpty
                  ? const Center(
                      child: Text(
                        'No Messages',
                        style: TextStyle(color: Color(0xFF8E8E93), fontSize: 17),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final name in names)
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorForName(name),
                              child: Text(
                                name.characters.first.toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(name, style: TextStyle(color: _ink, fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              grouped[name]!.last.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF8E8E93)),
                            ),
                            trailing: Text(
                              formatStamp(grouped[name]!.last.sentAt),
                              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                            ),
                            onTap: () => setState(() => _thread = name),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }
    final items = grouped[thread] ?? const <StageMessage>[];
    return Material(
      color: _page,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    hideIosKeyboard(context);
                    setState(() => _thread = null);
                  },
                  icon: Icon(Icons.chevron_left, color: _sent, size: 28),
                ),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colorForName(thread),
                  child: Text(thread.characters.first.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(thread, style: TextStyle(color: _ink, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final message in items)
                  GestureDetector(
                    onLongPress: () => _confirmDelete(message),
                    child: Align(
                    alignment: message.sender == 'phone' ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
                      decoration: BoxDecoration(
                        color: message.sender == 'phone' ? _sent : (widget.chrome == SkinChrome.tiles ? const Color(0xFF2C2C2E) : const Color(0xFFE9E9EB)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.sender == 'phone' || widget.chrome == SkinChrome.tiles ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.add_circle, color: Color(0xFF8E8E93)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _reply,
                    readOnly: true,
                    showCursor: true,
                    onTapAlwaysCalled: true,
                    style: TextStyle(color: _ink),
                    onTap: () => openIosKeyboard(context, _reply, onDone: _send),
                    decoration: InputDecoration(
                      hintText: _composerHint,
                      hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                      filled: true,
                      fillColor: const Color(0xFFEFEFF4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Send',
                  onPressed: _send,
                  icon: const Icon(Icons.arrow_upward, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: _sent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContactsApp extends StatelessWidget {
  const ContactsApp({
    super.key,
    required this.onMessage,
    required this.onCall,
    this.onAdd,
    this.contacts = kContacts,
  });

  final void Function(ContactCard contact) onMessage;
  final void Function(ContactCard contact) onCall;
  final ValueChanged<PropPerson>? onAdd;
  final List<ContactCard> contacts;

  @override
  Widget build(BuildContext context) {
    final sorted = [...contacts]..sort((a, b) => a.name.compareTo(b.name));
    return Material(
      color: Colors.black,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Contacts', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: onAdd == null ? null : () => _add(context),
                  child: const Text('Add', style: TextStyle(color: Color(0xFF0A84FF), fontSize: 17)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final contact in sorted)
                  ListTile(
                    title: Text(contact.name),
                    subtitle: Text(contact.number, style: const TextStyle(color: Color(0xFF8E8E93))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Call',
                          onPressed: () => onCall(contact),
                          icon: const Icon(Icons.phone, color: Color(0xFF34C759)),
                        ),
                        IconButton(
                          tooltip: 'Message',
                          onPressed: () => onMessage(contact),
                          icon: const Icon(Icons.message, color: Color(0xFF0A84FF)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final person = await Navigator.of(context).push<PropPerson>(
      MaterialPageRoute(builder: (context) => const _NewContactPage()),
    );
    if (person != null) onAdd?.call(person);
  }
}

class _NewContactPage extends StatefulWidget {
  const _NewContactPage();

  @override
  State<_NewContactPage> createState() => _NewContactPageState();
}

class _NewContactPageState extends State<_NewContactPage> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _company = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _company.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Widget _field(TextEditingController controller, String hint, {bool numeric = false}) {
    return TextField(
      controller: controller,
      readOnly: true,
      showCursor: true,
      style: const TextStyle(color: Colors.white, fontSize: 17),
      onTap: () => openIosKeyboard(context, controller, numeric: numeric),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        foregroundColor: const Color(0xFF0A84FF),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF0A84FF))),
        ),
        leadingWidth: 88,
        title: const Text('New Contact', style: TextStyle(color: Colors.white, fontSize: 17)),
        actions: [
          TextButton(
            onPressed: () {
              final name = '${_first.text.trim()} ${_last.text.trim()}'.trim();
              if (name.isEmpty) return;
              Navigator.pop(
                context,
                PropPerson(
                  name: name,
                  number: _phone.text.trim(),
                  email: _email.text.trim(),
                  company: _company.text.trim(),
                ),
              );
            },
            child: const Text('Done', style: TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 18),
          const CircleAvatar(
            radius: 48,
            backgroundColor: Color(0xFF2C2C2E),
            child: Icon(Icons.person, size: 56, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('Add Photo', style: TextStyle(color: Color(0xFF0A84FF)))),
          const SizedBox(height: 16),
          _group([
            _field(_first, 'First name'),
            _field(_last, 'Last name'),
            _field(_company, 'Company'),
          ]),
          const SizedBox(height: 18),
          _group([
            _field(_phone, 'add phone', numeric: true),
            _field(_email, 'add email'),
          ]),
        ],
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, color: Color(0x33FFFFFF)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: NavigationToolbar(
            leading: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            middle: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
