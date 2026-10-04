import 'dart:collection';

import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'catalog.dart';

class PhoneDialer extends StatefulWidget {
  const PhoneDialer({
    super.key,
    required this.store,
    required this.deviceId,
    this.contacts = kContacts,
  });

  final StageStore store;
  final String deviceId;
  final List<ContactCard> contacts;

  @override
  State<PhoneDialer> createState() => _PhoneDialerState();
}

class _PhoneDialerState extends State<PhoneDialer> {
  String _digits = '';

  void _call() {
    final match = widget.contacts
        .where(
          (contact) =>
              contact.number.replaceAll(' ', '') ==
              _digits.replaceAll(' ', ''),
        )
        .firstOrNull;
    widget.store.startCall(
      deviceId: widget.deviceId,
      contactName: match?.name ?? (_digits.isEmpty ? 'Unknown' : _digits),
      contactNumber: _digits,
      direction: 'outgoing',
    );
  }

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#'];
    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          _digits.isEmpty ? ' ' : _digits,
          style: const TextStyle(fontSize: 28, letterSpacing: 1),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(18),
            crossAxisCount: 3,
            childAspectRatio: 1.3,
            children: [
              for (final key in keys)
                InkWell(
                  onTap: () => setState(() => _digits += key),
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: Text(key, style: const TextStyle(fontSize: 28)),
                  ),
                ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _digits.isEmpty
                  ? null
                  : () => setState(
                      () => _digits = _digits.substring(0, _digits.length - 1),
                    ),
              icon: const Icon(Icons.backspace_outlined),
            ),
            const SizedBox(width: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kSignal,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(18),
              ),
              onPressed: _call,
              child: const Icon(Icons.call),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
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
