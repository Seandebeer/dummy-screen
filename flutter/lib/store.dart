import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'os_catalog.dart';

enum LinkRole { solo, host, client }

String sandboxName(String kind) {
  switch (kind) {
    case 'tablet':
      return 'Tablet';
    case 'computer':
      return 'Computer';
    case 'tv':
      return 'Smart TV';
    case 'console':
      return 'Game console';
    case 'atm':
      return 'ATM';
    case 'cctv':
      return 'CCTV';
    case 'smarthome':
      return 'Smart home';
    case 'homephone':
      return 'Smart home phone';
    default:
      return 'Phone';
  }
}

/// Talks to other copies of the app. The store stays the source of truth
/// on the machine that is hosting; clients send patches and accept snapshots.
abstract class StageSync {
  LinkRole get role;
  String get status;
  String? get address;
  Future<String?> host({int? port});
  Future<void> join(String input);
  Future<void> disconnect();
  void broadcastState();
  void sendPatch(Map<String, dynamic> patch);
}

class StageStore extends ChangeNotifier {
  StageStore();

  static const _prefsKey = 'dummy-phone-stage';

  StageSync? sync;
  bool persist = true;
  bool ready = false;
  bool _importing = false;
  final Map<String, Timer> _ringTimers = {};

  List<Project> projects = [];
  List<PropDevice> devices = [];
  List<StageMessage> messages = [];
  List<LiveCall> calls = [];
  List<CallRecord> callHistory = [];
  Map<String, bool> alarms = {};
  List<BannerNote> banners = [];
  List<SavedLayout> saved = [];
  List<VideoClip> clips = [];
  Map<String, List<PropPhoto>> photos = {};
  String vfxColor = 'green';
  List<MarkPoint> vfxMarks = [];
  List<String> uiMarkers = [];
  Map<String, dynamic> screenConfig = {};
  Map<String, dynamic> markerConfig = {};
  Map<String, dynamic> pages = {};
  String? pendingApp;
  String appTheme = 'black';
  String appLanguage = 'en';
  String operatorName = 'Operator';
  String operatorTitle = '';
  String operatorPhoto = '';
  List<String> appFavorites = [];

  String? selectedProjectId;
  String? boundDeviceId;
  String? targetDeviceId;
  bool filming = false;
  int lastTab = 0;
  bool bypassLock = false;
  bool osSession = false;
  String? osFlash;
  final String sessionId = 'sess-${DateTime.now().microsecondsSinceEpoch}';
  String? activeTrigger;
  bool _replay = false;
  final List<_OsStep> _undo = [];
  final List<_OsStep> _redo = [];
  Timer? _flashTimer;

  bool get holdsTrigger => activeTrigger == null || activeTrigger == sessionId;

  /// A joined screen only accepts control from the device that connected.
  bool get canTrigger =>
      (sync?.role ?? LinkRole.solo) != LinkRole.client || holdsTrigger;

  factory StageStore.demo() {
    final store = StageStore()..persist = false;
    store._seed();
    store.ready = true;
    return store;
  }

  void attach(StageSync link) => sync = link;

  @override
  void dispose() {
    for (final timer in _ringTimers.values) {
      timer.cancel();
    }
    _ringTimers.clear();
    super.dispose();
  }

  void _cancelRing(String deviceId) {
    _ringTimers.remove(deviceId)?.cancel();
  }

  void _scheduleRing(LiveCall call) {
    _cancelRing(call.deviceId);
    if (call.direction != 'outgoing' || call.status != 'ringing') return;
    final seconds = deviceById(call.deviceId)?.os.ringDelaySeconds ?? 4;
    _ringTimers[call.deviceId] = Timer(Duration(seconds: seconds), () {
      _ringTimers.remove(call.deviceId);
      final current = callFor(call.deviceId);
      if (current == null ||
          current.id != call.id ||
          current.status != 'ringing') {
        return;
      }
      setCallStatus(call.deviceId, 'active');
    });
  }

  void refresh() => notifyListeners();

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) {
        _seed();
      } else {
        _readAll(jsonMap(jsonDecode(raw)));
        if (projects.isEmpty) _seed();
      }
    } catch (_) {
      _seed();
    }
    ready = true;
    notifyListeners();
  }

  void _seed() {
    const project = Project(
      id: 'p-hero',
      name: 'Production',
      description: 'Hero unit',
    );
    const device = PropDevice(
      id: 'd-hero',
      name: 'Hero phone',
      projectId: 'p-hero',
    );
    projects = [project];
    devices = [device];
    selectedProjectId = project.id;
    boundDeviceId = device.id;
    targetDeviceId = device.id;
    vfxColor = 'green';
    vfxMarks = const [
      MarkPoint(id: 'mk1', x: 0.2, y: 0.22),
      MarkPoint(id: 'mk2', x: 0.8, y: 0.22),
      MarkPoint(id: 'mk3', x: 0.5, y: 0.5),
      MarkPoint(id: 'mk4', x: 0.2, y: 0.78),
      MarkPoint(id: 'mk5', x: 0.8, y: 0.78),
    ];
    uiMarkers = [];
  }

  Project? get selectedProject {
    for (final project in projects) {
      if (project.id == selectedProjectId) return project;
    }
    return null;
  }

  PropDevice? deviceById(String? id) {
    if (id == null) return null;
    for (final device in devices) {
      if (device.id == id) return device;
    }
    return null;
  }

  List<PropDevice> devicesFor(String? projectId) =>
      devices.where((device) => device.projectId == projectId).toList();

  LiveCall? callFor(String? deviceId) {
    if (deviceId == null) return null;
    for (final call in calls) {
      if (call.deviceId == deviceId) return call;
    }
    return null;
  }

  List<StageMessage> messagesFor(String deviceId) =>
      messages.where((message) => message.deviceId == deviceId).toList();

  List<BannerNote> bannersFor(String deviceId) =>
      banners.where((banner) => banner.deviceId == deviceId).toList();

  void openTab(int index) {
    lastTab = index;
    if (index != 1) endOsSession();
    _touch(null, sync: false);
  }

  void beginOsSession() {
    osSession = true;
    _undo.clear();
    _redo.clear();
    osFlash = null;
  }

  void endOsSession() {
    if (!osSession && _undo.isEmpty && _redo.isEmpty) return;
    osSession = false;
    _undo.clear();
    _redo.clear();
    osFlash = null;
    notifyListeners();
  }

  String? undoOs() {
    if (_undo.isEmpty) return null;
    final step = _undo.removeLast();
    _redo.add(_OsStep('Redo ${step.label}', _editBlob()));
    _replay = true;
    _restoreEdit(step.blob);
    _replay = false;
    _flash('Undid ${step.label}');
    return osFlash;
  }

  String? redoOs() {
    if (_redo.isEmpty) return null;
    final step = _redo.removeLast();
    _undo.add(_OsStep(step.label.replaceFirst('Redo ', ''), _editBlob()));
    _replay = true;
    _restoreEdit(step.blob);
    _replay = false;
    _flash('Redid ${step.label.replaceFirst('Redo ', '')}');
    return osFlash;
  }

  void _flash(String message) {
    osFlash = message;
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 1400), () {
      osFlash = null;
      if (!_importing) notifyListeners();
    });
    notifyListeners();
  }

  Map<String, dynamic> _editBlob() => {
    'devices': devices.map((device) => device.toJson()).toList(),
    'messages': messages.map((message) => message.toJson()).toList(),
    'banners': banners.map((banner) => banner.toJson()).toList(),
    'pages': pages,
    'bound': boundDeviceId,
  };

  void _pushUndo(String label) {
    if (!osSession || _replay) return;
    _undo.add(_OsStep(label, _editBlob()));
    if (_undo.length > 40) _undo.removeAt(0);
    _redo.clear();
  }

  void _restoreEdit(Map<String, dynamic> blob) {
    devices = [
      for (final item in jsonList(blob['devices']))
        if (item is Map) PropDevice.fromJson(jsonMap(item)),
    ];
    messages = [
      for (final item in jsonList(blob['messages']))
        if (item is Map) StageMessage.fromJson(jsonMap(item)),
    ];
    banners = [
      for (final item in jsonList(blob['banners']))
        if (item is Map) BannerNote.fromJson(jsonMap(item)),
    ];
    pages = jsonMap(blob['pages']);
    boundDeviceId = blob['bound'] as String?;
    _normalize();
    _touch(null, sync: false);
  }

  String _changeLabel(PropDevice before, PropDevice next) {
    if (before.name != next.name) return 'Renamed ${next.name}';
    if (before.locked != next.locked) {
      return next.locked ? 'Locked ${next.name}' : 'Unlocked ${next.name}';
    }
    if (before.skin != next.skin) return 'Changed the interface';
    final os = before.os;
    final now = next.os;
    if (os.wifi != now.wifi) return now.wifi ? 'Turned Wi-Fi on' : 'Turned Wi-Fi off';
    if (os.cellular != now.cellular) return 'Set mobile network to ${now.cellular}';
    if (os.signal != now.signal) return 'Set mobile signal to ${now.signal}';
    if (os.battery != now.battery) return 'Set battery to ${now.battery}%';
    if (os.lockType != now.lockType) return 'Changed the lock screen';
    if (os.homeOrder.length != now.homeOrder.length) return 'Changed home screen apps';
    if (os.language != now.language) return 'Changed the language';
    if (os.theme != now.theme) return 'Changed the theme';
    if (os.ringtone != now.ringtone) return 'Changed the ringtone';
    if (os.soundsMuted != now.soundsMuted) return now.soundsMuted ? 'Muted sounds' : 'Unmuted sounds';
    return 'Changed ${next.name}';
  }

  /// Home opens with the Projects strip expanded.
  bool revealProjects = false;

  void openHomeProjects() {
    revealProjects = true;
    openTab(0);
  }

  void bindDevice(String id) {
    boundDeviceId = id;
    _touch(null, sync: false);
  }

  /// A local preview device used when no project is open.
  void openSandbox(String kind) {
    const id = 'sandbox-device';
    final current = deviceById(id);
    final next = PropDevice(
      id: id,
      name: sandboxName(kind),
      projectId: 'sandbox',
      kind: kind,
      skin: 'modern',
      locked: false,
      os: current?.os ?? const OsSettings(),
    );
    if (current == null) {
      devices = [...devices, next];
    } else {
      devices = [
        for (final device in devices)
          if (device.id == id) next else device,
      ];
    }
    boundDeviceId = id;
    _touch(null, sync: false);
  }

  /// Devices the operator can still assign work to: the open project,
  /// skipping the sandbox preview and anything already deleted.
  List<PropDevice> get activeDevices {
    final projectId = selectedProjectId;
    final source = projectId == null
        ? devices.where((device) => device.projectId != 'sandbox')
        : devicesFor(projectId);
    return source.toList();
  }

  bool deckBroadcast = false;
  String? drivenDeviceId;
  String? drivenApp;

  bool remoteDriving(String deviceId) =>
      !deckBroadcast && drivenDeviceId == deviceId;

  void setDeckBroadcast(bool value) {
    if (deckBroadcast == value) return;
    deckBroadcast = value;
    if (value) {
      drivenDeviceId = null;
      drivenApp = null;
    }
    notifyListeners();
  }

  /// Direct trigger-to-target control. Broadcast decks do not drive a screen.
  void driveOs(String deviceId, String? app) {
    if (deckBroadcast || deviceId.isEmpty) return;
    if (!canTrigger) return;
    if ((sync?.role ?? LinkRole.solo) != LinkRole.client) return;
    sync?.sendPatch({
      'kind': 'os_drive',
      'deviceId': deviceId,
      'app': app,
    });
  }

  void _applyDrive(String? deviceId, String? app) {
    if (deckBroadcast) return;
    if (app == null || deviceId == null || deviceId.isEmpty) {
      drivenDeviceId = null;
      drivenApp = null;
    } else {
      drivenDeviceId = deviceId;
      drivenApp = app.isEmpty ? null : app;
      boundDeviceId = deviceId;
      lastTab = 1;
    }
    if (!_importing) notifyListeners();
  }

  void setTarget(String? id) {
    targetDeviceId = id;
    if (id != null && id.isNotEmpty) {
      boundDeviceId = id;
      activeTrigger = sessionId;
      _touch({'kind': 'claim_trigger', 'session': sessionId});
      return;
    }
    _touch(null, sync: false);
  }

  void selectProject(String? id) {
    selectedProjectId = (id == null || id.isEmpty) ? null : id;
    _touch(null, sync: false);
  }

  void setFilming(bool value) {
    if (filming == value) return;
    filming = value;
    _touch(null, sync: false);
  }

  void addProject(String name) {
    final trimmed = name.trim();
    final project = Project(
      id: _nid('p'),
      name: trimmed.isEmpty ? 'Project' : trimmed,
    );
    projects = [...projects, project];
    selectedProjectId = project.id;
    _touch({'kind': 'project', 'project': project.toJson()});
  }

  void renameProject(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    projects = [
      for (final project in projects)
        if (project.id == id) project.copyWith(name: trimmed) else project,
    ];
    final project = projects.where((item) => item.id == id).firstOrNull;
    if (project == null) return;
    _touch({'kind': 'project', 'project': project.toJson()});
  }

  void upsertProject(Project project) {
    if (project.id.isEmpty) return;
    final index = projects.indexWhere((item) => item.id == project.id);
    if (index < 0) {
      projects = [...projects, project];
    } else if (projects[index].name == project.name &&
        projects[index].description == project.description &&
        projects[index].sortOrder == project.sortOrder) {
      return;
    } else {
      projects = [...projects]..[index] = project;
    }
    _normalize();
    _touch({'kind': 'project', 'project': project.toJson()});
  }

  void deleteProject(String id) {
    if (!projects.any((project) => project.id == id)) return;
    final deviceIds = devices
        .where((device) => device.projectId == id)
        .map((device) => device.id)
        .toSet();
    projects = projects.where((project) => project.id != id).toList();
    devices = devices.where((device) => device.projectId != id).toList();
    _dropDevices(deviceIds);
    _normalize();
    _touch({'kind': 'delete_project', 'id': id});
  }

  PropDevice addDevice({
    required String projectId,
    required String name,
    String kind = 'phone',
    String skin = 'modern',
    OsSettings os = const OsSettings(),
  }) {
    final trimmed = name.trim();
    final device = PropDevice(
      id: _nid('d'),
      name: trimmed.isEmpty ? 'Phone' : trimmed,
      projectId: projectId,
      kind: kind,
      skin: skin,
      os: os,
    );
    boundDeviceId ??= device.id;
    targetDeviceId ??= device.id;
    upsertDevice(device);
    return device;
  }

  void upsertDevice(PropDevice device) {
    if (device.id.isEmpty) return;
    final index = devices.indexWhere((item) => item.id == device.id);
    if (index < 0) {
      devices = [...devices, device];
      targetDeviceId ??= device.id;
    } else {
      final current = devices[index];
      if (_sameDevice(current, device)) return;
      devices = [...devices]..[index] = device;
    }
    _normalize();
    _touch({'kind': 'device', 'device': device.toJson()});
  }

  void updateDevice(String id, PropDevice Function(PropDevice device) change) {
    final current = deviceById(id);
    if (current == null) return;
    final next = change(current);
    if (identical(next, current) || _sameDevice(current, next)) return;
    _pushUndo(_changeLabel(current, next));
    upsertDevice(next);
  }

  void deleteDevice(String id) {
    if (!devices.any((device) => device.id == id)) return;
    devices = devices.where((device) => device.id != id).toList();
    _dropDevices({id});
    _normalize();
    _touch({'kind': 'delete_device', 'id': id});
  }

  void setLocked(String id, bool locked) => updateDevice(
    id,
    (device) =>
        device.locked == locked ? device : device.copyWith(locked: locked),
  );

  void setSkin(String id, String skin) => updateDevice(id, (device) {
    final preset = presetForSkin(skin);
    final nextOs = preset == null || device.os.backgroundType == 'image'
        ? device.os
        : device.os.copyWith(
            backgroundType: 'preset',
            backgroundPreset: preset,
            backgroundUrl: '',
          );
    if (device.skin == skin && device.os == nextOs) return device;
    return device.copyWith(skin: skin, os: nextOs);
  });

  void updateOs(String id, OsSettings Function(OsSettings os) change) =>
      updateDevice(id, (device) {
        final next = change(device.os);
        if (next == device.os) return device;
        return device.copyWith(os: next);
      });

  /// Wipe this device's pages and settings. General saved layouts stay.
  void factoryResetDevice(String id) {
    final current = deviceById(id);
    if (current == null) return;
    _cancelRing(id);
    final reset = PropDevice(
      id: current.id,
      name: current.name,
      projectId: current.projectId,
      kind: current.kind,
      locked: true,
      make: current.make,
      model: current.model,
      colour: current.colour,
      serial: current.serial,
      photo: current.photo,
      status: current.status,
      sortOrder: current.sortOrder,
    );
    final index = devices.indexWhere((device) => device.id == id);
    devices = [...devices]..[index] = reset;
    messages = messages.where((message) => message.deviceId != id).toList();
    calls = calls.where((call) => call.deviceId != id).toList();
    callHistory = callHistory
        .where((record) => record.deviceId != id)
        .toList();
    banners = banners.where((banner) => banner.deviceId != id).toList();
    if (alarms.containsKey(id)) {
      alarms = {...alarms}..remove(id);
    }
    if (photos.containsKey(id)) {
      photos = {...photos}..remove(id);
    }
    _touch({'kind': 'device_reset', 'device': reset.toJson()});
  }

  void setNotes(String id, String notes) => updateDevice(
    id,
    (device) => device.notes == notes ? device : device.copyWith(notes: notes),
  );

  void setClockOffset(String id, int minutes) => updateDevice(
    id,
    (device) => device.clockOffsetMinutes == minutes
        ? device
        : device.copyWith(clockOffsetMinutes: minutes),
  );

  void renameDevice(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    updateDevice(
      id,
      (device) =>
          device.name == trimmed ? device : device.copyWith(name: trimmed),
    );
  }

  void sendMessage({
    String? id,
    required String deviceId,
    required String sender,
    required String text,
    required String senderName,
    required String thread,
    int? sentAt,
    String media = '',
    String mediaType = '',
    BannerNote? banner,
  }) {
    if (!canTrigger) return;
    final trimmed = text.trim();
    if ((trimmed.isEmpty && media.isEmpty) || deviceId.isEmpty) return;
    final message = StageMessage(
      id: id ?? _nid('m'),
      deviceId: deviceId,
      sender: sender,
      text: trimmed,
      senderName: senderName,
      thread: thread.trim().isEmpty ? senderName : thread.trim(),
      sentAt: sentAt ?? DateTime.now().millisecondsSinceEpoch,
      media: media,
      mediaType: mediaType,
    );
    if (message.id.isEmpty || messages.any((item) => item.id == message.id)) {
      return;
    }
    messages = [message, ...messages].take(200).toList();
    BannerNote? note = banner;
    if (note == null && sender == 'control') {
      note = BannerNote(
        id: _nid('b'),
        deviceId: deviceId,
        appLabel: 'Messages',
        appId: 'messages',
        text: trimmed,
      );
    }
    if (note != null &&
        note.id.isNotEmpty &&
        !banners.any((item) => item.id == note!.id)) {
      banners = [note, ...banners].take(20).toList();
    }
    _touch({
      'kind': 'message',
      'message': message.toJson(),
      if (note != null) 'banner': note.toJson(),
    });
  }

  void pushMail({
    required String deviceId,
    required String from,
    required String subject,
    required String body,
  }) {
    if (deviceId.isEmpty) return;
    final key = 'mail-$deviceId';
    final current = pages[key];
    final items = current is Map ? jsonList(current['items']) : const <dynamic>[];
    final mail = {
      'id': DateTime.now().microsecondsSinceEpoch,
      'from': from,
      'subject': subject,
      'time': 'Now',
      'unread': true,
      'thread': [
        {'who': 'them', 'body': body, 'time': 'Now'},
      ],
    };
    pages = {
      ...pages,
      key: {'items': [mail, ...items]},
    };
    _touch({'kind': 'page', 'app': key, 'data': pages[key]});
    pushBanner(
      deviceId: deviceId,
      appLabel: 'Mail',
      appId: 'email',
      text: subject,
    );
  }

  void clearMail(String deviceId) {
    if (deviceId.isEmpty) return;
    final key = 'mail-$deviceId';
    final hadMail = pages.containsKey(key);
    final hadBanner = banners.any(
      (banner) =>
          banner.deviceId == deviceId &&
          (banner.appId == 'email' ||
              banner.appId == 'mail' ||
              banner.appLabel == 'Mail'),
    );
    if (!hadMail && !hadBanner) return;
    if (hadMail) {
      pages = {...pages}..remove(key);
    }
    if (hadBanner) {
      banners = banners
          .where(
            (banner) =>
                banner.deviceId != deviceId ||
                (banner.appId != 'email' &&
                    banner.appId != 'mail' &&
                    banner.appLabel != 'Mail'),
          )
          .toList();
    }
    _touch({'kind': 'clear_mail', 'deviceId': deviceId});
  }

  void clearMessages(String deviceId) {
    if (!messages.any((message) => message.deviceId == deviceId)) return;
    messages = messages
        .where((message) => message.deviceId != deviceId)
        .toList();
    banners = banners
        .where(
          (banner) =>
              banner.deviceId != deviceId ||
              (banner.appId != 'messages' && banner.appLabel != 'Messages'),
        )
        .toList();
    _touch({'kind': 'clear_messages', 'deviceId': deviceId});
  }

  void deleteMessage(String id) {
    if (id.isEmpty || !messages.any((message) => message.id == id)) return;
    messages = messages.where((message) => message.id != id).toList();
    _touch({'kind': 'delete_message', 'id': id});
  }

  void startCall({
    String? id,
    required String deviceId,
    required String contactName,
    required String contactNumber,
    required String direction,
    String kind = 'voice',
    Map<String, dynamic> scene = const {},
  }) {
    if (deviceId.isEmpty) return;
    final call = LiveCall(
      id: id ?? _nid('c'),
      deviceId: deviceId,
      contactName: contactName.trim().isEmpty ? 'Unknown' : contactName.trim(),
      contactNumber: contactNumber.trim(),
      direction: direction,
      status: 'ringing',
      kind: kind == 'video' ? 'video' : 'voice',
      scene: Map<String, dynamic>.from(scene),
    );
    if (call.id.isEmpty || calls.any((item) => item.id == call.id)) return;
    calls = [call, ...calls.where((item) => item.deviceId != deviceId)];
    _scheduleRing(call);
    _touch({'kind': 'call_start', 'call': call.toJson()});
  }

  void setCallStatus(String deviceId, String status) {
    var changed = false;
    calls = [
      for (final call in calls)
        if (call.deviceId == deviceId && call.status != status)
          _markChanged(call.copyWith(status: status), () => changed = true)
        else
          call,
    ];
    if (!changed) return;
    if (status != 'ringing') _cancelRing(deviceId);
    _touch({'kind': 'call_status', 'deviceId': deviceId, 'status': status});
  }

  void updateCallScene(String deviceId, Map<String, dynamic> patch) {
    if (deviceId.isEmpty || patch.isEmpty) return;
    var changed = false;
    calls = [
      for (final call in calls)
        if (call.deviceId == deviceId)
          _markChanged(
            call.copyWith(scene: {...call.scene, ...patch}),
            () => changed = true,
          )
        else
          call,
    ];
    if (!changed) return;
    final scene = callFor(deviceId)?.scene;
    if (scene == null) return;
    _touch({'kind': 'call_scene', 'deviceId': deviceId, 'scene': scene});
  }

  void endCall(String deviceId) {
    LiveCall? live;
    for (final call in calls) {
      if (call.deviceId == deviceId) live = call;
    }
    if (live == null) return;
    _cancelRing(deviceId);
    calls = calls.where((call) => call.deviceId != deviceId).toList();
    final record = CallRecord(
      id: _nid('ch'),
      deviceId: live.deviceId,
      deviceName: deviceById(live.deviceId)?.name ?? '',
      name: live.contactName,
      number: live.contactNumber,
      type: live.direction == 'outgoing'
          ? 'outgoing'
          : (live.status == 'active' ? 'incoming' : 'missed'),
      at: DateTime.now().millisecondsSinceEpoch,
    );
    callHistory = [record, ...callHistory].take(200).toList();
    _touch({'kind': 'call_end', 'deviceId': deviceId});
  }

  void setAlarm(String deviceId, bool ringing) {
    if ((alarms[deviceId] ?? false) == ringing) return;
    alarms = {...alarms, deviceId: ringing};
    _touch({'kind': 'alarm', 'deviceId': deviceId, 'ringing': ringing});
  }

  void pushBanner({
    String? id,
    required String deviceId,
    required String appLabel,
    required String text,
    String appId = '',
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || deviceId.isEmpty) return;
    final note = BannerNote(
      id: id ?? _nid('b'),
      deviceId: deviceId,
      appLabel: appLabel.trim().isEmpty ? 'Messages' : appLabel.trim(),
      text: trimmed,
      appId: appId,
    );
    if (note.id.isEmpty || banners.any((item) => item.id == note.id)) return;
    banners = [note, ...banners].take(20).toList();
    _touch({'kind': 'banner', 'banner': note.toJson()});
  }

  void clearBanners(String deviceId) {
    if (!banners.any((banner) => banner.deviceId == deviceId)) return;
    banners = banners.where((banner) => banner.deviceId != deviceId).toList();
    _touch({'kind': 'clear_banners', 'deviceId': deviceId});
  }

  void dismissBanner(String id) {
    if (!banners.any((banner) => banner.id == id)) return;
    banners = banners.where((banner) => banner.id != id).toList();
    _touch({'kind': 'banner_dismiss', 'id': id});
  }

  void saveLayout(String name) {
    final trimmed = name.trim();
    final device = deviceById(boundDeviceId) ?? devices.firstOrNull;
    final layout = SavedLayout(
      id: _nid('s'),
      name: trimmed.isEmpty ? 'Layout' : trimmed,
      skin: device?.skin ?? 'modern',
      clockOffsetMinutes: device?.clockOffsetMinutes ?? 0,
      notes: device?.notes ?? '',
      vfxColor: vfxColor,
      vfxMarks: vfxMarks,
      uiMarkers: uiMarkers,
    );
    saved = [layout, ...saved];
    _touch({'kind': 'saved', 'layout': layout.toJson()});
  }

  void upsertSaved(SavedLayout layout) {
    if (layout.id.isEmpty) return;
    final index = saved.indexWhere((item) => item.id == layout.id);
    if (index < 0) {
      saved = [layout, ...saved];
    } else {
      return;
    }
    _touch({'kind': 'saved', 'layout': layout.toJson()});
  }

  void deleteSaved(String id) {
    if (!saved.any((layout) => layout.id == id)) return;
    saved = saved.where((layout) => layout.id != id).toList();
    _touch({'kind': 'delete_saved', 'id': id});
  }

  void applyLayout(SavedLayout layout, String deviceId) {
    if (layout.kind == 'screen') {
      if (layout.payload.isNotEmpty) {
        screenConfig = Map<String, dynamic>.from(layout.payload);
        final color = screenConfig['colorId'];
        if (color is String && kKnownVfx.contains(color)) vfxColor = color;
      }
      lastTab = 2;
      _touch({
        'kind': 'apply_layout',
        'deviceId': deviceId,
        'layout': layout.toJson(),
      });
      return;
    }
    if (layout.kind == 'page') {
      final app = layout.payload['app'] as String? ?? '';
      final data = layout.payload['data'];
      if (app.isNotEmpty && data is Map) {
        pages = {...pages, app: jsonMap(data)};
        pendingApp = app;
      }
      lastTab = 1;
      _touch({
        'kind': 'apply_layout',
        'deviceId': deviceId,
        'layout': layout.toJson(),
      });
      return;
    }
    if (layout.kind == 'markers') {
      if (layout.payload.isNotEmpty) {
        markerConfig = Map<String, dynamic>.from(layout.payload);
      }
      lastTab = 3;
      _touch({
        'kind': 'apply_layout',
        'deviceId': deviceId,
        'layout': layout.toJson(),
      });
      return;
    }
    final current = deviceById(deviceId);
    if (current != null) {
      final index = devices.indexWhere((device) => device.id == deviceId);
      devices = [...devices]
        ..[index] = current.copyWith(
          skin: layout.skin,
          clockOffsetMinutes: layout.clockOffsetMinutes,
          notes: layout.notes,
          os: _skinWallpaper(current.os, layout.skin),
        );
    }
    vfxColor = layout.vfxColor;
    vfxMarks = layout.vfxMarks;
    uiMarkers = [...layout.uiMarkers];
    _touch({
      'kind': 'apply_layout',
      'deviceId': deviceId,
      'layout': layout.toJson(),
    });
  }

  void reorderProjects(int from, int to) {
    if (from == to || from < 0 || to < 0) return;
    final next = [...projects]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (from >= next.length || to >= next.length) return;
    final item = next.removeAt(from);
    next.insert(to, item);
    projects = [
      for (var i = 0; i < next.length; i++) next[i].copyWith(sortOrder: i),
    ];
    _touch({'kind': 'projects', 'projects': projects.map((p) => p.toJson()).toList()});
  }

  void reorderDevices(String projectId, int from, int to) {
    if (from == to || from < 0 || to < 0) return;
    final group = devicesFor(projectId)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (from >= group.length || to >= group.length) return;
    final item = group.removeAt(from);
    group.insert(to, item);
    final ordered = {
      for (var i = 0; i < group.length; i++) group[i].id: i,
    };
    devices = [
      for (final device in devices)
        if (ordered.containsKey(device.id))
          device.copyWith(sortOrder: ordered[device.id])
        else
          device,
    ];
    _touch({'kind': 'devices', 'devices': devices.map((d) => d.toJson()).toList()});
  }

  void setScreenConfig(Map<String, dynamic> config) {
    screenConfig = Map<String, dynamic>.from(config);
    final color = config['colorId'];
    if (color is String && kKnownVfx.contains(color) && color != vfxColor) {
      vfxColor = color;
    }
    _touch({'kind': 'screen', 'screen': screenConfig, 'color': vfxColor});
  }

  void setPage(String app, Map<String, dynamic> data) {
    if (app.isEmpty) return;
    pages = {...pages, app: data};
    _touch({'kind': 'page', 'app': app, 'data': data});
  }

  void setMarkerConfig(Map<String, dynamic> config) {
    markerConfig = Map<String, dynamic>.from(config);
    _touch({'kind': 'marker_stage', 'markers': markerConfig});
  }

  void setAppTheme(String id) {
    if (id != 'black' && id != 'grey' && id != 'white') return;
    if (appTheme == id) return;
    appTheme = id;
    _touch(null, sync: false);
  }

  void setAppLanguage(String code) {
    if (appLanguage == code) return;
    appLanguage = code;
    _touch(null, sync: false);
  }

  void toggleAppFavorite(String id) {
    if (id.isEmpty) return;
    appFavorites = appFavorites.contains(id)
        ? appFavorites.where((item) => item != id).toList()
        : [...appFavorites, id];
    _touch(null, sync: false);
  }

  void setOperator({String? name, String? title, String? photo}) {
    if (name != null) operatorName = name.trim().isEmpty ? 'Operator' : name.trim();
    if (title != null) operatorTitle = title.trim();
    if (photo != null) operatorPhoto = photo;
    _touch(null, sync: false);
  }

  void updateClip(VideoClip clip) {
    final index = clips.indexWhere((item) => item.id == clip.id);
    if (index < 0) return;
    clips = [...clips]..[index] = clip;
    _touch(null, sync: false);
  }

  void moveClip(int from, int to) {
    if (from == to || from < 0 || to < 0 || from >= clips.length || to >= clips.length) {
      return;
    }
    final next = [...clips];
    final item = next.removeAt(from);
    next.insert(to, item);
    clips = [
      for (var i = 0; i < next.length; i++) next[i].copyWith(order: i),
    ];
    _touch(null, sync: false);
  }

  void setVfxColor(String color) {
    if (vfxColor == color || !kKnownVfx.contains(color)) return;
    vfxColor = color;
    _touch({'kind': 'vfx_color', 'color': color});
  }

  void setVfxMarks(List<MarkPoint> marks) {
    vfxMarks = marks;
    _touch({
      'kind': 'vfx_marks',
      'marks': marks.map((mark) => mark.toJson()).toList(),
    });
  }

  void toggleMarker(int col, int row) {
    final key = '$col:$row';
    uiMarkers = uiMarkers.contains(key)
        ? uiMarkers.where((item) => item != key).toList()
        : [...uiMarkers, key];
    _touch({'kind': 'markers', 'markers': uiMarkers});
  }

  void clearMarkers() {
    if (uiMarkers.isEmpty) return;
    uiMarkers = [];
    _touch({'kind': 'markers', 'markers': uiMarkers});
  }

  void addClip(VideoClip clip) {
    clips = [...clips, clip];
    if (clips.length > 5) clips = clips.sublist(clips.length - 5);
    _touch(null, sync: false);
  }

  void removeClip(String id) {
    clips = clips.where((clip) => clip.id != id).toList();
    _touch(null, sync: false);
  }

  void addPhoto(String deviceId, int color, {String image = ''}) {
    final photo = PropPhoto(
      id: _nid('ph'),
      color: color,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      image: image,
    );
    photos = {
      ...photos,
      deviceId: [...(photos[deviceId] ?? const []), photo],
    };
    _touch(null, sync: false);
  }

  void applyPatch(Map<String, dynamic> patch) {
    if ((sync?.role ?? LinkRole.solo) != LinkRole.host) return;
    final session = patch['session'] as String?;
    if (patch['kind'] == 'claim_trigger') {
      activeTrigger = session;
      _touch(null);
      return;
    }
    const steered = {
      'message',
      'call_start',
      'call_scene',
      'call_status',
      'call_end',
      'alarm',
      'banner',
      'banner_dismiss',
      'clear_messages',
      'delete_message',
      'clear_mail',
      'clear_banners',
      'os_drive',
      'device',
      'page',
      'screen',
      'marker_stage',
    };
    if (activeTrigger != null &&
        session != null &&
        session != activeTrigger &&
        steered.contains(patch['kind'])) {
      return;
    }
    switch (patch['kind']) {
      case 'project':
        upsertProject(Project.fromJson(jsonMap(patch['project'])));
      case 'delete_project':
        deleteProject(patch['id'] as String? ?? '');
      case 'device':
        upsertDevice(PropDevice.fromJson(jsonMap(patch['device'])));
      case 'delete_device':
        deleteDevice(patch['id'] as String? ?? '');
      case 'device_reset':
        factoryResetDevice(
          PropDevice.fromJson(jsonMap(patch['device'])).id,
        );
      case 'message':
        final message = StageMessage.fromJson(jsonMap(patch['message']));
        final banner = patch['banner'] == null
            ? null
            : BannerNote.fromJson(jsonMap(patch['banner']));
        sendMessage(
          id: message.id,
          deviceId: message.deviceId,
          sender: message.sender,
          text: message.text,
          senderName: message.senderName,
          thread: message.thread,
          sentAt: message.sentAt,
          banner: banner,
        );
      case 'call_start':
        final call = LiveCall.fromJson(jsonMap(patch['call']));
        startCall(
          id: call.id,
          deviceId: call.deviceId,
          contactName: call.contactName,
          contactNumber: call.contactNumber,
          direction: call.direction,
          kind: call.kind,
          scene: call.scene,
        );
      case 'call_scene':
        updateCallScene(
          patch['deviceId'] as String? ?? '',
          jsonMap(patch['scene']),
        );
      case 'call_status':
        setCallStatus(
          patch['deviceId'] as String? ?? '',
          patch['status'] as String? ?? 'active',
        );
      case 'call_end':
        endCall(patch['deviceId'] as String? ?? '');
      case 'alarm':
        setAlarm(
          patch['deviceId'] as String? ?? '',
          patch['ringing'] as bool? ?? false,
        );
      case 'banner':
        final banner = BannerNote.fromJson(jsonMap(patch['banner']));
        pushBanner(
          id: banner.id,
          deviceId: banner.deviceId,
          appLabel: banner.appLabel,
          text: banner.text,
          appId: banner.appId,
        );
      case 'banner_dismiss':
        dismissBanner(patch['id'] as String? ?? '');
      case 'clear_messages':
        clearMessages(patch['deviceId'] as String? ?? '');
      case 'delete_message':
        deleteMessage(patch['id'] as String? ?? '');
      case 'clear_mail':
        clearMail(patch['deviceId'] as String? ?? '');
      case 'clear_banners':
        clearBanners(patch['deviceId'] as String? ?? '');
      case 'screen':
        final next = jsonMap(patch['screen']);
        screenConfig = next;
        final color = patch['color'] as String? ?? vfxColor;
        if (kKnownVfx.contains(color)) vfxColor = color;
        _touch({'kind': 'screen', 'screen': screenConfig, 'color': vfxColor});
      case 'marker_stage':
        markerConfig = jsonMap(patch['markers']);
        _touch({'kind': 'marker_stage', 'markers': markerConfig});
      case 'page':
        final app = patch['app'] as String? ?? '';
        if (app.isEmpty) return;
        pages = {...pages, app: jsonMap(patch['data'])};
        _touch({'kind': 'page', 'app': app, 'data': pages[app]});
      case 'saved':
        upsertSaved(SavedLayout.fromJson(jsonMap(patch['layout'])));
      case 'delete_saved':
        deleteSaved(patch['id'] as String? ?? '');
      case 'apply_layout':
        applyLayout(
          SavedLayout.fromJson(jsonMap(patch['layout'])),
          patch['deviceId'] as String? ?? '',
        );
      case 'os_drive':
        _applyDrive(
          patch['deviceId'] as String?,
          patch.containsKey('app') ? patch['app'] as String? : null,
        );
      case 'vfx_color':
        setVfxColor(patch['color'] as String? ?? 'green');
      case 'vfx_marks':
        setVfxMarks(marksFrom(patch['marks']));
      case 'markers':
        final next = [
          for (final item in jsonList(patch['markers'])) item.toString(),
        ];
        if (_sameStrings(uiMarkers, next)) return;
        uiMarkers = next;
        _touch({'kind': 'markers', 'markers': uiMarkers});
    }
  }

  Map<String, dynamic> exportState() => {
    'projects': projects.map((project) => project.toJson()).toList(),
    'devices': devices.map((device) => device.toJson()).toList(),
    'messages': messages.map((message) => message.toJson()).toList(),
    'calls': calls.map((call) => call.toJson()).toList(),
    'callHistory': callHistory.map((record) => record.toJson()).toList(),
    'alarms': alarms,
    'banners': banners.map((banner) => banner.toJson()).toList(),
    'saved': saved.map((layout) => layout.toJson()).toList(),
    'vfxColor': vfxColor,
    'vfxMarks': vfxMarks.map((mark) => mark.toJson()).toList(),
    'uiMarkers': uiMarkers,
    'screenConfig': screenConfig,
    'markerConfig': markerConfig,
    'pages': pages,
    'activeTrigger': activeTrigger,
  };

  void importState(Map<String, dynamic> json) {
    _importing = true;
    _readShared(json);
    _normalize();
    _importing = false;
    if (persist) unawaited(_writePrefs());
    notifyListeners();
  }

  void _readAll(Map<String, dynamic> json) {
    _readShared(json);
    selectedProjectId = json['selectedProjectId'] as String?;
    boundDeviceId = json['boundDeviceId'] as String?;
    targetDeviceId = json['targetDeviceId'] as String?;
    filming = json['filming'] as bool? ?? false;
    lastTab = (json['lastTab'] as num?)?.toInt() ?? 0;
    appTheme = json['appTheme'] as String? ?? 'black';
    appLanguage = json['appLanguage'] as String? ?? 'en';
    operatorName = json['operatorName'] as String? ?? 'Operator';
    operatorTitle = json['operatorTitle'] as String? ?? '';
    operatorPhoto = json['operatorPhoto'] as String? ?? '';
    appFavorites = [
      for (final item in jsonList(json['appFavorites'])) item.toString(),
    ].where((id) => id.isNotEmpty).toList();
    clips = [
      for (final item in jsonList(json['clips']))
        if (item is Map) VideoClip.fromJson(jsonMap(item)),
    ].where((clip) => clip.id.isNotEmpty).toList();
    photos = {};
    final rawPhotos = json['photos'];
    if (rawPhotos is Map) {
      rawPhotos.forEach((key, value) {
        photos[key.toString()] = [
          for (final item in jsonList(value))
            if (item is Map) PropPhoto.fromJson(jsonMap(item)),
        ].where((photo) => photo.id.isNotEmpty).toList();
      });
    }
    _normalize();
  }

  void _readShared(Map<String, dynamic> json) {
    projects = [
      for (final item in jsonList(json['projects']))
        if (item is Map) Project.fromJson(jsonMap(item)),
    ].where((project) => project.id.isNotEmpty).toList();
    devices = [
      for (final item in jsonList(json['devices']))
        if (item is Map) PropDevice.fromJson(jsonMap(item)),
    ].where((device) => device.id.isNotEmpty).toList();
    messages = [
      for (final item in jsonList(json['messages']))
        if (item is Map) StageMessage.fromJson(jsonMap(item)),
    ].where((message) => message.id.isNotEmpty).toList();
    calls = [
      for (final item in jsonList(json['calls']))
        if (item is Map) LiveCall.fromJson(jsonMap(item)),
    ].where((call) => call.id.isNotEmpty).toList();
    callHistory = [
      for (final item in jsonList(json['callHistory']))
        if (item is Map) CallRecord.fromJson(jsonMap(item)),
    ].where((record) => record.id.isNotEmpty).take(200).toList();
    alarms = {};
    final rawAlarms = json['alarms'];
    if (rawAlarms is Map) {
      rawAlarms.forEach((key, value) {
        if (value is bool) alarms[key.toString()] = value;
      });
    }
    banners = [
      for (final item in jsonList(json['banners']))
        if (item is Map) BannerNote.fromJson(jsonMap(item)),
    ].where((banner) => banner.id.isNotEmpty).toList();
    saved = [
      for (final item in jsonList(json['saved']))
        if (item is Map) SavedLayout.fromJson(jsonMap(item)),
    ].where((layout) => layout.id.isNotEmpty).toList();
    vfxColor = json['vfxColor'] as String? ?? 'green';
    vfxMarks = marksFrom(json['vfxMarks']);
    uiMarkers = [
      for (final item in jsonList(json['uiMarkers'])) item.toString(),
    ];
    screenConfig = jsonMap(json['screenConfig']);
    markerConfig = jsonMap(json['markerConfig']);
    pages = jsonMap(json['pages']);
    activeTrigger = json['activeTrigger'] as String?;
  }

  void _dropDevices(Set<String> ids) {
    messages = messages
        .where((message) => !ids.contains(message.deviceId))
        .toList();
    calls = calls.where((call) => !ids.contains(call.deviceId)).toList();
    callHistory = callHistory
        .where((record) => !ids.contains(record.deviceId))
        .toList();
    banners = banners
        .where((banner) => !ids.contains(banner.deviceId))
        .toList();
    alarms.removeWhere((key, _) => ids.contains(key));
    photos.removeWhere((key, _) => ids.contains(key));
  }

  void _normalize() {
    if (selectedProjectId != null &&
        !projects.any((project) => project.id == selectedProjectId)) {
      selectedProjectId = projects.isEmpty ? null : projects.first.id;
    }
    if (!devices.any((device) => device.id == boundDeviceId)) {
      boundDeviceId = null;
    }
    if (!devices.any((device) => device.id == targetDeviceId)) {
      targetDeviceId = devices.isEmpty ? null : devices.first.id;
    }
    if (lastTab < 0 || lastTab > 5) lastTab = 0;
  }

  void _touch(Map<String, dynamic>? patch, {bool sync = true}) {
    if (persist) unawaited(_writePrefs());
    if (!_importing) notifyListeners();
    if (_importing || !sync) return;
    final link = this.sync;
    if (link == null) return;
    if (link.role == LinkRole.host) {
      link.broadcastState();
    } else if (link.role == LinkRole.client && patch != null) {
      link.sendPatch({...patch, 'session': sessionId});
    }
  }

  Future<void> _writePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_localBlob()));
    } catch (_) {}
  }

  Map<String, dynamic> _localBlob() => {
    ...exportState(),
    'selectedProjectId': selectedProjectId,
    'boundDeviceId': boundDeviceId,
    'targetDeviceId': targetDeviceId,
    'filming': filming,
    'lastTab': lastTab,
    'appTheme': appTheme,
    'appLanguage': appLanguage,
    'operatorName': operatorName,
    'operatorTitle': operatorTitle,
    'operatorPhoto': operatorPhoto,
    'appFavorites': appFavorites,
    'clips': clips.map((clip) => clip.toJson()).toList(),
    'photos': {
      for (final entry in photos.entries)
        entry.key: entry.value.map((photo) => photo.toJson()).toList(),
    },
  };
}

const kKnownVfx = {'green', 'blue', 'white', 'grey', 'red'};

String _nid(String prefix) =>
    '$prefix-${DateTime.now().microsecondsSinceEpoch}';

bool _sameDevice(PropDevice a, PropDevice b) =>
    a.name == b.name &&
    a.projectId == b.projectId &&
    a.kind == b.kind &&
    a.skin == b.skin &&
    a.locked == b.locked &&
    a.clockOffsetMinutes == b.clockOffsetMinutes &&
    a.notes == b.notes &&
    a.os == b.os &&
    a.make == b.make &&
    a.model == b.model &&
    a.colour == b.colour &&
    a.serial == b.serial &&
    a.photo == b.photo &&
    a.status == b.status &&
    a.sortOrder == b.sortOrder;

OsSettings _skinWallpaper(OsSettings os, String skin) {
  final preset = presetForSkin(skin);
  if (preset == null || os.backgroundType == 'image') return os;
  return os.copyWith(
    backgroundType: 'preset',
    backgroundPreset: preset,
    backgroundUrl: '',
  );
}

class _OsStep {
  _OsStep(this.label, this.blob);

  final String label;
  final Map<String, dynamic> blob;
}

bool _sameStrings(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

T _markChanged<T>(T value, VoidCallback mark) {
  mark();
  return value;
}
