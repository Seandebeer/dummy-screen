import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import 'app_catalog.dart';
import 'catalog.dart';
import 'extra_settings.dart';

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
  if (id.startsWith('file:')) {
    return MacGlyph(id.substring(5), Icons.folder_outlined, Colors.white);
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

/// Wallpaper, theme, menu bar, dock order, and custom icons.
class MacSettings extends StatelessWidget {
  const MacSettings({
    super.key,
    required this.store,
    required this.device,
    required this.onShiftDock,
    required this.onToDesktop,
    required this.onToDock,
    required this.onNudge,
  });

  final StageStore store;
  final PropDevice device;
  final void Function(String id, int delta) onShiftDock;
  final ValueChanged<String> onToDesktop;
  final ValueChanged<String> onToDock;
  final void Function(String id, double dx, double dy) onNudge;

  OsSettings get os => device.os;

  void _save(OsSettings Function(OsSettings current) change) {
    store.updateOs(device.id, change);
  }

  @override
  Widget build(BuildContext context) {
    final dock = MacLayout.dock(os);
    final desk = MacLayout.desktop(os);
    final shown = MacLayout.status(os).toSet();
    const ink = Color(0xFF1D1D1F);
    const muted = Color(0xFF6E6E73);
    return _SettingsPager(
      look: [
        const _Head('Theme'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final theme in osThemes)
              ChoiceChip(
                key: Key('mac-theme-${theme.id}'),
                label: Text(theme.name),
                selected:
                    os.backgroundPreset == theme.preset &&
                    os.isLight == theme.light &&
                    os.backgroundType != 'image',
                onSelected: (_) => _save(
                  (current) => current.copyWith(
                    theme: theme.light ? 'light' : 'dark',
                    backgroundType: 'preset',
                    backgroundPreset: theme.preset,
                    backgroundUrl: '',
                  ),
                ),
              ),
          ],
        ),
        const _Head('Background'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const Key('mac-bg-dune'),
              label: const Text('Dune'),
              selected:
                  !os.isLight &&
                  os.backgroundPreset == 'default' &&
                  os.backgroundType != 'image',
              onSelected: (_) => _save(
                (current) => current.copyWith(
                  theme: 'dark',
                  backgroundType: 'preset',
                  backgroundPreset: 'default',
                  backgroundUrl: '',
                ),
              ),
            ),
            for (final preset in bgPresets)
              if (preset.id != 'default')
                ChoiceChip(
                  key: Key('mac-bg-${preset.id}'),
                  label: Text(preset.name),
                  selected:
                      os.backgroundType != 'image' &&
                      os.backgroundPreset == preset.id,
                  onSelected: (_) => _save(
                    (current) => current.copyWith(
                      backgroundType: 'preset',
                      backgroundPreset: preset.id,
                      backgroundUrl: '',
                    ),
                  ),
                ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('mac-bg-upload'),
            onPressed: () async {
              final file = await FilePicker.pickFile(type: FileType.image);
              if (file == null) return;
              final path = await persistPickedImage(file);
              if (path == null) return;
              _save(
                (current) => current.copyWith(
                  backgroundType: 'image',
                  backgroundUrl: path,
                ),
              );
            },
            child: const Text('Choose picture'),
          ),
        ),
      ],
      menu: [
        _switch(
          'Wi-Fi',
          os.wifi,
          'mac-status-wifi',
          (value) => _save((current) => current.copyWith(wifi: value)),
        ),
        _switch('Show Wi-Fi', shown.contains('wifi'), 'mac-show-wifi', (value) {
          _show('wifi', value);
        }),
        _switch(
          'Show battery',
          shown.contains('battery'),
          'mac-show-battery',
          (value) => _show('battery', value),
        ),
        Row(
          children: [
            Text('Battery  ${os.battery}%', style: const TextStyle(color: ink)),
            const Spacer(),
            IconButton(
              key: const Key('mac-battery-down'),
              onPressed: os.battery <= 0
                  ? null
                  : () => _save(
                      (current) => current.copyWith(
                        battery: (current.battery - 10).clamp(0, 100),
                      ),
                    ),
              icon: const Icon(Icons.remove),
            ),
            IconButton(
              key: const Key('mac-battery-up'),
              onPressed: os.battery >= 100
                  ? null
                  : () => _save(
                      (current) => current.copyWith(
                        battery: (current.battery + 10).clamp(0, 100),
                      ),
                    ),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        Slider(
          key: const Key('mac-status-battery'),
          value: os.battery.toDouble().clamp(0, 100),
          max: 100,
          onChanged: (value) => _save(
            (current) => current.copyWith(battery: value.round().clamp(0, 100)),
          ),
        ),
        _switch(
          'Bluetooth',
          os.bluetooth,
          'mac-status-bluetooth',
          (value) => _save((current) {
            final items = [...MacLayout.status(current)];
            if (value && !items.contains('bluetooth')) items.add('bluetooth');
            if (!value) items.remove('bluetooth');
            return MacLayout.writeStatus(
              current.copyWith(bluetooth: value),
              items,
            );
          }),
        ),
        _switch('Alarm', os.showAlarm, 'mac-status-alarm', (value) {
          _save((current) {
            final items = [...MacLayout.status(current)];
            if (value && !items.contains('alarm')) items.add('alarm');
            if (!value) items.remove('alarm');
            return MacLayout.writeStatus(
              current.copyWith(showAlarm: value),
              items,
            );
          });
        }),
        TextFormField(
          key: const Key('mac-status-network'),
          initialValue: os.networkName,
          style: const TextStyle(color: Color(0xFF1D1D1F)),
          decoration: const InputDecoration(
            labelText: 'Network name',
            labelStyle: TextStyle(color: Color(0xFF6E6E73)),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
          ),
          onFieldSubmitted: (value) => _rename(value),
          onChanged: _rename,
        ),
        _switch(
          'Show clock',
          shown.contains('clock'),
          'mac-show-clock',
          (value) => _show('clock', value),
        ),
        Row(
          children: [
            const Text('Clock', style: TextStyle(color: ink)),
            const Spacer(),
            IconButton(
              key: const Key('mac-clock-back'),
              onPressed: () => store.setClockOffset(
                device.id,
                device.clockOffsetMinutes - 60,
              ),
              icon: const Icon(Icons.remove),
            ),
            IconButton(
              key: const Key('mac-clock-forward'),
              onPressed: () => store.setClockOffset(
                device.id,
                device.clockOffsetMinutes + 60,
              ),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        _switch(
          'Show search',
          shown.contains('search'),
          'mac-show-search',
          (value) => _show('search', value),
        ),
        _switch(
          'Show Control Center',
          shown.contains('control'),
          'mac-show-control',
          (value) => _show('control', value),
        ),
      ],
      layout: [
        const _Head('Dock'),
        for (final id in dock)
          _arrange(
            id,
            macGlyph(id, os).label,
            muted,
            onLeft: () => onShiftDock(id, -1),
            onRight: () => onShiftDock(id, 1),
            onDesk: () => onToDesktop(id),
          ),
        const _Head('Desktop'),
        for (final id in desk)
          _deskRow(id, macGlyph(id, os).label, muted),
      ],
      icons: [
        const _Head('Custom icons'),
        const Text(
          'Same icon maker as the phone. New icons show up in the App Store.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CustomIconMaker(store: store, device: device),
          ),
        ),
      ],
    );
  }

  void _show(String id, bool value) {
    _save((current) {
      final items = [...MacLayout.status(current)];
      if (value && !items.contains(id)) items.add(id);
      if (!value) items.remove(id);
      return MacLayout.writeStatus(current, items);
    });
  }

  void _rename(String value) {
    final name = value.trim();
    _save((current) {
      final items = [...MacLayout.status(current)];
      if (name.isNotEmpty && !items.contains('network')) items.add('network');
      if (name.isEmpty) items.remove('network');
      return MacLayout.writeStatus(
        current.copyWith(networkName: name),
        items,
      );
    });
  }

  Widget _switch(
    String label,
    bool value,
    String keyName,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      key: Key(keyName),
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: const TextStyle(color: Color(0xFF1D1D1F))),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _arrange(
    String id,
    String label,
    Color muted, {
    required VoidCallback onLeft,
    required VoidCallback onRight,
    required VoidCallback onDesk,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: muted, fontSize: 13)),
        ),
        IconButton(
          key: Key('mac-dock-left-$id'),
          tooltip: 'Move left',
          onPressed: onLeft,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          key: Key('mac-dock-right-$id'),
          tooltip: 'Move right',
          onPressed: onRight,
          icon: const Icon(Icons.chevron_right),
        ),
        TextButton(
          key: Key('mac-dock-desk-$id'),
          onPressed: onDesk,
          child: const Text('Desktop'),
        ),
      ],
    );
  }

  Widget _deskRow(String id, String label, Color muted) {
    final file = id.startsWith('file:');
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: muted, fontSize: 13)),
        ),
        IconButton(
          key: Key('mac-nudge-left-$id'),
          tooltip: 'Nudge left',
          onPressed: () => onNudge(id, -80, 0),
          icon: const Icon(Icons.west, size: 18),
        ),
        IconButton(
          key: Key('mac-nudge-right-$id'),
          tooltip: 'Nudge right',
          onPressed: () => onNudge(id, 80, 0),
          icon: const Icon(Icons.east, size: 18),
        ),
        IconButton(
          key: Key('mac-nudge-up-$id'),
          tooltip: 'Nudge up',
          onPressed: () => onNudge(id, 0, -48),
          icon: const Icon(Icons.north, size: 18),
        ),
        IconButton(
          key: Key('mac-nudge-down-$id'),
          tooltip: 'Nudge down',
          onPressed: () => onNudge(id, 0, 48),
          icon: const Icon(Icons.south, size: 18),
        ),
        if (!file)
          TextButton(
            key: Key('mac-desk-dock-$id'),
            onPressed: () => onToDock(id),
            child: const Text('Dock'),
          ),
      ],
    );
  }
}

class _SettingsPager extends StatefulWidget {
  const _SettingsPager({
    required this.look,
    required this.menu,
    required this.layout,
    required this.icons,
  });

  final List<Widget> look;
  final List<Widget> menu;
  final List<Widget> layout;
  final List<Widget> icons;

  @override
  State<_SettingsPager> createState() => _SettingsPagerState();
}

class _SettingsPagerState extends State<_SettingsPager> {
  String _page = 'look';

  @override
  Widget build(BuildContext context) {
    final pages = {
      'look': ('Wallpaper', widget.look),
      'menu': ('Menu bar', widget.menu),
      'layout': ('Layout', widget.layout),
      'icons': ('Icons', widget.icons),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entry in pages.entries)
                ChoiceChip(
                  key: Key('mac-settings-${entry.key}'),
                  label: Text(entry.value.$1),
                  selected: _page == entry.key,
                  onSelected: (_) => setState(() => _page = entry.key),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            key: const Key('mac-settings-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: pages[_page]!.$2,
          ),
        ),
      ],
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1D1D1F),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
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

class _StoreSection extends StatelessWidget {
  const _StoreSection({
    required this.name,
    required this.apps,
    required this.favs,
    required this.dock,
    required this.desk,
    required this.onFav,
    required this.onDock,
    required this.onDesktop,
  });

  final String name;
  final List<(String, MacGlyph)> apps;
  final Set<String> favs;
  final Set<String> dock;
  final Set<String> desk;
  final ValueChanged<String> onFav;
  final ValueChanged<String> onDock;
  final ValueChanged<String> onDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (apps.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'Icons you create in Settings land here.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        for (final app in apps)
          Row(
            children: [
              IconButton(
                key: Key('mac-store-fav-${app.$1}'),
                onPressed: () => onFav(app.$1),
                icon: Icon(
                  favs.contains(app.$1) ? Icons.star : Icons.star_border,
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
                onPressed: dock.contains(app.$1) ? null : () => onDock(app.$1),
                child: Text(dock.contains(app.$1) ? 'Docked' : 'Dock'),
              ),
              TextButton(
                key: Key('mac-store-desk-${app.$1}'),
                onPressed: desk.contains(app.$1) ? null : () => onDesktop(app.$1),
                child: Text(desk.contains(app.$1) ? 'Placed' : 'Desktop'),
              ),
            ],
          ),
      ],
    );
  }
}
