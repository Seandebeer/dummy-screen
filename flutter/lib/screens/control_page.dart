import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../deck/chrome.dart';
import '../image_file.dart';
import '../media/call_media.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../phone/app_catalog.dart';
import '../phone/catalog.dart';
import '../store.dart';
import '../theme.dart';
import '../video_source.dart';
import '../vfx/catalog.dart';

class _Reply {
  _Reply(this.text);

  final String text;
}

class _QueuedNote {
  _QueuedNote(this.app, this.screen, this.text);

  final String app;
  String text;
  final String screen;
}

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  late final TextEditingController _name;
  late final TextEditingController _number;
  late final TextEditingController _email;
  late final TextEditingController _message;
  late final TextEditingController _reply;
  late final TextEditingController _banner;
  late final TextEditingController _join;
  String _photo = '';
  String _photoMode = 'circle';
  bool _mic = true;
  bool _speaker = false;
  String _videoMode = 'live';
  bool _cam = true;
  bool _videoMic = true;
  String _farPhoto = '';
  String _farVideo = '';
  String _vfxHex = '#00B140';
  String _vfxMark = 'cross';
  String _notifScreen = 'lock';
  String _notifApp = 'messages';
  final List<_Reply> _replies = [];
  final List<_Reply> _pushedReplies = [];
  final List<_QueuedNote> _notes = [];
  final List<_QueuedNote> _pushedNotes = [];
  bool _broadcast = false;
  int _lockClicks = 0;
  DateTime? _lockAt;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: kContacts.first.name);
    _number = TextEditingController(text: kContacts.first.number);
    _email = TextEditingController();
    _message = TextEditingController();
    _reply = TextEditingController();
    _banner = TextEditingController();
    _join = TextEditingController();
    for (final controller in [_name, _number, _message, _reply, _banner]) {
      controller.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _email.dispose();
    _message.dispose();
    _reply.dispose();
    _banner.dispose();
    _join.dispose();
    super.dispose();
  }

  String _bannerLabel(String id) {
    if (id.startsWith('custom:')) return id.substring('custom:'.length);
    return propAppById(id)?.label ?? catalogAppById(id)?.label ?? id;
  }

  List<String> _targets(StageStore store) {
    if (_broadcast) return store.devices.map((device) => device.id).toList();
    final id = store.targetDeviceId;
    return id == null ? const [] : [id];
  }

  Map<String, dynamic> _videoScene() => {
    'mode': _videoMode,
    'photo': _farPhoto,
    'video': _farVideo,
    'bg': _vfxHex,
    'mark': _vfxMark,
    'camOff': !_cam,
  };

  void _pushVideoScene(StageStore store) {
    for (final id in _targets(store)) {
      final live = store.callFor(id);
      if (live != null && live.kind == 'video') {
        store.updateCallScene(id, _videoScene());
      }
    }
  }

  Future<void> _pickFar(StageStore store, bool video) async {
    final file = await FilePicker.pickFile(
      type: video ? FileType.video : FileType.image,
      dialogTitle: video ? 'Video clip' : 'Photo',
    );
    if (file == null || !mounted) return;
    final saved = video ? await persistPickedVideo(file) : await persistPickedImage(file);
    if (!mounted || saved == null || saved.isEmpty) return;
    setState(() {
      if (video) {
        _farVideo = saved;
      } else {
        _farPhoto = saved;
      }
    });
    _pushVideoScene(store);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final palette = paletteFor(store.appTheme);
    final link = store.sync;
    final target = store.deviceById(store.targetDeviceId);
    final channel = _broadcast
        ? 'stage-1'
        : (target == null ? null : 'device-${target.id}');
    final call = target == null ? null : store.callFor(target.id);
    final alarm = target != null && (store.alarms[target.id] ?? false);
    final messages = target == null
        ? const <StageMessage>[]
        : store.messagesFor(target.id);
    final media = CallMediaScope.maybeOf(context);
    return GridFill(
      palette: palette,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REMOTE CONTROL DECK',
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'DRIVE THE PROP PHONE - CALLS & MESSAGES',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _TargetCard(
                    palette: palette,
                    store: store,
                    channel: channel,
                    broadcast: _broadcast,
                    onBroadcast: (value) {
                      setState(() => _broadcast = value);
                      store.setDeckBroadcast(value);
                    },
                    link: link,
                    join: _join,
                  ),
                  const SizedBox(height: 20),
                  CollapsibleCard(
                    palette: palette,
                    icon: Icons.person_outline,
                    title: 'Contact',
                    child: _ContactCard(
                      palette: palette,
                      name: _name,
                      number: _number,
                      email: _email,
                      photo: _photo,
                      photoMode: _photoMode,
                      onPhotoMode: (value) {
                        setState(() => _photoMode = value);
                        for (final id in _targets(store)) {
                          store.updateOs(id, (os) => os.copyWith(callerPhoto: value));
                          store.updateCallScene(id, {'caller': value, 'photo': _photo});
                        }
                      },
                      onPhoto: (value) {
                        setState(() => _photo = value);
                        for (final id in _targets(store)) {
                          store.updateCallScene(id, {'photo': value, 'caller': _photoMode});
                        }
                      },
                      os: target?.os ?? const OsSettings(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CollapsibleCard(
                    palette: palette,
                    icon: Icons.phone_callback,
                    title: 'Call',
                    child: _CallBody(
                      palette: palette,
                      channel: channel,
                      call: call,
                      photoMode: _photoMode,
                      mic: _mic,
                      speaker: _speaker,
                      onPhotoMode: (value) => setState(() => _photoMode = value),
                      voiceStatus: media?.voiceStatus ?? 'off',
                      onMic: () {
                        setState(() => _mic = !_mic);
                        if (call?.kind != 'video') media?.setMic(_mic);
                      },
                      onSpeaker: () {
                        setState(() => _speaker = !_speaker);
                        media?.setSpeaker(_speaker);
                      },
                      onCall: () {
                        for (final id in _targets(store)) {
                          media?.arm(mic: _mic, speaker: _speaker, camera: false);
                          store.startCall(
                            deviceId: id,
                            contactName: _name.text,
                            contactNumber: _number.text,
                            direction: 'incoming',
                            scene: {'photo': _photo, 'caller': _photoMode},
                          );
                        }
                      },
                      onEnd: () {
                        for (final id in _targets(store)) {
                          store.endCall(id);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  CollapsibleCard(
                    palette: palette,
                    icon: Icons.videocam_outlined,
                    title: 'Video call',
                    child: _VideoCallBody(
                      palette: palette,
                      enabled: channel != null && _name.text.trim().isNotEmpty,
                      mode: _videoMode,
                      cam: _cam,
                      mic: _videoMic,
                      status: media?.videoStatus ?? 'off',
                      vfxHex: _vfxHex,
                      vfxMark: _vfxMark,
                      hasPhoto: _farPhoto.isNotEmpty,
                      hasVideo: _farVideo.isNotEmpty,
                      onColor: (hex) {
                        setState(() => _vfxHex = hex);
                        _pushVideoScene(store);
                      },
                      onMark: (id) {
                        setState(() => _vfxMark = id);
                        _pushVideoScene(store);
                      },
                      onUpload: () => _pickFar(store, _videoMode == 'video'),
                      onMode: (value) {
                        setState(() => _videoMode = value);
                        if (value == 'live') {
                          media?.arm(mic: _videoMic, speaker: false, camera: _cam);
                          media?.promoteLive();
                        }
                        _pushVideoScene(store);
                      },
                      onCam: () {
                        setState(() => _cam = !_cam);
                        media?.setCam(_cam);
                        _pushVideoScene(store);
                      },
                      onMic: () {
                        setState(() => _videoMic = !_videoMic);
                        if (call?.kind == 'video') media?.setMic(_videoMic);
                      },
                      onStart: () {
                        for (final id in _targets(store)) {
                          if (_videoMode == 'live') {
                            media?.arm(
                              mic: _videoMic,
                              speaker: false,
                              camera: _cam,
                            );
                          }
                          store.startCall(
                            deviceId: id,
                            contactName: _name.text,
                            contactNumber: _number.text,
                            direction: 'incoming',
                            kind: 'video',
                            scene: _videoScene(),
                          );
                        }
                      },
                      onEnd: () {
                        for (final id in _targets(store)) {
                          store.endCall(id);
                        }
                      },
                      live: call != null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CollapsibleCard(
                    palette: palette,
                    icon: Icons.chat_bubble_outline,
                    title: 'Message',
                    child: _MessageBody(
                      palette: palette,
                      messages: messages,
                      contact: _name.text.trim(),
                      text: _message,
                      reply: _reply,
                      replies: _replies,
                      onSend: () {
                        final body = _message.text;
                        for (final id in _targets(store)) {
                          store.sendMessage(
                            deviceId: id,
                            sender: 'control',
                            text: body,
                            senderName: _name.text.trim().isEmpty
                                ? 'Control'
                                : _name.text.trim(),
                            thread: _name.text.trim().isEmpty
                                ? 'Control'
                                : _name.text.trim(),
                          );
                        }
                        _message.clear();
                      },
                      onAddReply: () {
                        if (_replies.length >= 20 || _reply.text.trim().isEmpty) {
                          return;
                        }
                        setState(() {
                          _replies.add(_Reply(_reply.text.trim()));
                          _reply.clear();
                        });
                      },
                      onSendReply: () {
                        if (_replies.isEmpty) return;
                        final next = _replies.first;
                        for (final id in _targets(store)) {
                          store.sendMessage(
                            deviceId: id,
                            sender: 'control',
                            text: next.text,
                            senderName: _name.text.trim().isEmpty
                                ? 'Control'
                                : _name.text.trim(),
                            thread: _name.text.trim().isEmpty
                                ? 'Control'
                                : _name.text.trim(),
                          );
                        }
                        setState(() {
                          _pushedReplies.add(next);
                          _replies.removeAt(0);
                        });
                      },
                      onRemoveReply: (index) =>
                          setState(() => _replies.removeAt(index)),
                      onReset: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear all messages on this channel?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true) return;
                        for (final id in _targets(store)) {
                          store.clearMessages(id);
                        }
                        setState(() {
                          _replies
                            ..clear()
                            ..addAll(_pushedReplies.take(20));
                          _pushedReplies.clear();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  CollapsibleCard(
                    palette: palette,
                    icon: Icons.notifications_none,
                    title: 'Notification',
                    child: _NotifBody(
                      palette: palette,
                      screen: _notifScreen,
                      app: _notifApp,
                      text: _banner,
                      queue: _notes,
                      onScreen: (value) => setState(() => _notifScreen = value),
                      onApp: (value) => setState(() => _notifApp = value),
                      onAdd: () {
                        if (_notes.length >= 20 || _banner.text.trim().isEmpty) {
                          return;
                        }
                        setState(() {
                          _notes.add(
                            _QueuedNote(_notifApp, _notifScreen, _banner.text.trim()),
                          );
                          _banner.clear();
                        });
                      },
                      onPush: () {
                        if (_notes.isEmpty) return;
                        final next = _notes.first;
                        for (final id in _targets(store)) {
                          store.pushBanner(
                            deviceId: id,
                            appLabel: _bannerLabel(next.app),
                            appId: next.app,
                            text: next.text,
                          );
                        }
                        setState(() {
                          _pushedNotes.add(next);
                          _notes.removeAt(0);
                        });
                      },
                      onReset: () {
                        for (final id in _targets(store)) {
                          store.clearBanners(id);
                        }
                        setState(() {
                          _notes
                            ..clear()
                            ..addAll(_pushedNotes.take(20));
                          _pushedNotes.clear();
                        });
                      },
                      onRemove: (index) => setState(() => _notes.removeAt(index)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CollapsibleCard(
                    palette: palette,
                    icon: Icons.alarm,
                    iconColor: kAccent,
                    title: 'Alarm',
                    badge: alarm
                        ? const Text(
                            'RINGING',
                            style: TextStyle(
                              color: kAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: channel == null && !alarm
                            ? null
                            : () {
                                for (final id in _targets(store)) {
                                  store.setAlarm(id, !alarm);
                                }
                              },
                        icon: const Icon(Icons.alarm),
                        label: Text(alarm ? 'Stop Alarm' : 'Trigger Alarm'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CollapsibleCard(
                    palette: palette,
                    icon: Icons.mail_outline,
                    title: 'Email',
                    child: _EmailBody(
                      palette: palette,
                      enabled: channel != null,
                      onSend: (from, subject, body) {
                        for (final id in _targets(store)) {
                          store.pushMail(
                            deviceId: id,
                            from: from,
                            subject: subject,
                            body: body,
                          );
                        }
                      },
                      onClear: () {
                        for (final id in _targets(store)) {
                          store.clearMail(id);
                        }
                      },
                    ),
                  ),
                  if (channel != null) ...[
                    const SizedBox(height: 20),
                    _LockPad(
                      palette: palette,
                      locked: store.filming,
                      onToggle: () {
                        final now = DateTime.now();
                        if (_lockAt != null &&
                            now.difference(_lockAt!) <
                                const Duration(milliseconds: 600)) {
                          _lockClicks += 1;
                        } else {
                          _lockClicks = 1;
                        }
                        _lockAt = now;
                        if (_lockClicks >= 3) {
                          _lockClicks = 0;
                          store.setFilming(!store.filming);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.palette,
    required this.store,
    required this.channel,
    required this.broadcast,
    required this.onBroadcast,
    required this.link,
    required this.join,
  });

  final DeckPalette palette;
  final StageStore store;
  final String? channel;
  final bool broadcast;
  final ValueChanged<bool> onBroadcast;
  final StageSync? link;
  final TextEditingController join;

  @override
  Widget build(BuildContext context) {
    final connected = channel != null;
    return DeckCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.podcasts, size: 16, color: kSignal),
              const SizedBox(width: 8),
              Text(
                'Target Device',
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(Icons.circle, size: 8, color: connected ? kSignal : palette.muted),
              const SizedBox(width: 6),
              Text(
                connected ? 'CONNECTED' : 'NOT CONNECTED',
                style: TextStyle(
                  color: connected ? kSignal : palette.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (store.devices.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No devices detected - ensure that you have created a device. Home screen › Projects › Devices.',
                style: TextStyle(color: palette.muted, fontSize: 11),
              ),
            ),
          if (store.devices.isNotEmpty && !connected)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No device connected. Ensure that you have selected a device on the home screen — Projects › Devices.',
                style: TextStyle(color: palette.muted, fontSize: 11),
              ),
            ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.secondary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (connected ? kSignal : kAlert).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (connected ? kSignal : kAlert).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.power,
                      color: connected ? kSignal : kAlert,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: broadcast ? 'all' : store.targetDeviceId,
                      underline: const SizedBox.shrink(),
                      dropdownColor: palette.surface,
                      hint: Text(
                        'Tap to connect a device…',
                        style: TextStyle(color: palette.muted),
                      ),
                      items: [
                        for (final device in store.activeDevices)
                          DropdownMenuItem(
                            value: device.id,
                            child: Text(device.name),
                          ),
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('All devices (broadcast)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == 'all') {
                          onBroadcast(true);
                        } else {
                          onBroadcast(false);
                          store.setTarget(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            connected
                ? 'channel $channel · ${broadcast ? 'every connected phone reacts' : "only this device's phones react"}'
                : 'tap the panel to pick a device - None disconnects',
            style: TextStyle(color: palette.muted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Text(
            link?.status ?? 'On this device only.',
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
          if (link?.address != null)
            SelectableText(
              link!.address!,
              style: const TextStyle(
                color: kAccent,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: link == null || link!.role == LinkRole.host
                    ? null
                    : () => link!.host(),
                child: const Text('Host deck'),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: join,
                  decoration: deckField(palette, 'Join address'),
                ),
              ),
              OutlinedButton(
                onPressed: link == null
                    ? null
                    : () {
                        link!.join(join.text);
                        join.clear();
                      },
                child: const Text('Join'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.palette,
    required this.name,
    required this.number,
    required this.email,
    required this.photo,
    required this.photoMode,
    required this.onPhoto,
    required this.onPhotoMode,
    required this.os,
  });

  final DeckPalette palette;
  final TextEditingController name;
  final TextEditingController number;
  final TextEditingController email;
  final String photo;
  final String photoMode;
  final ValueChanged<String> onPhoto;
  final ValueChanged<String> onPhotoMode;
  final OsSettings os;

  @override
  Widget build(BuildContext context) {
    final contacts = contactsFor(os);
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CALLER DETAILS',
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      "Displayed on the actor's OS when calling or messaging",
                      style: TextStyle(color: palette.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (photo.isNotEmpty)
                TextButton(
                  onPressed: () => onPhoto(''),
                  child: const Text('Remove photo'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () async {
                  final file = await FilePicker.pickFile(type: FileType.image);
                  if (file == null) return;
                  final path = await persistPickedImage(file);
                  if (path != null) onPhoto(path);
                },
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.secondary,
                    border: Border.all(color: palette.line),
                    image: imageProviderForPath(photo) == null
                        ? null
                        : DecorationImage(
                            image: imageProviderForPath(photo)!,
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: photo.isEmpty
                      ? Icon(Icons.add_photo_alternate_outlined, color: palette.muted)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: name,
                            decoration: deckField(palette, 'Name'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: number,
                            decoration: deckField(palette, 'Mock number'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: email,
                      decoration: deckField(palette, 'Email (optional)'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDialog<ContactCard>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Choose from contacts'),
                  children: [
                    for (final contact in contacts)
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, contact),
                        child: Text('${contact.name}  ${contact.number}'),
                      ),
                  ],
                ),
              );
              if (picked == null) return;
              name.text = picked.name;
              number.text = picked.number;
            },
            icon: const Icon(Icons.smartphone, size: 14),
            label: const Text('Choose from contacts'),
          ),
          const SizedBox(height: 12),
          Text('Caller photo', style: TextStyle(color: palette.muted, fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Round avatar'),
                selected: photoMode != 'full',
                onSelected: (_) => onPhotoMode('circle'),
              ),
              ChoiceChip(
                label: const Text('Full screen'),
                selected: photoMode == 'full',
                onSelected: (_) => onPhotoMode('full'),
              ),
            ],
          ),
        ],
    );
  }
}

class _QueuedMail {
  _QueuedMail(this.from, this.subject, this.body);

  final String from;
  final String subject;
  final String body;
}

class _EmailBody extends StatefulWidget {
  const _EmailBody({
    required this.palette,
    required this.enabled,
    required this.onSend,
    required this.onClear,
  });

  final DeckPalette palette;
  final bool enabled;
  final void Function(String from, String subject, String body) onSend;
  final VoidCallback onClear;

  @override
  State<_EmailBody> createState() => _EmailBodyState();
}

class _EmailBodyState extends State<_EmailBody> {
  final _from = TextEditingController(text: 'Production Desk');
  final _subject = TextEditingController();
  final _body = TextEditingController();
  final List<_QueuedMail> _queue = [];
  final List<_QueuedMail> _sent = [];

  @override
  void dispose() {
    _from.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  _QueuedMail? _draft() {
    final subject = _subject.text.trim();
    final body = _body.text.trim();
    if (subject.isEmpty && body.isEmpty) return null;
    return _QueuedMail(
      _from.text.trim().isEmpty ? 'Production Desk' : _from.text.trim(),
      subject.isEmpty ? '(no subject)' : subject,
      body,
    );
  }

  void _sendDraft() {
    final mail = _draft();
    if (mail == null || !widget.enabled) return;
    widget.onSend(mail.from, mail.subject, mail.body);
    setState(() {
      _sent.add(mail);
      _subject.clear();
      _body.clear();
    });
  }

  void _add() {
    final mail = _draft();
    if (mail == null || _queue.length >= 20) return;
    setState(() {
      _queue.add(mail);
      _subject.clear();
      _body.clear();
    });
  }

  void _sendNext() {
    if (_queue.isEmpty || !widget.enabled) return;
    final mail = _queue.removeAt(0);
    widget.onSend(mail.from, mail.subject, mail.body);
    setState(() => _sent.add(mail));
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear mail on this channel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    widget.onClear();
    setState(() {
      _queue.insertAll(0, _sent);
      _sent.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Column(
      children: [
        TextField(controller: _from, decoration: deckField(palette, 'From')),
        const SizedBox(height: 8),
        TextField(
          controller: _subject,
          onChanged: (_) => setState(() {}),
          decoration: deckField(palette, 'Subject'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _body,
          minLines: 2,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          decoration: deckField(palette, 'Message'),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: _draft() == null || _queue.length >= 20 ? null : _add,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: !widget.enabled || _draft() == null ? null : _sendDraft,
              child: const Text('Send'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Queue · ${_queue.length}/20',
            style: TextStyle(color: palette.muted, fontSize: 10),
          ),
        ),
        for (var i = 0; i < _queue.length; i++)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Text('${i + 1}'),
            title: Text(_queue[i].subject),
            subtitle: Text(_queue[i].body, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              onPressed: () => setState(() => _queue.removeAt(i)),
              icon: const Icon(Icons.delete_outline, size: 16),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              key: const Key('deck-email-reset'),
              onPressed: _reset,
              icon: const Icon(Icons.recycling, size: 14),
              label: const Text('Reset'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kSignal,
                foregroundColor: Colors.black,
              ),
              onPressed: !widget.enabled || _queue.isEmpty ? null : _sendNext,
              icon: const Icon(Icons.send, size: 14),
              label: const Text('Send'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CallBody extends StatelessWidget {
  const _CallBody({
    required this.palette,
    required this.channel,
    required this.call,
    required this.photoMode,
    required this.mic,
    required this.speaker,
    required this.onPhotoMode,
    required this.voiceStatus,
    required this.onMic,
    required this.onSpeaker,
    required this.onCall,
    required this.onEnd,
  });

  final DeckPalette palette;
  final String? channel;
  final LiveCall? call;
  final String photoMode;
  final bool mic;
  final bool speaker;
  final String voiceStatus;
  final ValueChanged<String> onPhotoMode;
  final VoidCallback onMic;
  final VoidCallback onSpeaker;
  final VoidCallback onCall;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final idle = call == null;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                key: const Key('deck-call'),
                color: kSignal,
                icon: Icons.phone_callback,
                label: 'Call',
                onTap: channel == null || !idle ? null : onCall,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionTile(
                color: kAlert,
                icon: Icons.call_end,
                label: 'End',
                onTap: idle ? null : onEnd,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Caller photo before answering',
                style: TextStyle(color: palette.muted, fontSize: 10),
              ),
            ),
            ChoiceChip(
              label: const Text('Circle'),
              selected: photoMode == 'circle',
              onSelected: (_) => onPhotoMode('circle'),
            ),
            const SizedBox(width: 4),
            ChoiceChip(
              label: const Text('Full screen'),
              selected: photoMode == 'full',
              onSelected: (_) => onPhotoMode('full'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('On this deck', style: TextStyle(color: palette.muted, fontSize: 10)),
            ActionChip(
              avatar: Icon(mic ? Icons.mic : Icons.mic_off, size: 14),
              label: Text(mic ? 'Mic on' : 'Mic off'),
              onPressed: onMic,
            ),
            ActionChip(
              avatar: const Icon(Icons.volume_up, size: 14),
              label: Text(speaker ? 'Speaker on' : 'Speaker off'),
              onPressed: onSpeaker,
            ),
            Text(
              'your voice into the phone · hear the actor',
              style: TextStyle(color: palette.muted, fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          voiceStatusLine(voiceStatus),
          style: TextStyle(
            color: voiceStatus == 'mic-on' ? kSignal : palette.muted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _VideoCallBody extends StatelessWidget {
  const _VideoCallBody({
    required this.palette,
    required this.enabled,
    required this.live,
    required this.mode,
    required this.cam,
    required this.mic,
    required this.status,
    required this.vfxHex,
    required this.vfxMark,
    required this.hasPhoto,
    required this.hasVideo,
    required this.onMode,
    required this.onCam,
    required this.onMic,
    required this.onColor,
    required this.onMark,
    required this.onUpload,
    required this.onStart,
    required this.onEnd,
  });

  final DeckPalette palette;
  final bool enabled;
  final bool live;
  final String mode;
  final bool cam;
  final bool mic;
  final String status;
  final String vfxHex;
  final String vfxMark;
  final bool hasPhoto;
  final bool hasVideo;
  final ValueChanged<String> onMode;
  final VoidCallback onCam;
  final VoidCallback onMic;
  final ValueChanged<String> onColor;
  final ValueChanged<String> onMark;
  final VoidCallback onUpload;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final item in const ['live', 'vfx', 'video', 'photo'])
              ChoiceChip(
                label: Text(_videoModeLabel(item)),
                selected: mode == item,
                onSelected: (_) => onMode(item),
              ),
          ],
        ),
        if (mode == 'live') ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ActionChip(
                avatar: Icon(cam ? Icons.videocam : Icons.videocam_off, size: 14),
                label: const Text('Camera'),
                onPressed: onCam,
              ),
              ActionChip(
                avatar: Icon(mic ? Icons.mic : Icons.mic_off, size: 14),
                label: const Text('Mic'),
                onPressed: onMic,
              ),
              Text(
                videoStatusLine(status),
                style: TextStyle(
                  color: status == 'cam-on' ? kSignal : palette.muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
        if (mode == 'vfx') ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final color in kVfxPalette)
                GestureDetector(
                  onTap: () => onColor(_hex(color.hex)),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.hex,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: vfxHex == _hex(color.hex) ? kSignal : palette.line,
                        width: vfxHex == _hex(color.hex) ? 2 : 1,
                      ),
                    ),
                  ),
                ),
              DropdownButton<String>(
                value: vfxMark,
                dropdownColor: palette.surface,
                style: TextStyle(color: palette.ink, fontSize: 11),
                items: [
                  for (final style in kTrackingStyles)
                    DropdownMenuItem(value: style.id, child: Text(style.name)),
                ],
                onChanged: (value) {
                  if (value != null) onMark(value);
                },
              ),
            ],
          ),
        ],
        if (mode == 'video' || mode == 'photo') ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onUpload,
              icon: Icon(mode == 'video' ? Icons.movie_outlined : Icons.image_outlined, size: 14),
              label: Text(
                mode == 'video'
                    ? (hasVideo ? 'Replace video clip' : 'Upload video clip')
                    : (hasPhoto ? 'Replace photo' : 'Upload photo'),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: !enabled || live ? null : onStart,
                icon: const Icon(Icons.videocam),
                label: const Text('Start'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: live ? onEnd : null,
                icon: const Icon(Icons.call_end),
                label: const Text('End'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.palette,
    required this.messages,
    required this.contact,
    required this.text,
    required this.reply,
    required this.replies,
    required this.onSend,
    required this.onAddReply,
    required this.onSendReply,
    required this.onRemoveReply,
    required this.onReset,
  });

  final DeckPalette palette;
  final List<StageMessage> messages;
  final String contact;
  final TextEditingController text;
  final TextEditingController reply;
  final List<_Reply> replies;
  final VoidCallback onSend;
  final VoidCallback onAddReply;
  final VoidCallback onSendReply;
  final ValueChanged<int> onRemoveReply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final ordered = messages.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 120, maxHeight: 220),
          child: ordered.isEmpty
              ? Center(
                  child: Text(
                    'No messages. Push one to the prop phone.',
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                )
              : ListView(
                  children: [
                    for (final message in ordered)
                      Align(
                        alignment: message.sender == 'control'
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          constraints: const BoxConstraints(maxWidth: 320),
                          decoration: BoxDecoration(
                            color: message.sender == 'control'
                                ? kAccent.withValues(alpha: 0.15)
                                : kSignal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: message.sender == 'control'
                                  ? kAccent.withValues(alpha: 0.3)
                                  : kSignal.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(message.text, style: TextStyle(color: palette.ink, fontSize: 13)),
                        ),
                      ),
                  ],
                ),
        ),
        if (contact.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Sending as $contact',
              style: TextStyle(color: palette.muted, fontSize: 10),
            ),
          ),
        TextField(
          key: const Key('deck-message'),
          controller: text,
          minLines: 3,
          maxLines: 5,
          decoration: deckField(palette, 'Type message to push…'),
          onSubmitted: (_) => onSend(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ListenableBuilder(
            listenable: text,
            builder: (context, _) {
              return IconButton(
                key: const Key('deck-send'),
                tooltip: 'Send',
                onPressed: text.text.trim().isEmpty ? null : onSend,
                icon: const Icon(Icons.send, color: Colors.black),
                style: IconButton.styleFrom(backgroundColor: kSignal),
              );
            },
          ),
        ),
        const Divider(),
        Text(
          'Pre-loaded replies · ${replies.length}/20',
          style: TextStyle(color: palette.muted, fontSize: 10),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: reply,
                decoration: deckField(palette, 'Queue up a reply…'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: reply.text.trim().isEmpty || replies.length >= 20
                  ? null
                  : onAddReply,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              key: const Key('deck-message-reset'),
              onPressed: onReset,
              icon: const Icon(Icons.recycling, size: 14),
              label: const Text('Reset'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kSignal,
                foregroundColor: Colors.black,
              ),
              onPressed: replies.isEmpty ? null : onSendReply,
              icon: const Icon(Icons.send, size: 14),
              label: const Text('Send'),
            ),
          ],
        ),
        for (var i = 0; i < replies.length; i++)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Text('${i + 1}'),
            title: Text(replies[i].text),
            trailing: IconButton(
              onPressed: () => onRemoveReply(i),
              icon: const Icon(Icons.delete_outline, size: 16),
            ),
          ),
      ],
    );
  }
}

class _NotifBody extends StatelessWidget {
  const _NotifBody({
    required this.palette,
    required this.screen,
    required this.app,
    required this.text,
    required this.queue,
    required this.onScreen,
    required this.onApp,
    required this.onAdd,
    required this.onPush,
    required this.onReset,
    required this.onRemove,
  });

  final DeckPalette palette;
  final String screen;
  final String app;
  final TextEditingController text;
  final List<_QueuedNote> queue;
  final ValueChanged<String> onScreen;
  final ValueChanged<String> onApp;
  final VoidCallback onAdd;
  final VoidCallback onPush;
  final VoidCallback onReset;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Show on', style: TextStyle(color: palette.muted, fontSize: 10)),
            const Spacer(),
            ChoiceChip(
              label: const Text('Lock screen'),
              selected: screen == 'lock',
              onSelected: (_) => onScreen('lock'),
            ),
            const SizedBox(width: 4),
            ChoiceChip(
              label: const Text('Home screen'),
              selected: screen == 'home',
              onSelected: (_) => onScreen('home'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('App Library', style: TextStyle(color: palette.muted, fontSize: 10)),
        const SizedBox(height: 6),
        _LibraryPicker(palette: palette, selected: app, onSelect: onApp),
        const SizedBox(height: 8),
        TextField(
          controller: text,
          minLines: 3,
          maxLines: 4,
          decoration: deckField(palette, 'Banner text…'),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: text.text.trim().isEmpty || queue.length >= 20 ? null : onAdd,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add'),
          ),
        ),
        if (queue.isNotEmpty)
          Text(
            'Queue · ${queue.length}/20',
            style: TextStyle(color: palette.muted, fontSize: 10),
          ),
        for (var i = 0; i < queue.length; i++)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.drag_indicator, size: 16),
            title: Text(queue[i].text),
            trailing: IconButton(
              onPressed: () => onRemove(i),
              icon: const Icon(Icons.delete_outline, size: 16),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kSignal,
                  foregroundColor: Colors.black,
                ),
                onPressed: queue.isEmpty ? null : onPush,
                icon: const Icon(Icons.notifications),
                label: const Text('Push'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.recycling, size: 14),
              label: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Banners stack below each other on the phone until Reset clears them',
          style: TextStyle(color: palette.muted, fontSize: 10),
        ),
      ],
    );
  }
}

class _LibraryPicker extends StatefulWidget {
  const _LibraryPicker({
    required this.palette,
    required this.selected,
    required this.onSelect,
  });

  final DeckPalette palette;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  State<_LibraryPicker> createState() => _LibraryPickerState();
}

class _LibraryPickerState extends State<_LibraryPicker> {
  final _query = TextEditingController();
  final _name = TextEditingController();
  final List<({String id, String label, Color color, IconData icon})> _custom = [];

  @override
  void dispose() {
    _query.dispose();
    _name.dispose();
    super.dispose();
  }

  List<({String id, String label, Color color, IconData icon})> get _apps {
    final seen = <String>{};
    final apps = <({String id, String label, Color color, IconData icon})>[];
    void add(String id, String label, Color color, IconData icon) {
      if (!seen.add(id)) return;
      apps.add((id: id, label: label, color: color, icon: icon));
    }

    for (final item in _custom) {
      add(item.id, item.label, item.color, item.icon);
    }
    for (final item in kPropApps) {
      add(item.id, item.label, item.color, item.icon);
    }
    for (final section in mockCatalog) {
      for (final item in section.apps) {
        add(item.id, item.label, item.color, item.icon);
      }
    }
    final query = _query.text.trim().toLowerCase();
    if (query.isEmpty) return apps;
    return [
      for (final app in apps)
        if (app.label.toLowerCase().contains(query)) app,
    ];
  }

  String _label(String id) {
    if (id.startsWith('custom:')) return id.substring('custom:'.length);
    return propAppById(id)?.label ?? catalogAppById(id)?.label ?? id;
  }

  void _create() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final id = 'custom:$name';
    setState(() {
      _custom.add((
        id: id,
        label: name,
        color: const Color(0xFF3A3A3C),
        icon: Icons.apps,
      ));
      _name.clear();
    });
    widget.onSelect(id);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final apps = _apps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _label(widget.selected),
          style: TextStyle(color: palette.ink, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _query,
          onChanged: (_) => setState(() {}),
          decoration: deckField(palette, 'Search the library'),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('notif-custom-app'),
                controller: _name,
                onChanged: (_) => setState(() {}),
                decoration: deckField(palette, 'Create your own'),
                onSubmitted: (_) => _create(),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              key: const Key('notif-create-app'),
              onPressed: _name.text.trim().isEmpty ? null : _create,
              child: const Text('Create'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.line),
          ),
          child: SizedBox(
            height: 220,
            child: ListView(
              key: const Key('notif-app-library'),
              children: [
                for (final item in apps)
                  InkWell(
                    key: Key('notif-app-${item.id}'),
                    onTap: () => widget.onSelect(item.id),
                    child: ColoredBox(
                      color: item.id == widget.selected
                          ? kSignal.withValues(alpha: 0.16)
                          : Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: item.color,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Icon(item.icon, color: Colors.white, size: 15),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(color: palette.ink, fontSize: 13),
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
        ),
      ],
    );
  }
}

class _LockPad extends StatelessWidget {
  const _LockPad({
    required this.palette,
    required this.locked,
    required this.onToggle,
  });

  final DeckPalette palette;
  final bool locked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return DeckCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_open, size: 16, color: kAccent),
              const SizedBox(width: 8),
              Text(
                'Screen Lock Pad',
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onToggle,
            child: Container(
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    locked ? Icons.lock : Icons.lock_open,
                    color: locked ? kAccent : palette.muted,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locked ? 'Screen locked' : 'Screen unlocked',
                    style: TextStyle(color: palette.ink, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '3-finger tap to toggle',
                    style: TextStyle(color: palette.muted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: color, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _hex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

String _videoModeLabel(String mode) {
  switch (mode) {
    case 'vfx':
      return 'VFX';
    case 'video':
      return 'Video';
    case 'photo':
      return 'Photo';
    default:
      return 'Live cam';
  }
}

String voiceStatusLine(String status) {
  switch (status) {
    case 'mic-on':
      return "Voice live - you're speaking through the target device";
    case 'mic-denied':
      return 'Mic blocked - calls run without live voice';
    case 'error':
      return 'Voice link failed - calls run without live voice';
    default:
      return 'Allow mic access for live voice through the target device';
  }
}

String videoStatusLine(String status) {
  switch (status) {
    case 'cam-on':
      return 'Live camera streaming';
    case 'cam-denied':
      return 'Camera blocked - pick another mode';
    case 'error':
      return 'Live link failed';
    default:
      return 'Toggles control your live feed only';
  }
}
