import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'catalog.dart';
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
  });

  final StageStore store;
  final String deviceId;
  final List<ContactCard> contacts;
  final String language;

  @override
  State<PhoneDialer> createState() => _PhoneDialerState();
}

class _PhoneDialerState extends State<PhoneDialer> {
  String _digits = '';
  String _tab = 'keypad';
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
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
            ),
            child: Row(
              children: [
                _tabButton('recents', copy.recents),
                _tabButton('history', 'History'),
                _tabButton('keypad', copy.keypad),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              'recents' => _recents(copy),
              'history' => _history(copy),
              _ => _keypad(),
            },
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String id, String label) {
    final selected = _tab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? _phoneGreen : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: selected ? _phoneGreen : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }

  Widget _recents(PhoneCopy copy) {
    final rows = widget.store.callHistory
        .where((record) => record.deviceId == widget.deviceId)
        .take(100)
        .toList();
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            copy.noCalls,
            style: const TextStyle(color: Colors.white30, fontSize: 14),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        for (final record in rows) _callRow(copy, record, showNumber: true),
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
              Text(
                _digits.isEmpty ? 'Enter number' : _digits,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1,
                  color: _digits.isEmpty ? Colors.white24 : Colors.white,
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
                        child: Icon(Icons.phone, color: Colors.black, size: 30),
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
    return Material(
      color: Colors.white10,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() => _digits += label),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
            ),
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
  });

  final StageStore store;
  final String deviceId;
  final VoidCallback onClose;
  final String? initialThread;

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

  void _send() {
    final thread = _thread;
    if (thread == null) return;
    widget.store.sendMessage(
      deviceId: widget.deviceId,
      sender: 'phone',
      text: _reply.text,
      senderName: thread,
      thread: thread,
    );
    _reply.clear();
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
      if (names.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Messages from the control deck show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted),
            ),
          ),
        );
      }
      return Column(
        children: [
          SizedBox(
            height: 44,
            child: NavigationToolbar(
              leading: IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.arrow_back),
              ),
              middle: const Text(
                'Messages',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final name in names)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorForName(name),
                      child: Text(name.characters.first.toUpperCase()),
                    ),
                    title: Text(name),
                    subtitle: Text(
                      grouped[name]!.last.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => setState(() => _thread = name),
                  ),
              ],
            ),
          ),
        ],
      );
    }
    final items = grouped[thread] ?? const <StageMessage>[];
    return Column(
      children: [
        ListTile(
          leading: IconButton(
            onPressed: () => setState(() => _thread = null),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(thread),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final message in items)
                Align(
                  alignment: message.sender == 'phone'
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: message.sender == 'phone' ? kAccent : kLine,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message.text),
                        Text(
                          formatStamp(message.sentAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _reply,
                  decoration: const InputDecoration(hintText: 'Reply'),
                  onSubmitted: (_) => _send(),
                ),
              ),
              IconButton(
                onPressed: _send,
                icon: const Icon(Icons.send, color: kAccent),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ContactsApp extends StatelessWidget {
  const ContactsApp({
    super.key,
    required this.onMessage,
    required this.onCall,
    this.contacts = kContacts,
  });

  final void Function(ContactCard contact) onMessage;
  final void Function(ContactCard contact) onCall;
  final List<ContactCard> contacts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final contact in contacts)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorForName(contact.name),
              child: Text(contact.name.characters.first),
            ),
            title: Text(contact.name),
            subtitle: Text(contact.number),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => onCall(contact),
                  icon: const Icon(Icons.call, color: kSignal),
                ),
                IconButton(
                  onPressed: () => onMessage(contact),
                  icon: const Icon(Icons.message, color: kAccent),
                ),
              ],
            ),
          ),
      ],
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
