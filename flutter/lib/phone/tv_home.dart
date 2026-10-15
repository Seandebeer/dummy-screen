import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';

/// Smart TV launcher. The rows follow a living-room home: search, apps,
/// what is playing next, and a recommended shelf.
class TvHome extends StatelessWidget {
  const TvHome({
    super.key,
    required this.os,
    required this.shell,
    required this.onShell,
    required this.onOpen,
  });

  final OsSettings os;
  final String shell;
  final ValueChanged<String> onShell;
  final ValueChanged<String?> onOpen;

  static const _shells = [
    ('aurora', 'Aurora'),
    ('slate', 'Slate'),
    ('neon', 'Neon'),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = switch (shell) {
      'slate' => const Color(0xFF14171C),
      'neon' => const Color(0xFF160818),
      _ => const Color(0xFF0C1218),
    };
    final clock = formatOsClock(osNow(os), hour24: os.clockFormat == '24');
    return ColoredBox(
      key: const Key('tv-home'),
      color: bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(clock: clock, onShell: onShell),
            const SizedBox(height: 18),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: _Shelf(
                      label: 'Apps',
                      mark: const _AppsMark(),
                      child: _AppRow(onOpen: onOpen),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    flex: 6,
                    child: _Shelf(
                      label: 'Watch Next',
                      mark: const _PlayMark(),
                      child: const _PosterRow(posters: _watchNext, tall: true),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    flex: 6,
                    child: _Shelf(
                      label: 'Recommended',
                      mark: const _WordMark(word: 'NETFLIX', color: Color(0xFFE50914), on: Colors.white),
                      child: const _PosterRow(posters: _recommended),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.clock, required this.onShell});

  final String clock;
  final ValueChanged<String> onShell;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.mic, color: Color(0xFF8AB4F8), size: 22),
        const SizedBox(width: 12),
        const Text(
          'Search movies, TV, and more',
          key: Key('tv-search'),
          style: TextStyle(color: Color(0xFF9AA4B0), fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        const _CountBadge(),
        const SizedBox(width: 16),
        const Icon(Icons.cast, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          key: const Key('tv-settings'),
          tooltip: 'TV system',
          icon: const Icon(Icons.settings, color: Colors.white, size: 20),
          onSelected: onShell,
          itemBuilder: (context) => [
            for (final item in TvHome._shells)
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
  const _Shelf({required this.label, required this.mark, required this.child});

  final String label;
  final Widget mark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              mark,
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
  const _AppRow({required this.onOpen});

  final ValueChanged<String?> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('tv-apps'),
      scrollDirection: Axis.horizontal,
      children: [
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
        _AppTile(
          id: 'news',
          width: 132,
          color: Colors.white,
          onTap: () => onOpen('news'),
          child: const _NbcMark(),
        ),
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
        _AppTile(
          id: 'sport',
          width: 132,
          color: const Color(0xFF1D428A),
          onTap: () => onOpen('sport'),
          child: const Icon(Icons.sports_basketball, color: Colors.white, size: 36),
        ),
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
      ],
    );
  }
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
              child: SizedBox(width: width, height: focused ? 78 : 68, child: Center(child: child)),
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
];

class _PosterRow extends StatelessWidget {
  const _PosterRow({required this.posters, this.tall = false});

  final List<_Poster> posters;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (final poster in posters)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _PosterCard(poster: poster, tall: tall),
          ),
      ],
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.poster, required this.tall});

  final _Poster poster;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final light = poster.colors.first.computeLuminance() > 0.6;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: tall ? 236 : 210,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: poster.colors,
            ),
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
    );
  }
}
