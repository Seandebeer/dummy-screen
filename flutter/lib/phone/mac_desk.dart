import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import 'app_catalog.dart';
import 'catalog.dart';

/// Built-in Mac shelf, left to right: the same daily drivers the phone docks,
/// then the desk tools. Settings and App Store sit on the end.
const kMacDockIds = [
  ...kDockIds,
  'call',
  'tracking',
  'markers',
  'video',
  'word',
  'excel',
  'terminal',
  'settings',
  'appstore',
];

const kMacFileNames = [
  'Documents',
  'Images',
  'Movies',
  'Presentations',
  'Spreadsheets',
  'Work',
  'Projects',
];

/// Menu-bar tokens. An empty saved list still means this set.
const kMacStatusDefault = ['wifi', 'battery', 'clock', 'search', 'control'];

/// Tools that exist only on a computer.
const kDeskTools = {
  'call',
  'tracking',
  'markers',
  'video',
  'word',
  'excel',
  'terminal',
};

const kMacPainted = {
  ...kDeskTools,
  'settings',
  'appstore',
};

class MacGlyph {
  const MacGlyph(this.label, this.icon, this.color, {this.image = ''});

  final String label;
  final IconData icon;
  final Color color;
  final String image;
}

MacGlyph macGlyph(String id, OsSettings os) {
  final base = _macGlyph(id, os);
  final named = os.deskNames[id]?.trim() ?? '';
  if (named.isEmpty) return base;
  return MacGlyph(named, base.icon, base.color, image: base.image);
}

MacGlyph _macGlyph(String id, OsSettings os) {
  if (id.startsWith('file:') || id.startsWith('folder:')) {
    final fallback = id.startsWith('file:') ? id.substring(5) : 'New Folder';
    return MacGlyph(fallback, Icons.folder_outlined, Colors.white);
  }
  if (id == 'appstore') {
    return const MacGlyph('App Store', Icons.shopping_bag, Color(0xFF0A84FF));
  }
  if (id == 'settings') {
    return const MacGlyph('Settings', Icons.settings, Color(0xFF636366));
  }
  for (final glyph in os.glyphs) {
    if (glyph.id == id) {
      return MacGlyph(
        glyph.name,
        Icons.apps,
        const Color(0xFF3A3A3C),
        image: glyph.image,
      );
    }
  }
  final prop = propAppById(id);
  if (prop != null) {
    return MacGlyph(
      appLabel(prop, branded: os.branded),
      prop.icon,
      prop.color,
      image: prop.image,
    );
  }
  for (final section in mockCatalog) {
    for (final app in section.apps) {
      if (app.id == id) return MacGlyph(app.label, app.icon, app.color);
    }
  }
  const labels = {
    'call': 'Call',
    'tracking': 'Tracking',
    'markers': 'UI Markers',
    'video': 'Video',
    'word': 'Word',
    'excel': 'Excel',
    'terminal': 'Terminal',
    'social': 'Social',
    'photos': 'Photos',
    'music': 'Music',
    'settings': 'Settings',
    'appstore': 'App Store',
  };
  return MacGlyph(labels[id] ?? 'App', Icons.apps, const Color(0xFF8E8E93));
}

/// Dock order, desktop spots, and menu-bar tokens saved on [OsSettings].
class MacLayout {
  static List<String> dock(OsSettings os) {
    if (os.macDock.isEmpty) return kMacDockIds;
    return [for (final id in os.macDock) if (id != '-') id];
  }

  static bool deskCustom(OsSettings os) => os.macPlaces.containsKey('_');

  /// The desktop starts with page one of the home screen on the left and the
  /// file column on the right.
  static List<String> defaultDesktop() => [
    for (final id in homePageOne())
      if (!kMacDockIds.contains(id)) id,
    for (final name in kMacFileNames) 'file:$name',
  ];

  static List<String> desktop(OsSettings os) {
    if (!deskCustom(os)) return defaultDesktop();
    return [for (final id in os.macDesktop) if (id.isNotEmpty) id];
  }

  static List<String> status(OsSettings os) {
    if (os.macStatus.isEmpty) return kMacStatusDefault;
    return [for (final id in os.macStatus) if (id != '-') id];
  }

  static Map<String, Offset> defaultSpots(Size area) {
    const itemWidth = 108.0;
    const itemHeight = 64.0;
    final spots = <String, Offset>{};
    final apps = [
      for (final id in homePageOne())
        if (!kMacDockIds.contains(id)) id,
    ];
    const appWidth = 84.0;
    const appHeight = 72.0;
    final rows = ((area.height - 16) / appHeight).floor().clamp(1, 12);
    for (var i = 0; i < apps.length; i++) {
      spots[apps[i]] = Offset(
        10 + (i ~/ rows) * appWidth,
        10 + (i % rows) * appHeight,
      );
    }
    spots.addAll(_fileSpots(area, itemWidth, itemHeight));
    return spots;
  }

  static Map<String, Offset> _fileSpots(
    Size area,
    double itemWidth,
    double itemHeight,
  ) {
    final count = kMacFileNames.length;
    final gaps = count - 1;
    final free = area.height - 12 - itemHeight * count;
    final gap = gaps == 0 ? 0.0 : (free / gaps).clamp(4.0, 30.0);
    final left = (area.width - 18 - itemWidth).clamp(0.0, area.width);
    final spots = {
      for (var i = 0; i < count; i++)
        'file:${kMacFileNames[i]}': Offset(left, 8 + i * (itemHeight + gap)),
    };
    final bottom = spots.values.last.dy + itemHeight;
    if (bottom <= area.height || bottom <= 0) return spots;
    final scale = (area.height - 4) / bottom;
    return {
      for (final entry in spots.entries)
        entry.key: Offset(entry.value.dx, entry.value.dy * scale),
    };
  }

  static Map<String, Offset> spots(OsSettings os, Size area) {
    final saved = deskCustom(os);
    final defaults = defaultSpots(area);
    final out = <String, Offset>{};
    var extra = 0;
    for (final id in desktop(os)) {
      final raw = os.macPlaces[id];
      if (saved && raw != null) {
        out[id] = decode(raw, area);
      } else if (defaults.containsKey(id)) {
        out[id] = defaults[id]!;
      } else {
        out[id] = Offset(16 + (extra % 4) * 116, 16 + (extra ~/ 4) * 86);
        extra++;
      }
    }
    return out;
  }

  static String encode(Offset local, Size area) {
    final width = area.width <= 0 ? 1.0 : area.width;
    final height = area.height <= 0 ? 1.0 : area.height;
    final x = (local.dx / width * 1000).round().clamp(0, 1000);
    final y = (local.dy / height * 1000).round().clamp(0, 1000);
    return '$x,$y';
  }

  static Offset decode(String raw, Size area) {
    final parts = raw.split(',');
    final x = int.tryParse(parts.first) ?? 0;
    final y = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return Offset(area.width * x / 1000, area.height * y / 1000);
  }

  static Offset clampSpot(Offset spot, Size area) {
    const itemWidth = 108.0;
    const itemHeight = 70.0;
    final maxX = area.width <= itemWidth ? 0.0 : area.width - itemWidth;
    final maxY = area.height <= itemHeight ? 0.0 : area.height - itemHeight;
    return Offset(spot.dx.clamp(0.0, maxX), spot.dy.clamp(0.0, maxY));
  }

  static OsSettings writeDock(OsSettings os, List<String> ids) =>
      os.copyWith(macDock: ids.isEmpty ? const ['-'] : ids);

  static OsSettings writeDesktop(
    OsSettings os,
    Map<String, Offset> spots,
    Size area,
  ) {
    final places = <String, String>{'_': '1'};
    for (final entry in spots.entries) {
      places[entry.key] = encode(clampSpot(entry.value, area), area);
    }
    return os.copyWith(macDesktop: spots.keys.toList(), macPlaces: places);
  }

  static OsSettings writeStatus(OsSettings os, List<String> items) =>
      os.copyWith(macStatus: items.isEmpty ? const ['-'] : items);
}

/// The next "New Folder" name that is not already on the desktop.
String freshFolderName(OsSettings os) {
  final used = <String>{
    ...os.deskNames.values,
    for (final id in MacLayout.desktop(os)) _macGlyph(id, os).label,
    ...kMacFileNames,
  };
  var name = 'New Folder';
  var count = 2;
  while (used.contains(name)) {
    name = 'New Folder $count';
    count++;
  }
  return name;
}

/// Adds a desktop folder. A spot places it on the Mac desktop.
OsSettings addDeskFolder(OsSettings os, {Offset? spot, Size? area}) {
  final id = 'folder:${DateTime.now().microsecondsSinceEpoch}';
  final names = Map<String, String>.from(os.deskNames)
    ..[id] = freshFolderName(os);
  final folders = [...os.deskFolders, id];
  if (spot == null || area == null) {
    return os.copyWith(deskFolders: folders, deskNames: names);
  }
  final spots = Map<String, Offset>.from(MacLayout.spots(os, area));
  spots[id] = MacLayout.clampSpot(spot, area);
  return MacLayout.writeDesktop(os, spots, area).copyWith(
    deskFolders: folders,
    deskNames: names,
  );
}

/// Stores the name typed onto a desktop icon. An empty name restores the
/// original label.
OsSettings renameDeskItem(OsSettings os, String id, String name) {
  final names = Map<String, String>.from(os.deskNames);
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    names.remove(id);
  } else {
    names[id] = trimmed;
  }
  return os.copyWith(deskNames: names);
}

/// Same catalog as the phone App Library, with Dock and Desktop actions.
class MacAppStore extends StatefulWidget {
  const MacAppStore({
    super.key,
    required this.store,
    required this.device,
    required this.onDock,
    required this.onDesktop,
  });

  final StageStore store;
  final PropDevice device;
  final ValueChanged<String> onDock;
  final ValueChanged<String> onDesktop;

  @override
  State<MacAppStore> createState() => _MacAppStoreState();
}

class _MacAppStoreState extends State<MacAppStore> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final os = widget.device.os;
    final query = _query.text.trim().toLowerCase();
    final dock = MacLayout.dock(os).toSet();
    final desk = MacLayout.desktop(os).toSet();
    final favs = widget.store.appFavorites.toSet();
    final sections = <({String name, List<(String, MacGlyph)> apps})>[
      (
        name: 'Favourites',
        apps: [
          for (final id in widget.store.appFavorites)
            (id, macGlyph(id, os)),
        ],
      ),
      (
        name: 'Custom',
        apps: [
          for (final glyph in os.glyphs)
            (
              glyph.id,
              MacGlyph(
                glyph.name,
                Icons.apps,
                const Color(0xFF3A3A3C),
                image: glyph.image,
              ),
            ),
        ],
      ),
      (
        name: 'Functional',
        apps: [
          for (final app in kPropApps) (app.id, macGlyph(app.id, os)),
        ],
      ),
      for (final section in mockCatalog)
        (
          name: section.name,
          apps: [
            for (final app in section.apps) (app.id, macGlyph(app.id, os)),
          ],
        ),
    ];
    return ColoredBox(
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              key: const Key('mac-store-search'),
              controller: _query,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search apps',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 16),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              key: const Key('mac-store-scroll'),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                for (final section in sections)
                  if (section.apps.isNotEmpty || section.name == 'Custom')
                    _StoreSection(
                      name: section.name,
                      searching: query.isNotEmpty,
                      apps: [
                        for (final app in section.apps)
                          if (query.isEmpty ||
                              app.$2.label.toLowerCase().contains(query))
                            app,
                      ],
                      favs: favs,
                      dock: dock,
                      desk: desk,
                      onFav: widget.store.toggleAppFavorite,
                      onDock: widget.onDock,
                      onDesktop: widget.onDesktop,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreSection extends StatefulWidget {
  const _StoreSection({
    required this.name,
    required this.searching,
    required this.apps,
    required this.favs,
    required this.dock,
    required this.desk,
    required this.onFav,
    required this.onDock,
    required this.onDesktop,
  });

  final String name;
  final bool searching;
  final List<(String, MacGlyph)> apps;
  final Set<String> favs;
  final Set<String> dock;
  final Set<String> desk;
  final ValueChanged<String> onFav;
  final ValueChanged<String> onDock;
  final ValueChanged<String> onDesktop;

  @override
  State<_StoreSection> createState() => _StoreSectionState();
}

class _StoreSectionState extends State<_StoreSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final open = widget.searching || _open;
    final apps = widget.apps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: Key('mac-store-section-${widget.name}'),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  open ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        if (open && apps.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'Icons you create in Settings land here.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        if (open)
          for (final app in apps)
          Row(
            children: [
              IconButton(
                key: Key('mac-store-fav-${app.$1}'),
                onPressed: () => widget.onFav(app.$1),
                icon: Icon(
                  widget.favs.contains(app.$1) ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFFD60A),
                  size: 16,
                ),
              ),
              Icon(app.$2.icon, color: app.$2.color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  app.$2.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              TextButton(
                key: Key('mac-store-dock-${app.$1}'),
                onPressed: widget.dock.contains(app.$1)
                    ? null
                    : () => widget.onDock(app.$1),
                child: Text(widget.dock.contains(app.$1) ? 'Docked' : 'Dock'),
              ),
              TextButton(
                key: Key('mac-store-desk-${app.$1}'),
                onPressed: widget.desk.contains(app.$1)
                    ? null
                    : () => widget.onDesktop(app.$1),
                child: Text(widget.desk.contains(app.$1) ? 'Placed' : 'Desktop'),
              ),
            ],
          ),
      ],
    );
  }
}
