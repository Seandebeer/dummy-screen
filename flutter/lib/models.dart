/// Shared stage records. The same shapes move between the prop phone,
/// the control deck, and any other machine joined on the local link.
library;

class Project {
  const Project({required this.id, required this.name, this.description = ''});

  final String id;
  final String name;
  final String description;

  Project copyWith({String? name, String? description}) => Project(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Project',
    description: json['description'] as String? ?? '',
  );
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
  });

  final String id;
  final String name;
  final String projectId;
  final String kind;
  final String skin;
  final bool locked;
  final int clockOffsetMinutes;
  final String notes;

  PropDevice copyWith({
    String? name,
    String? projectId,
    String? kind,
    String? skin,
    bool? locked,
    int? clockOffsetMinutes,
    String? notes,
  }) => PropDevice(
    id: id,
    name: name ?? this.name,
    projectId: projectId ?? this.projectId,
    kind: kind ?? this.kind,
    skin: skin ?? this.skin,
    locked: locked ?? this.locked,
    clockOffsetMinutes: clockOffsetMinutes ?? this.clockOffsetMinutes,
    notes: notes ?? this.notes,
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
  });

  final String id;
  final String deviceId;
  final String sender;
  final String text;
  final String senderName;
  final String thread;
  final int sentAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceId': deviceId,
    'sender': sender,
    'text': text,
    'senderName': senderName,
    'thread': thread,
    'sentAt': sentAt,
  };

  factory StageMessage.fromJson(Map<String, dynamic> json) => StageMessage(
    id: json['id'] as String? ?? '',
    deviceId: json['deviceId'] as String? ?? '',
    sender: json['sender'] as String? ?? 'control',
    text: json['text'] as String? ?? '',
    senderName: json['senderName'] as String? ?? '',
    thread: json['thread'] as String? ?? '',
    sentAt: (json['sentAt'] as num?)?.toInt() ?? 0,
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
  });

  final String id;
  final String deviceId;
  final String contactName;
  final String contactNumber;
  final String direction;
  final String status;

  LiveCall copyWith({String? status}) => LiveCall(
    id: id,
    deviceId: deviceId,
    contactName: contactName,
    contactNumber: contactNumber,
    direction: direction,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceId': deviceId,
    'contactName': contactName,
    'contactNumber': contactNumber,
    'direction': direction,
    'status': status,
  };

  factory LiveCall.fromJson(Map<String, dynamic> json) => LiveCall(
    id: json['id'] as String? ?? '',
    deviceId: json['deviceId'] as String? ?? '',
    contactName: json['contactName'] as String? ?? '',
    contactNumber: json['contactNumber'] as String? ?? '',
    direction: json['direction'] as String? ?? 'incoming',
    status: json['status'] as String? ?? 'ringing',
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
  });

  final String id;
  final String name;
  final String skin;
  final int clockOffsetMinutes;
  final String notes;
  final String vfxColor;
  final List<MarkPoint> vfxMarks;
  final List<String> uiMarkers;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'skin': skin,
    'clockOffsetMinutes': clockOffsetMinutes,
    'notes': notes,
    'vfxColor': vfxColor,
    'vfxMarks': vfxMarks.map((mark) => mark.toJson()).toList(),
    'uiMarkers': uiMarkers,
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
  );
}

class VideoClip {
  const VideoClip({required this.id, required this.name, this.path, this.url});

  final String id;
  final String name;
  final String? path;
  final String? url;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'url': url,
  };

  factory VideoClip.fromJson(Map<String, dynamic> json) => VideoClip(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Clip',
    path: json['path'] as String?,
    url: json['url'] as String?,
  );
}

class PropPhoto {
  const PropPhoto({
    required this.id,
    required this.color,
    required this.createdAt,
  });

  final String id;
  final int color;
  final int createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'color': color,
    'createdAt': createdAt,
  };

  factory PropPhoto.fromJson(Map<String, dynamic> json) => PropPhoto(
    id: json['id'] as String? ?? '',
    color: (json['color'] as num?)?.toInt() ?? 0xFF318DF6,
    createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
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
