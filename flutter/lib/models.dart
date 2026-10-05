/// Shared stage records. The same shapes move between the prop phone,
/// the control deck, and any other machine joined on the local link.
library;

class Project {
  const Project({
    required this.id,
    required this.name,
    this.description = '',
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String description;
  final int sortOrder;

  Project copyWith({String? name, String? description, int? sortOrder}) =>
      Project(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'sortOrder': sortOrder,
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Project',
    description: json['description'] as String? ?? '',
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  );
}

/// On-device OS settings. Field names follow the Base44 `takeover-os-config`
/// object: theme, wallpaper, lock screen, dial codes, language, answer mode,
/// ring duration, and auto-rotate.
class OsSettings {
  const OsSettings({
    this.theme = 'dark',
    this.backgroundType = 'preset',
    this.backgroundPreset = 'default',
    this.backgroundUrl = '',
    this.lockType = 'none',
    this.lockBackgroundType = 'preset',
    this.lockBackgroundPreset = 'default',
    this.lockBackgroundUrl = '',
    this.passcode = '',
    this.pattern = '',
    this.dialCodes = const ['026', '034', '049'],
    this.language = 'en',
    this.callAnswer = 'tap',
    this.ringDelay = 4,
    this.autoRotate = true,
    this.homeOrder = const [],
  });

  final String theme;
  final String backgroundType;
  final String backgroundPreset;
  final String backgroundUrl;
  final String lockType;
  final String lockBackgroundType;
  final String lockBackgroundPreset;
  final String lockBackgroundUrl;
  final String passcode;
  final String pattern;
  final List<String> dialCodes;
  final String language;
  final String callAnswer;
  final int ringDelay;
  final bool autoRotate;

  /// Empty means the Base44 default home layout.
  final List<String> homeOrder;

  bool get isLight => theme == 'light';

  int get ringDelaySeconds {
    if (ringDelay < 1) return 1;
    if (ringDelay > 60) return 60;
    return ringDelay;
  }

  OsSettings copyWith({
    String? theme,
    String? backgroundType,
    String? backgroundPreset,
    String? backgroundUrl,
    String? lockType,
    String? lockBackgroundType,
    String? lockBackgroundPreset,
    String? lockBackgroundUrl,
    String? passcode,
    String? pattern,
    List<String>? dialCodes,
    String? language,
    String? callAnswer,
    int? ringDelay,
    bool? autoRotate,
    List<String>? homeOrder,
  }) => OsSettings(
    theme: theme ?? this.theme,
    backgroundType: backgroundType ?? this.backgroundType,
    backgroundPreset: backgroundPreset ?? this.backgroundPreset,
    backgroundUrl: backgroundUrl ?? this.backgroundUrl,
    lockType: lockType ?? this.lockType,
    lockBackgroundType: lockBackgroundType ?? this.lockBackgroundType,
    lockBackgroundPreset: lockBackgroundPreset ?? this.lockBackgroundPreset,
    lockBackgroundUrl: lockBackgroundUrl ?? this.lockBackgroundUrl,
    passcode: passcode ?? this.passcode,
    pattern: pattern ?? this.pattern,
    dialCodes: dialCodes ?? this.dialCodes,
    language: language ?? this.language,
    callAnswer: callAnswer ?? this.callAnswer,
    ringDelay: ringDelay ?? this.ringDelay,
    autoRotate: autoRotate ?? this.autoRotate,
    homeOrder: homeOrder ?? this.homeOrder,
  );

  Map<String, dynamic> toJson() => {
    'theme': theme,
    'backgroundType': backgroundType,
    'backgroundPreset': backgroundPreset,
    'backgroundUrl': backgroundUrl,
    'lockType': lockType,
    'lockBackgroundType': lockBackgroundType,
    'lockBackgroundPreset': lockBackgroundPreset,
    'lockBackgroundUrl': lockBackgroundUrl,
    'passcode': passcode,
    'pattern': pattern,
    'dialCodes': dialCodes,
    'language': language,
    'callAnswer': callAnswer,
    'ringDelay': ringDelay,
    'autoRotate': autoRotate,
    'homeOrder': homeOrder,
  };

  factory OsSettings.fromJson(Map<String, dynamic> json) {
    final codes = [
      for (final item in jsonList(json['dialCodes'])) item.toString(),
    ].where((code) => RegExp(r'^\d{3}$').hasMatch(code)).take(3).toList();
    final theme = json['theme'] == 'light' ? 'light' : 'dark';
    final answer = json['callAnswer'] == 'swipe' ? 'swipe' : 'tap';
    final delay = (json['ringDelay'] as num?)?.toInt() ?? 4;
    return OsSettings(
      theme: theme,
      backgroundType: json['backgroundType'] == 'image' ? 'image' : 'preset',
      backgroundPreset: json['backgroundPreset'] as String? ?? 'default',
      backgroundUrl: json['backgroundUrl'] as String? ?? '',
      lockType: json['lockType'] as String? ?? 'none',
      lockBackgroundType: json['lockBackgroundType'] == 'image'
          ? 'image'
          : 'preset',
      lockBackgroundPreset:
          json['lockBackgroundPreset'] as String? ?? 'default',
      lockBackgroundUrl: json['lockBackgroundUrl'] as String? ?? '',
      passcode: json['passcode'] as String? ?? '',
      pattern: json['pattern'] as String? ?? '',
      dialCodes: codes.isEmpty ? const ['026', '034', '049'] : codes,
      language: json['language'] as String? ?? 'en',
      callAnswer: answer,
      ringDelay: delay < 1 ? 1 : (delay > 60 ? 60 : delay),
      autoRotate: json['autoRotate'] as bool? ?? true,
      homeOrder: [
        for (final item in jsonList(json['homeOrder'])) item.toString(),
      ].where((id) => id.isNotEmpty).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! OsSettings) return false;
    return theme == other.theme &&
        backgroundType == other.backgroundType &&
        backgroundPreset == other.backgroundPreset &&
        backgroundUrl == other.backgroundUrl &&
        lockType == other.lockType &&
        lockBackgroundType == other.lockBackgroundType &&
        lockBackgroundPreset == other.lockBackgroundPreset &&
        lockBackgroundUrl == other.lockBackgroundUrl &&
        passcode == other.passcode &&
        pattern == other.pattern &&
        language == other.language &&
        callAnswer == other.callAnswer &&
        ringDelay == other.ringDelay &&
        autoRotate == other.autoRotate &&
        _sameCodes(dialCodes, other.dialCodes) &&
        _sameOrder(homeOrder, other.homeOrder);
  }

  @override
  int get hashCode => Object.hash(
    theme,
    backgroundType,
    backgroundPreset,
    backgroundUrl,
    lockType,
    lockBackgroundType,
    lockBackgroundPreset,
    lockBackgroundUrl,
    passcode,
    pattern,
    language,
    callAnswer,
    ringDelay,
    autoRotate,
    Object.hashAll(dialCodes),
    Object.hashAll(homeOrder),
  );
}

bool _sameOrder(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameCodes(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class PropDevice {
  const PropDevice({
    required this.id,
    required this.name,
    required this.projectId,
    this.kind = 'phone',
    this.skin = 'modern',
    this.locked = true,
    this.clockOffsetMinutes = 0,
    this.notes = '',
    this.os = const OsSettings(),
    this.make = '',
    this.model = '',
    this.colour = '',
    this.serial = '',
    this.photo = '',
    this.status = 'offline',
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String projectId;
  final String kind;
  final String skin;
  final bool locked;
  final int clockOffsetMinutes;
  final String notes;
  final OsSettings os;
  final String make;
  final String model;
  final String colour;
  final String serial;
  final String photo;
  final String status;
  final int sortOrder;

  bool get online => status == 'online';

  PropDevice copyWith({
    String? name,
    String? projectId,
    String? kind,
    String? skin,
    bool? locked,
    int? clockOffsetMinutes,
    String? notes,
    OsSettings? os,
    String? make,
    String? model,
    String? colour,
    String? serial,
    String? photo,
    String? status,
    int? sortOrder,
  }) => PropDevice(
    id: id,
    name: name ?? this.name,
    projectId: projectId ?? this.projectId,
    kind: kind ?? this.kind,
    skin: skin ?? this.skin,
    locked: locked ?? this.locked,
    clockOffsetMinutes: clockOffsetMinutes ?? this.clockOffsetMinutes,
    notes: notes ?? this.notes,
    os: os ?? this.os,
    make: make ?? this.make,
    model: model ?? this.model,
    colour: colour ?? this.colour,
    serial: serial ?? this.serial,
    photo: photo ?? this.photo,
    status: status ?? this.status,
    sortOrder: sortOrder ?? this.sortOrder,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'projectId': projectId,
    'kind': kind,
    'skin': skin,
    'locked': locked,
    'clockOffsetMinutes': clockOffsetMinutes,
    'notes': notes,
    'os': os.toJson(),
    'make': make,
    'model': model,
    'colour': colour,
    'serial': serial,
    'photo': photo,
    'status': status,
    'sortOrder': sortOrder,
  };

  factory PropDevice.fromJson(Map<String, dynamic> json) => PropDevice(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Phone',
    projectId: json['projectId'] as String? ?? '',
    kind: json['kind'] as String? ?? 'phone',
    skin: json['skin'] as String? ?? 'modern',
    locked: json['locked'] as bool? ?? true,
    clockOffsetMinutes: (json['clockOffsetMinutes'] as num?)?.toInt() ?? 0,
    notes: json['notes'] as String? ?? '',
    os: OsSettings.fromJson(jsonMap(json['os'])),
    make: json['make'] as String? ?? '',
    model: json['model'] as String? ?? '',
    colour: json['colour'] as String? ?? '',
    serial: json['serial'] as String? ?? '',
    photo: json['photo'] as String? ?? '',
    status: json['status'] == 'online' ? 'online' : 'offline',
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  );
}

class StageMessage {
  const StageMessage({
    required this.id,
    required this.deviceId,
    required this.sender,
    required this.text,
    required this.senderName,
    required this.thread,
    required this.sentAt,
    this.media = '',
    this.mediaType = '',
    this.read = false,
  });

  final String id;
  final String deviceId;
  final String sender;
  final String text;
  final String senderName;
  final String thread;
  final int sentAt;
  final String media;
  final String mediaType;
  final bool read;

  StageMessage copyWith({bool? read}) => StageMessage(
    id: id,
    deviceId: deviceId,
    sender: sender,
    text: text,
    senderName: senderName,
    thread: thread,
    sentAt: sentAt,
    media: media,
    mediaType: mediaType,
    read: read ?? this.read,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceId': deviceId,
    'sender': sender,
    'text': text,
    'senderName': senderName,
    'thread': thread,
    'sentAt': sentAt,
    'media': media,
    'mediaType': mediaType,
    'read': read,
  };

  factory StageMessage.fromJson(Map<String, dynamic> json) => StageMessage(
    id: json['id'] as String? ?? '',
    deviceId: json['deviceId'] as String? ?? '',
    sender: json['sender'] as String? ?? 'control',
    text: json['text'] as String? ?? '',
    senderName: json['senderName'] as String? ?? '',
    thread: json['thread'] as String? ?? '',
    sentAt: (json['sentAt'] as num?)?.toInt() ?? 0,
    media: json['media'] as String? ?? '',
    mediaType: json['mediaType'] as String? ?? '',
    read: json['read'] as bool? ?? false,
  );
}

class LiveCall {
  const LiveCall({
    required this.id,
    required this.deviceId,
    required this.contactName,
    required this.contactNumber,
    required this.direction,
    required this.status,
    this.kind = 'voice',
    this.scene = const {},
  });

  final String id;
  final String deviceId;
  final String contactName;
  final String contactNumber;
  final String direction;
  final String status;

  /// `voice` or `video`. Older snapshots omit it and stay voice calls.
  final String kind;

  /// What the actor sees after answering a video call: `mode` is
  /// `live`, `vfx`, `video`, or `photo`, plus the colour, mark, and file.
  final Map<String, dynamic> scene;

  /// Far-end content. A video call with no scene is a live camera.
  String get sceneMode {
    if (kind != 'video') return 'voice';
    final mode = scene['mode'] as String? ?? 'live';
    if (mode == 'vfx' || mode == 'video' || mode == 'photo' || mode == 'live') {
      return mode;
    }
    return 'live';
  }

  bool get liveCamera => sceneMode == 'live';

  LiveCall copyWith({String? status, Map<String, dynamic>? scene}) => LiveCall(
    id: id,
    deviceId: deviceId,
    contactName: contactName,
    contactNumber: contactNumber,
    direction: direction,
    status: status ?? this.status,
    kind: kind,
    scene: scene ?? this.scene,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceId': deviceId,
    'contactName': contactName,
    'contactNumber': contactNumber,
    'direction': direction,
    'status': status,
    'kind': kind,
    'scene': scene,
  };

  factory LiveCall.fromJson(Map<String, dynamic> json) => LiveCall(
    id: json['id'] as String? ?? '',
    deviceId: json['deviceId'] as String? ?? '',
    contactName: json['contactName'] as String? ?? '',
    contactNumber: json['contactNumber'] as String? ?? '',
    direction: json['direction'] as String? ?? 'incoming',
    status: json['status'] as String? ?? 'ringing',
    kind: json['kind'] as String? ?? 'voice',
    scene: json['scene'] is Map
        ? Map<String, dynamic>.from(json['scene'] as Map)
        : const {},
  );
}

/// A finished call kept on this device. The web app stores the same rows in
/// Base44 CallLog; here they travel with the deck snapshot instead.
class CallRecord {
  const CallRecord({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.name,
    required this.number,
    required this.type,
    required this.at,
  });

  final String id;
  final String deviceId;
  final String deviceName;
  final String name;
  final String number;
  final String type;
  final int at;

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'name': name,
    'number': number,
    'type': type,
    'at': at,
  };

  factory CallRecord.fromJson(Map<String, dynamic> json) => CallRecord(
    id: json['id'] as String? ?? '',
    deviceId: json['deviceId'] as String? ?? '',
    deviceName: json['deviceName'] as String? ?? '',
    name: json['name'] as String? ?? '',
    number: json['number'] as String? ?? '',
    type: json['type'] as String? ?? 'outgoing',
    at: (json['at'] as num?)?.toInt() ?? 0,
  );
}

class BannerNote {
  const BannerNote({
    required this.id,
    required this.deviceId,
    required this.appLabel,
    required this.text,
  });

  final String id;
  final String deviceId;
  final String appLabel;
  final String text;

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceId': deviceId,
    'appLabel': appLabel,
    'text': text,
  };

  factory BannerNote.fromJson(Map<String, dynamic> json) => BannerNote(
    id: json['id'] as String? ?? '',
    deviceId: json['deviceId'] as String? ?? '',
    appLabel: json['appLabel'] as String? ?? 'Messages',
    text: json['text'] as String? ?? '',
  );
}

class MarkPoint {
  const MarkPoint({required this.id, required this.x, required this.y});

  final String id;
  final double x;
  final double y;

  Map<String, dynamic> toJson() => {'id': id, 'x': x, 'y': y};

  factory MarkPoint.fromJson(Map<String, dynamic> json) => MarkPoint(
    id: json['id'] as String? ?? '',
    x: (json['x'] as num?)?.toDouble() ?? 0.5,
    y: (json['y'] as num?)?.toDouble() ?? 0.5,
  );
}

class SavedLayout {
  const SavedLayout({
    required this.id,
    required this.name,
    required this.skin,
    required this.clockOffsetMinutes,
    required this.notes,
    required this.vfxColor,
    required this.vfxMarks,
    required this.uiMarkers,
    this.kind = 'os',
    this.category = '',
    this.deviceId = '',
    this.payload = const {},
  });

  final String id;
  final String name;
  final String skin;
  final int clockOffsetMinutes;
  final String notes;
  final String vfxColor;
  final List<MarkPoint> vfxMarks;
  final List<String> uiMarkers;
  final String kind;
  final String category;
  final String deviceId;
  final Map<String, dynamic> payload;

  String get savedCategory {
    if (kind == 'os') return 'OS';
    if (kind == 'markers') return 'UI Markers';
    if (kind == 'screen') return 'Key Screens';
    if (category.isNotEmpty) return category;
    return 'Pages';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'skin': skin,
    'clockOffsetMinutes': clockOffsetMinutes,
    'notes': notes,
    'vfxColor': vfxColor,
    'vfxMarks': vfxMarks.map((mark) => mark.toJson()).toList(),
    'uiMarkers': uiMarkers,
    'kind': kind,
    'category': category,
    'deviceId': deviceId,
    'payload': payload,
  };

  factory SavedLayout.fromJson(Map<String, dynamic> json) => SavedLayout(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Layout',
    skin: json['skin'] as String? ?? 'modern',
    clockOffsetMinutes: (json['clockOffsetMinutes'] as num?)?.toInt() ?? 0,
    notes: json['notes'] as String? ?? '',
    vfxColor: json['vfxColor'] as String? ?? 'green',
    vfxMarks: marksFrom(json['vfxMarks']),
    uiMarkers: [
      for (final item in jsonList(json['uiMarkers'])) item.toString(),
    ],
    kind: json['kind'] as String? ?? 'os',
    category: json['category'] as String? ?? '',
    deviceId: json['deviceId'] as String? ?? '',
    payload: jsonMap(json['payload']),
  );
}

class VideoClip {
  const VideoClip({
    required this.id,
    required this.name,
    this.path,
    this.url,
    this.durationMs = 0,
    this.trimStartMs = 0,
    this.trimEndMs = 0,
    this.loop = false,
    this.aspect = 'fit',
    this.order = 0,
  });

  final String id;
  final String name;
  final String? path;
  final String? url;
  final int durationMs;
  final int trimStartMs;
  final int trimEndMs;
  final bool loop;
  final String aspect;
  final int order;

  int get playEndMs => trimEndMs > 0 ? trimEndMs : durationMs;

  VideoClip copyWith({
    int? durationMs,
    int? trimStartMs,
    int? trimEndMs,
    bool? loop,
    String? aspect,
    int? order,
  }) => VideoClip(
    id: id,
    name: name,
    path: path,
    url: url,
    durationMs: durationMs ?? this.durationMs,
    trimStartMs: trimStartMs ?? this.trimStartMs,
    trimEndMs: trimEndMs ?? this.trimEndMs,
    loop: loop ?? this.loop,
    aspect: aspect ?? this.aspect,
    order: order ?? this.order,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'url': url,
    'durationMs': durationMs,
    'trimStartMs': trimStartMs,
    'trimEndMs': trimEndMs,
    'loop': loop,
    'aspect': aspect,
    'order': order,
  };

  factory VideoClip.fromJson(Map<String, dynamic> json) => VideoClip(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Clip',
    path: json['path'] as String?,
    url: json['url'] as String?,
    durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
    trimStartMs: (json['trimStartMs'] as num?)?.toInt() ?? 0,
    trimEndMs: (json['trimEndMs'] as num?)?.toInt() ?? 0,
    loop: json['loop'] as bool? ?? false,
    aspect: json['aspect'] as String? ?? 'fit',
    order: (json['order'] as num?)?.toInt() ?? 0,
  );
}

class PropPhoto {
  const PropPhoto({
    required this.id,
    required this.color,
    required this.createdAt,
    this.image = '',
  });

  final String id;
  final int color;
  final int createdAt;

  /// File path or data URL of the captured frame. Empty keeps the colour tile.
  final String image;

  Map<String, dynamic> toJson() => {
    'id': id,
    'color': color,
    'createdAt': createdAt,
    'image': image,
  };

  factory PropPhoto.fromJson(Map<String, dynamic> json) => PropPhoto(
    id: json['id'] as String? ?? '',
    color: (json['color'] as num?)?.toInt() ?? 0xFF318DF6,
    createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
    image: json['image'] as String? ?? '',
  );
}

class ContactCard {
  const ContactCard(this.name, this.number);

  final String name;
  final String number;
}

const kContacts = <ContactCard>[
  ContactCard('Sarah Chen', '026 555 0142'),
  ContactCard('Marcus Webb', '034 555 0198'),
  ContactCard('Elena Frost', '049 555 0177'),
  ContactCard('David Park', '026 555 0123'),
  ContactCard('Nora Vega', '034 555 0156'),
  ContactCard('Sam Ryder', '049 555 0119'),
];

const kSampleClipUrl =
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

Map<String, dynamic> jsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return {};
}

List<dynamic> jsonList(dynamic value) => value is List ? value : const [];

List<MarkPoint> marksFrom(dynamic value) => [
  for (final item in jsonList(value))
    if (item is Map) MarkPoint.fromJson(jsonMap(item)),
].where((mark) => mark.id.isNotEmpty).toList();
