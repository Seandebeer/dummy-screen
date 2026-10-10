import 'dart:ui';

import 'package:flutter/material.dart';

import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import 'catalog.dart';
import 'legacy_homes.dart';

class PhoneHome extends StatelessWidget {
  const PhoneHome({
    super.key,
    required this.skin,
    required this.onOpen,
    required this.os,
    this.light = false,
    this.wide = false,
  });

  final String skin;
  final void Function(String id) onOpen;
  final OsSettings os;
  final bool light;
  final bool wide;

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
      return LegacyHome(skin: skin, os: os, light: light, onOpen: onOpen);
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
    final dock = [for (final id in kDockIds) propAppById(id)!];
    final cellW = modern ? 84.0 : 76.0;
    final cellH = modern ? 104.0 : 92.0;
    return Column(
      children: [
        Expanded(
          child: _HomePages(
            apps: grid,
            cellWidth: cellW,
            cellHeight: cellH,
            glossy: chrome == SkinChrome.classic,
            round: chrome == SkinChrome.android,
            labelColor: ink,
            branded: os.branded,
            modern: modern,
            onOpen: onOpen,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final app in dock)
                          SizedBox(
                            width: cellW,
                            child: _IconApp(
                              key: Key('dock-${app.id}'),
                              app: app,
                              glossy: chrome == SkinChrome.classic,
                              round: chrome == SkinChrome.android,
                              labelColor: ink,
                              branded: os.branded,
                              modern: modern,
                              onTap: () => onOpen(app.id),
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
    required this.glossy,
    required this.round,
    required this.labelColor,
    required this.branded,
    this.modern = false,
    required this.onOpen,
  });

  final List<PropApp> apps;
  final double cellWidth;
  final double cellHeight;
  final bool glossy;
  final bool round;
  final Color labelColor;
  final bool branded;
  final bool modern;
  final void Function(String id) onOpen;

  @override
  State<_HomePages> createState() => _HomePagesState();
}

class _HomePagesState extends State<_HomePages> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const foot = 36.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final top = widget.modern ? 22.0 : 4.0;
        final gridWidth = constraints.maxWidth - 16;
        final gridHeight = constraints.maxHeight - foot - top - 4;
        final columns = _spanCount(gridWidth, widget.cellWidth);
        final rows = _spanCount(gridHeight, widget.cellHeight + 10);
        final pageSize = columns * rows;
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
        return Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                scrollBehavior: const _HomeScroll(),
                onPageChanged: (index) => setState(() => _page = index),
                children: [
                  for (final page in pages)
                    Padding(
                      padding: EdgeInsets.fromLTRB(8, top, 8, 4),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _IconGrid(
                          apps: page,
                          columns: columns,
                          cellWidth: widget.cellWidth,
                          cellHeight: widget.cellHeight,
                          glossy: widget.glossy,
                          round: widget.round,
                          labelColor: widget.labelColor,
                          branded: widget.branded,
                          modern: widget.modern,
                          onOpen: widget.onOpen,
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
        );
      },
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({
    required this.apps,
    required this.columns,
    required this.cellWidth,
    required this.cellHeight,
    required this.glossy,
    required this.round,
    required this.labelColor,
    required this.branded,
    required this.modern,
    required this.onOpen,
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
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = (apps.length / columns).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < rows; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
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
                        onTap: () => onOpen(apps[row * columns + column].id),
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

Widget _glyph(PropApp app, {required bool branded}) {
  if (branded) {
    final art = brandMark(app.id);
    if (art != null) {
      return Icon(art.$2, color: Colors.white, size: 32);
    }
  }
  final provider = app.image.isEmpty ? null : imageProviderForPath(app.image);
  if (provider == null) {
    return Icon(app.icon, color: Colors.white, size: 30);
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image(
      image: provider,
      width: 40,
      height: 40,
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
  });

  final PropApp app;
  final VoidCallback onTap;
  final bool glossy;
  final bool round;
  final Color labelColor;
  final bool branded;
  final bool modern;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: modern ? 68 : 60,
            height: modern ? 68 : 60,
            decoration: BoxDecoration(
              color: branded ? (brandMark(app.id)?.$1 ?? app.color) : app.color,
              borderRadius: BorderRadius.circular(
                round ? 20 : (glossy ? 10 : 12),
              ),
              gradient: glossy
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withValues(alpha: 0.45), app.color],
                    )
                  : null,
            ),
            child: _glyph(app, branded: branded),
          ),
          const SizedBox(height: 4),
          Text(
            appLabel(app, branded: branded),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: labelColor),
          ),
        ],
      ),
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
