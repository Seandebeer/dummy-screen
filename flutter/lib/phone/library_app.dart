import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'app_catalog.dart';
import 'catalog.dart';

/// Core phone apps, in the same order as `coreApps` in the Base44 OS.
const _coreIds = [
  'phone',
  'messages',
  'email',
  'clock',
  'music',
  'contacts',
  'settings',
  'calculator',
  'calendar',
  'notes',
  'camera',
  'photos',
  'videocall',
  'maps',
  'appstore',
  'facepage',
  'photogram',
  'vidtube',
  'quicktok',
  'browser',
  'webdeck',
  'news',
  'property',
  'fitness',
];

class _LibApp {
  const _LibApp(this.id, this.label, this.color, this.icon, this.sub);

  final String id;
  final String label;
  final Color color;
  final IconData icon;
  final String sub;
}

List<_LibApp> _coreApps() => [
  for (final id in _coreIds)
    if (propAppById(id) case final app?)
      _LibApp(app.id, app.label, app.color, app.icon, 'Fully working'),
];

List<_LibApp> _everyApp() => [
  for (final id in _coreIds)
    if (propAppById(id) case final app?)
      _LibApp(app.id, app.label, app.color, app.icon, ''),
  for (final section in mockCatalog)
    for (final app in section.apps)
      _LibApp(app.id, app.label, app.color, app.icon, app.sub),
];

/// App Library, matching `AppLibrary.jsx`.
class LibraryApp extends StatefulWidget {
  const LibraryApp({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<LibraryApp> createState() => _LibraryAppState();
}

class _LibraryAppState extends State<LibraryApp> {
  final _query = TextEditingController();
  final _open = <String>{};

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _toggleHome(String id) {
    if (kDockIds.contains(id)) return;
    final current = widget.device.os.homeOrder.isEmpty
        ? [...kHomeOrder]
        : [...widget.device.os.homeOrder];
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    widget.store.updateOs(
      widget.device.id,
      (os) => os.copyWith(homeOrder: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.text.trim().toLowerCase();
    final order = widget.device.os.homeOrder.isEmpty
        ? kHomeOrder
        : widget.device.os.homeOrder;
    final favs = widget.store.appFavorites.toSet();
    final categories = [...mockCatalog]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final sections = <({String id, String name, List<_LibApp> apps})>[
      (
        id: 'favourites',
        name: 'Favourites',
        apps: [
          for (final app in _everyApp())
            if (favs.contains(app.id)) app,
        ],
      ),
      (id: 'functional', name: 'Functional', apps: _coreApps()),
      for (final section in categories)
        (
          id: section.id,
          name: section.name,
          apps: [
            for (final app in section.apps)
              _LibApp(app.id, app.label, app.color, app.icon, app.sub),
          ],
        ),
    ];
    final visibleSections = [
      for (final section in sections)
        (
          id: section.id,
          name: section.name,
          apps: query.isEmpty
              ? section.apps
              : [
                  for (final app in section.apps)
                    if (app.label.toLowerCase().contains(query)) app,
                ],
        ),
    ];
    final anyMatch = visibleSections.any((section) => section.apps.isNotEmpty);

    return ColoredBox(
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'App Library',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, size: 13, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _query,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search apps',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'STAR FAVOURITES · TOGGLE APPS ON THE HOME SCREEN',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                for (final section in visibleSections)
                  if (query.isEmpty || section.apps.isNotEmpty)
                    _Section(
                      name: section.name,
                      count: section.apps.length,
                      favourites: section.id == 'favourites',
                      expanded: query.isNotEmpty || _open.contains(section.id),
                      onToggle: () => setState(() {
                        if (_open.contains(section.id)) {
                          _open.remove(section.id);
                        } else {
                          _open.add(section.id);
                        }
                      }),
                      child: section.id == 'favourites' && section.apps.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                              child: Text(
                                'Tap the star on any app to save it here',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 10,
                                ),
                              ),
                            )
                          : _AppGrid(
                              apps: section.apps,
                              order: order,
                              favs: favs,
                              onStar: widget.store.toggleAppFavorite,
                              onEye: _toggleHome,
                            ),
                    ),
                if (query.isNotEmpty && !anyMatch)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      'No apps match that search',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
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

class _Section extends StatelessWidget {
  const _Section({
    required this.name,
    required this.count,
    required this.favourites,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String name;
  final int count;
  final bool favourites;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: Row(
                  children: [
                    if (favourites) ...[
                      Icon(Icons.star, size: 12, color: kAccent),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        name.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Transform.rotate(
                      angle: expanded ? 3.14159 : 0,
                      child: Icon(
                        Icons.expand_more,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _AppGrid extends StatelessWidget {
  const _AppGrid({
    required this.apps,
    required this.order,
    required this.favs,
    required this.onStar,
    required this.onEye,
  });

  final List<_LibApp> apps;
  final List<String> order;
  final Set<String> favs;
  final void Function(String id) onStar;
  final void Function(String id) onEye;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = (constraints.maxWidth - 8) / 2;
        final compact = cell < 168;
        final icon = compact ? 26.0 : 36.0;
        final button = compact ? 22.0 : 28.0;
        final gap = compact ? 4.0 : 8.0;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: apps.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: compact ? 48 : 56,
          ),
          itemBuilder: (context, index) {
            final app = apps[index];
            final docked = kDockIds.contains(app.id);
            final visible = docked || order.contains(app.id);
            final faved = favs.contains(app.id);
            return Opacity(
              opacity: visible ? 1 : 0.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: visible
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: visible
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8, vertical: 4),
                  child: Row(
                    children: [
                      AppIconBadge(
                        color: app.color,
                        icon: app.icon,
                        size: icon,
                        iconSize: compact ? 13 : 16,
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white, fontSize: compact ? 11 : 12),
                            ),
                            Text(
                              app.sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: compact ? 8 : 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _RoundIcon(
                        tooltip: 'Favourite',
                        onTap: () => onStar(app.id),
                        background: faved
                            ? kAccent.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        icon: faved ? Icons.star : Icons.star_border,
                        color: faved ? kAccent : Colors.white.withValues(alpha: 0.4),
                        size: compact ? 11 : 13,
                        box: button,
                      ),
                      SizedBox(width: compact ? 2 : 4),
                      _RoundIcon(
                        tooltip: docked
                            ? 'Stays in the dock'
                            : (visible ? 'Hide from home' : 'Show on home'),
                        onTap: docked ? null : () => onEye(app.id),
                        background: visible
                            ? Colors.white.withValues(alpha: 0.20)
                            : Colors.white.withValues(alpha: 0.05),
                        icon: visible ? Icons.visibility : Icons.visibility_off,
                        color: visible ? Colors.white : Colors.white.withValues(alpha: 0.5),
                        size: compact ? 12 : 14,
                        box: button,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.tooltip,
    required this.onTap,
    required this.background,
    required this.icon,
    required this.color,
    required this.size,
    this.box = 28,
  });

  final String tooltip;
  final VoidCallback? onTap;
  final Color background;
  final IconData icon;
  final Color color;
  final double size;
  final double box;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: box,
            height: box,
            child: Icon(icon, size: size, color: color),
          ),
        ),
      ),
    );
  }
}

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.color,
    required this.icon,
    this.size = 36,
    this.iconSize = 16,
  });

  final Color color;
  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.23),
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}

/// Placeholder screen for a catalog app, matching `MockApp.jsx`.
class MockScreen extends StatelessWidget {
  const MockScreen({super.key, required this.app});

  final CatalogApp app;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14162A), Color(0xFF050609)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconBadge(color: app.color, icon: app.icon, size: 80, iconSize: 38),
            const SizedBox(height: 16),
            Text(
              app.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MOCK APP · PROP ONLY',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'tap the home bar to return',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
