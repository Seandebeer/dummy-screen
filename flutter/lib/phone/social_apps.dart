import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../widgets/prompt.dart';
import 'social_feed.dart';

const _stockIds = [
  'photo-1506744038136-46273834b3fb',
  'photo-1501594907352-04cda38ebc29',
  'photo-1519681393784-d120267933ba',
  'photo-1470071459604-3b5ec3a7fe05',
  'photo-1441974231531-c6227db76b6e',
  'photo-1469474968028-5162334e2825',
  'photo-1493246507139-91e8fad4d8d6',
  'photo-1472214103451-9374bd1c798e',
  'photo-1518791841217-8f162f1e0700',
  'photo-1517849845537-26462ac246c9',
  'photo-1504674900247-0877499adc3b',
  'photo-1512621776951-a57141f2eefd',
  'photo-1514525253161-7a46d19cd819',
  'photo-1494790108377-be9c29b29330',
  'photo-1500648767791-00dcc994a43e',
  'photo-1544005313-94ddf0286df2',
];

String stock(int index) =>
    'https://images.unsplash.com/${_stockIds[index % _stockIds.length]}?auto=format&fit=crop&w=800&q=80';

String fmtCount(num value) {
  final number = value.toDouble();
  if (number >= 1000000) {
    final text = (number / 1000000).toStringAsFixed(number >= 10000000 ? 0 : 1);
    return '${text.replaceAll(RegExp(r'\.0$'), '')}M';
  }
  if (number >= 1000) {
    final text = (number / 1000).toStringAsFixed(number >= 10000 ? 0 : 1);
    return '${text.replaceAll(RegExp(r'\.0$'), '')}K';
  }
  return number.round().toString();
}

class HueAvatar extends StatelessWidget {
  const HueAvatar({super.key, required this.name, required this.hue, this.size = 36});

  final String name;
  final Color hue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: hue, shape: BoxShape.circle),
      child: Text(
        letters.isEmpty ? '?' : letters,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class NetPhoto extends StatelessWidget {
  const NetPhoto({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const ColoredBox(color: Color(0xFF1C1C1E));
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stack) => const ColoredBox(color: Color(0xFF1C1C1E)),
    );
  }
}

Map<String, dynamic> _savedPage(BuildContext context, String app) {
  final raw = StoreScope.of(context).pages[app];
  if (raw is Map) return jsonMap(raw);
  return {};
}

Future<void> savePhonePage(
  BuildContext context, {
  required String app,
  required String category,
  required String initial,
  required Map<String, dynamic> data,
}) async {
  final name = await promptText(context, title: 'Save page', initial: initial);
  if (name == null || name.trim().isEmpty || !context.mounted) return;
  final store = StoreScope.of(context);
  store.setPage(app, data);
  store.upsertSaved(
    SavedLayout(
      id: 's-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      skin: 'modern',
      clockOffsetMinutes: 0,
      notes: '',
      vfxColor: 'green',
      vfxMarks: const [],
      uiMarkers: const [],
      kind: 'page',
      category: category,
      payload: {'app': app, 'data': data},
    ),
  );
}

class GrapevineApp extends StatefulWidget {
  const GrapevineApp({super.key});

  @override
  State<GrapevineApp> createState() => _GrapevineAppState();
}

class _GrapevineAppState extends State<GrapevineApp> {
  String _name = 'Grapevine';
  String _profile = 'Alex Carter';
  String _bio = 'Coffee, cameras and long drives. Opinions are my own.';
  int _friends = 1204;
  String _tab = 'feed';
  bool _editing = false;
  late List<Map<String, dynamic>> _posts;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final saved = _savedPage(context, 'facepage');
    _name = saved['name'] as String? ?? _name;
    final profile = jsonMap(saved['profile']);
    _profile = profile['name'] as String? ?? _profile;
    _bio = profile['bio'] as String? ?? _bio;
    _friends = (profile['friends'] as num?)?.toInt() ?? _friends;
    _posts = topUpFeed(saved['posts'], grapevinePosts());
  }

  Map<String, dynamic> _post(
    String id,
    String author,
    int hue,
    String time,
    String text,
    String image,
    int likes,
    int comments,
    int shares,
  ) => {
    'id': id,
    'author': author,
    'hue': hue,
    'time': time,
    'text': text,
    'image': image,
    'likes': likes,
    'comments': comments,
    'shares': shares,
    'liked': false,
  };

  Map<String, dynamic> _snapshot() => {
    'name': _name,
    'profile': {'name': _profile, 'bio': _bio, 'friends': _friends},
    'posts': _posts,
  };

  void _keep() {
    StoreScope.of(context).setPage('facepage', _snapshot());
  }

  Widget _editText(String value, ValueChanged<String> onChanged, TextStyle style, {int lines = 1}) {
    if (!_editing) return Text(value, style: style);
    return TextFormField(
      initialValue: value,
      style: style,
      maxLines: lines,
      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
      onChanged: (next) {
        onChanged(next);
        _keep();
      },
    );
  }

  Future<void> _compose() async {
    final text = await promptText(context, title: "What's on your mind?", confirm: 'Post');
    if (text == null || text.trim().isEmpty) return;
    setState(() {
      _posts.insert(0, _post('fp-${DateTime.now().microsecondsSinceEpoch}', _profile, 0xFF1877F2, 'Just now', text.trim(), '', 0, 0, 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    const blue = Color(0xFF1877F2);
    return ColoredBox(
      color: const Color(0xFFF0F2F5),
      child: Column(
        children: [
          Container(
            color: blue,
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: [
                Text(_name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  tooltip: 'Save',
                  onPressed: () => savePhonePage(context, app: 'facepage', category: 'Socials', initial: '$_name page', data: _snapshot()),
                  icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => setState(() => _editing = !_editing),
                  icon: Icon(Icons.edit, color: _editing ? Colors.white : Colors.white70, size: 18),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tab == 'profile' ? _profileView(blue) : _feed(blue),
          ),
          Material(
            color: Colors.white,
            child: Row(
              children: [
                _tabButton('feed', Icons.home, 'Feed', blue),
                _tabButton('profile', Icons.person, 'Profile', blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feed(Color blue) {
    return ListView(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              HueAvatar(name: _profile, hue: blue, size: 36),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _compose,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "What's on your mind, ${_profile.split(' ').first}?",
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final post in _posts) _card(post, blue),
      ],
    );
  }

  Widget _card(Map<String, dynamic> post, Color blue) {
    final liked = post['liked'] == true;
    final image = post['image'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: HueAvatar(name: '${post['author']}', hue: Color(post['hue'] as int? ?? 0xFF1877F2), size: 36),
            title: _editText(
              '${post['author']}',
              (value) => post['author'] = value,
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
            ),
            subtitle: _editText(
              '${post['time']}',
              (value) => post['time'] = value,
              const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            dense: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: _editText(
              '${post['text']}',
              (value) => post['text'] = value,
              const TextStyle(fontSize: 14, height: 1.3, color: Colors.black),
              lines: 4,
            ),
          ),
          if (image.isNotEmpty) AspectRatio(aspectRatio: 4 / 3, child: NetPhoto(url: image)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _editText(
                  '${post['likes']}',
                  (value) => post['likes'] = int.tryParse(value) ?? post['likes'],
                  const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const Spacer(),
                _editText(
                  '${post['comments']}',
                  (value) => post['comments'] = int.tryParse(value) ?? post['comments'],
                  const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                _editText(
                  '${post['shares']}',
                  (value) => post['shares'] = int.tryParse(value) ?? post['shares'],
                  const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              _action(liked ? Icons.thumb_up : Icons.thumb_up_outlined, 'Like', liked ? blue : Colors.black54, () {
                setState(() {
                  post['liked'] = !liked;
                  post['likes'] = (post['likes'] as int) + (liked ? -1 : 1);
                });
              }),
              _action(Icons.chat_bubble_outline, 'Comment', Colors.black54, () {
                setState(() => post['comments'] = (post['comments'] as int) + 1);
              }),
              _action(Icons.share_outlined, 'Share', Colors.black54, () {
                setState(() => post['shares'] = (post['shares'] as int) + 1);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileView(Color blue) {
    final photos = _posts.where((post) => (post['image'] as String? ?? '').isNotEmpty);
    return ListView(
      children: [
        Container(height: 96, color: blue),
        Transform.translate(
          offset: const Offset(0, -36),
          child: Column(
            children: [
              HueAvatar(name: _profile, hue: blue, size: 72),
              const SizedBox(height: 8),
              _editText(
                _profile,
                (value) => _profile = value,
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: _editText(
                  _bio,
                  (value) => _bio = value,
                  const TextStyle(fontSize: 12, color: Colors.black87),
                  lines: 3,
                ),
              ),
              _editText(
                '$_friends',
                (value) => _friends = int.tryParse(value) ?? _friends,
                const TextStyle(color: Color(0xFF1877F2), fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: [
            for (final post in photos)
              NetPhoto(url: post['image'] as String),
          ],
        ),
      ],
    );
  }

  Widget _tabButton(String id, IconData icon, String label, Color blue) {
    final on = _tab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = id),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Icon(icon, size: 20, color: on ? blue : Colors.black45),
              Text(label, style: TextStyle(fontSize: 10, color: on ? blue : Colors.black45, fontWeight: on ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}

class LumeApp extends StatefulWidget {
  const LumeApp({super.key});

  @override
  State<LumeApp> createState() => _LumeAppState();
}

class _LumeAppState extends State<LumeApp> {
  String _name = 'Lume';
  String _handle = 'alex.carter';
  String _profile = 'Alex Carter';
  String _bio = 'Filmmaker & coffee enthusiast\nCape Town / wherever the light is';
  int _followers = 8432;
  int _following = 312;
  String _tab = 'home';
  bool _ready = false;
  late List<Map<String, dynamic>> _posts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final saved = _savedPage(context, 'photogram');
    _name = saved['name'] as String? ?? _name;
    final profile = jsonMap(saved['profile']);
    _profile = profile['name'] as String? ?? _profile;
    _handle = profile['handle'] as String? ?? _handle;
    _bio = profile['bio'] as String? ?? _bio;
    _followers = (profile['followers'] as num?)?.toInt() ?? _followers;
    _following = (profile['following'] as num?)?.toInt() ?? _following;
    _posts = topUpFeed(saved['posts'], lumePosts());
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final visible = _tab == 'liked' ? _posts.where((post) => post['liked'] == true).toList() : _posts;
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
            child: Row(
              children: [
                Text(_name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)),
                const Spacer(),
                IconButton(
                  tooltip: 'Save',
                  onPressed: () => savePhonePage(
                    context,
                    app: 'photogram',
                    category: 'Socials',
                    initial: '$_name page',
                    data: {
                      'name': _name,
                      'profile': {
                        'name': _profile,
                        'handle': _handle,
                        'bio': _bio,
                        'followers': _followers,
                        'following': _following,
                      },
                      'posts': _posts,
                    },
                  ),
                  icon: const Icon(Icons.save_outlined, size: 18),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tab == 'profile'
                ? _profileGrid()
                : ListView(
                    children: [
                      SizedBox(
                        height: 78,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          children: [
                            _story('Your story', const Color(0xFF262626), false),
                            for (final post in _posts) _story('${post['author']}', Color(post['hue'] as int? ?? 0xFF833AB4), true),
                          ],
                        ),
                      ),
                      for (final post in visible) _card(post),
                    ],
                  ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              _nav('home', Icons.home_outlined),
              _nav('liked', Icons.favorite_border),
              _nav('profile', Icons.person_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _story(String name, Color hue, bool ring) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ring
                  ? const LinearGradient(colors: [Color(0xFFFEDA75), Color(0xFFFA7E1E), Color(0xFFD62976), Color(0xFF4F5BD5)])
                  : null,
              border: ring ? null : Border.all(color: Colors.black26),
            ),
            child: HueAvatar(name: name, hue: hue, size: 46),
          ),
          const SizedBox(height: 2),
          SizedBox(width: 64, child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> post) {
    final liked = post['liked'] == true;
    final saved = post['saved'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          leading: HueAvatar(name: '${post['author']}', hue: Color(post['hue'] as int? ?? 0xFF833AB4), size: 30),
          title: Text('${post['author']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        AspectRatio(aspectRatio: 1, child: NetPhoto(url: '${post['image']}')),
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                post['liked'] = !liked;
                post['likes'] = (post['likes'] as int) + (liked ? -1 : 1);
              }),
              icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? const Color(0xFFFF3040) : const Color(0xFF262626)),
            ),
            IconButton(
              onPressed: () => setState(() => post['comments'] = (post['comments'] as int) + 1),
              icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF262626)),
            ),
            const Icon(Icons.send_outlined, color: Color(0xFF262626)),
            const Spacer(),
            IconButton(
              onPressed: () => setState(() => post['saved'] = !saved),
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: const Color(0xFF262626)),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${post['likes']} likes', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text.rich(TextSpan(children: [
                TextSpan(text: '${post['author']} ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                TextSpan(text: '${post['caption']}', style: const TextStyle(fontSize: 13)),
              ])),
              Text('View all ${post['comments']} comments', style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileGrid() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            HueAvatar(name: _profile, hue: const Color(0xFF833AB4), size: 72),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('${_posts.length}', 'Posts'),
                  _stat(fmtCount(_followers), 'Followers'),
                  _stat(fmtCount(_following), 'Following'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(_profile, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(_bio, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: [for (final post in _posts) NetPhoto(url: '${post['image']}')],
        ),
      ],
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _nav(String id, IconData icon) {
    final on = _tab == id;
    return Expanded(
      child: IconButton(
        onPressed: () => setState(() => _tab = id),
        icon: Icon(icon, color: on ? Colors.black : Colors.black45),
      ),
    );
  }
}

class StreamlyApp extends StatefulWidget {
  const StreamlyApp({super.key});

  @override
  State<StreamlyApp> createState() => _StreamlyAppState();
}

class _StreamlyAppState extends State<StreamlyApp> {
  String _name = 'Streamly';
  String _tab = 'home';
  String _chip = 'All';
  String? _watchId;
  bool _ready = false;
  late List<Map<String, dynamic>> _videos;
  final Map<String, bool> _subs = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final saved = _savedPage(context, 'vidtube');
    _name = saved['name'] as String? ?? _name;
    _videos = topUpFeed(saved['videos'], streamlyVideos());
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final cats = ['All', ...{for (final video in _videos) '${video['cat']}'}];
    final visible = _chip == 'All' ? _videos : _videos.where((video) => video['cat'] == _chip).toList();
    Map<String, dynamic>? watch;
    for (final video in _videos) {
      if (video['id'] == _watchId) watch = video;
    }
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
            child: Row(
              children: [
                if (_tab == 'watch')
                  IconButton(onPressed: () => setState(() => _tab = 'home'), icon: const Icon(Icons.arrow_back))
                else ...[
                  Container(
                    width: 32,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xFFFF0000), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(_name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                ],
              ],
            ),
          ),
          Expanded(
            child: _tab == 'watch' && watch != null
                ? _watch(watch)
                : ListView(
                    children: [
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          children: [
                            for (final cat in cats)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: _chip == cat,
                                  onSelected: (_) => setState(() => _chip = cat),
                                ),
                              ),
                          ],
                        ),
                      ),
                      for (final video in (_tab == 'subs' ? visible.where((video) => _subs[video['channel']] == true) : visible))
                        _card(video),
                    ],
                  ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              _nav('home', Icons.home_outlined, 'Home'),
              _nav('subs', Icons.subscriptions_outlined, 'Subscriptions'),
              _nav('you', Icons.person_outline, 'You'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> video) {
    return InkWell(
      onTap: () => setState(() {
        _watchId = video['id'] as String;
        _tab = 'watch';
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetPhoto(url: '${video['image']}'),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    color: const Color(0xBF000000),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    child: Text('${video['duration']}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: HueAvatar(name: '${video['channel']}', hue: Color(video['chHue'] as int? ?? 0xFF1877F2), size: 34),
            title: Text('${video['title']}', maxLines: 2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            subtitle: Text('${video['channel']} · ${fmtCount(video['views'] as num)} views · ${video['age']}', style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _watch(Map<String, dynamic> video) {
    final channel = '${video['channel']}';
    final subbed = _subs[channel] == true;
    return ListView(
      children: [
        AspectRatio(aspectRatio: 16 / 9, child: NetPhoto(url: '${video['image']}')),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${video['title']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('${fmtCount(video['views'] as num)} views · ${video['age']}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                children: [
                  HueAvatar(name: channel, hue: Color(video['chHue'] as int? ?? 0xFF1877F2)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(channel, style: const TextStyle(fontWeight: FontWeight.w600))),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: subbed ? const Color(0xFFE5E5E5) : Colors.black, foregroundColor: subbed ? Colors.black : Colors.white),
                    onPressed: () => setState(() => _subs[channel] = !subbed),
                    child: Text(subbed ? 'Subscribed' : 'Subscribe'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nav(String id, IconData icon, String label) {
    final on = _tab == id || (id == 'home' && _tab == 'watch');
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = id),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Icon(icon, size: 20, color: on ? Colors.black : Colors.black45),
              Text(label, style: TextStyle(fontSize: 10, color: on ? Colors.black : Colors.black45)),
            ],
          ),
        ),
      ),
    );
  }
}

class FlickdeckApp extends StatefulWidget {
  const FlickdeckApp({super.key});

  @override
  State<FlickdeckApp> createState() => _FlickdeckAppState();
}

class _FlickdeckAppState extends State<FlickdeckApp> {
  String _feed = 'foryou';
  String _tab = 'home';
  bool _ready = false;
  final List<String> _following = ['dan.m', 'sara.lane'];
  late List<Map<String, dynamic>> _posts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final saved = _savedPage(context, 'quicktok');
    _posts = topUpFeed(saved['posts'], flickdeckPosts());
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final posts = _feed == 'following'
        ? _posts.where((post) => _following.contains(post['author'])).toList()
        : _posts;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          if (_tab == 'home')
            PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: posts.length,
              itemBuilder: (context, index) => _slide(posts[index]),
            )
          else
            _me(),
          if (_tab == 'home')
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _feedButton('following', 'Following'),
                  Container(width: 1, height: 14, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 12)),
                  _feedButton('foryou', 'For You'),
                ],
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              children: [
                _dock('home', Icons.home, 'Home'),
                _dock('me', Icons.person, 'Profile'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slide(Map<String, dynamic> post) {
    final liked = post['liked'] == true;
    return Stack(
      fit: StackFit.expand,
      children: [
        NetPhoto(url: '${post['image']}'),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.center,
              colors: [Color(0xCC000000), Color(0x00000000)],
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 72,
          bottom: 56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('@${post['author']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${post['caption']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
              const SizedBox(height: 6),
              Text('♪ ${post['music']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        Positioned(
          right: 8,
          bottom: 72,
          child: Column(
            children: [
              HueAvatar(name: '${post['author']}', hue: const Color(0xFF25F4EE), size: 40),
              const SizedBox(height: 12),
              _side(liked ? Icons.favorite : Icons.favorite_border, fmtCount(post['likes'] as num), () {
                setState(() {
                  post['liked'] = !liked;
                  post['likes'] = (post['likes'] as int) + (liked ? -1 : 1);
                });
              }),
              _side(Icons.chat_bubble, fmtCount(post['comments'] as num), () {
                setState(() => post['comments'] = (post['comments'] as int) + 1);
              }),
              _side(Icons.share, fmtCount(post['shares'] as num), () {
                setState(() => post['shares'] = (post['shares'] as int) + 1);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _side(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _feedButton(String id, String label) {
    final on = _feed == id;
    return GestureDetector(
      onTap: () => setState(() => _feed = id),
      child: Text(label, style: TextStyle(color: on ? Colors.white : Colors.white54, fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  Widget _dock(String id, IconData icon, String label) {
    final on = _tab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = id),
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 8),
          child: Column(
            children: [
              Icon(icon, color: on ? Colors.white : Colors.white54, size: 22),
              Text(label, style: TextStyle(color: on ? Colors.white : Colors.white54, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _me() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 64),
      children: [
        const Center(child: HueAvatar(name: 'Alex Carter', hue: Color(0xFF25F4EE), size: 84)),
        const SizedBox(height: 8),
        const Center(child: Text('@alex.carter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ProfileStat('2431', 'Followers'),
            _ProfileStat('89.5K', 'Likes'),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: [for (final post in _posts) NetPhoto(url: '${post['image']}')],
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
