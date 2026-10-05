import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../image_file.dart';
import '../models.dart';
import '../store.dart';

/// PlayStation 5 Games home: icon strip, dark cards, and line-art background.
class Ps5Home extends StatefulWidget {
  const Ps5Home({
    super.key,
    required this.store,
    required this.device,
    required this.onOpen,
    required this.onShell,
  });

  final StageStore store;
  final PropDevice device;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onShell;

  @override
  State<Ps5Home> createState() => _Ps5HomeState();
}

class _Ps5HomeState extends State<Ps5Home> {
  int _tab = 0;

  static const _shells = [
    ('xbox', 'Xbox Series'),
    ('ps5', 'PlayStation 5'),
    ('ps2', 'PlayStation 2'),
    ('x360', 'Xbox 360'),
  ];

  @override
  Widget build(BuildContext context) {
    final now = propNow(widget.device.clockOffsetMinutes);
    final featured = widget.device.os.steamTitle.trim().isEmpty
        ? 'Night Run'
        : widget.device.os.steamTitle.trim();
    final cover = imageProviderForPath(widget.device.os.steamCover);
    return Stack(
      key: const Key('ps5-home'),
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: CustomPaint(painter: _BackdropPainter())),
        LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _Metrics(constraints.biggest);
            final chrome =
                metrics.pad +
                metrics.header +
                metrics.gap +
                metrics.strip +
                metrics.gap;
            final room = math.max(0.0, metrics.h - chrome);
            final wanted = metrics.h * (metrics.tight ? 0.66 : 0.56);
            final cardsH = math.min(wanted, room);
            return _Scope(
              metrics: metrics,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.pad,
                  metrics.pad * 0.45,
                  0,
                  metrics.pad * 0.4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: metrics.pad),
                      child: _Header(
                        tab: _tab,
                        time: _clock(now),
                        onTab: (index) => setState(() => _tab = index),
                        onShell: widget.onShell,
                        shells: _shells,
                      ),
                    ),
                    SizedBox(height: metrics.gap),
                    if (_tab == 0) ...[
                      SizedBox(
                        height: metrics.strip,
                        child: _GameStrip(cover: cover, onOpen: widget.onOpen),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: cardsH,
                        child: _Cards(
                          featured: featured,
                          cover: cover,
                          onOpen: widget.onOpen,
                        ),
                      ),
                    ] else
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: metrics.pad),
                          child: _Media(onOpen: widget.onOpen),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Metrics {
  const _Metrics(this.size);

  final Size size;

  double get w => size.width;
  double get h => size.height;
  bool get tight => h < 420 || w < 680;
  double get scale => (w / 1100).clamp(0.78, 1.12);
  double fs(double value) => value * scale;
  double get pad => tight ? 8 : 16;
  double get gap => tight ? 6 : 12;
  double get header => math.max(26, fs(18) + 8);
  double get strip {
    final raw = h * (tight ? 0.22 : 0.16);
    return raw.clamp(tight ? 54.0 : 76.0, tight ? 72.0 : 112.0);
  }

  double get radius => tight ? 10 : 16;
  double get cardPad => tight ? 7 : 12;
  double get peek => (w * 0.1).clamp(46.0, 120.0);

  @override
  bool operator ==(Object other) => other is _Metrics && other.size == size;

  @override
  int get hashCode => size.hashCode;
}

class _Scope extends InheritedWidget {
  const _Scope({required this.metrics, required super.child});

  final _Metrics metrics;

  static _Metrics of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_Scope>();
    assert(scope != null, 'Ps5 widgets must sit under _Scope');
    return scope!.metrics;
  }

  @override
  bool updateShouldNotify(_Scope oldWidget) => oldWidget.metrics != metrics;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tab,
    required this.time,
    required this.onTab,
    required this.onShell,
    required this.shells,
  });

  final int tab;
  final String time;
  final ValueChanged<int> onTab;
  final ValueChanged<String> onShell;
  final List<(String, String)> shells;

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    return SizedBox(
      height: metrics.header,
      child: Row(
        children: [
          _TabLabel(label: 'Games', selected: tab == 0, onTap: () => onTab(0)),
          SizedBox(width: metrics.gap + 4),
          _TabLabel(label: 'Media', selected: tab == 1, onTap: () => onTab(1)),
          const Spacer(),
          Icon(Icons.search, color: Colors.white, size: metrics.fs(18)),
          SizedBox(width: metrics.gap),
          PopupMenuButton<String>(
            tooltip: 'Console',
            padding: EdgeInsets.zero,
            color: const Color(0xFF1C1C1E),
            onSelected: onShell,
            itemBuilder: (context) => [
              for (final item in shells)
                PopupMenuItem(value: item.$1, child: Text(item.$2)),
            ],
            child: Icon(
              Icons.settings,
              color: Colors.white,
              size: metrics.fs(18),
            ),
          ),
          SizedBox(width: metrics.gap),
          Icon(Icons.crop_square, color: Colors.white, size: metrics.fs(16)),
          SizedBox(width: metrics.gap),
          Text(
            time,
            style: TextStyle(
              color: Colors.white,
              fontSize: metrics.fs(14),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF9AA0AE),
          fontSize: metrics.fs(18),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _GameStrip extends StatefulWidget {
  const _GameStrip({required this.onOpen, this.cover});

  final ImageProvider? cover;
  final ValueChanged<String> onOpen;

  @override
  State<_GameStrip> createState() => _GameStripState();
}

class _GameStripState extends State<_GameStrip> {
  final _scroll = ScrollController(initialScrollOffset: 34);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    final label = metrics.fs(11).clamp(9.0, 13.0);
    final box = math.max(28.0, metrics.strip - label - 4);
    return ClipRect(
      child: Transform.translate(
        offset: const Offset(-26, 0),
        child: ListView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          children: [
            _MarkTile(side: box * 0.92),
            SizedBox(width: metrics.gap * 0.6),
            _IconTile(icon: Icons.shopping_bag_outlined, side: box * 0.92),
            SizedBox(width: metrics.gap * 0.6),
            _WelcomeTile(
              side: box,
              label: label,
              onTap: () => widget.onOpen('Welcome'),
            ),
            SizedBox(width: metrics.gap * 0.6),
            _CoverTile(
              art: _Art.night,
              side: box * 0.92,
              image: widget.cover,
              onTap: () => widget.onOpen('steam'),
            ),
            _CoverTile(
              art: _Art.harbor,
              side: box * 0.92,
              tileKey: const Key('ps5-game-harbor'),
              onTap: () => widget.onOpen('Harbor'),
            ),
            _CoverTile(
              art: _Art.signal,
              side: box * 0.92,
              onTap: () => widget.onOpen('Signal'),
            ),
            _CoverTile(
              art: _Art.relay,
              side: box * 0.92,
              onTap: () => widget.onOpen('Relay'),
            ),
            _IconTile(icon: Icons.sports_esports, side: box * 0.92),
            _GridTile(side: box * 0.92),
          ],
        ),
      ),
    );
  }
}

class _WelcomeTile extends StatelessWidget {
  const _WelcomeTile({
    required this.side,
    required this.label,
    required this.onTap,
  });

  final double side;
  final double label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: side,
            height: side,
            decoration: BoxDecoration(
              color: const Color(0xFF161820),
              borderRadius: BorderRadius.circular(side * 0.16),
              border: Border.all(
                color: const Color(0xFFE4E7EE),
                width: math.max(1.6, side * 0.035),
              ),
            ),
            child: const CustomPaint(painter: _SymbolsPainter()),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: label,
            child: Text(
              'Welcome',
              style: TextStyle(
                color: Colors.white,
                fontSize: label * 0.92,
                height: 1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverTile extends StatelessWidget {
  const _CoverTile({
    required this.art,
    required this.side,
    required this.onTap,
    this.image,
    this.tileKey,
  });

  final _Art art;
  final double side;
  final VoidCallback onTap;
  final ImageProvider? image;
  final Key? tileKey;

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    return Padding(
      padding: EdgeInsets.only(right: metrics.gap * 0.6),
      child: GestureDetector(
        key: tileKey,
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(side * 0.14),
          child: SizedBox(
            width: side,
            height: side,
            child: _ArtPaint(art, image: image),
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.side});

  final IconData icon;
  final double side;

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    return Padding(
      padding: EdgeInsets.only(right: metrics.gap * 0.6),
      child: Container(
        width: side,
        height: side,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C24),
          borderRadius: BorderRadius.circular(side * 0.16),
        ),
        child: Icon(icon, color: Colors.white, size: side * 0.42),
      ),
    );
  }
}

class _MarkTile extends StatelessWidget {
  const _MarkTile({required this.side});

  final double side;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(side * 0.16),
      child: SizedBox(
        width: side,
        height: side,
        child: const CustomPaint(painter: _MarkPainter()),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({required this.side});

  final double side;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C24),
        borderRadius: BorderRadius.circular(side * 0.16),
      ),
      child: const CustomPaint(painter: _GridPainter()),
    );
  }
}

class _Cards extends StatelessWidget {
  const _Cards({required this.featured, required this.onOpen, this.cover});

  final String featured;
  final ImageProvider? cover;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    final gap = metrics.gap * 0.65;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: _Friends(onTap: () => onOpen('Friends')),
              ),
              SizedBox(height: gap),
              Expanded(flex: 2, child: _Store(onTap: () => onOpen('Harbor'))),
            ],
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: _Access(onTap: () => onOpen('Accessibility')),
              ),
              SizedBox(height: gap),
              Expanded(
                flex: 3,
                child: _Trophies(onTap: () => onOpen('Trophies')),
              ),
            ],
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: 4,
          child: _WishlistColumn(
            title: featured,
            image: cover,
            onOpen: () => onOpen('steam'),
          ),
        ),
        SizedBox(width: gap),
        const _ActivityPeek(),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: _cardDecoration(metrics),
        child: Padding(padding: EdgeInsets.all(metrics.cardPad), child: child),
      ),
    );
  }
}

BoxDecoration _cardDecoration(_Metrics metrics, {double? radius}) {
  return BoxDecoration(
    color: const Color(0xFF1C1F29),
    borderRadius: BorderRadius.circular(radius ?? metrics.radius),
    border: Border.all(color: const Color(0x18FFFFFF)),
  );
}

class _Friends extends StatelessWidget {
  const _Friends({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    const marks = [
      (Color(0xFF8FD0C4), Icons.person),
      (Color(0xFFE0A23A), Icons.view_in_ar),
      (Color(0xFFE07AB0), Icons.diamond),
      (Color(0xFF7AA2E0), Icons.public),
    ];
    return _Panel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, color: Colors.white, size: metrics.fs(14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Online Friends',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: metrics.fs(13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.circle,
                color: const Color(0xFF3DDC84),
                size: metrics.fs(8),
              ),
              const SizedBox(width: 4),
              Text(
                '4',
                style: TextStyle(color: Colors.white, fontSize: metrics.fs(13)),
              ),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                for (final mark in marks)
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: mark.$1,
                          child: Icon(mark.$2, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            'Mara Quinn, Northline, Kiln, Glass',
            maxLines: metrics.tight ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFFC5C8D2),
              fontSize: metrics.fs(11),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Store extends StatelessWidget {
  const _Store({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    return _Panel(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: metrics.fs(14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Game Store',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: metrics.fs(12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Harbor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: metrics.fs(13),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const _Pills(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(6)),
              child: _ArtPaint(_Art.harbor),
            ),
          ),
        ],
      ),
    );
  }
}

class _Access extends StatelessWidget {
  const _Access({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    return _Panel(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.accessibility_new,
                        color: Colors.white,
                        size: metrics.fs(14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Accessibility',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: metrics.fs(13),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Make this console easier to use.',
                    style: TextStyle(
                      color: const Color(0xFFC5C8D2),
                      fontSize: metrics.fs(11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 36,
              height: 36,
              child: CustomPaint(
                painter: const _RingPainter(Color(0xFF7EB6FF)),
                child: Icon(
                  Icons.accessibility_new,
                  color: const Color(0xFF7EB6FF),
                  size: metrics.fs(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Trophies extends StatelessWidget {
  const _Trophies({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    const cups = [
      (Color(0xFF8FD8F2), '2'),
      (Color(0xFFE0B03A), '14'),
      (Color(0xFFC9CDD4), '41'),
      (Color(0xFFC4784A), '179'),
    ];
    return _Panel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: metrics.fs(14),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Trophies',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: metrics.fs(13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Total: 236',
                style: TextStyle(color: Colors.white, fontSize: metrics.fs(12)),
              ),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                for (final cup in cups)
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events, color: cup.$1, size: 22),
                          const SizedBox(height: 2),
                          Text(
                            cup.$2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                'Level 42',
                style: TextStyle(
                  color: const Color(0xFFC5C8D2),
                  fontSize: metrics.fs(11),
                ),
              ),
              const Spacer(),
              Text(
                '61%',
                style: TextStyle(
                  color: const Color(0xFFC5C8D2),
                  fontSize: metrics.fs(11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: const LinearProgressIndicator(
              value: 0.61,
              minHeight: 3,
              backgroundColor: Color(0xFF3A3E4A),
              color: Color(0xFFE8ECF4),
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistColumn extends StatelessWidget {
  const _WishlistColumn({
    required this.title,
    required this.onOpen,
    this.image,
  });

  final String title;
  final ImageProvider? image;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final orbsH = (constraints.maxHeight * 0.24).clamp(30.0, 72.0);
        return Column(
          children: [
            SizedBox(height: orbsH, child: const _Orbs()),
            SizedBox(height: metrics.gap * 0.65),
            Expanded(
              child: _Wishlist(title: title, image: image, onTap: onOpen),
            ),
          ],
        );
      },
    );
  }
}

class _Orbs extends StatelessWidget {
  const _Orbs();

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    const orbs = [
      (Icons.sports_esports, Color(0xFF3DDC84)),
      (Icons.headset, Color(0xFF3DDC84)),
      (Icons.power_settings_new, Color(0xFFFF9F0A)),
    ];
    return DecoratedBox(
      decoration: _cardDecoration(metrics, radius: metrics.radius + 4),
      child: Row(
        children: [
          for (final orb in orbs)
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _Orb(icon: orb.$1, color: orb.$2),
              ),
            ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(
        painter: _RingPainter(color),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

class _Wishlist extends StatelessWidget {
  const _Wishlist({required this.title, required this.onTap, this.image});

  final String title;
  final ImageProvider? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(metrics.radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _ArtPaint(_Art.night, image: image),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x22000000), Color(0xCC000000)],
                  stops: [0.35, 1],
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 8,
              right: 8,
              child: Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: metrics.fs(14),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Wishlist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: metrics.fs(13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 10,
              right: 8,
              bottom: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: metrics.fs(13),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const _Pills(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityPeek extends StatelessWidget {
  const _ActivityPeek();

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    final visible = (metrics.w * 0.072).clamp(52.0, 84.0);
    return SizedBox(
      width: visible,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: visible + 78,
          maxWidth: visible + 78,
          child: SizedBox(width: visible + 78, child: const _Activity()),
        ),
      ),
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity();

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    return _Panel(
      onTap: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Friend activity',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: metrics.fs(12),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFF8FD0C4),
            child: Icon(Icons.person, color: Colors.white, size: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Mara',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: metrics.fs(12)),
          ),
          Text(
            'playing now',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFFC5C8D2),
              fontSize: metrics.fs(10),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pills extends StatelessWidget {
  const _Pills();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Pill(label: 'PS5'),
        SizedBox(width: 4),
        _Pill(label: 'PS4'),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xCC101218),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Media extends StatelessWidget {
  const _Media({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final metrics = _Scope.of(context);
    const items = [
      ('Music', Icons.music_note, [Color(0xFF1A2748), Color(0xFF3A6EA5)]),
      ('Clips', Icons.movie, [Color(0xFF3A1A28), Color(0xFF8A3050)]),
      ('Gallery', Icons.photo, [Color(0xFF1A3028), Color(0xFF3A8A62)]),
    ];
    return Row(
      children: [
        for (final item in items) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onOpen(item.$1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(metrics.radius),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: item.$3,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.$2, color: Colors.white, size: metrics.fs(36)),
                      const SizedBox(height: 8),
                      Text(
                        item.$1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: metrics.fs(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (item != items.last) SizedBox(width: metrics.gap),
        ],
      ],
    );
  }
}

enum _Art { night, harbor, signal, relay }

class _ArtPaint extends StatelessWidget {
  const _ArtPaint(this.art, {this.image});

  final _Art art;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _ArtPainter(art)),
        if (image != null && art == _Art.night)
          Image(image: image!, fit: BoxFit.cover),
      ],
    );
  }
}

class _SymbolsPainter extends CustomPainter {
  const _SymbolsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE7E9F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, size.shortestSide * 0.045)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final d = size.shortestSide * 0.16;
    final left = size.width * 0.32;
    final right = size.width * 0.68;
    final top = size.height * 0.32;
    final bottom = size.height * 0.68;
    final tri = Path()
      ..moveTo(left, top + d * 0.85)
      ..lineTo(left - d * 0.7, top - d * 0.55)
      ..lineTo(left + d * 0.7, top - d * 0.55)
      ..close();
    canvas.drawPath(tri, paint);
    canvas.drawCircle(Offset(right, top), d * 0.62, paint);
    canvas.drawLine(
      Offset(left - d * 0.55, bottom - d * 0.55),
      Offset(left + d * 0.55, bottom + d * 0.55),
      paint,
    );
    canvas.drawLine(
      Offset(left - d * 0.55, bottom + d * 0.55),
      Offset(left + d * 0.55, bottom - d * 0.55),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(right, bottom),
          width: d * 1.15,
          height: d * 1.15,
        ),
        Radius.circular(d * 0.12),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.38;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, size.shortestSide * 0.07)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.72,
      math.pi * 1.55,
      false,
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + radius),
          width: radius * 0.42,
          height: radius * 0.42,
        ),
        const Radius.circular(1.5),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE6E8EE);
    final cell = size.shortestSide * 0.16;
    final gap = cell * 0.38;
    final origin = Offset(
      (size.width - cell * 2 - gap) / 2,
      (size.height - cell * 2 - gap) / 2,
    );
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 2; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              origin.dx + col * (cell + gap),
              origin.dy + row * (cell + gap),
              cell,
              cell,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A4E8A), Color(0xFF1A1C28)],
        ).createShader(rect),
    );
    final paint = Paint()
      ..color = const Color(0xFFE0B03A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide * 0.22,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArtPainter extends CustomPainter {
  const _ArtPainter(this.art);

  final _Art art;

  @override
  void paint(Canvas canvas, Size size) {
    switch (art) {
      case _Art.night:
        _night(canvas, size);
      case _Art.harbor:
        _harbor(canvas, size);
      case _Art.signal:
        _signal(canvas, size);
      case _Art.relay:
        _relay(canvas, size);
    }
  }

  void _fill(Canvas canvas, Size size, List<Color> colors) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );
  }

  void _night(Canvas canvas, Size size) {
    _fill(canvas, size, const [
      Color(0xFF1A3A6A),
      Color(0xFF16345A),
      Color(0xFF8A2430),
      Color(0xFF120810),
    ]);
    final body = Path()
      ..moveTo(size.width * 0.08, size.height * 0.62)
      ..lineTo(size.width * 0.22, size.height * 0.48)
      ..lineTo(size.width * 0.4, size.height * 0.42)
      ..lineTo(size.width * 0.62, size.height * 0.46)
      ..lineTo(size.width * 0.9, size.height * 0.58)
      ..lineTo(size.width * 0.9, size.height * 0.7)
      ..lineTo(size.width * 0.08, size.height * 0.7)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFD5DCE8));
    final cabin = Path()
      ..moveTo(size.width * 0.4, size.height * 0.42)
      ..lineTo(size.width * 0.48, size.height * 0.3)
      ..lineTo(size.width * 0.66, size.height * 0.3)
      ..lineTo(size.width * 0.74, size.height * 0.46)
      ..close();
    canvas.drawPath(cabin, Paint()..color = const Color(0xFF243044));
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.7),
      size.shortestSide * 0.07,
      Paint()..color = const Color(0xFF101418),
    );
    canvas.drawCircle(
      Offset(size.width * 0.74, size.height * 0.7),
      size.shortestSide * 0.07,
      Paint()..color = const Color(0xFF101418),
    );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.22),
      size.shortestSide * 0.06,
      Paint()..color = const Color(0x66FFFFFF),
    );
  }

  void _harbor(Canvas canvas, Size size) {
    _fill(canvas, size, const [
      Color(0xFF8EC8E4),
      Color(0xFF1A6898),
      Color(0xFF08243A),
    ]);
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.28),
      size.shortestSide * 0.1,
      Paint()..color = const Color(0xFFFFE2A0),
    );
    final land = Path()
      ..moveTo(0, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.4,
        size.width,
        size.height * 0.58,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(land, Paint()..color = const Color(0xFF14324A));
    canvas.drawCircle(
      Offset(size.width * 0.42, size.height * 0.48),
      size.shortestSide * 0.05,
      Paint()..color = const Color(0xFF0C1C28),
    );
  }

  void _signal(Canvas canvas, Size size) {
    _fill(canvas, size, const [
      Color(0xFFE08A3A),
      Color(0xFF8A3018),
      Color(0xFF1A1010),
    ]);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.58),
        width: size.width * 0.62,
        height: size.height * 0.22,
      ),
      Radius.circular(size.shortestSide * 0.06),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFF2E6D4));
    canvas.drawCircle(
      Offset(size.width * 0.34, size.height * 0.72),
      size.shortestSide * 0.07,
      Paint()..color = const Color(0xFF1A1A1A),
    );
    canvas.drawCircle(
      Offset(size.width * 0.66, size.height * 0.72),
      size.shortestSide * 0.07,
      Paint()..color = const Color(0xFF1A1A1A),
    );
  }

  void _relay(Canvas canvas, Size size) {
    _fill(canvas, size, const [
      Color(0xFF4A1018),
      Color(0xFFC4471A),
      Color(0xFF1A0A0C),
    ]);
    final flame = Path()
      ..moveTo(size.width * 0.5, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.48,
        size.width * 0.62,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.62,
        size.width * 0.38,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.48,
        size.width * 0.5,
        size.height * 0.18,
      )
      ..close();
    canvas.drawPath(flame, Paint()..color = const Color(0xFFFFC46A));
  }

  @override
  bool shouldRepaint(covariant _ArtPainter oldDelegate) =>
      oldDelegate.art != art;
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF140818),
            Color(0xFF07111F),
            Color(0xFF0A2048),
            Color(0xFF070E18),
          ],
          stops: [0, 0.38, 0.74, 1],
        ).createShader(rect),
    );
    final glow = Rect.fromCircle(
      center: Offset(size.width * 0.7, size.height * 0.2),
      radius: size.shortestSide * 0.42,
    );
    canvas.drawCircle(
      glow.center,
      glow.width / 2,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x55305CFF), Color(0x00000000)],
        ).createShader(glow),
    );

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..color = const Color(0x6698B4FF);
    final dim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0x33E4E8FF);

    final sweep = Path()
      ..moveTo(-size.width * 0.02, size.height * 0.72)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.48,
        size.width * 0.38,
        size.height * 0.9,
        size.width * 0.58,
        size.height * 0.4,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.08,
        size.width * 0.86,
        size.height * 0.46,
        size.width * 1.04,
        size.height * 0.22,
      );
    canvas.drawPath(sweep, dim);
    final sweep2 = Path()
      ..moveTo(size.width * 0.08, size.height * 0.9)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.62,
        size.width * 0.5,
        size.height * 0.84,
        size.width * 0.78,
        size.height * 0.5,
      )
      ..cubicTo(
        size.width * 0.9,
        size.height * 0.34,
        size.width * 0.96,
        size.height * 0.42,
        size.width * 1.05,
        size.height * 0.36,
      );
    canvas.drawPath(sweep2, line);

    final origin = Offset(size.width * 0.68, size.height * 0.22);
    final reach = size.shortestSide;
    canvas.drawCircle(origin, reach * 0.13, line);
    final tri = Path()
      ..moveTo(origin.dx - reach * 0.02, origin.dy - reach * 0.2)
      ..lineTo(origin.dx + reach * 0.16, origin.dy + reach * 0.08)
      ..lineTo(origin.dx - reach * 0.18, origin.dy + reach * 0.1)
      ..close();
    canvas.drawPath(tri, line);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: origin + Offset(reach * 0.2, reach * 0.05),
          width: reach * 0.14,
          height: reach * 0.14,
        ),
        const Radius.circular(4),
      ),
      dim,
    );
    canvas.drawLine(
      origin + Offset(-reach * 0.16, reach * 0.02),
      origin + Offset(-reach * 0.02, reach * 0.16),
      dim,
    );
    canvas.drawLine(
      origin + Offset(-reach * 0.16, reach * 0.16),
      origin + Offset(-reach * 0.02, reach * 0.02),
      dim,
    );

    final capsule = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = const Color(0x44D5DEFF);
    final marks = <(double, double, double, double)>[
      (0.56, 0.34, 0.09, 0.028),
      (0.7, 0.4, 0.12, 0.03),
      (0.82, 0.16, 0.1, 0.026),
      (0.88, 0.3, 0.08, 0.024),
      (0.48, 0.58, 0.11, 0.026),
      (0.74, 0.62, 0.09, 0.022),
    ];
    for (final mark in marks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * mark.$1,
            size.height * mark.$2,
            size.width * mark.$3,
            size.height * mark.$4,
          ),
          const Radius.circular(20),
        ),
        capsule,
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.42, size.height * 0.46),
      reach * 0.05,
      dim,
    );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.48),
      reach * 0.08,
      line,
    );
    final smallTri = Path()
      ..moveTo(size.width * 0.34, size.height * 0.3)
      ..lineTo(size.width * 0.4, size.height * 0.42)
      ..lineTo(size.width * 0.28, size.height * 0.42)
      ..close();
    canvas.drawPath(smallTri, dim);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _clock(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
