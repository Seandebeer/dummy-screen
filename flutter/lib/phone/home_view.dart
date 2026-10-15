import 'dart:ui';

import 'package:flutter/material.dart';

import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import 'android_home.dart';
import 'catalog.dart';
import 'home_drag.dart';
import 'home_metrics.dart';
import 'icon_finish.dart';
import 'legacy_homes.dart';

class PhoneHome extends StatelessWidget {
  const PhoneHome({
    super.key,
    required this.skin,
    required this.onOpen,
    required this.os,
    this.light = false,
    this.wide = false,
    this.onOrder,
    this.onHide,
  });

  final String skin;
  final void Function(String id) onOpen;
  final OsSettings os;
  final bool light;
  final bool wide;

  /// New home-grid order after a snapped drop.
  final ValueChanged<List<String>>? onOrder;

  /// `dock:id` or `widget:id` dragged off the device onto the stage.
  final ValueChanged<String>? onHide;

  PropApp? _resolve(String id) {
    final app = propAppById(id);
    if (app != null) return app;
    for (final glyph in os.glyphs) {
      if (glyph.id == id && glyph.name.isNotEmpty) {
        return PropApp(
          glyph.id,
          glyph.name,
          const Color(0xFF3A3A3C),
          Icons.apps,
          image: glyph.image,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isLegacySkin(skin)) {
      return LegacyHome(
        skin: skin,
        os: os,
        light: light,
        onOpen: onOpen,
        onOrder: onOrder,
        onHide: onHide,
      );
    }
    if (skin == 'android') {
      return AndroidHome(
        os: os,
        onOpen: onOpen,
        onOrder: onOrder,
        onHide: onHide,
      );
    }
    final chrome = chromeFor(skin);
    final ink = light ? const Color(0xD9000000) : Colors.white;
    final layout = os.homeOrder.isEmpty ? kHomeOrder : os.homeOrder;
    if (chrome == SkinChrome.tiles) {
      return GridView.count(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        crossAxisCount: wide ? 3 : 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.1,
        children: [
          for (final id in layout)
            if (_resolve(id) case final app?)
              _Tile(
                key: Key('home-${app.id}'),
                app: app,
                ink: ink,
                branded: os.branded,
                onTap: () => onOpen(app.id),
              ),
        ],
      );
    }
    final modern = chrome == SkinChrome.modern;
    final grid = [
      for (final id in layout)
        if (_resolve(id) case final app? when !kDockIds.contains(id)) app,
    ];
    final hidden = os.homeHidden.toSet();
    final dock = [
      for (final id in kDockIds)
        if (!hidden.contains('dock:$id')) ?propAppById(id),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = modern
            ? homeMetricsForFrame(constraints.maxWidth, constraints.maxHeight)
            : null;
        final cellW = metrics?.cellWidth ?? 76.0;
        final cellH = metrics?.cellHeight ?? 92.0;
        final iconSize = metrics?.iconSize ?? 60.0;
        return Column(
      children: [
        Expanded(
          child: _HomePages(
            apps: grid,
            cellWidth: cellW,
            cellHeight: cellH,
            iconSize: iconSize,
            lockGrid: modern,
            glossy: chrome == SkinChrome.classic,
            round: chrome == SkinChrome.android,
            labelColor: ink,
            branded: os.branded,
            modern: modern,
            onOpen: onOpen,
            onOrder: onOrder,
          ),
        ),
        if (modern) const SizedBox(height: kHomeSearchLift),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Align(
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.46),
                        Colors.white.withValues(alpha: 0.16),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66FFFFFF), blurRadius: 10, offset: Offset(0, -1)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final app in dock)
                          SizedBox(
                            width: cellW,
                            child: _DockIcon(
                              app: app,
                              glossy: chrome == SkinChrome.classic,
                              round: chrome == SkinChrome.android,
                              labelColor: ink,
                              branded: os.branded,
                              modern: modern,
                              iconSize: iconSize,
                              onTap: () => onOpen(app.id),
                              onHide: onHide == null ? null : () => onHide!('dock:${app.id}'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
        );
      },
    );
  }
}

/// How many fixed-size cells fit along [extent]. [stride] is the cell plus
/// the gap that follows every cell, including the last.
int _spanCount(double extent, double stride) {
  if (extent <= 0 || stride <= 0) return 1;
  final count = (extent / stride).floor();
  return count < 1 ? 1 : count;
}

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

class _HomePages extends StatefulWidget {
  const _HomePages({
    required this.apps,
    required this.cellWidth,
    required this.cellHeight,
    required this.iconSize,
    this.lockGrid = false,
    required this.glossy,
    required this.round,
    required this.labelColor,
    required this.branded,
    this.modern = false,
    required this.onOpen,
    this.onOrder,
  });

  final List<PropApp> apps;
  final double cellWidth;
  final double cellHeight;
  final double iconSize;
  final bool lockGrid;
  final bool glossy;
  final bool round;
  final Color labelColor;
  final bool branded;
  final bool modern;
  final void Function(String id) onOpen;
  final ValueChanged<List<String>>? onOrder;

  @override
  State<_HomePages> createState() => _HomePagesState();
}

class _HomePagesState extends State<_HomePages> {
  final _controller = PageController();
  final _gridKey = GlobalKey();
  int _page = 0;
  String? _dragId;
  Offset? _finger;
  int? _slot;
  bool _off = false;
  OverlayEntry? _ghost;
  int _columns = 1;
  int _rows = 1;
  int _pageSize = 1;

  @override
  void dispose() {
    _ghost?.remove();
    _controller.dispose();
    super.dispose();
  }

  List<String> get _ids => [for (final app in widget.apps) app.id];

  void _beginDrag(PropApp app, LongPressStartDetails details) {
    setState(() {
      _dragId = app.id;
      _finger = details.globalPosition;
      _slot = widget.apps.indexWhere((item) => item.id == app.id);
      _off = false;
    });
    _syncGhost();
  }

  void _moveDrag(LongPressMoveUpdateDetails details) {
    final home = context.findRenderObject() as RenderBox?;
    final grid = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    final off = home == null ? false : droppedOffDevice(home, details.globalPosition);
    int? slot;
    if (!off && grid != null) {
      final local = gridSlot(
        grid,
        details.globalPosition,
        columns: _columns,
        rows: _rows,
        cellWidth: widget.cellWidth,
        cellHeight: widget.cellHeight,
        gap: 10,
      );
      if (local != null) {
        slot = _page * _pageSize + local;
        if (slot > widget.apps.length) slot = widget.apps.length;
      }
    }
    setState(() {
      _finger = details.globalPosition;
      _off = off;
      if (slot != null) _slot = slot;
    });
    _syncGhost();
  }

  void _endDrag() {
    final id = _dragId;
    final order = widget.onOrder;
    if (id != null && order != null) {
      final index = _off ? null : _slot;
      order(movedOrder(_ids, id, remove: _off, index: index));
    }
    _ghost?.remove();
    _ghost = null;
    setState(() {
      _dragId = null;
      _finger = null;
      _slot = null;
      _off = false;
    });
  }

  void _syncGhost() {
    if (_dragId == null || _finger == null) return;
    _ghost?.remove();
    final finger = _finger!;
    final off = _off;
    final app = widget.apps.where((item) => item.id == _dragId).firstOrNull;
    if (app == null) return;
    _ghost = OverlayEntry(
      builder: (context) => Positioned(
        left: finger.dx - widget.cellWidth / 2,
        top: finger.dy - 36,
        width: widget.cellWidth,
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.92,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconApp(
                  app: app,
                  glossy: widget.glossy,
                  round: widget.round,
                  labelColor: widget.labelColor,
                  branded: widget.branded,
                  modern: widget.modern,
                  iconSize: widget.iconSize,
                  onTap: () {},
                ),
                if (off)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xE6FF453A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Remove',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_ghost!);
  }

  @override
  Widget build(BuildContext context) {
    const foot = 36.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final top = widget.modern ? 22.0 : 4.0;
        final gridWidth = constraints.maxWidth - 16;
        final gridHeight = constraints.maxHeight - foot - top - 4;
        final columns = widget.lockGrid
            ? kHomeIconColumns
            : _spanCount(gridWidth, widget.cellWidth);
        final rows = widget.lockGrid
            ? kHomeIconRows
            : _spanCount(gridHeight, widget.cellHeight + 10);
        final pageSize = columns * rows;
        _columns = columns;
        _rows = rows;
        _pageSize = pageSize;
        final pages = <List<PropApp>>[];
        for (var i = 0; i < widget.apps.length; i += pageSize) {
          final end = i + pageSize > widget.apps.length ? widget.apps.length : i + pageSize;
          pages.add(widget.apps.sublist(i, end));
        }
        if (pages.isEmpty) pages.add(const []);
        final shown = _page >= pages.length ? pages.length - 1 : _page;
        if (shown != _page) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _page = shown);
            if (_controller.hasClients) _controller.jumpToPage(shown);
          });
        }
        return Stack(
          children: [
            Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                scrollBehavior: const _HomeScroll(),
                physics: _dragId != null ? const NeverScrollableScrollPhysics() : null,
                onPageChanged: (index) => setState(() => _page = index),
                children: [
                  for (final page in pages)
                    Padding(
                      padding: EdgeInsets.fromLTRB(8, top, 8, 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: _IconGrid(
                          key: page == pages[shown] ? _gridKey : null,
                          apps: page,
                          columns: columns,
                          cellWidth: widget.cellWidth,
                          cellHeight: widget.cellHeight,
                          glossy: widget.glossy,
                          round: widget.round,
                          labelColor: widget.labelColor,
                          branded: widget.branded,
                          modern: widget.modern,
                          iconSize: widget.iconSize,
                          onOpen: widget.onOpen,
                          draggingId: _dragId,
                          highlight: _slot == null ? null : _slot! - _page * _pageSize,
                          onHoldStart: _beginDrag,
                          onHoldMove: _moveDrag,
                          onHoldEnd: _endDrag,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: foot,
              child: shown == 0
                  ? Center(
                      child: Container(
                        key: const Key('home-search'),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search, size: 16, color: widget.labelColor.withValues(alpha: 0.85)),
                            const SizedBox(width: 6),
                            Text(
                              'Search',
                              style: TextStyle(
                                color: widget.labelColor.withValues(alpha: 0.85),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : pages.length > 1
                      ? Row(
                          key: const Key('home-pages'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < pages.length; i++)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == shown
                                      ? widget.labelColor
                                      : widget.labelColor.withValues(alpha: 0.35),
                                ),
                              ),
                          ],
                        )
                      : const SizedBox.shrink(),
            ),
          ],
            ),
          ],
        );
      },
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({
    super.key,
    required this.apps,
    required this.columns,
    required this.cellWidth,
    required this.cellHeight,
    required this.glossy,
    required this.round,
    required this.labelColor,
    required this.branded,
    required this.modern,
    required this.iconSize,
    required this.onOpen,
    this.draggingId,
    this.highlight,
    this.onHoldStart,
    this.onHoldMove,
    this.onHoldEnd,
  });

  final List<PropApp> apps;
  final int columns;
  final double cellWidth;
  final double cellHeight;
  final bool glossy;
  final bool round;
  final Color labelColor;
  final bool branded;
  final bool modern;
  final double iconSize;
  final void Function(String id) onOpen;
  final String? draggingId;
  final int? highlight;
  final void Function(PropApp app, LongPressStartDetails details)? onHoldStart;
  final void Function(LongPressMoveUpdateDetails details)? onHoldMove;
  final VoidCallback? onHoldEnd;

  @override
  Widget build(BuildContext context) {
    final rows = (apps.length / columns).ceil();
    final grid = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < rows; row++)
          Padding(
            padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var column = 0; column < columns; column++)
                  if (row * columns + column < apps.length)
                    SizedBox(
                      width: cellWidth,
                      height: cellHeight,
                      child: _IconApp(
                        key: Key('home-${apps[row * columns + column].id}'),
                        app: apps[row * columns + column],
                        glossy: glossy,
                        round: round,
                        labelColor: labelColor,
                        branded: branded,
                        modern: modern,
                        iconSize: iconSize,
                        dimmed: draggingId == apps[row * columns + column].id,
                        onTap: () => onOpen(apps[row * columns + column].id),
                        onHoldStart: onHoldStart == null
                            ? null
                            : (details) => onHoldStart!(apps[row * columns + column], details),
                        onHoldMove: onHoldMove,
                        onHoldEnd: onHoldEnd,
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
    if (draggingId == null) return grid;
    return Stack(
      children: [
        grid,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: SnapGridPainter(
                columns: columns,
                rows: rows < 1 ? 1 : rows,
                cellWidth: cellWidth,
                cellHeight: cellHeight,
                gap: 10,
                slot: highlight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Widget _glyph(PropApp app, {required bool branded, double size = 30}) {
  if (branded) {
    final art = brandMark(app.id);
    if (art != null) {
      return Icon(art.$2, color: Colors.white, size: size);
    }
  }
  final provider = app.image.isEmpty ? null : imageProviderForPath(app.image);
  if (provider == null) {
    return Icon(app.icon, color: Colors.white, size: size);
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image(
      image: provider,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) =>
          Icon(app.icon, color: Colors.white, size: 22),
    ),
  );
}

class _IconApp extends StatelessWidget {
  const _IconApp({
    super.key,
    required this.app,
    required this.onTap,
    this.glossy = false,
    this.round = false,
    this.labelColor = Colors.white,
    this.branded = false,
    this.modern = false,
    this.iconSize = 60,
    this.showLabel = true,
    this.dimmed = false,
    this.onHoldStart,
    this.onHoldMove,
    this.onHoldEnd,
  });

  final PropApp app;
  final VoidCallback onTap;
  final bool glossy;
  final bool round;
  final Color labelColor;
  final bool branded;
  final bool modern;
  final double iconSize;
  final bool showLabel;
  final bool dimmed;
  Color get _iconColor => branded ? (brandMark(app.id)?.$1 ?? app.color) : app.color;

  final GestureLongPressStartCallback? onHoldStart;
  final GestureLongPressMoveUpdateCallback? onHoldMove;
  final VoidCallback? onHoldEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: onHoldStart,
      onLongPressMoveUpdate: onHoldMove,
      onLongPressEnd: onHoldEnd == null ? null : (_) => onHoldEnd!(),
      onLongPressCancel: onHoldEnd,
      child: Opacity(
        opacity: dimmed ? 0.25 : 1,
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            foregroundDecoration: modern && !glossy
                ? edgeLightRim(radius: round ? 20 : 14)
                : null,
            decoration: BoxDecoration(
              color: modern && !glossy
                  ? null
                  : (branded ? (brandMark(app.id)?.$1 ?? app.color) : app.color),
              borderRadius: BorderRadius.circular(
                round ? 20 : (glossy ? 10 : (modern ? 14 : 12)),
              ),
              gradient: glossy
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withValues(alpha: 0.45), app.color],
                    )
                  : modern
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(_iconColor, Colors.white, 0.28)!,
                            _iconColor,
                            Color.lerp(_iconColor, Colors.black, 0.22)!,
                          ],
                          stops: const [0, 0.42, 1],
                        )
                      : null,
              boxShadow: modern && !glossy
                  ? const [
                      BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3)),
                    ]
                  : null,
            ),
            child: _glyph(app, branded: branded, size: iconSize * 0.46),
          ),
          if (showLabel) ...[
            const SizedBox(height: 4),
            Text(
              appLabel(app, branded: branded),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
          ],
        ],
        ),
      ),
    );
  }
}

class _DockIcon extends StatefulWidget {
  const _DockIcon({
    required this.app,
    required this.onTap,
    required this.glossy,
    required this.round,
    required this.labelColor,
    required this.branded,
    required this.modern,
    this.iconSize = 60,
    this.onHide,
  });

  final PropApp app;
  final VoidCallback onTap;
  final bool glossy;
  final bool round;
  final Color labelColor;
  final bool branded;
  final bool modern;
  final double iconSize;
  final VoidCallback? onHide;

  @override
  State<_DockIcon> createState() => _DockIconState();
}

class _DockIconState extends State<_DockIcon> {
  bool _off = false;
  OverlayEntry? _ghost;

  @override
  void dispose() {
    _ghost?.remove();
    super.dispose();
  }

  RenderBox? get _phone {
    RenderBox? found;
    context.visitAncestorElements((element) {
      final object = element.renderObject;
      if (object is RenderBox && object.hasSize && object.size.shortestSide > 180) {
        found = object;
        return false;
      }
      return true;
    });
    return found;
  }

  void _move(LongPressMoveUpdateDetails details) {
    final phone = _phone;
    final off = phone != null && droppedOffDevice(phone, details.globalPosition);
    setState(() => _off = off);
    _ghost?.remove();
    _ghost = OverlayEntry(
      builder: (context) => Positioned(
        left: details.globalPosition.dx - 34,
        top: details.globalPosition.dy - 34,
        width: 76,
        child: IgnorePointer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconApp(
                app: widget.app,
                glossy: widget.glossy,
                round: widget.round,
                labelColor: widget.labelColor,
                branded: widget.branded,
                modern: widget.modern,
                iconSize: widget.iconSize,
                showLabel: false,
                onTap: () {},
              ),
              if (off)
                const Text('Remove', style: TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_ghost!);
  }

  void _end() {
    if (_off) widget.onHide?.call();
    _ghost?.remove();
    _ghost = null;
    setState(() => _off = false);
  }

  @override
  Widget build(BuildContext context) {
    return _IconApp(
      key: Key('dock-${widget.app.id}'),
      app: widget.app,
      glossy: widget.glossy,
      round: widget.round,
      labelColor: widget.labelColor,
      branded: widget.branded,
      modern: widget.modern,
      iconSize: widget.iconSize,
      showLabel: false,
      dimmed: _off,
      onTap: widget.onTap,
      onHoldStart: widget.onHide == null ? null : (_) {},
      onHoldMove: widget.onHide == null ? null : _move,
      onHoldEnd: widget.onHide == null ? null : _end,
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.app,
    required this.onTap,
    required this.ink,
    this.branded = false,
  });

  final PropApp app;
  final VoidCallback onTap;
  final Color ink;
  final bool branded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: app.color,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(app.icon, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appLabel(app, branded: branded),
                  style: TextStyle(fontWeight: FontWeight.w600, color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
