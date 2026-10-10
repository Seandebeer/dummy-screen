import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import 'app_catalog.dart';
import 'catalog.dart';
import 'clock_settings.dart';
import 'extra_settings.dart';
import 'mac_desk.dart';

/// Header tokens drawn on the console shells. Empty keeps this set.
const kConsoleStatusDefault = [
  'clock',
  'battery',
  'tag',
  'search',
  'score',
  'trophies',
  'mail',
];

/// Pins and header tokens saved on a console.
class ConsoleLayout {
  static List<String> status(OsSettings os) {
    if (os.consoleStatus.isEmpty) return kConsoleStatusDefault;
    if (os.consoleStatus.length == 1 && os.consoleStatus.first == '-') {
      return const [];
    }
    return os.consoleStatus;
  }

  static bool shows(OsSettings os, String token) => status(os).contains(token);

  static OsSettings writeStatus(OsSettings os, List<String> items) {
    if (items.isEmpty) return os.copyWith(consoleStatus: const ['-']);
    return os.copyWith(consoleStatus: items);
  }

  static OsSettings pin(OsSettings os, String id) {
    if (id.isEmpty || os.consolePins.contains(id)) return os;
    return os.copyWith(consolePins: [...os.consolePins, id]);
  }

  static OsSettings unpin(OsSettings os, String id) => os.copyWith(
    consolePins: [for (final item in os.consolePins) if (item != id) item],
  );

  /// The reference shell art stays until a wallpaper or light theme is chosen.
  static bool customWall(OsSettings os) {
    if (os.backgroundType == 'image' && os.backgroundUrl.isNotEmpty) return true;
    if (os.isLight) return true;
    return os.backgroundPreset.isNotEmpty && os.backgroundPreset != 'default';
  }
}

/// Label for a launched app. Unknown ids keep the title the shell already uses.
String consoleAppLabel(String id, OsSettings os) {
  final glyph = macGlyph(id, os);
  if (glyph.label == 'App') return id;
  return glyph.label;
}

/// Saved wallpaper, or the shell's own art when nothing has been chosen.
class ConsoleWallpaper extends StatelessWidget {
  const ConsoleWallpaper({
    super.key,
    required this.device,
    required this.fallback,
  });

  final PropDevice device;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    if (!ConsoleLayout.customWall(device.os)) return fallback;
    final paper = wallpaperFor(device, locked: false);
    final image = paper.imagePath.isEmpty
        ? null
        : imageProviderForPath(paper.imagePath);
    return DecoratedBox(
      key: const Key('console-wallpaper'),
      decoration: BoxDecoration(
        gradient: paper.gradient,
        image: image == null
            ? null
            : DecorationImage(image: image, fit: BoxFit.cover),
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Apps pinned from the store, drawn only after the first pin.
class ConsolePinStrip extends StatelessWidget {
  const ConsolePinStrip({super.key, required this.os, required this.onOpen});

  final OsSettings os;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (os.consolePins.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final id in os.consolePins)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                key: Key('console-pin-$id'),
                avatar: Icon(
                  macGlyph(id, os).icon,
                  size: 16,
                  color: macGlyph(id, os).color,
                ),
                label: Text(macGlyph(id, os).label),
                onPressed: () => onOpen(id),
              ),
            ),
        ],
      ),
    );
  }
}

/// Wallpaper, theme, header details, pinned apps, and custom icons.
class ConsoleSettings extends StatelessWidget {
  const ConsoleSettings({
    super.key,
    required this.store,
    required this.device,
    required this.onClose,
  });

  final StageStore store;
  final PropDevice device;
  final VoidCallback onClose;

  OsSettings get os => device.os;

  void _save(OsSettings Function(OsSettings current) change) {
    store.updateOs(device.id, change);
  }

  void _show(String token, bool value) {
    _save((current) {
      final items = [...ConsoleLayout.status(current)];
      if (value && !items.contains(token)) items.add(token);
      if (!value) items.remove(token);
      return ConsoleLayout.writeStatus(current, items);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shown = ConsoleLayout.status(os).toSet();
    return _Pane(
      title: 'Settings',
      onClose: onClose,
      child: _Pager(
        pages: const [
          ('look', 'Wallpaper'),
          ('status', 'Status'),
          ('home', 'Home'),
          ('icons', 'Icons'),
        ],
        bodies: [
          [
            const _Head('Theme'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final theme in osThemes)
                  ChoiceChip(
                    key: Key('console-theme-${theme.id}'),
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
                  key: const Key('console-bg-shell'),
                  label: const Text('Shell'),
                  selected: !ConsoleLayout.customWall(os),
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
                      key: Key('console-bg-${preset.id}'),
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
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('console-bg-upload'),
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
          [
            _switch('Clock', shown.contains('clock'), 'console-show-clock', (
              value,
            ) {
              _show('clock', value);
            }),
            _switch(
              'Battery',
              shown.contains('battery'),
              'console-show-battery',
              (value) => _show('battery', value),
            ),
            Row(
              children: [
                Text(
                  'Battery  ${os.battery}%',
                  style: const TextStyle(color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  key: const Key('console-battery-down'),
                  onPressed: os.battery <= 0
                      ? null
                      : () => _save(
                          (current) => current.copyWith(
                            battery: (current.battery - 10).clamp(0, 100),
                          ),
                        ),
                  icon: const Icon(Icons.remove, color: Colors.white),
                ),
                IconButton(
                  key: const Key('console-battery-up'),
                  onPressed: os.battery >= 100
                      ? null
                      : () => _save(
                          (current) => current.copyWith(
                            battery: (current.battery + 10).clamp(0, 100),
                          ),
                        ),
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            Slider(
              key: const Key('console-status-battery'),
              value: os.battery.toDouble().clamp(0, 100),
              max: 100,
              onChanged: (value) => _save(
                (current) =>
                    current.copyWith(battery: value.round().clamp(0, 100)),
              ),
            ),
            ClockSettings(store: store, device: device),
            _switch('Player', shown.contains('tag'), 'console-show-tag', (
              value,
            ) {
              _show('tag', value);
            }),
            TextFormField(
              key: const Key('console-status-tag'),
              initialValue: store.operatorName,
              style: const TextStyle(color: Color(0xFF1D1D1F)),
              cursorColor: const Color(0xFF1D1D1F),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Player name',
                isDense: true,
              ),
              onFieldSubmitted: (value) => store.setOperator(name: value),
            ),
            _switch('Search', shown.contains('search'), 'console-show-search', (
              value,
            ) {
              _show('search', value);
            }),
            _switch(
              'Gamerscore',
              shown.contains('score'),
              'console-show-score',
              (value) => _show('score', value),
            ),
            _switch(
              'Trophies',
              shown.contains('trophies'),
              'console-show-trophies',
              (value) => _show('trophies', value),
            ),
            _switch('Mail', shown.contains('mail'), 'console-show-mail', (
              value,
            ) {
              _show('mail', value);
            }),
          ],
          [
            const _Head('Pinned apps'),
            if (os.consolePins.isEmpty)
              const Text(
                'Pin an app from the App Store and it lands on the home screen.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            for (final id in os.consolePins)
              Row(
                children: [
                  Icon(
                    macGlyph(id, os).icon,
                    color: macGlyph(id, os).color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      macGlyph(id, os).label,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    key: Key('console-unpin-$id'),
                    onPressed: () => _save((current) => ConsoleLayout.unpin(current, id)),
                    child: const Text('Remove'),
                  ),
                ],
              ),
          ],
          [
            const _Head('Custom icons'),
            const Text(
              'Same icon maker as the phone. New icons show up in the App Store.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CustomIconMaker(store: store, device: device),
              ),
            ),
          ],
        ],
      ),
    );
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
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Same catalog as the phone App Library.
class ConsoleAppStore extends StatefulWidget {
  const ConsoleAppStore({
    super.key,
    required this.store,
    required this.device,
    required this.onOpen,
    required this.onClose,
  });

  final StageStore store;
  final PropDevice device;
  final ValueChanged<String> onOpen;
  final VoidCallback onClose;

  @override
  State<ConsoleAppStore> createState() => _ConsoleAppStoreState();
}

class _ConsoleAppStoreState extends State<ConsoleAppStore> {
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
    final pins = os.consolePins.toSet();
    final favs = widget.store.appFavorites.toSet();
    final sections = <({String name, List<(String, MacGlyph)> apps})>[
      (
        name: 'Favourites',
        apps: [
          for (final id in widget.store.appFavorites) (id, macGlyph(id, os)),
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
    return _Pane(
      title: 'App Store',
      onClose: widget.onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              key: const Key('console-store-search'),
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
              key: const Key('console-store-scroll'),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 6),
                  child: Text(
                    'App Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
                      pins: pins,
                      onFav: widget.store.toggleAppFavorite,
                      onOpen: widget.onOpen,
                      onPin: (id) => widget.store.updateOs(
                        widget.device.id,
                        (current) => ConsoleLayout.pin(current, id),
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

class _StoreSection extends StatelessWidget {
  const _StoreSection({
    required this.name,
    required this.apps,
    required this.favs,
    required this.pins,
    required this.onFav,
    required this.onOpen,
    required this.onPin,
  });

  final String name;
  final List<(String, MacGlyph)> apps;
  final Set<String> favs;
  final Set<String> pins;
  final ValueChanged<String> onFav;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onPin;

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
                key: Key('console-store-fav-${app.$1}'),
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
                key: Key('console-store-open-${app.$1}'),
                onPressed: () => onOpen(app.$1),
                child: const Text('Open'),
              ),
              TextButton(
                key: Key('console-store-home-${app.$1}'),
                onPressed: pins.contains(app.$1) ? null : () => onPin(app.$1),
                child: Text(pins.contains(app.$1) ? 'Pinned' : 'Home'),
              ),
            ],
          ),
      ],
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({
    required this.title,
    required this.onClose,
    required this.child,
  });

  final String title;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF101114),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                IconButton(
                  key: const Key('console-back'),
                  tooltip: 'Back',
                  onPressed: onClose,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Pager extends StatefulWidget {
  const _Pager({required this.pages, required this.bodies});

  final List<(String, String)> pages;
  final List<List<Widget>> bodies;

  @override
  State<_Pager> createState() => _PagerState();
}

class _PagerState extends State<_Pager> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (var i = 0; i < widget.pages.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: Key('console-settings-${widget.pages[i].$1}'),
                    label: Text(widget.pages[i].$2),
                    selected: _page == i,
                    onSelected: (_) => setState(() => _page = i),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            key: const Key('console-settings-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: widget.bodies[_page],
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
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
