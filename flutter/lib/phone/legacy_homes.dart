import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'catalog.dart';
import '../models.dart';

/// The seven legacy phone homes. Modern and Current Android stay on [PhoneHome].
bool isLegacySkin(String skin) {
  switch (skin) {
    case 'iphoneos':
    case 'aqua':
    case 'classic':
    case 'ios6':
    case 'ios7':
    case 'winphone':
    case 'tiles':
    case 'holo':
    case 'material':
    case 'webos':
    case 'belle':
    case 'blackberry':
      return true;
    default:
      return false;
  }
}

String _canonical(String skin) {
  switch (skin) {
    case 'aqua':
    case 'classic':
      return 'iphoneos';
    case 'tiles':
      return 'winphone';
    case 'material':
      return 'holo';
    case 'blackberry':
      return 'belle';
    default:
      return skin;
  }
}

class LegacyHome extends StatelessWidget {
  const LegacyHome({
    super.key,
    required this.skin,
    required this.os,
    required this.onOpen,
    this.light = false,
  });

  final String skin;
  final OsSettings os;
  final void Function(String id) onOpen;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final id = _canonical(skin);
    final home = switch (id) {
      'ios6' => _IosShelfHome(os: os, onOpen: onOpen, kind: _IosKind.six),
      'ios7' => _IosShelfHome(os: os, onOpen: onOpen, kind: _IosKind.seven),
      'winphone' => _WindowsHome(os: os, onOpen: onOpen),
      'holo' => _HoloHome(os: os, onOpen: onOpen),
      'webos' => _WebOsHome(os: os, onOpen: onOpen),
      'belle' => _BelleHome(os: os, onOpen: onOpen),
      _ => _IosShelfHome(os: os, onOpen: onOpen, kind: _IosKind.original),
    };
    return KeyedSubtree(key: Key('legacy-$id'), child: home);
  }
}

List<PropApp> _grid(OsSettings os, Set<String> dock) {
  final layout = os.homeOrder.isEmpty ? kHomeOrder : os.homeOrder;
  final apps = <PropApp>[];
  for (final id in layout) {
    if (dock.contains(id)) continue;
    final app = propAppById(id);
    if (app != null) apps.add(app);
  }
  return apps;
}

PropApp? _app(String id) => propAppById(id);

class _HomeScroll extends MaterialScrollBehavior {
  const _HomeScroll();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

enum _IosKind { original, six, seven }

class _IosShelfHome extends StatelessWidget {
  const _IosShelfHome({required this.os, required this.onOpen, required this.kind});

  final OsSettings os;
  final void Function(String id) onOpen;
  final _IosKind kind;

  @override
  Widget build(BuildContext context) {
    const dockIds = ['phone', 'email', 'browser', 'music'];
    final dock = [for (final id in dockIds) ?_app(id)];
    final apps = _grid(os, dockIds.toSet());
    final gloss = kind != _IosKind.seven;
    final label = kind == _IosKind.original ? Colors.white : const Color(0xF2FFFFFF);
    return Stack(
      fit: StackFit.expand,
      children: [
        _iosPaper(kind),
        Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellW = (constraints.maxWidth / 4).clamp(72.0, 88.0);
                  const cellH = 96.0;
                  final columns = 4;
                  final rows = kind == _IosKind.original ? 4 : (constraints.maxHeight > 520 ? 5 : 4);
                  final pageSize = columns * rows;
                  final pages = <List<PropApp>>[];
                  for (var i = 0; i < apps.length; i += pageSize) {
                    final end = i + pageSize > apps.length ? apps.length : i + pageSize;
                    pages.add(apps.sublist(i, end));
                  }
                  if (pages.isEmpty) pages.add(const []);
                  return _PagedGrid(
                    pages: pages,
                    columns: columns,
                    cellWidth: cellW,
                    cellHeight: cellH,
                    gloss: gloss,
                    radius: kind == _IosKind.seven ? 14 : 12,
                    labelColor: label,
                    onOpen: onOpen,
                    searchMark: kind != _IosKind.original,
                  );
                },
              ),
            ),
            _IosDock(apps: dock, kind: kind, onOpen: onOpen),
          ],
        ),
      ],
    );
  }
}

Widget _iosPaper(_IosKind kind) {
  switch (kind) {
    case _IosKind.six:
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9FD4EA), Color(0xFF3E94C8), Color(0xFF1E6A9A), Color(0xFF0E3A5A)],
            stops: [0, 0.32, 0.66, 1],
          ),
        ),
        child: CustomPaint(painter: _WaterPainter(), child: SizedBox.expand()),
      );
    case _IosKind.seven:
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.15, -0.55),
            radius: 1.25,
            colors: [Color(0xFF4E86C8), Color(0xFF1C4E96), Color(0xFF1A2A62), Color(0xFF0A1830)],
            stops: [0, 0.32, 0.68, 1],
          ),
        ),
        child: CustomPaint(painter: _StarPainter(), child: SizedBox.expand()),
      );
    case _IosKind.original:
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A2A2E), Color(0xFF050506)],
          ),
        ),
      );
  }
}

class _WaterPainter extends CustomPainter {
  const _WaterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2;
    for (var i = 0; i < 18; i++) {
      paint.color = Color.fromARGB(i.isEven ? 48 : 28, 255, 255, 255);
      final path = Path();
      final y = size.height * (0.08 + i * 0.055);
      path.moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 12) {
        final wave = math.sin((x / size.width) * math.pi * (2 + i * 0.15) + i) * (6 + (i % 3));
        path.lineTo(x, y + wave);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarPainter extends CustomPainter {
  const _StarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final star = Paint()..color = const Color(0xCCFFFFFF);
    final dim = Paint()..color = const Color(0x66FFFFFF);
    var seed = 17;
    for (var i = 0; i < 70; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final x = (seed % 1000) / 1000 * size.width;
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final y = (seed % 1000) / 1000 * size.height;
      canvas.drawCircle(Offset(x, y), i % 9 == 0 ? 1.4 : 0.7, i % 4 == 0 ? star : dim);
    }
    final cloud = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x553E6A58), Color(0x003E6A58)],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.82, size.height * 0.72), radius: size.width * 0.55));
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.72), size.width * 0.55, cloud);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IosDock extends StatelessWidget {
  const _IosDock({required this.apps, required this.kind, required this.onOpen});

  final List<PropApp> apps;
  final _IosKind kind;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    final gloss = kind != _IosKind.seven;
    final icons = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final app in apps)
          _AppButton(
            key: Key('dock-${app.id}'),
            app: app,
            size: kind == _IosKind.original ? 58 : 54,
            radius: kind == _IosKind.seven ? 13 : 12,
            gloss: gloss,
            label: app.label,
            labelColor: Colors.white,
            onTap: () => onOpen(app.id),
          ),
      ],
    );
    if (kind == _IosKind.original) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE4E6EA), Color(0xFFB4B8BE), Color(0xFF8E939A), Color(0xFF6A6E74)],
            stops: [0, 0.18, 0.55, 1],
          ),
          border: Border(top: BorderSide(color: Color(0xEEFFFFFF), width: 1)),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _BrushedMetal()),
            Padding(padding: const EdgeInsets.fromLTRB(6, 6, 6, 8), child: icons),
          ],
        ),
      );
    }
    if (kind == _IosKind.seven) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x3AF4F7FB),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.45))),
            ),
            child: Padding(padding: const EdgeInsets.fromLTRB(6, 8, 6, 10), child: icons),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x663A3A3E), Color(0x88222226)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: icons),
          ),
        ),
      ),
    );
  }
}

class _BrushedMetal extends StatelessWidget {
  const _BrushedMetal();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _MetalPainter());
  }
}

class _MetalPainter extends CustomPainter {
  const _MetalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x22FFFFFF);
    for (var x = 0.0; x < size.width; x += 3) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    final sheen = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.45), sheen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PagedGrid extends StatefulWidget {
  const _PagedGrid({
    required this.pages,
    required this.columns,
    required this.cellWidth,
    required this.cellHeight,
    required this.gloss,
    required this.radius,
    required this.labelColor,
    required this.onOpen,
    this.top = 8,
    this.searchMark = false,
  });

  final List<List<PropApp>> pages;
  final int columns;
  final double cellWidth;
  final double cellHeight;
  final bool gloss;
  final double radius;
  final Color labelColor;
  final void Function(String id) onOpen;
  final double top;
  final bool searchMark;

  @override
  State<_PagedGrid> createState() => _PagedGridState();
}

class _PagedGridState extends State<_PagedGrid> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _controller,
            scrollBehavior: const _HomeScroll(),
            onPageChanged: (index) => setState(() => _page = index),
            children: [
              for (final page in widget.pages)
                Padding(
                  padding: EdgeInsets.fromLTRB(6, widget.top, 6, 0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _FixedGrid(
                      apps: page,
                      columns: widget.columns,
                      cellWidth: widget.cellWidth,
                      cellHeight: widget.cellHeight,
                      gloss: widget.gloss,
                      radius: widget.radius,
                      labelColor: widget.labelColor,
                      onOpen: widget.onOpen,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.pages.length > 1 || widget.searchMark)
          Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.searchMark) ...[
                Icon(Icons.search, size: 11, color: widget.labelColor.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
              ],
              for (var i = 0; i < widget.pages.length; i++)
                Container(
                  width: i == _page ? 7 : 6,
                  height: i == _page ? 7 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page ? widget.labelColor : widget.labelColor.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FixedGrid extends StatelessWidget {
  const _FixedGrid({
    required this.apps,
    required this.columns,
    required this.cellWidth,
    required this.cellHeight,
    required this.gloss,
    required this.radius,
    required this.labelColor,
    required this.onOpen,
  });

  final List<PropApp> apps;
  final int columns;
  final double cellWidth;
  final double cellHeight;
  final bool gloss;
  final double radius;
  final Color labelColor;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = (apps.length / columns).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < rows; row++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var column = 0; column < columns; column++)
                if (row * columns + column < apps.length)
                  SizedBox(
                    width: cellWidth,
                    height: cellHeight,
                    child: _AppButton(
                      key: Key('home-${apps[row * columns + column].id}'),
                      app: apps[row * columns + column],
                      size: cellWidth * 0.72,
                      radius: radius,
                      gloss: gloss,
                      label: apps[row * columns + column].label,
                      labelColor: labelColor,
                      onTap: () => onOpen(apps[row * columns + column].id),
                    ),
                  )
                else
                  SizedBox(width: cellWidth, height: cellHeight),
            ],
          ),
      ],
    );
  }
}

class _AppButton extends StatelessWidget {
  const _AppButton({
    super.key,
    required this.app,
    required this.onTap,
    required this.size,
    required this.radius,
    required this.gloss,
    required this.labelColor,
    this.label,
  });

  final PropApp app;
  final VoidCallback onTap;
  final double size;
  final double radius;
  final bool gloss;
  final String? label;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GlossIcon(app: app, size: size, radius: radius, gloss: gloss),
          if (label != null) ...[
            const SizedBox(height: 3),
            Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: labelColor, fontSize: 11, shadows: const [
                Shadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(0, 1)),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _GlossIcon extends StatelessWidget {
  const _GlossIcon({required this.app, required this.size, required this.radius, required this.gloss});

  final PropApp app;
  final double size;
  final double radius;
  final bool gloss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 3, offset: Offset(0, 1))],
        gradient: app.id == 'calendar'
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(app.color, Colors.white, gloss ? 0.42 : 0.12)!,
                  app.color,
                  Color.lerp(app.color, Colors.black, gloss ? 0.22 : 0.08)!,
                ],
                stops: const [0, 0.45, 1],
              ),
        color: app.id == 'calendar' ? Colors.white : null,
      ),
      child: Stack(
        children: [
          if (app.id == 'calendar')
            _CalendarFace(size: size, radius: radius, gloss: gloss)
          else
            Center(child: Icon(app.icon, color: Colors.white, size: size * 0.48)),
          if (gloss && app.id != 'calendar')
            Positioned(
              left: 2,
              right: 2,
              top: 2,
              height: size * 0.46,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(radius - 1)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0.7), Colors.white.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CalendarFace extends StatelessWidget {
  const _CalendarFace({required this.size, required this.radius, required this.gloss});

  final double size;
  final double radius;
  final bool gloss;

  @override
  Widget build(BuildContext context) {
    final day = DateTime.now().day.toString();
    if (!gloss) {
      return Column(
        children: [
          const SizedBox(height: 4),
          Text(_weekday(), style: TextStyle(color: const Color(0xFFE23B32), fontSize: size * 0.13, fontWeight: FontWeight.w600)),
          Expanded(
            child: Center(child: Text(day, style: TextStyle(color: Colors.black, fontSize: size * 0.42, fontWeight: FontWeight.w400, height: 1))),
          ),
        ],
      );
    }
    return Column(
      children: [
        Container(
          height: size * 0.26,
          decoration: BoxDecoration(
            color: const Color(0xFFE23B32),
            borderRadius: BorderRadius.vertical(top: Radius.circular((radius - 1).clamp(0, 40))),
          ),
        ),
        Expanded(
          child: Center(child: Text(day, style: TextStyle(color: Colors.black, fontSize: size * 0.4, fontWeight: FontWeight.w500, height: 1))),
        ),
      ],
    );
  }

  String _weekday() {
    const names = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return names[DateTime.now().weekday % 7];
  }
}

class _WindowsHome extends StatelessWidget {
  const _WindowsHome({required this.os, required this.onOpen});

  final OsSettings os;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    final phone = _app('phone');
    final people = _app('contacts');
    final text = _app('messages');
    final mail = _app('email');
    final pictures = _app('photos');
    final games = _app('questly');
    final me = _app('settings');
    return ColoredBox(
      color: const Color(0xFF000000),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inner = constraints.maxWidth - 20;
          const arrow = 36.0;
          final pair = inner - arrow - 16;
          final wide = pair * 0.54;
          final narrow = pair - wide;
          final half = (inner - 8) / 2;
          final tall = wide * 0.92;
          return ListView(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (phone != null)
                    _LiveTile(
                      app: phone,
                      width: wide,
                      height: tall,
                      color: const Color(0xFF1BA1E2),
                      caption: '2',
                      onTap: () => onOpen(phone.id),
                    ),
                  const SizedBox(width: 8),
                  if (people != null)
                    _LiveTile(
                      app: people,
                      width: narrow,
                      height: tall,
                      color: const Color(0xFF1BA1E2),
                      faces: true,
                      onTap: () => onOpen(people.id),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    key: const Key('wp-apps'),
                    onTap: () => onOpen('appstore'),
                    child: Container(
                      width: arrow,
                      height: arrow,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70),
                      ),
                      child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (text != null)
                    _LiveTile(
                      app: text,
                      width: half,
                      height: tall * 0.92,
                      color: const Color(0xFF1BA1E2),
                      caption: '3',
                      onTap: () => onOpen(text.id),
                    ),
                  const SizedBox(width: 8),
                  if (mail != null)
                    _LiveTile(
                      app: mail,
                      width: half,
                      height: tall * 0.92,
                      color: const Color(0xFF1BA1E2),
                      caption: '20',
                      onTap: () => onOpen(mail.id),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (pictures != null)
                _LiveTile(
                  app: pictures,
                  width: inner,
                  height: tall * 0.78,
                  color: const Color(0xFF123A4A),
                  scenic: true,
                  label: 'Pictures',
                  onTap: () => onOpen(pictures.id),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (games != null)
                    _LiveTile(
                      app: games,
                      width: half,
                      height: tall * 0.78,
                      color: const Color(0xFF111111),
                      body: const _GamesMark(),
                      onTap: () => onOpen(games.id),
                    ),
                  const SizedBox(width: 8),
                  if (me != null)
                    _LiveTile(
                      app: me,
                      width: half,
                      height: tall * 0.78,
                      color: const Color(0xFF1BA1E2),
                      body: const _MeMark(),
                      onTap: () => onOpen(me.id),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LiveTile extends StatelessWidget {
  const _LiveTile({
    required this.app,
    required this.width,
    required this.height,
    required this.color,
    required this.onTap,
    this.caption,
    this.label,
    this.faces = false,
    this.scenic = false,
    this.body,
  });

  final PropApp app;
  final double width;
  final double height;
  final Color color;
  final VoidCallback onTap;
  final String? caption;
  final String? label;
  final bool faces;
  final bool scenic;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('home-${app.id}'),
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        color: color,
        padding: body != null || scenic ? EdgeInsets.zero : const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: body ??
            (scenic
                ? Stack(
                    children: [
                      const Positioned.fill(child: _Scenic()),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(label ?? app.label, style: const TextStyle(color: Colors.white, fontSize: 15)),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (faces)
                        const _FaceRow()
                      else
                        Row(
                          children: [
                            Icon(app.icon, color: Colors.white, size: 26),
                            if (caption != null) ...[
                              const SizedBox(width: 8),
                              Text(caption!, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w300, height: 1)),
                            ],
                          ],
                        ),
                      const Spacer(),
                      Text(label ?? app.label, style: const TextStyle(color: Colors.white, fontSize: 15)),
                    ],
                  )),
      ),
    );
  }
}

class _FaceRow extends StatelessWidget {
  const _FaceRow();

  @override
  Widget build(BuildContext context) {
    const hues = [Color(0xFFE8A87C), Color(0xFF7EB6D9), Color(0xFFD98B8B), Color(0xFF8E7CC3)];
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final hue in hues)
          Container(width: 26, height: 26, decoration: BoxDecoration(color: hue, shape: BoxShape.circle)),
      ],
    );
  }
}

class _GamesMark extends StatelessWidget {
  const _GamesMark();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUEST', style: TextStyle(color: Color(0xFFF5A623), fontSize: 18, fontWeight: FontWeight.w800, height: 1)),
        Text('PLAY', style: TextStyle(color: Color(0xFF7AC943), fontSize: 18, fontWeight: FontWeight.w800, height: 1.05)),
        Spacer(),
        Text('Games', style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 14)),
      ],
    );
  }
}

class _MeMark extends StatelessWidget {
  const _MeMark();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3E6B45), Color(0xFF1E3A28)],
            ),
          ),
        ),
        Align(
          alignment: Alignment(0, 0.15),
          child: _Portrait(),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 8, top: 6),
            child: Text('Me', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

class _Portrait extends StatelessWidget {
  const _Portrait();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(color: Color(0xFFE0B090), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: const Icon(Icons.person, color: Color(0xFF6B4632), size: 28),
    );
  }
}

class _Scenic extends StatelessWidget {
  const _Scenic();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8FCBE8), Color(0xFF2E6B4F), Color(0xFF1C3A28)],
        ),
      ),
    );
  }
}

class _HoloHome extends StatelessWidget {
  const _HoloHome({required this.os, required this.onOpen});

  final OsSettings os;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    const hotseat = ['phone', 'email', 'messages', 'browser'];
    final apps = _grid(os, hotseat.toSet());
    final rowA = apps.take(4).toList();
    final rowB = apps.skip(4).take(3).toList();
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2F80ED), Color(0xFF5B4BDB), Color(0xFF7B2FBE), Color(0xFF4A148C)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(right: 24, top: 120, child: _Bokeh(90, Color(0x44E1BEE7))),
          const Positioned(left: -10, top: 280, child: _Bokeh(120, Color(0x33FFFFFF))),
          const Positioned(right: 40, bottom: 160, child: _Bokeh(70, Color(0x449C27B0))),
          Column(
            children: [
              const SizedBox(height: 6),
              const _HoloSearch(),
              const SizedBox(height: 28),
              const _AnalogClock(),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final app in rowA) _roundApp(app),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final app in rowB)
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: _roundApp(app)),
                ],
              ),
              const Spacer(),
              const Divider(color: Color(0x88FFFFFF), height: 1, thickness: 1, indent: 12, endIndent: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_app('phone') case final app?) _roundApp(app, dock: true),
                    if (_app('email') case final app?) _roundApp(app, dock: true),
                    _DrawerButton(onTap: () => onOpen('appstore')),
                    if (_app('messages') case final app?) _roundApp(app, dock: true),
                    if (_app('browser') case final app?) _roundApp(app, dock: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundApp(PropApp app, {bool dock = false}) {
    return GestureDetector(
      key: Key(dock ? 'dock-${app.id}' : 'home-${app.id}'),
      onTap: () => onOpen(app.id),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: dock ? 40 : 52,
              height: dock ? 40 : 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(dock ? 8 : 14),
                color: app.color,
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(app.icon, color: Colors.white, size: dock ? 22 : 26),
            ),
            if (!dock)
              Text(app.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _Bokeh extends StatelessWidget {
  const _Bokeh(this.size, this.color);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _HoloSearch extends StatelessWidget {
  const _HoloSearch();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xCCFFFFFF)),
          color: const Color(0x22FFFFFF),
        ),
        child: const Row(
          children: [
            Text('Google', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400)),
            Spacer(),
            Icon(Icons.mic_none, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AnalogClock extends StatelessWidget {
  const _AnalogClock();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 150, height: 150, child: CustomPaint(painter: _ClockPainter()));
  }
}

class _ClockPainter extends CustomPainter {
  const _ClockPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final dot = Paint()..color = Colors.white;
    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2 - math.pi / 2;
      final at = center + Offset(radius * math.cos(angle), radius * math.sin(angle));
      canvas.drawCircle(at, i % 3 == 0 ? 3.2 : 2.2, dot);
    }
    final hand = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    // A fixed 10:10 pose, the arrangement on the reference face.
    final hour = -math.pi / 2 + (10 / 12) * math.pi * 2;
    final minute = -math.pi / 2 + (2 / 12) * math.pi * 2;
    canvas.drawLine(center, center + Offset(math.cos(hour) * radius * 0.42, math.sin(hour) * radius * 0.42), hand);
    canvas.drawLine(center, center + Offset(math.cos(minute) * radius * 0.62, math.sin(minute) * radius * 0.62), hand..strokeWidth = 2.2);
    canvas.drawCircle(center, 3, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DrawerButton extends StatelessWidget {
  const _DrawerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('holo-drawer'),
      onTap: onTap,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: const CustomPaint(painter: _DotRingPainter(), child: SizedBox.expand()),
          ),
        ),
      ),
    );
  }
}

class _DotRingPainter extends CustomPainter {
  const _DotRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2 - math.pi / 2;
      canvas.drawCircle(center + Offset(math.cos(angle) * radius, math.sin(angle) * radius), 1.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WebOsHome extends StatelessWidget {
  const _WebOsHome({required this.os, required this.onOpen});

  final OsSettings os;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    const dockIds = ['phone', 'photos', 'email', 'messages'];
    final apps = _grid(os, dockIds.toSet());
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9A978C), Color(0xFF6E6A60), Color(0xFF4A4E46)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _BranchPainter())),
          Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final pages = <List<PropApp>>[];
                    const pageSize = 9;
                    for (var i = 0; i < apps.length; i += pageSize) {
                      final end = i + pageSize > apps.length ? apps.length : i + pageSize;
                      pages.add(apps.sublist(i, end));
                    }
                    if (pages.isEmpty) pages.add(const []);
                    final cell = (constraints.maxWidth / 3).clamp(96.0, 118.0);
                    return _PagedGrid(
                      pages: pages,
                      columns: 3,
                      cellWidth: cell,
                      cellHeight: cell + 8,
                      gloss: true,
                      radius: 10,
                      labelColor: Colors.white,
                      onOpen: onOpen,
                      top: 12,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                child: Row(
                  children: [
                    for (final id in dockIds)
                      if (_app(id) case final app?)
                        Expanded(
                          child: GestureDetector(
                            key: Key('dock-${app.id}'),
                            onTap: () => onOpen(app.id),
                            child: Center(child: _GlossIcon(app: app, size: 44, radius: 8, gloss: true)),
                          ),
                        ),
                    GestureDetector(
                      key: const Key('webos-launcher'),
                      onTap: () => onOpen('appstore'),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(color: Color(0xFF2C2C2E), shape: BoxShape.circle),
                        child: const Icon(Icons.refresh, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BranchPainter extends CustomPainter {
  const _BranchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    void branch(Offset start, Offset ctrl, Offset end, double width, Color color) {
      paint
        ..color = color
        ..strokeWidth = width;
      canvas.drawPath(Path()..moveTo(start.dx, start.dy)..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy), paint);
    }
    branch(Offset(size.width * 0.1, size.height), Offset(size.width * 0.4, size.height * 0.45), Offset(size.width * 0.85, size.height * 0.15), 10, const Color(0x665C4033));
    branch(Offset(size.width * 0.2, size.height), Offset(size.width * 0.55, size.height * 0.5), Offset(size.width * 0.95, size.height * 0.35), 6, const Color(0x554E5A40));
    branch(Offset(-10, size.height * 0.7), Offset(size.width * 0.3, size.height * 0.4), Offset(size.width * 0.7, size.height * 0.55), 8, const Color(0x556B5344));
    branch(Offset(size.width * 0.5, size.height), Offset(size.width * 0.2, size.height * 0.6), Offset(size.width * 0.15, size.height * 0.25), 5, const Color(0x444A5C3A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BelleHome extends StatelessWidget {
  const _BelleHome({required this.os, required this.onOpen});

  final OsSettings os;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    final apps = _grid(os, const {});
    final icons = apps.take(8).toList();
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6B13A), Color(0xFFE25B2A), Color(0xFF2F6FBE), Color(0xFF1B4F8A)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        children: [
          _TodayCard(onTap: () => onOpen('calendar')),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 6,
            childAspectRatio: 0.78,
            children: [
              for (final app in icons)
                GestureDetector(
                  key: Key('home-${app.id}'),
                  onTap: () => onOpen(app.id),
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 44,
                        decoration: BoxDecoration(color: app.color, borderRadius: BorderRadius.circular(6)),
                        child: Icon(app.icon, color: Colors.white, size: 24),
                      ),
                      Container(
                        width: 62,
                        margin: const EdgeInsets.only(top: 2),
                        color: const Color(0xE61A1A1A),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          app.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _FlipCard(hour)),
              const SizedBox(width: 8),
              Expanded(child: _FlipCard(minute, sub: '${now.day}/${now.month}/${now.year}')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _PhotoCard('Fiona', const [Color(0xFF5C6B73), Color(0xFF253237)])),
              const SizedBox(width: 8),
              Expanded(child: _PhotoCard('Rachel', const [Color(0xFFD7C4B0), Color(0xFF8C6A55)])),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(left: 28, top: -6, child: _Pin()),
            const Positioned(right: 28, top: -6, child: _Pin()),
            Container(
              key: const Key('belle-today'),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 4, offset: Offset(0, 2))],
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16)),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Text('15:00', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      SizedBox(width: 3, height: 18, child: ColoredBox(color: Color(0xFF1E88E5))),
                      SizedBox(width: 8),
                      Expanded(child: Text('Progress meeting', style: TextStyle(color: Colors.black87), overflow: TextOverflow.ellipsis)),
                    ],
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

class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE8E8E8),
        border: Border.all(color: const Color(0xFF9A9A9A)),
        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 1, offset: Offset(0, 1))],
      ),
    );
  }
}

class _FlipCard extends StatelessWidget {
  const _FlipCard(this.value, {this.sub});

  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w300, height: 1)),
              if (sub != null) Text(sub!, style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 11)),
            ],
          ),
          const Positioned(left: 8, right: 8, child: Divider(color: Color(0xFF3A3A3A), height: 1)),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard(this.name, this.colors);

  final String name;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 110,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: colors))),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                color: const Color(0xCC111111),
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
