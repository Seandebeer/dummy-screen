import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../app.dart';
import '../image_file.dart';
import '../media/live_lens.dart';
import '../models.dart';
import '../video_source.dart';
import 'ios_keyboard.dart';
import 'browser_frame.dart';
import 'catalog.dart';
import 'social_apps.dart';

class BulletinApp extends StatefulWidget {
  const BulletinApp({super.key});

  @override
  State<BulletinApp> createState() => _BulletinAppState();
}

class _BulletinAppState extends State<BulletinApp> {
  String _name = 'Bulletin';
  String _tagline = 'The world, twice daily';
  bool _ready = false;
  late List<Map<String, dynamic>> _articles;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final saved = jsonMap(StoreScope.of(context).pages['news']);
    _name = saved['name'] as String? ?? _name;
    _tagline = saved['tagline'] as String? ?? _tagline;
    final articles = saved['articles'];
    _articles = articles is List && articles.isNotEmpty
        ? [for (final item in articles) if (item is Map) jsonMap(item)]
        : [
            _story('n1', 'Breaking', 'Night shoot wraps early as storm front clears the coast', 'Production confirmed the final scene wrapped at 21:40, an hour ahead of schedule, after the forecast squall swung south. Crew call for Monday stands at 07:00.', stock(1)),
            _story('n2', 'Local', 'Waterfront night market opens to long queues', 'Forty stalls traded on the pier on Friday night, with organisers reporting more than 4 000 visitors before close.', stock(7)),
            _story('n3', 'Culture', 'The violin maker with a two-year waitlist', 'Her workshop now holds three benches, two apprentices and a small dog called Rosy.', stock(8)),
            _story('n4', 'Sport', 'Harbour swim returns after three-year break', 'Two hundred swimmers entered the bay crossing, the first since the event paused in 2023.', stock(5)),
            _story('n5', 'Weather', 'Warming trend into Thursday, weak front Friday', 'Temperatures climb to 26° inland midweek before a light shower brushes the coast to end the week.', stock(6)),
          ];
  }

  Map<String, dynamic> _story(String id, String tag, String title, String body, String image) => {
    'id': id,
    'tag': tag,
    'title': title,
    'body': body,
    'image': image,
  };

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final today = MaterialLocalizations.of(context).formatFullDate(DateTime.now());
    return ColoredBox(
      color: Colors.black,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                      Text(_tagline.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.4)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Save',
                  onPressed: () => savePhonePage(
                    context,
                    app: 'news',
                    category: 'Apps',
                    initial: '$_name edition',
                    data: {'name': _name, 'tagline': _tagline, 'articles': _articles},
                  ),
                  icon: const Icon(Icons.save_outlined, color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(today.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2)),
          ),
          for (var i = 0; i < _articles.length; i++) _article(_articles[i], i == 0),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('© $_name · Mock edition', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white24, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _article(Map<String, dynamic> article, bool lead) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lead)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(aspectRatio: 16 / 10, child: NetPhoto(url: '${article['image']}')),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: const Color(0xFFDC4A38),
            child: Text('${article['tag']}'.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${article['title']}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: lead ? 21 : 15, height: 1.15)),
                    const SizedBox(height: 4),
                    Text('${article['body']}', maxLines: lead ? 6 : 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white60, fontSize: lead ? 13 : 12.5, height: 1.35)),
                  ],
                ),
              ),
              if (!lead) ...[
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(width: 112, height: 80, child: NetPhoto(url: '${article['image']}')),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class PulseApp extends StatefulWidget {
  const PulseApp({super.key});

  @override
  State<PulseApp> createState() => _PulseAppState();
}

class _PulseAppState extends State<PulseApp> {
  int _steps = 4820;
  int _stepGoal = 10000;
  int _water = 3;
  int _waterGoal = 8;
  int _hr = 72;
  final List<Map<String, dynamic>> _workouts = [];
  Timer? _tick;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (!mounted) return;
      setState(() {
        _steps += 3 + _random.nextInt(12);
        _hr = 66 + _random.nextInt(11);
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  int get _exercise => _workouts.fold<int>(0, (sum, item) => sum + (item['mins'] as int));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ColoredBox(
      color: Colors.black,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text('Fitness', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
          Text(
            '${_weekday(now.weekday)} ${now.day} ${_month(now.month)} · TODAY'.toUpperCase(),
            style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ring(_steps / _stepGoal, const Color(0xFF32D74B), '$_steps', 'of ${(_stepGoal / 1000).round()}k', 'Steps'),
              _ring(_water / _waterGoal, const Color(0xFF0A84FF), '$_water', 'of $_waterGoal', 'Water'),
              _ring(_exercise / 30, const Color(0xFFFF9F0A), '${_exercise}m', 'of 30m', 'Exercise'),
            ],
          ),
          const SizedBox(height: 12),
          _card(
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0x33FF375F), child: Icon(Icons.favorite, color: Color(0xFFFF375F))),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HEART RATE', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                      Text('Resting walk', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                Text('$_hr', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                const Text(' bpm', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          _card(
            child: Column(
              children: [
                _stepper('Step goal', Icons.directions_walk, const Color(0xFF32D74B), '${(_stepGoal / 1000).round()}k', () {
                  setState(() => _stepGoal = math.max(2000, _stepGoal - 1000));
                }, () {
                  setState(() => _stepGoal = math.min(20000, _stepGoal + 1000));
                }),
                const Divider(color: Colors.white10),
                _stepper('Water goal', Icons.water_drop, const Color(0xFF0A84FF), '$_waterGoal glasses', () {
                  setState(() => _waterGoal = math.max(2, _waterGoal - 1));
                }, () {
                  setState(() => _waterGoal = math.min(15, _waterGoal + 1));
                }),
              ],
            ),
          ),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Water today', style: TextStyle(color: Colors.white, fontSize: 13)),
                    const Spacer(),
                    Text('$_water / $_waterGoal', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: [
                    for (var i = 0; i < math.max(_waterGoal, _water); i++)
                      Container(width: 16, height: 24, decoration: BoxDecoration(color: i < _water ? const Color(0xFF0A84FF) : Colors.white10, borderRadius: BorderRadius.circular(3))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => setState(() => _water = math.max(0, _water - 1)), child: const Text('− Glass'))),
                    const SizedBox(width: 8),
                    Expanded(child: FilledButton(onPressed: () => setState(() => _water += 1), child: const Text('+ Glass'))),
                  ],
                ),
              ],
            ),
          ),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Workouts', style: const TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in const [('Run', 20), ('Walk', 15), ('Cycle', 30), ('Gym', 45)])
                      ActionChip(
                        label: Text('+ ${item.$1} ${item.$2}m'),
                        onPressed: () => setState(() {
                          _workouts.insert(0, {'id': 'w-${DateTime.now().microsecondsSinceEpoch}', 'kind': item.$1, 'mins': item.$2});
                        }),
                      ),
                  ],
                ),
                if (_workouts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Tap a quick workout to log it', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                for (final workout in _workouts)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${workout['kind']}', style: const TextStyle(color: Colors.white)),
                    trailing: Text('${workout['mins']} min', style: const TextStyle(color: Colors.white54)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double pct, Color color, String value, String sub, String label) {
    return Column(
      children: [
        SizedBox(
          width: 92,
          height: 92,
          child: CustomPaint(
            painter: _RingPainter(pct.clamp(0, 1), color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(sub.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 8, letterSpacing: 0.6)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }

  Widget _stepper(String label, IconData icon, Color color, String value, VoidCallback minus, VoidCallback plus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13))),
          IconButton(onPressed: minus, icon: const Icon(Icons.remove, color: Colors.white70, size: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          IconButton(onPressed: plus, icon: const Icon(Icons.add, color: Colors.white70, size: 16)),
        ],
      ),
    );
  }

  String _weekday(int day) => const ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][day];
  String _month(int month) => const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month];
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.pct, this.color);

  final double pct;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    final track = Paint()
      ..color = const Color(0x17FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi * 2 * pct, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.pct != pct || oldDelegate.color != color;
}

class RealtyApp extends StatefulWidget {
  const RealtyApp({super.key});

  @override
  State<RealtyApp> createState() => _RealtyAppState();
}

class _RealtyAppState extends State<RealtyApp> {
  bool _ready = false;
  String? _openId;
  final Set<String> _booked = {};
  late List<Map<String, dynamic>> _listings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final saved = jsonMap(StoreScope.of(context).pages['property']);
    final listings = saved['listings'];
    _listings = listings is List && listings.isNotEmpty
        ? [for (final item in listings) if (item is Map) jsonMap(item)]
        : [
            _home('p1', 'R 4 250 000', '22 Vlei Road, Cape Town', '3', '2', '142 m²', 'North-facing family home steps from the vlei, with a courtyard braai and restored oregon floors.', stock(0)),
            _home('p2', 'R 2 995 000', '8A Kloof Street, Gardens', '2', '1', '94 m²', 'Apartment in a Victorian block with mountain views from the shared roof terrace.', stock(9)),
            _home('p3', 'R 6 750 000', '14 Protea Lane, Constantia', '4', '3', '210 m²', 'Classic gable with a mature garden, pool and cottage ideal for guests or a studio.', stock(4)),
            _home('p4', 'R 1 695 000', '77 Beach Road, Sea Point', '1', '1', '58 m²', 'Compact studio a block off the promenade, ideal first step onto the ladder.', stock(2)),
          ];
  }

  Map<String, dynamic> _home(String id, String price, String address, String beds, String baths, String size, String blurb, String image) => {
    'id': id,
    'price': price,
    'address': address,
    'beds': beds,
    'baths': baths,
    'size': size,
    'blurb': blurb,
    'image': image,
  };

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    Map<String, dynamic>? open;
    for (final listing in _listings) {
      if (listing['id'] == _openId) open = listing;
    }
    if (open != null) return _detail(open);
    return ColoredBox(
      color: Colors.black,
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text('Realty', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('FIND THE ONE', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.4)),
          ),
          for (final listing in _listings)
            InkWell(
              onTap: () => setState(() => _openId = listing['id'] as String),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(aspectRatio: 16 / 9, child: NetPhoto(url: '${listing['image']}')),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${listing['price']}', style: const TextStyle(color: Color(0xFF32D74B), fontSize: 18, fontWeight: FontWeight.w700)),
                        Text('${listing['address']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('${listing['beds']} bed · ${listing['baths']} bath · ${listing['size']}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _detail(Map<String, dynamic> listing) {
    final booked = _booked.contains(listing['id']);
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(onPressed: () => setState(() => _openId = null), icon: const Icon(Icons.arrow_back, color: Colors.white)),
              Expanded(child: Text('${listing['address']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
            ],
          ),
          Expanded(
            child: ListView(
              children: [
                AspectRatio(aspectRatio: 4 / 3, child: NetPhoto(url: '${listing['image']}')),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${listing['price']}', style: const TextStyle(color: Color(0xFF32D74B), fontSize: 22, fontWeight: FontWeight.w700)),
                      Text('${listing['address']}', style: const TextStyle(color: Colors.white60)),
                      const SizedBox(height: 12),
                      Text('${listing['beds']} bed   ${listing['baths']} bath   ${listing['size']}', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      Text('${listing['blurb']}', style: const TextStyle(color: Colors.white, height: 1.4)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: booked ? Colors.white10 : const Color(0xFF32D74B),
                            foregroundColor: booked ? Colors.white70 : Colors.black,
                          ),
                          onPressed: () => setState(() {
                            if (booked) {
                              _booked.remove(listing['id']);
                            } else {
                              _booked.add(listing['id'] as String);
                            }
                          }),
                          child: Text(booked ? 'Viewing booked ✓' : 'Book a viewing'),
                        ),
                      ),
                    ],
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

class InboxApp extends StatefulWidget {
  const InboxApp({super.key, this.extra = const []});

  final List<Map<String, dynamic>> extra;

  @override
  State<InboxApp> createState() => _InboxAppState();
}

class _InboxAppState extends State<InboxApp> {
  final _query = TextEditingController();
  int? _openId;
  late final List<Map<String, dynamic>> _emails = [
    ...widget.extra,

    {
      'id': 1,
      'from': 'Production Desk',
      'subject': 'Call sheet - Day 14',
      'time': '9:41 AM',
      'unread': true,
      'thread': [
        {'who': 'them', 'body': "Crew,\n\nWe're relocating to the warehouse unit for the night shoot tonight. Call time 18:00 sharp. Parking is on the east lot - do not block the loading bay.\n\nThe VFX team will be running the chroma inserts after midnight, so keep the prop phones on the control channel until wrap.\n\n- Production", 'time': '9:41 AM'},
      ],
    },
    {
      'id': 2,
      'from': 'VFX Supervisor',
      'subject': 'Tracking marks - approved',
      'time': '8:02 AM',
      'unread': true,
      'thread': [
        {'who': 'them', 'body': 'Tracking marks are cleared for the insert shots. Crosshair and L-bar are good to go. Skip the dot grid for the close-ups - it reads on the lens.', 'time': '8:02 AM'},
      ],
    },
    {
      'id': 3,
      'from': 'Script',
      'subject': 'Revised pages - Scene 47',
      'time': 'Yesterday',
      'unread': false,
      'thread': [
        {'who': 'them', 'body': 'Revised pages attached. The phone call beats in Scene 47 have been trimmed - we lose the second ring and the voicemail. New sides are in your inbox.', 'time': 'Yesterday'},
      ],
    },
    {
      'id': 4,
      'from': 'Post',
      'subject': 'Playback reference uploaded',
      'time': 'Yesterday',
      'unread': false,
      'thread': [
        {'who': 'them', 'body': 'Reference clips for the prop screen inserts are ready to review. Link in the shared drive under /prop-screens/ref.', 'time': 'Yesterday'},
      ],
    },
    {
      'id': 5,
      'from': 'Locations',
      'subject': 'Unit move confirmed',
      'time': 'Mon',
      'unread': false,
      'thread': [
        {'who': 'them', 'body': 'Company move confirmed for 16:30. Trucks roll at 16:00. Everyone off the lot by 15:45.', 'time': 'Mon'},
      ],
    },
  ];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? open;
    for (final email in _emails) {
      if (email['id'] == _openId) open = email;
    }
    if (open != null) return _thread(open);
    final q = _query.text.trim().toLowerCase();
    final visible = _emails.where((email) {
      return '${email['from']}'.toLowerCase().contains(q) || '${email['subject']}'.toLowerCase().contains(q);
    }).toList();
    final unread = _emails.where((email) => email['unread'] == true).length;
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text('Inbox', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                if (unread > 0)
                  Text('$unread', style: const TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _query,
              readOnly: true,
              showCursor: true,
              onTap: () => openIosKeyboard(
                context,
                _query,
                onChanged: (_) => setState(() {}),
              ),
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.white38),
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final email in visible)
                  ListTile(
                    onTap: () => setState(() {
                      email['unread'] = false;
                      _openId = email['id'] as int;
                    }),
                    title: Text('${email['from']}', style: TextStyle(color: Colors.white, fontWeight: email['unread'] == true ? FontWeight.w700 : FontWeight.w500)),
                    subtitle: Text('${email['subject']}\n${(email['thread'] as List).first['body']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)),
                    trailing: Text('${email['time']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thread(Map<String, dynamic> email) {
    final thread = email['thread'] as List;
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(onPressed: () => setState(() => _openId = null), icon: const Icon(Icons.arrow_back, color: Colors.white)),
              Expanded(child: Text('${email['subject']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final message in thread)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message['who'] == 'me' ? const Color(0xFF0A84FF) : const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('${message['body']}', style: const TextStyle(color: Colors.white, height: 1.35)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PropBrowser extends StatefulWidget {
  const PropBrowser({super.key});

  @override
  State<PropBrowser> createState() => _PropBrowserState();
}

class _PropBrowserState extends State<PropBrowser> {
  final _url = TextEditingController();
  final List<String> _history = [];
  int _index = -1;
  String? _current;
  bool _loading = false;

  static const _quick = [
    ('Wikipedia', 'https://en.wikipedia.org/wiki/Main_Page', Color(0xFF64748B)),
    ('Wiktionary', 'https://en.wiktionary.org/wiki/Wiktionary:Main_Page', Color(0xFF475569)),
    ('OpenStreetMap', 'https://www.openstreetmap.org/export/embed.html?bbox=18.35,-33.95,18.55,-33.85&layer=mapnik', Color(0xFF3F8F5F)),
    ('Example.com', 'https://example.com', Color(0xFF8A8A8E)),
  ];

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  String? _normalize(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('http://') || text.startsWith('https://')) return text;
    if (RegExp(r'^[\w-]+(\.[\w-]+)+').hasMatch(text)) return 'https://$text';
    return 'https://en.wikipedia.org/wiki/Special:Search?search=${Uri.encodeQueryComponent(text)}';
  }

  void _go(String raw) {
    final target = _normalize(raw);
    if (target == null) return;
    setState(() {
      _history
        ..removeRange(_index + 1, _history.length)
        ..add(target);
      _index = _history.length - 1;
      _current = target;
      _url.text = target;
      _loading = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted && _current == target) setState(() => _loading = false);
    });
  }

  void _jump(int index) {
    if (index < 0 || index >= _history.length) return;
    setState(() {
      _index = index;
      _current = _history[index];
      _url.text = _current!;
      _loading = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF2F2F7),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                IconButton(tooltip: 'Start page', onPressed: () => setState(() { _current = null; _url.clear(); _loading = false; }), icon: const Icon(Icons.home, size: 18, color: Colors.black87)),
                IconButton(tooltip: 'Back', onPressed: _index <= 0 ? null : () => _jump(_index - 1), icon: const Icon(Icons.arrow_back, size: 18)),
                IconButton(tooltip: 'Forward', onPressed: _index >= _history.length - 1 ? null : () => _jump(_index + 1), icon: const Icon(Icons.arrow_forward, size: 18)),
                IconButton(tooltip: 'Reload', onPressed: _current == null ? null : () => _go(_current!), icon: const Icon(Icons.refresh, size: 18)),
                Expanded(
                  child: TextField(
                    controller: _url,
                    readOnly: true,
                    showCursor: true,
                    onTap: () => openIosKeyboard(
                      context,
                      _url,
                      onChanged: (value) {
                        if (value.endsWith(' ')) _go(value.trim());
                      },
                    ),
                    onSubmitted: _go,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search or enter address',
                      prefixIcon: const Icon(Icons.language, size: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0x1A000000))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2, color: Color(0xFF0A84FF)),
          Expanded(
            child: _current == null
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                    children: [
                      const Center(child: CircleAvatar(radius: 28, backgroundColor: Color(0xFF0A84FF), child: Icon(Icons.language, color: Colors.white, size: 26))),
                      const SizedBox(height: 10),
                      const Center(child: Text('Browser', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111111)))),
                      const Center(child: Text('Live web, right on the mock phone', style: TextStyle(fontSize: 11, color: Colors.black45))),
                      const SizedBox(height: 18),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.4,
                        children: [
                          for (final site in _quick)
                            InkWell(
                              onTap: () => _go(site.$2),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  children: [
                                    CircleAvatar(radius: 14, backgroundColor: site.$3, child: Text(site.$1[0], style: const TextStyle(color: Colors.white, fontSize: 12))),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(site.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Type an address or a search. Some sites refuse to load inside other apps and will stay blank.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: Colors.black38),
                      ),
                    ],
                  )
                : BrowserFrame(url: _current!),
          ),
        ],
      ),
    );
  }
}

class PropMusic extends StatefulWidget {
  const PropMusic({super.key});

  @override
  State<PropMusic> createState() => _PropMusicState();
}

class _PropMusicState extends State<PropMusic> {
  final List<({String id, String name, String path})> _tracks = [];
  String? _currentId;
  bool _playing = false;
  bool _repeat = false;
  bool _player = false;
  String _error = '';
  VideoPlayerController? _audio;

  @override
  void dispose() {
    _audio?.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final file = await FilePicker.pickFile(type: FileType.audio);
    if (file == null) return;
    final path = await persistPickedImage(file);
    if (!mounted) return;
    if (path == null) {
      setState(() => _error = 'Could not import this file');
      return;
    }
    setState(() {
      _error = '';
      _tracks.add((id: 't-${DateTime.now().microsecondsSinceEpoch}', name: file.name, path: path));
    });
  }

  Future<void> _play(String id) async {
    ({String id, String name, String path})? track;
    for (final item in _tracks) {
      if (item.id == id) track = item;
    }
    if (track == null) return;
    if (_currentId == id && _audio != null) {
      if (_audio!.value.isPlaying) {
        await _audio!.pause();
        setState(() => _playing = false);
      } else {
        await _audio!.play();
        setState(() => _playing = true);
      }
      return;
    }
    final next = playerForPath(track.path);
    if (next == null) {
      setState(() => _error = 'Playback needs the installed app on this machine.');
      return;
    }
    await _audio?.dispose();
    _audio = next;
    await _audio!.initialize();
    await _audio!.play();
    if (!mounted) return;
    setState(() {
      _currentId = id;
      _playing = true;
      _player = true;
    });
    _audio!.addListener(() {
      if (!mounted || _audio == null) return;
      final value = _audio!.value;
      if (value.isCompleted) {
        if (_repeat) {
          _audio!.seekTo(Duration.zero);
          _audio!.play();
        } else {
          _step(1);
        }
      }
      setState(() => _playing = value.isPlaying);
    });
  }

  void _step(int dir) {
    if (_tracks.isEmpty) return;
    final index = _tracks.indexWhere((track) => track.id == _currentId);
    final next = index < 0 ? 0 : (index + dir + _tracks.length) % _tracks.length;
    _play(_tracks[next].id);
  }

  @override
  Widget build(BuildContext context) {
    ({String id, String name, String path})? current;
    for (final item in _tracks) {
      if (item.id == _currentId) current = item;
    }
    if (_player && current != null) {
      final value = _audio?.value;
      final position = value?.position ?? Duration.zero;
      final duration = value?.duration ?? Duration.zero;
      return ColoredBox(
        color: const Color(0xFF0C0D14),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(onPressed: () => setState(() => _player = false), icon: const Icon(Icons.chevron_left, color: Colors.white70)),
                  const Expanded(child: Text('NOW PLAYING', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.4))),
                  IconButton(
                    onPressed: () => setState(() => _repeat = !_repeat),
                    icon: Icon(Icons.repeat, color: _repeat ? const Color(0xFFFC3C44) : Colors.white38),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(colors: [Color(0xFFFC3C44), Color(0xFF7A1FA2)]),
              ),
              child: const Icon(Icons.music_note, color: Colors.white, size: 52),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(current.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            Slider(
              value: duration.inMilliseconds == 0 ? 0 : position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
              max: math.max(1, duration.inMilliseconds).toDouble(),
              activeColor: const Color(0xFFFC3C44),
              onChanged: (next) => _audio?.seekTo(Duration(milliseconds: next.round())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () => _step(-1), icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32)),
                const SizedBox(width: 12),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFC3C44), shape: const CircleBorder(), padding: const EdgeInsets.all(18)),
                  onPressed: () => _play(current!.id),
                  child: Icon(_playing ? Icons.pause : Icons.play_arrow, size: 28),
                ),
                const SizedBox(width: 12),
                IconButton(onPressed: () => _step(1), icon: const Icon(Icons.skip_next, color: Colors.white, size: 32)),
              ],
            ),
            const Spacer(),
          ],
        ),
      );
    }
    return ColoredBox(
      color: const Color(0xFF0C0D14),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                const Text('Music', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(onPressed: _import, icon: const Icon(Icons.upload, size: 14), label: const Text('Import')),
              ],
            ),
          ),
          if (_error.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(_error, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
          Expanded(
            child: _tracks.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No tracks yet. Import music files from this device to play them on the mock phone.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      for (final track in _tracks)
                        ListTile(
                          onTap: () => _play(track.id),
                          leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.music_note, color: Colors.white60)),
                          title: Text(track.name, style: TextStyle(color: track.id == _currentId ? const Color(0xFFFC3C44) : Colors.white)),
                          trailing: IconButton(
                            onPressed: () => setState(() => _tracks.removeWhere((item) => item.id == track.id)),
                            icon: const Icon(Icons.delete_outline, color: Colors.white30),
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

class WebdeckApp extends StatefulWidget {
  const WebdeckApp({super.key});

  @override
  State<WebdeckApp> createState() => _WebdeckAppState();
}

class _WebdeckAppState extends State<WebdeckApp> {
  String? _openId;
  late final List<Map<String, dynamic>> _sites = [
    {
      'id': 'ledger',
      'name': 'The Daily Ledger',
      'url': 'dailyledger.co',
      'hue': 0xFFB91C1C,
      'tagline': 'Independent news since 1962',
      'heading': 'Harbour lights return as the waterfront reopens',
      'sub': 'After three years behind scaffolding, the old dock district welcomes the public back this weekend.',
      'image': stock(1),
    },
    {
      'id': 'brewbean',
      'name': 'Brew & Bean',
      'url': 'brewandbean.coffee',
      'hue': 0xFF92400E,
      'tagline': 'Coffee, slowly',
      'heading': 'Slow mornings, faster coffee',
      'sub': 'Single-origin espresso, baked goods before eight, and a corner seat with your name on it.',
      'image': stock(10),
    },
    {
      'id': 'trailhead',
      'name': 'Trailhead Outfitters',
      'url': 'trailheadgear.com',
      'hue': 0xFF15803D,
      'tagline': 'Equipment for the long way round',
      'heading': 'Gear that outlasts the trip',
      'sub': 'Field-tested packs, tents and layers - built for the mountain, priced for the valley.',
      'image': stock(3),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final open = _sites.where((site) => site['id'] == _openId);
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF2F2F7),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                if (_openId != null)
                  IconButton(onPressed: () => setState(() => _openId = null), icon: const Icon(Icons.arrow_back, size: 18))
                else
                  const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.language, size: 18)),
                Expanded(
                  child: Text(
                    open.isEmpty ? 'Webdeck' : '${open.first['url']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: open.isEmpty
                ? ListView(
                    children: [
                      for (final site in _sites)
                        ListTile(
                          leading: CircleAvatar(backgroundColor: Color(site['hue'] as int), child: Text('${site['name']}'.substring(0, 1), style: const TextStyle(color: Colors.white))),
                          title: Text('${site['name']}'),
                          subtitle: Text('${site['url']}'),
                          onTap: () => setState(() => _openId = site['id'] as String),
                        ),
                    ],
                  )
                : ListView(
                    children: [
                      AspectRatio(aspectRatio: 16 / 9, child: NetPhoto(url: '${open.first['image']}')),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${open.first['tagline']}'.toUpperCase(), style: TextStyle(color: Color(open.first['hue'] as int), fontSize: 11, letterSpacing: 1)),
                            const SizedBox(height: 6),
                            Text('${open.first['heading']}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.1)),
                            const SizedBox(height: 8),
                            Text('${open.first['sub']}', style: const TextStyle(color: Colors.black54, height: 1.4)),
                          ],
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

class VidcallApp extends StatefulWidget {
  const VidcallApp({super.key, required this.contacts});

  final List<ContactCard> contacts;

  @override
  State<VidcallApp> createState() => _VidcallAppState();
}

class _VidcallAppState extends State<VidcallApp> {
  final LiveLens _lens = LiveLens();
  ContactCard? _picked;
  bool _inCall = false;
  bool _muted = false;
  int _secs = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _lens.close();
    super.dispose();
  }

  void _start(ContactCard contact) {
    setState(() {
      _picked = contact;
      _inCall = true;
      _secs = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secs += 1);
    });
    _lens.open(video: true, audio: false, front: true).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _hangUp() {
    _timer?.cancel();
    _lens.close();
    setState(() => _inCall = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_inCall && _picked != null) {
      final minutes = (_secs ~/ 60).toString().padLeft(2, '0');
      final seconds = (_secs % 60).toString().padLeft(2, '0');
      return ColoredBox(
        color: const Color(0xFF00B140),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_lens.ready)
              LensView(lens: _lens, mirror: true)
            else if (_lens.denied)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'Allow camera access to use the lens.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              )
            else
              const Center(child: Icon(Icons.add, size: 42, color: Colors.black87)),
            Positioned(
              top: 28,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(_picked!.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                  Text('$minutes:$seconds', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: () {
                      setState(() => _muted = !_muted);
                      _lens.setMic(!_muted);
                    },
                    icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                  ),
                  const SizedBox(width: 18),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFFF453A)),
                    onPressed: _hangUp,
                    icon: const Icon(Icons.call_end),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text('Vidcall', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
          ),
          for (final contact in widget.contacts)
            ListTile(
              leading: HueAvatar(name: contact.name, hue: colorForName(contact.name)),
              title: Text(contact.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(contact.number, style: const TextStyle(color: Colors.white54)),
              trailing: const Icon(Icons.videocam, color: Color(0xFF32D74B)),
              onTap: () => _start(contact),
            ),
        ],
      ),
    );
  }
}
