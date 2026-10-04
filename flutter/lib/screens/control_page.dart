import 'dart:collection';

import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import '../theme.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  late final TextEditingController _name;
  late final TextEditingController _number;
  late final TextEditingController _message;
  late final TextEditingController _banner;
  late final TextEditingController _join;
  String _appLabel = 'Messages';
  String _contactSignature = '';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: kContacts.first.name);
    _number = TextEditingController(text: kContacts.first.number);
    _message = TextEditingController();
    _banner = TextEditingController();
    _join = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _message.dispose();
    _banner.dispose();
    _join.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final link = store.sync;
    final target = store.deviceById(store.targetDeviceId);
    final call = store.callFor(target?.id);
    final contacts = contactsFor(target?.os ?? const OsSettings());
    final signature = contacts
        .map((contact) => '${contact.name}|${contact.number}')
        .join(';');
    if (_contactSignature != signature) {
      _contactSignature = signature;
      if (!contacts.any((contact) => contact.name == _name.text)) {
        _name.text = contacts.first.name;
        _number.text = contacts.first.number;
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        const Text(
          'Control deck',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Drive the prop phone — calls, messages, alarms.',
          style: TextStyle(color: kMuted),
        ),
        const SizedBox(height: 18),
        _Card(
          title: 'Connection',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: target?.id,
                decoration: const InputDecoration(labelText: 'Prop device'),
                items: [
                  for (final device in store.devices)
                    DropdownMenuItem(
                      value: device.id,
                      child: Text('${device.name} · ${device.kind}'),
                    ),
                ],
                onChanged: store.setTarget,
              ),
              const SizedBox(height: 12),
              Text(
                link?.status ?? 'On this device only.',
                style: const TextStyle(color: kMuted),
              ),
              if (link?.address != null) ...[
                const SizedBox(height: 6),
                SelectableText(
                  link!.address!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kAccent,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: link == null || link.role == LinkRole.host
                        ? null
                        : () => link.host(),
                    child: const Text('Host deck'),
                  ),
                  OutlinedButton(
                    onPressed: link == null || link.role == LinkRole.solo
                        ? null
                        : () => link.disconnect(),
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _join,
                      decoration: const InputDecoration(
                        hintText: '192.168.0.12:8765',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: link == null
                        ? null
                        : () => link.join(_join.text),
                    child: const Text('Join'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Same Wi-Fi. Host on the operator machine (Mac, Windows, or a tablet). Join from the prop phone.',
                style: TextStyle(color: kMuted, fontSize: 12, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'Call',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey(signature),
                initialValue: contacts
                    .where((contact) => contact.name == _name.text)
                    .firstOrNull
                    ?.name ??
                    contacts.first.name,
                decoration: const InputDecoration(labelText: 'Contact'),
                items: [
                  for (final contact in contacts)
                    DropdownMenuItem(
                      value: contact.name,
                      child: Text(contact.name),
                    ),
                ],
                onChanged: (name) {
                  final contact = contacts
                      .where((item) => item.name == name)
                      .firstOrNull;
                  if (contact == null) return;
                  _name.text = contact.name;
                  _number.text = contact.number;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _number,
                decoration: const InputDecoration(labelText: 'Number'),
              ),
              const SizedBox(height: 12),
              if (call != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    call.status == 'ringing'
                        ? (call.direction == 'incoming'
                              ? 'Ringing on ${target?.name ?? 'the phone'}'
                              : '${target?.name ?? 'Phone'} is calling')
                        : 'Call is live',
                    style: const TextStyle(color: kSignal),
                  ),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: const Key('deck-call'),
                    onPressed: target == null
                        ? null
                        : () => store.startCall(
                            deviceId: target.id,
                            contactName: _name.text,
                            contactNumber: _number.text,
                            direction: 'incoming',
                          ),
                    icon: const Icon(Icons.call),
                    label: const Text('Call phone'),
                  ),
                  OutlinedButton(
                    onPressed: call == null || target == null
                        ? null
                        : () => store.setCallStatus(target.id, 'active'),
                    child: const Text('Mark answered'),
                  ),
                  OutlinedButton(
                    onPressed: call == null || target == null
                        ? null
                        : () => store.endCall(target.id),
                    child: const Text('End'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'Message',
          child: Column(
            children: [
              TextField(
                key: const Key('deck-message'),
                controller: _message,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Text the prop phone',
                ),
                onSubmitted: (_) => _send(store, target?.id),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const Key('deck-send'),
                  onPressed: target == null
                      ? null
                      : () => _send(store, target.id),
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'Cues',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: target == null
                        ? null
                        : () => store.setAlarm(target.id, true),
                    icon: const Icon(Icons.alarm),
                    label: const Text('Alarm'),
                  ),
                  OutlinedButton(
                    onPressed: target == null
                        ? null
                        : () => store.setAlarm(target.id, false),
                    child: const Text('Stop alarm'),
                  ),
                  OutlinedButton(
                    onPressed: target == null
                        ? null
                        : () => store.setLocked(target.id, true),
                    child: const Text('Lock'),
                  ),
                  OutlinedButton(
                    onPressed: target == null
                        ? null
                        : () => store.setLocked(target.id, false),
                    child: const Text('Unlock'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _appLabel,
                decoration: const InputDecoration(
                  labelText: 'Notification app',
                ),
                items: const [
                  DropdownMenuItem(value: 'Messages', child: Text('Messages')),
                  DropdownMenuItem(value: 'Mail', child: Text('Mail')),
                  DropdownMenuItem(
                    value: 'Grapevine',
                    child: Text('Grapevine'),
                  ),
                  DropdownMenuItem(value: 'Calendar', child: Text('Calendar')),
                ],
                onChanged: (value) =>
                    setState(() => _appLabel = value ?? 'Messages'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _banner,
                decoration: const InputDecoration(hintText: 'Banner text'),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: target == null
                      ? null
                      : () {
                          store.pushBanner(
                            deviceId: target.id,
                            appLabel: _appLabel,
                            text: _banner.text,
                          );
                          _banner.clear();
                        },
                  child: const Text('Push banner'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _send(StageStore store, String? deviceId) {
    if (deviceId == null) return;
    store.sendMessage(
      deviceId: deviceId,
      sender: 'control',
      text: _message.text,
      senderName: _name.text,
      thread: _name.text,
    );
    _message.clear();
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
