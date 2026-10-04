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
    final pad = first.weekday - 1;
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          formatDay(now),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final label in labels)
              Expanded(
                child: Center(
                  child: Text(label, style: const TextStyle(color: kMuted)),
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
                    backgroundColor: day == now.day
                        ? kAccent
                        : Colors.transparent,
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
    );
  }
}

class MapsApp extends StatelessWidget {
  const MapsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ListTile(
          title: Text('Set route'),
          subtitle: Text('Stage door to holding'),
        ),
        Expanded(
          child: CustomPaint(painter: _MapPainter(), child: SizedBox.expand()),
        ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0E1A16),
    );
    final road = Paint()
      ..color = const Color(0xFF2A3A34)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.8)
      ..lineTo(size.width * 0.15, size.height * 0.35)
      ..lineTo(size.width * 0.72, size.height * 0.35)
      ..lineTo(size.width * 0.72, size.height * 0.18);
    canvas.drawPath(path, road);
    final route = Paint()
      ..color = kAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, route);
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.8),
      7,
      Paint()..color = kSignal,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.18),
      8,
      Paint()..color = kAlert,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
