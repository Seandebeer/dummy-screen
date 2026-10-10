import 'dart:ui';

import 'package:flutter/material.dart';

import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import 'catalog.dart';

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
    final chrome = chromeFor(skin);
    final ink = light ? const Color(0xD9000000) : Colors.white;
    final layout = os.homeOrder.isEmpty ? kHomeOrder : os.homeOrder;
    final columns = wide ? 5 : 4;
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
    final pages = <List<PropApp>>[];
    for (var i = 0; i < grid.length; i += kPageSize) {
      final end = i + kPageSize > grid.length ? grid.length : i + kPageSize;
      pages.add(grid.sublist(i, end));
    }
    if (pages.isEmpty) pages.add(const []);
    final dock = [for (final id in kDockIds) propAppById(id)!];
    return Column(
      children: [
        Expanded(
          child: _HomePages(
            pages: pages,
            columns: columns,
            glossy: chrome == SkinChrome.classic,
            round: chrome == SkinChrome.android,
            labelColor: ink,
            branded: os.branded,
            modern: modern,
            onOpen: onOpen,
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final app in dock)
                _IconApp(
                  key: Key('dock-${app.id}'),
                  app: app,
                  glossy: chrome == SkinChrome.classic,
                  round: chrome == SkinChrome.android,
                  labelColor: ink,
                  branded: os.branded,
                  modern: modern,
                  onTap: () => onOpen(app.id),
                ),
            ],
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

class _HomePages extends StatefulWidget {
  const _HomePages({
    required this.pages,
    required this.columns,
    required this.glossy,
    required this.round,
    required this.labelColor,
    required this.branded,
    this.modern = false,
    required this.onOpen,
  });

  final List<List<PropApp>> pages;
  final int columns;
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
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _controller,
            onPageChanged: (index) => setState(() => _page = index),
            children: [
              for (final page in widget.pages)
                Padding(
                  padding: EdgeInsets.fromLTRB(12, widget.modern ? 22 : 4, 12, 4),
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 6,
                    runSpacing: 14,
                    children: [
                      for (final app in page)
                        SizedBox(
                          width: widget.modern ? 84 : 76,
                          height: widget.modern ? 104 : 92,
                          child: _IconApp(
                            key: Key('home-${app.id}'),
                            app: app,
                            glossy: widget.glossy,
                            round: widget.round,
                            labelColor: widget.labelColor,
                            branded: widget.branded,
                            modern: widget.modern,
                            onTap: () => widget.onOpen(app.id),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (_page == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Center(
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
            ),
          )
        else if (widget.pages.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.pages.length; i++)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page
                          ? widget.labelColor
                          : widget.labelColor.withValues(alpha: 0.35),
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
