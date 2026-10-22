import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../format.dart';
import '../image_file.dart';
import '../models.dart';
import '../store.dart';
import '../video_source.dart';
import 'app_catalog.dart';
import 'app_place.dart';
import 'catalog.dart';

/// Smart TV launcher. The rows follow a living-room home: search, apps,
/// what is playing next, and a recommended shelf.
class TvHome extends StatefulWidget {
  const TvHome({
    super.key,
    required this.os,
    required this.shell,
    required this.onShell,
    required this.onOpen,
    this.store,
    this.device,
  });

  final OsSettings os;
  final String shell;
  final ValueChanged<String> onShell;
  final ValueChanged<String?> onOpen;
  final StageStore? store;
  final PropDevice? device;

  @override
  State<TvHome> createState() => _TvHomeState();
}

class _TvHomeState extends State<TvHome> {
  String _query = '';
  String? _shelf;
  String? _playing;

  OsSettings get os => widget.device == null
      ? widget.os
      : (widget.store?.deviceById(widget.device!.id)?.os ?? widget.os);

  static const _shells = [
    ('aurora', 'Aurora'),
    ('slate', 'Slate'),
    ('neon', 'Neon'),
  ];

  bool _matches(String title) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return title.toLowerCase().contains(query);
  }

  Future<void> _upload(String id) async {
    final store = widget.store;
    final device = widget.device;
    if (store == null || device == null || store.filming) return;
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const [
      'png', 'jpg', 'jpeg', 'gif', 'webp', 'mp4', 'mov', 'webm',
    ]);
    if (file == null || !mounted) return;
    final ext = (file.extension ?? '').toLowerCase();
    final video = ext == 'mp4' || ext == 'mov' || ext == 'webm';
    final path = video ? await persistPickedVideo(file) : await persistPickedImage(file);
    if (path == null || !mounted) return;
    final next = [
      for (final item in os.tvMedia)
        if (!item.startsWith('$id$kFlightCell')) item,
      '$id$kFlightCell${video ? 'video' : 'image'}$kFlightCell$path',
    ];
    store.updateOs(device.id, (current) => current.copyWith(tvMedia: next));
  }

  (String, String)? _media(String id) {
    for (final item in os.tvMedia) {
      final parts = item.split(kFlightCell);
      if (parts.length >= 3 && parts.first == id) return (parts[1], parts[2]);
    }
    return null;
  }

  void _openTile(String id, VoidCallback open) {
    final media = _media(id);
    if (media != null && media.$1 == 'video') {
      setState(() => _playing = media.$2);
      return;
    }
    open();
  }

  @override
  Widget build(BuildContext context) {
    final shell = os.shell.isEmpty ? widget.shell : os.shell;
    final bg = switch (shell) {
      'slate' => const Color(0xFF14171C),
      'neon' => const Color(0xFF160818),
      _ => const Color(0xFF0C1218),
    };
    final clock = formatOsClock(osNow(os), hour24: os.clockFormat == '24');
    if (_playing != null) {
      return _TvPlayer(path: _playing!, onClose: () => setState(() => _playing = null));
    }
    return ColoredBox(
      key: const Key('tv-home'),
      color: bg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: os.backgroundType == 'image' && os.backgroundUrl.isNotEmpty && imageProviderForPath(os.backgroundUrl) != null
              ? DecorationImage(image: imageProviderForPath(os.backgroundUrl)!, fit: BoxFit.cover)
              : null,
          gradient: os.backgroundType == 'image'
              ? null
              : _wallpaper(os.backgroundPreset.isEmpty ? shell : os.backgroundPreset),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(
              clock: clock,
              onShell: widget.onShell,
              onQuery: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _shelf == null
                  ? Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: _Shelf(
                      label: 'Apps',
                      mark: const _AppsMark(),
                      onMark: () => widget.onOpen('appstore'),
                      child: _AppRow(
                        os: os,
                        onOpen: (id) => _openTile(id, () => widget.onOpen(id)),
                        matches: _matches,
                        media: _media,
                        onUpload: widget.store == null ? null : _upload,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    flex: 6,
                    child: _Shelf(
                      label: 'Watch Next',
                      mark: const _PlayMark(),
                      onMark: () => setState(() => _shelf = 'Watch Next'),
                      child: _PosterRow(
                        posters: _watchNext.where((item) => _matches(item.title)).toList(),
                        tall: true,
                        media: _media,
                        onUpload: widget.store == null ? null : _upload,
                        onOpen: (id) => _openTile(id, () => setState(() => _shelf = 'Watch Next')),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    flex: 6,
                    child: _Shelf(
                      label: 'Recommended',
                      mark: const _WordMark(word: 'NETFLIX', color: Colors.white, on: Color(0xFFE50914)),
                      onMark: () => setState(() => _shelf = 'Recommended'),
                      child: _PosterRow(
                        posters: _recommended.where((item) => _matches(item.caption ?? item.title)).toList(),
                        media: _media,
                        onUpload: widget.store == null ? null : _upload,
                        onOpen: (id) => _openTile(id, () => setState(() => _shelf = 'Recommended')),
                      ),
                    ),
                  ),
                ],
              )
                  : _SuggestionPage(
                      title: _shelf!,
                      posters: _shelf == 'Watch Next' ? _watchNext : _recommended,
                      onBack: () => setState(() => _shelf = null),
                      media: _media,
                      onOpen: (poster) => _openTile(poster.title, () {}),
                    ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}

LinearGradient _wallpaper(String preset) {
  return switch (preset) {
    'slate' => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2A3340), Color(0xFF10151C), Color(0xFF3D4A5C)],
    ),
    'neon' => const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2A0845), Color(0xFF0B1B3A), Color(0xFF123C34)],
    ),
    'dusk' => const LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFF3A1D4A), Color(0xFF12243A), Color(0xFF0C1218)],
    ),
    'ember' => const LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [Color(0xFF3A140C), Color(0xFF1A120C), Color(0xFF243044)],
    ),
    _ => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF12304A), Color(0xFF0C1218), Color(0xFF1A3A34), Color(0xFF101820)],
      stops: [0, 0.35, 0.7, 1],
    ),
  };
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.clock, required this.onShell, required this.onQuery});

  final String clock;
  final ValueChanged<String> onShell;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.mic, color: Color(0xFF8AB4F8), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            key: const Key('tv-search'),
            onChanged: onQuery,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            cursorColor: Colors.white,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Search movies, TV, and more',
              hintStyle: TextStyle(color: Color(0xFF9AA4B0), fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const _CountBadge(),
        const SizedBox(width: 16),
        PopupMenuButton<String>(
          key: const Key('tv-settings'),
          tooltip: 'TV system',
          icon: const Icon(Icons.settings, color: Colors.white, size: 20),
          onSelected: onShell,
          itemBuilder: (context) => [
            for (final item in _TvHomeState._shells)
              PopupMenuItem(value: item.$1, child: Text(item.$2)),
          ],
        ),
        const SizedBox(width: 4),
        Text(
          clock,
          key: const Key('tv-clock'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Color(0xFF1A73E8), shape: BoxShape.circle),
      child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.label, required this.mark, required this.child, this.onMark});

  final String label;
  final Widget mark;
  final Widget child;
  final VoidCallback? onMark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(onTap: onMark, child: mark),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

class _AppsMark extends StatelessWidget {
  const _AppsMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(color: Color(0xFFE23B3B), shape: BoxShape.circle),
      child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 24),
    );
  }
}

class _PlayMark extends StatelessWidget {
  const _PlayMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(color: Color(0xFF1A73E8), shape: BoxShape.circle),
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
    );
  }
}

class _WordMark extends StatelessWidget {
  const _WordMark({required this.word, required this.color, required this.on});

  final String word;
  final Color color;
  final Color on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        word,
        style: TextStyle(color: on, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.2),
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.os,
    required this.onOpen,
    required this.matches,
    required this.media,
    this.onUpload,
  });

  final OsSettings os;
  final ValueChanged<String> onOpen;
  final bool Function(String title) matches;
  final (String, String)? Function(String id) media;
  final ValueChanged<String>? onUpload;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
        if (matches('Netflix') && tvTileVisible(os, 'flixiq'))
        _AppTile(
          id: 'flixiq',
          width: 148,
          color: Colors.white,
          onTap: () => onOpen('flixiq'),
          child: const Text(
            'NETFLIX',
            style: TextStyle(color: Color(0xFFE50914), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.4),
          ),
        ),
        if (matches('YouTube') && tvTileVisible(os, 'vidtube'))
        _AppTile(
          id: 'vidtube',
          width: 168,
          color: const Color(0xFFFF0000),
          focused: true,
          label: 'YouTube',
          onTap: () => onOpen('vidtube'),
          child: const Text(
            'YouTube',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        if (matches('NBC') && tvTileVisible(os, 'news'))
        _AppTile(
          id: 'news',
          width: 132,
          color: Colors.white,
          onTap: () => onOpen('news'),
          child: const _NbcMark(),
        ),
        if (matches('Hulu') && tvTileVisible(os, 'shows'))
        _AppTile(
          id: 'shows',
          width: 132,
          color: const Color(0xFF2A2E33),
          onTap: () => onOpen('shows'),
          child: const Text(
            'ZATTOO',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.6),
          ),
        ),
        if (matches('NBA') && tvTileVisible(os, 'sport'))
        _AppTile(
          id: 'sport',
          width: 132,
          color: const Color(0xFF1D428A),
          onTap: () => onOpen('sport'),
          child: const Text(
            'NBA',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.4),
          ),
        ),
        if (matches('Canal') && tvTileVisible(os, 'films'))
        _AppTile(
          id: 'films',
          width: 148,
          color: const Color(0xFF8E1B2C),
          onTap: () => onOpen('films'),
          child: const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'my', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
                TextSpan(text: 'CANAL', style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        if (matches('Disney') && tvTileVisible(os, 'disney'))
        _AppTile(
          id: 'disney',
          width: 140,
          color: const Color(0xFF113CCF),
          onTap: () => onOpen('disney'),
          child: const Text('Disney+', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        if (matches('Prime') && tvTileVisible(os, 'prime'))
        _AppTile(
          id: 'prime',
          width: 140,
          color: const Color(0xFF00A8E1),
          onTap: () => onOpen('prime'),
          child: const Text('prime', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        for (final id in tvExtraApps(os)) ..._extraTile(id),
    ];
    if (tiles.isEmpty) {
      return const Center(child: Text('No matches', style: TextStyle(color: Colors.white70)));
    }
    return Row(
      children: [
        for (final tile in tiles) Expanded(child: tile),
      ],
    );
  }

  List<Widget> _extraTile(String id) {
    final glyph = _tvGlyph(id);
    if (!matches(glyph.$1)) return const [];
    return [
      _AppTile(
        id: id,
        width: 140,
        color: glyph.$3,
        onTap: () => onOpen(id),
        label: glyph.$1,
        child: Icon(glyph.$2, color: Colors.white, size: 28),
      ),
    ];
  }
}

(String, IconData, Color) _tvGlyph(String id) {
  final prop = propAppById(id);
  if (prop != null) return (prop.label, prop.icon, prop.color);
  for (final section in mockCatalog) {
    for (final app in section.apps) {
      if (app.id == id) return (app.label, app.icon, app.color);
    }
  }
  return (id, Icons.apps, const Color(0xFF3A3A3C));
}

class _AppTile extends StatelessWidget {
  const _AppTile({
    required this.id,
    required this.width,
    required this.color,
    required this.child,
    required this.onTap,
    this.focused = false,
    this.label,
  });

  final String id;
  final double width;
  final Color color;
  final Widget child;
  final VoidCallback onTap;
  final bool focused;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            color: color,
            borderRadius: BorderRadius.circular(8),
            elevation: focused ? 8 : 0,
            child: InkWell(
              key: Key('tv-app-$id'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: double.infinity, height: focused ? 78 : 68, child: Center(child: child)),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 6),
            Text(label!, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _NbcMark extends StatelessWidget {
  const _NbcMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: CustomPaint(painter: _PeacockPainter()),
        ),
        const SizedBox(width: 6),
        const Text(
          'NBC',
          style: TextStyle(color: Color(0xFF111111), fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _PeacockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFF7C948),
      const Color(0xFFF47B20),
      const Color(0xFFE23B3B),
      const Color(0xFF7B3FF2),
      const Color(0xFF1A73E8),
      const Color(0xFF1DB954),
    ];
    final center = Offset(size.width / 2, size.height * 0.72);
    for (var i = 0; i < colors.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(center: center, width: size.width, height: size.height),
        -3.0 + i * 0.22,
        0.16,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Poster {
  const _Poster({
    required this.title,
    required this.colors,
    this.mark = false,
    this.caption,
  });

  final String title;
  final List<Color> colors;
  final bool mark;
  final String? caption;
}

const _watchNext = [
  _Poster(title: 'Night Run', colors: [Color(0xFF8C3A2F), Color(0xFF2A211C), Color(0xFF111111)]),
  _Poster(title: 'Two in a Car', colors: [Color(0xFF3A332C), Color(0xFF1A1816), Color(0xFF0C0C0C)]),
  _Poster(title: 'Late Set', colors: [Color(0xFF1E4D3A), Color(0xFF12304A), Color(0xFF101418)]),
  _Poster(title: 'Platform', colors: [Color(0xFFC4A574), Color(0xFF8C6A45), Color(0xFF2A241C)]),
  _Poster(title: 'Harbor', colors: [Color(0xFF1A3A5C), Color(0xFF0E2438)]),
  _Poster(title: 'Redline', colors: [Color(0xFF6A1B2A), Color(0xFF1A1014)]),
];

const _recommended = [
  _Poster(
    title: 'HOUSE\nof CARDS',
    colors: [Color(0xFF1A1A1A), Color(0xFF3A3A3A)],
    mark: true,
    caption: 'HOUSE of CARDS',
  ),
  _Poster(
    title: 'Master\nof None',
    colors: [Color(0xFFF4F4F4), Color(0xFFD0D0D0)],
    mark: true,
    caption: 'Master of None',
  ),
  _Poster(
    title: 'GIRLBOSS',
    colors: [Color(0xFFF2C14E), Color(0xFFE07A3D), Color(0xFF2E6BFF)],
    mark: true,
  ),
  _Poster(
    title: 'STRANGER\nTHINGS',
    colors: [Color(0xFF1A1208), Color(0xFF4A2A12)],
    mark: true,
  ),
  _Poster(title: 'The Crown', colors: [Color(0xFF1C2838), Color(0xFF8C7348)], mark: true),
  _Poster(title: 'Ozark', colors: [Color(0xFF123028), Color(0xFF0C1410)], mark: true),
];

class _PosterRow extends StatelessWidget {
  const _PosterRow({
    required this.posters,
    this.tall = false,
    this.media,
    this.onUpload,
    this.onOpen,
  });

  final List<_Poster> posters;
  final bool tall;
  final (String, String)? Function(String id)? media;
  final ValueChanged<String>? onUpload;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    if (posters.isEmpty) {
      return const Center(child: Text('No matches', style: TextStyle(color: Colors.white70)));
    }
    return Row(
      children: [
        for (final poster in posters)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _PosterCard(
                poster: poster,
                tall: tall,
                media: media?.call(poster.title),
                onTap: () => onOpen?.call(poster.title),
                onHold: onUpload == null ? null : () => onUpload!(poster.title),
              ),
            ),
          ),
      ],
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({
    required this.poster,
    required this.tall,
    this.media,
    this.onTap,
    this.onHold,
  });

  final _Poster poster;
  final bool tall;
  final (String, String)? media;
  final VoidCallback? onTap;
  final VoidCallback? onHold;

  @override
  Widget build(BuildContext context) {
    final light = poster.colors.first.computeLuminance() > 0.6;
    final shot = media?.$1 == 'image' ? imageProviderForPath(media!.$2) : null;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onHold,
      child: ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: poster.colors,
            ),
            image: shot == null ? null : DecorationImage(image: shot, fit: BoxFit.cover),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (poster.mark)
                  const Text(
                    'NETFLIX',
                    style: TextStyle(color: Color(0xFFE50914), fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                const Spacer(),
                Text(
                  poster.caption ?? poster.title,
                  key: Key('tv-title-${poster.title}'),
                  maxLines: 2,
                  style: TextStyle(
                    color: light ? const Color(0xFF111111) : Colors.white,
                    fontSize: tall ? 16 : 18,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _SuggestionPage extends StatelessWidget {
  const _SuggestionPage({
    required this.title,
    required this.posters,
    required this.onBack,
    required this.media,
    required this.onOpen,
  });

  final String title;
  final List<_Poster> posters;
  final VoidCallback onBack;
  final (String, String)? Function(String id) media;
  final ValueChanged<_Poster> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              for (final poster in posters)
                _PosterCard(
                  poster: poster,
                  tall: false,
                  media: media(poster.title),
                  onTap: () => onOpen(poster),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TvPlayer extends StatefulWidget {
  const _TvPlayer({required this.path, required this.onClose});

  final String path;
  final VoidCallback onClose;

  @override
  State<_TvPlayer> createState() => _TvPlayerState();
}

class _TvPlayerState extends State<_TvPlayer> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final next = playerForPath(widget.path);
    _controller = next;
    next?.initialize().then((_) {
      if (!mounted) return;
      next.play();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _controller;
    final ready = player != null && player.value.isInitialized;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready) Center(child: AspectRatio(aspectRatio: player.value.aspectRatio, child: VideoPlayer(player))),
          Positioned(
            left: 8,
            top: 8,
            child: IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
