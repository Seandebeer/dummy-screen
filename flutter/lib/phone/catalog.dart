import 'package:flutter/material.dart';

class PropApp {
  const PropApp(this.id, this.label, this.color, this.icon);

  final String id;
  final String label;
  final Color color;
  final IconData icon;
}

const kPropApps = <PropApp>[
  PropApp('phone', 'Phone', Color(0xFF34C759), Icons.phone),
  PropApp('messages', 'Messages', Color(0xFF34C759), Icons.message),
  PropApp('mail', 'Mail', Color(0xFF0A84FF), Icons.mail),
  PropApp('calendar', 'Calendar', Color(0xFFFF3B30), Icons.calendar_month),
  PropApp('photos', 'Photos', Color(0xFFFF9500), Icons.photo),
  PropApp('camera', 'Camera', Color(0xFF2C2C2E), Icons.photo_camera),
  PropApp('clock', 'Clock', Color(0xFFFF9F0A), Icons.schedule),
  PropApp('maps', 'Maps', Color(0xFF00C7BE), Icons.map),
  PropApp('notes', 'Notes', Color(0xFFFFC800), Icons.sticky_note_2),
  PropApp('calculator', 'Calculator', Color(0xFF1C1C1E), Icons.calculate),
  PropApp('contacts', 'Contacts', Color(0xFF5A5D6B), Icons.contacts),
  PropApp('settings', 'Settings', Color(0xFF636366), Icons.settings),
  PropApp('grapevine', 'Grapevine', Color(0xFF1877F2), Icons.thumb_up_alt),
  PropApp('lume', 'Lume', Color(0xFF833AB4), Icons.camera_alt),
  PropApp('streamly', 'Streamly', Color(0xFFFF0000), Icons.play_arrow),
  PropApp('flickdeck', 'Flickdeck', Color(0xFF111111), Icons.music_note),
];

const kDockIds = ['phone', 'messages', 'camera', 'settings'];

PropApp? propAppById(String id) {
  for (final app in kPropApps) {
    if (app.id == id) return app;
  }
  return null;
}

Color colorForName(String name) {
  const colors = [
    Color(0xFF318DF6),
    Color(0xFF30D158),
    Color(0xFFFF9F0A),
    Color(0xFFFF453A),
    Color(0xFF5E5CE6),
    Color(0xFF64D2FF),
    Color(0xFFFF375F),
  ];
  final sum = name.codeUnits.fold<int>(0, (total, unit) => total + unit);
  return colors[sum % colors.length];
}
