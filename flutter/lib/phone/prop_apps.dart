import 'package:flutter/material.dart';

import '../format.dart';
import '../theme.dart';

class MailApp extends StatelessWidget {
  const MailApp({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        'Production',
        'Call sheet is up',
        'Unit call is 6:40. Hero phone stays with you between setups.',
      ),
      (
        'Elena Frost',
        'Tonight',
        'Use the thread we loaded. Do not answer until the deck rings you.',
      ),
      ('Locations', 'Gate code', 'The lot gate is on the lock screen note.'),
    ];
    return ListView(
      children: [
        for (final item in items)
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.mail, size: 18)),
            title: Text(item.$1),
            subtitle: Text('${item.$2}\n${item.$3}', maxLines: 3),
            isThreeLine: true,
          ),
      ],
    );
  }
}

class CalendarApp extends StatelessWidget {
  const CalendarApp({super.key, required this.offsetMinutes});

  final int offsetMinutes;

  @override
  Widget build(BuildContext context) {
    final now = propNow(offsetMinutes);
    final first = DateTime(now.year, now.month, 1);
    final days = DateTime(now.year, now.month + 1, 0).day;
    final pad = first.weekday % 7;
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            formatDay(now),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final label in labels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(color: label == 'S' ? kAlert : kMuted, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              children: [
                for (var i = 0; i < pad; i++) const SizedBox.shrink(),
                for (var day = 1; day <= days; day++)
                  Center(
                    child: CircleAvatar(
                      backgroundColor: day == now.day ? kAlert : Colors.transparent,
                      child: Text(
                        '$day',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PropFeed extends StatelessWidget {
  const PropFeed({
    super.key,
    required this.title,
    required this.accent,
    required this.posts,
  });

  final String title;
  final Color accent;
  final List<(String, String)> posts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
        const SizedBox(height: 12),
        for (final post in posts)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kLine,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.$1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(post.$2, style: const TextStyle(height: 1.35)),
              ],
            ),
          ),
      ],
    );
  }
}

const kFeeds = <String, (String, Color, List<(String, String)>)>{
  'facepage': (
    'Grapevine',
    Color(0xFF1877F2),
    [
      ('Elena Frost', 'On set. Do not text the real number.'),
      ('Unit', 'Picture is up. Phones on silent except the hero.'),
    ],
  ),
  'photogram': (
    'Lume',
    Color(0xFF833AB4),
    [
      ('night exterior', 'Holding photo, loaded for the insert.'),
      ('call sheet', 'Wardrobe still has the case.'),
    ],
  ),
  'vidtube': (
    'Streamly',
    Color(0xFFFF3B30),
    [
      ('Continue watching', 'The interview cut, 12 minutes.'),
      ('For you', 'City skyline, no audio.'),
    ],
  ),
  'quicktok': (
    'Flickdeck',
    Color(0xFF111111),
    [
      ('Sound on set', 'The track is loaded. Do not scroll past it.'),
      ('Hold', 'Loop the chorus until cut.'),
    ],
  ),
  'grapevine': (
    'Grapevine',
    Color(0xFF1877F2),
    [
      ('Elena Frost', 'On set. Do not text the real number.'),
      ('Unit', 'Picture is up. Phones on silent except the hero.'),
    ],
  ),
  'lume': (
    'Lume',
    Color(0xFF833AB4),
    [
      ('night exterior', 'Holding photo, loaded for the insert.'),
      ('call sheet', 'Wardrobe still has the case.'),
    ],
  ),
  'streamly': (
    'Streamly',
    Color(0xFFFF3B30),
    [
      ('Continue watching', 'The interview cut, 12 minutes.'),
      ('For you', 'City skyline, no audio.'),
    ],
  ),
  'flickdeck': (
    'Flickdeck',
    Color(0xFF25F4EE),
    [
      ('For you', 'Vertical clip, looped, no captions.'),
      ('Sounds', 'The ringtone we cleared.'),
    ],
  ),
};
