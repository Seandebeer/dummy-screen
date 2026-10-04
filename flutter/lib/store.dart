import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'os_catalog.dart';

enum LinkRole { solo, host, client }

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
  Map<String, bool> alarms = {};
  List<BannerNote> banners = [];
  List<SavedLayout> saved = [];
  List<VideoClip> clips = [];
  Map<String, List<PropPhoto>> photos = {};
  String vfxColor = 'green';
  List<MarkPoint> vfxMarks = [];
  List<String> uiMarkers = [];

  String? selectedProjectId;
  String? boundDeviceId;
  String? targetDeviceId;
  bool filming = false;
  int lastTab = 0;

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
    _touch(null, sync: false);
  }

  void bindDevice(String id) {
    boundDeviceId = id;
    _touch(null, sync: false);
  }

  void setTarget(String? id) {
    targetDeviceId = id;
    _touch(null, sync: false);
  }

  void selectProject(String id) {
    selectedProjectId = id;
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
        projects[index].description == project.description) {
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

  void addDevice({
    required String projectId,
    required String name,
    String kind = 'phone',
  }) {
    final trimmed = name.trim();
    final device = PropDevice(
      id: _nid('d'),
      name: trimmed.isEmpty ? 'Phone' : trimmed,
      projectId: projectId,
      kind: kind,
    );
    boundDeviceId ??= device.id;
    targetDeviceId ??= device.id;
    upsertDevice(device);
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
    if (identical(next, current)) return;
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
    );
    final index = devices.indexWhere((device) => device.id == id);
    devices = [...devices]..[index] = reset;
    messages = messages.where((message) => message.deviceId != id).toList();
    calls = calls.where((call) => call.deviceId != id).toList();
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
    BannerNote? banner,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || deviceId.isEmpty) return;
    final message = StageMessage(
      id: id ?? _nid('m'),
      deviceId: deviceId,
      sender: sender,
      text: trimmed,
      senderName: senderName,
      thread: thread.trim().isEmpty ? senderName : thread.trim(),
      sentAt: sentAt ?? DateTime.now().millisecondsSinceEpoch,
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
        text: trimmed,
      );
    }
    if (note != null &&
        note.id.isNotEmpty &&
        !banners.any((item) => item.id == note!.id)) {
      banners = [note, ...banners].take(6).toList();
    }
    _touch({
      'kind': 'message',
      'message': message.toJson(),
      if (note != null) 'banner': note.toJson(),
    });
  }

  void startCall({
    String? id,
    required String deviceId,
    required String contactName,
    required String contactNumber,
    required String direction,
  }) {
    if (deviceId.isEmpty) return;
    final call = LiveCall(
      id: id ?? _nid('c'),
      deviceId: deviceId,
      contactName: contactName.trim().isEmpty ? 'Unknown' : contactName.trim(),
      contactNumber: contactNumber.trim(),
      direction: direction,
      status: 'ringing',
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

  void endCall(String deviceId) {
    if (!calls.any((call) => call.deviceId == deviceId)) return;
    _cancelRing(deviceId);
    calls = calls.where((call) => call.deviceId != deviceId).toList();
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
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || deviceId.isEmpty) return;
    final note = BannerNote(
      id: id ?? _nid('b'),
      deviceId: deviceId,
      appLabel: appLabel.trim().isEmpty ? 'Messages' : appLabel.trim(),
      text: trimmed,
    );
    if (note.id.isEmpty || banners.any((item) => item.id == note.id)) return;
    banners = [note, ...banners].take(6).toList();
    _touch({'kind': 'banner', 'banner': note.toJson()});
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

  void addPhoto(String deviceId, int color) {
    final photo = PropPhoto(
      id: _nid('ph'),
      color: color,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    photos = {
      ...photos,
      deviceId: [...(photos[deviceId] ?? const []), photo],
    };
    _touch(null, sync: false);
  }

  void applyPatch(Map<String, dynamic> patch) {
    if ((sync?.role ?? LinkRole.solo) != LinkRole.host) return;
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
        );
      case 'banner_dismiss':
        dismissBanner(patch['id'] as String? ?? '');
      case 'saved':
        upsertSaved(SavedLayout.fromJson(jsonMap(patch['layout'])));
      case 'delete_saved':
        deleteSaved(patch['id'] as String? ?? '');
      case 'apply_layout':
        applyLayout(
          SavedLayout.fromJson(jsonMap(patch['layout'])),
          patch['deviceId'] as String? ?? '',
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
    'alarms': alarms,
    'banners': banners.map((banner) => banner.toJson()).toList(),
    'saved': saved.map((layout) => layout.toJson()).toList(),
    'vfxColor': vfxColor,
    'vfxMarks': vfxMarks.map((mark) => mark.toJson()).toList(),
    'uiMarkers': uiMarkers,
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
  }

  void _dropDevices(Set<String> ids) {
    messages = messages
        .where((message) => !ids.contains(message.deviceId))
        .toList();
    calls = calls.where((call) => !ids.contains(call.deviceId)).toList();
    banners = banners
        .where((banner) => !ids.contains(banner.deviceId))
        .toList();
    alarms.removeWhere((key, _) => ids.contains(key));
    photos.removeWhere((key, _) => ids.contains(key));
  }

  void _normalize() {
    if (!projects.any((project) => project.id == selectedProjectId)) {
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
      link.sendPatch(patch);
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
    a.os == b.os;

OsSettings _skinWallpaper(OsSettings os, String skin) {
  final preset = presetForSkin(skin);
  if (preset == null || os.backgroundType == 'image') return os;
  return os.copyWith(
    backgroundType: 'preset',
    backgroundPreset: preset,
    backgroundUrl: '',
  );
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
