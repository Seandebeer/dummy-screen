import 'package:flutter/material.dart';

import '../os_catalog.dart';
import 'catalog.dart';

class PhoneHome extends StatelessWidget {
  const PhoneHome({
    super.key,
    required this.skin,
    required this.onOpen,
    this.light = false,
  });

  final String skin;
  final void Function(String id) onOpen;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final chrome = chromeFor(skin);
    final ink = light ? const Color(0xD9000000) : Colors.white;
    if (chrome == SkinChrome.tiles) {
      return GridView.count(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.1,
        children: [
          for (final id in kHomeOrder)
            if (propAppById(id) case final app?)
              _Tile(app: app, ink: ink, onTap: () => onOpen(app.id)),
        ],
      );
    }
    final grid = [
      for (final id in kHomeOrder)
        if (!kDockIds.contains(id) && propAppById(id) != null) propAppById(id)!,
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
            glossy: chrome == SkinChrome.classic,
            round: chrome == SkinChrome.android,
            labelColor: ink,
            onOpen: onOpen,
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: chrome == SkinChrome.classic ? 0.16 : 0.08,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white24),
          ),
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
                  onTap: () => onOpen(app.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomePages extends StatefulWidget {
  const _HomePages({
    required this.pages,
    required this.glossy,
    required this.round,
    required this.labelColor,
    required this.onOpen,
  });

  final List<List<PropApp>> pages;
  final bool glossy;
  final bool round;
  final Color labelColor;
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final rows = (page.length / 4).ceil().clamp(1, 5);
                    final aspect = constraints.maxWidth / 4 / (constraints.maxHeight / rows);
                    return GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                      crossAxisCount: 4,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      childAspectRatio: aspect.isFinite && aspect > 0 ? aspect : 1,
                      children: [
                        for (final app in page)
                          _IconApp(
                            key: Key('home-${app.id}'),
                            app: app,
                            glossy: widget.glossy,
                            round: widget.round,
                            labelColor: widget.labelColor,
                            onTap: () => widget.onOpen(app.id),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
        if (widget.pages.length > 1)
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

class _IconApp extends StatelessWidget {
  const _IconApp({
    super.key,
    required this.app,
    required this.onTap,
    this.glossy = false,
    this.round = false,
    this.labelColor = Colors.white,
  });

  final PropApp app;
  final VoidCallback onTap;
  final bool glossy;
  final bool round;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: app.color,
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
            child: Icon(app.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            app.label,
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
  const _Tile({required this.app, required this.onTap, required this.ink});

  final PropApp app;
  final VoidCallback onTap;
  final Color ink;

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
                  app.label,
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
