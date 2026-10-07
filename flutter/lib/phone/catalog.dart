import 'package:flutter/material.dart';

class PropApp {
  const PropApp(this.id, this.label, this.color, this.icon, {this.image = ''});

  final String id;
  final String label;
  final Color color;
  final IconData icon;
  final String image;
}

/// Core apps, in the same order and colors as the Base44 OS.
const kPropApps = <PropApp>[
  PropApp('phone', 'Phone', Color(0xFF34C759), Icons.phone),
  PropApp('messages', 'Messages', Color(0xFF34C759), Icons.message),
  PropApp('email', 'Mail', Color(0xFF0A84FF), Icons.mail),
  PropApp('clock', 'Clock', Color(0xFFFF9F0A), Icons.schedule),
  PropApp('music', 'Music', Color(0xFFFC3C44), Icons.music_note),
  PropApp('contacts', 'Contacts', Color(0xFF5A5D6B), Icons.contacts),
  PropApp('settings', 'Settings', Color(0xFF636366), Icons.settings),
  PropApp('calculator', 'Calculator', Color(0xFF1C1C1E), Icons.calculate),
  PropApp('calendar', 'Calendar', Color(0xFFFF3B30), Icons.calendar_month),
  PropApp('notes', 'Notes', Color(0xFFFFC800), Icons.sticky_note_2),
  PropApp('camera', 'Camera', Color(0xFF2C2C2E), Icons.photo_camera),
  PropApp('photos', 'Photos', Color(0xFFFF9500), Icons.photo),
  PropApp('videocall', 'Vidcall', Color(0xFF32D74B), Icons.videocam),
  PropApp('maps', 'Maps', Color(0xFF00C7BE), Icons.map),
  PropApp('appstore', 'App Library', Color(0xFF0A84FF), Icons.shopping_bag),
  PropApp('facepage', 'Grapevine', Color(0xFF1877F2), Icons.thumb_up_alt),
  PropApp('photogram', 'Lume', Color(0xFF833AB4), Icons.camera_alt),
  PropApp('vidtube', 'Streamly', Color(0xFFFF0000), Icons.play_arrow),
  PropApp('quicktok', 'Flickdeck', Color(0xFF25F4EE), Icons.music_note),
  PropApp('browser', 'Browser', Color(0xFF0A84FF), Icons.language),
  PropApp('webdeck', 'Webdeck', Color(0xFFFF9F0A), Icons.web_asset),
  PropApp('news', 'Bulletin', Color(0xFFDC4A38), Icons.newspaper),
  PropApp('property', 'Realty', Color(0xFF32D74B), Icons.apartment),
  PropApp('fitness', 'Pulse', Color(0xFFFF375F), Icons.favorite),
  PropApp('ping', 'Ping', Color(0xFF0A84FF), Icons.chat_bubble),
  PropApp('buzz', 'Buzz', Color(0xFF3B82F6), Icons.groups),
  PropApp('visage', 'Visage', Color(0xFF059669), Icons.video_call),
  PropApp('flixiq', 'Flixiq', Color(0xFFFF375F), Icons.play_circle),
  PropApp('waveform', 'Waveform', Color(0xFF8B5CF6), Icons.headphones),
  PropApp('questly', 'Questly', Color(0xFFA78BFA), Icons.sports_esports),
  PropApp('headlines24', 'Headlines24', Color(0xFFDC4A38), Icons.feed),
  PropApp('skycast', 'Skycast', Color(0xFF60A5FA), Icons.wb_cloudy),
  PropApp('findit', 'Findit', Color(0xFFF97316), Icons.shopping_bag_outlined),
  PropApp('zippyride', 'Zippyride', Color(0xFF111827), Icons.directions_car),
  PropApp('wandermap', 'Wandermap', Color(0xFF0EA5E9), Icons.explore),
  PropApp('recipebox', 'Recipebox', Color(0xFFEA580C), Icons.restaurant),
  PropApp('flexr', 'Flexr', Color(0xFF16A34A), Icons.fitness_center),
  PropApp('walletto', 'Walletto', Color(0xFF1E40AF), Icons.account_balance_wallet),
];

/// Daily drivers, matching the Base44 dock.
const kDockIds = ['phone', 'browser', 'messages', 'music'];

/// Home pages, matching `defaultHomeOrder` in the Base44 OS.
const kHomeOrder = [
  'videocall', 'calendar', 'photos', 'camera',
  'email', 'notes', 'contacts', 'clock',
  'maps', 'appstore', 'fitness', 'calculator',
  'facepage', 'photogram', 'vidtube', 'quicktok',
  'webdeck', 'news', 'property', 'settings',
  'ping', 'buzz', 'visage', 'flixiq',
  'waveform', 'questly', 'headlines24', 'skycast',
  'findit', 'zippyride', 'wandermap', 'recipebox',
  'flexr', 'walletto',
];

const kPageSize = 20;

/// Page one of the default home screen: every functional app.
/// Phones, tablets, and computers all start with these.
List<String> homePageOne() => kHomeOrder.take(kPageSize).toList();

/// Real product names used only while App Branding is set to Branded.
/// Icons stay simple glyphs so the prop never ships another company's artwork.
const kBrandNames = <String, String>{
  'phone': 'Phone',
  'messages': 'Messages',
  'email': 'Mail',
  'clock': 'Clock',
  'music': 'Music',
  'contacts': 'Contacts',
  'settings': 'Settings',
  'calculator': 'Calculator',
  'calendar': 'Calendar',
  'notes': 'Notes',
  'camera': 'Camera',
  'photos': 'Photos',
  'videocall': 'FaceTime',
  'maps': 'Maps',
  'appstore': 'App Store',
  'facepage': 'Facebook',
  'photogram': 'Instagram',
  'vidtube': 'YouTube',
  'quicktok': 'TikTok',
  'browser': 'Safari',
  'webdeck': 'Chrome',
  'news': 'News',
  'property': 'Zillow',
  'fitness': 'Fitness',
  'ping': 'Messenger',
  'buzz': 'X',
  'visage': 'Zoom',
  'flixiq': 'Netflix',
  'waveform': 'Spotify',
  'questly': 'Steam',
  'headlines24': 'Headlines',
  'skycast': 'Weather',
  'findit': 'Amazon',
  'zippyride': 'Uber',
  'wandermap': 'Maps',
  'recipebox': 'Recipes',
  'flexr': 'Fitness',
  'walletto': 'Wallet',
  'teamly': 'Slack',
};

String appLabel(PropApp app, {required bool branded}) {
  if (!branded) return app.label;
  return kBrandNames[app.id] ?? app.label;
}

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
