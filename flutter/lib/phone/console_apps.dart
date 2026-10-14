import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import 'app_catalog.dart';
import 'catalog.dart';
import 'extra_settings.dart';
import 'game_catalog.dart';
import 'language_settings.dart';
import 'local_game.dart';
import 'mac_desk.dart';
import 'settings_kit.dart';
import 'wallpaper_art.dart';

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
  final game = gameById(id);
  if (game != null) return game.title;
  final glyph = macGlyph(id, os);
  if (glyph.label == 'App') return id;
  return glyph.label;
}

MockGame pinCover(String id, OsSettings os) {
  final game = gameById(id);
  if (game != null) return game;
  final glyph = macGlyph(id, os);
  return coverForLabel(
    id: id,
    title: glyph.label == 'App' ? id : glyph.label,
    color: glyph.color,
    mark: glyph.icon,
  );
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
      child: image == null
          ? WallpaperMotif(presetId: paper.presetId)
          : const SizedBox.expand(),
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
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final id in os.consolePins)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: KeyedSubtree(
                key: Key('console-pin-$id'),
                child: GameCover(
                  game: pinCover(id, os),
                  width: 68,
                  height: 90,
                  onTap: () => onOpen(id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Wallpaper, theme, header details, pinned games, and custom icons.
/// Same category index the phone Settings app uses.
class ConsoleSettings extends StatefulWidget {
  const ConsoleSettings({
    super.key,
    required this.store,
    required this.device,
    this.onClose,
    this.bare = false,
  });

  final StageStore store;
  final PropDevice device;
  final VoidCallback? onClose;
  final bool bare;

  @override
  State<ConsoleSettings> createState() => _ConsoleSettingsState();
}

class _ConsoleSettingsState extends State<ConsoleSettings> {
  String? _page;
  String _localName = '';

  StageStore get store => widget.store;
  PropDevice get device => widget.device;
  VoidCallback? get onClose => widget.onClose;
  OsSettings get os => device.os;

  void _save(OsSettings Function(OsSettings current) change) {
    store.updateOs(device.id, change);
  }

  @override
  void initState() {
    super.initState();
    LocalGameLink.read().then((link) {
      if (!mounted) return;
      setState(() => _localName = link?.name ?? '');
    });
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
    final page = SettingsPage(
        listKey: const Key('console-settings-list'),
        title: switch (_page) {
          'look' => 'Display',
          'status' => 'Status',
          'icons' => 'Apps',
          'games' => 'Games',
          'language' => 'Language',
          _ => 'Settings',
        },
        onBack: _page == null ? null : () => setState(() => _page = null),
        onReset: () => store.factoryResetDevice(device.id),
        children: [
          if (_page == null)
            SettingsGroup(
              children: [
                SettingsCategory(
                  categoryKey: const Key('console-settings-look'),
                  icon: Icons.wallpaper,
                  title: 'Display',
                  detail: 'Theme and wallpaper',
                  onOpen: () => setState(() => _page = 'look'),
                ),
                SettingsCategory(
                  categoryKey: const Key('console-settings-status'),
                  icon: Icons.tune,
                  title: 'Status',
                  detail: 'Player and scores',
                  onOpen: () => setState(() => _page = 'status'),
                ),
                SettingsCategory(
                  categoryKey: const Key('console-settings-icons'),
                  icon: Icons.apps,
                  title: 'Apps',
                  detail: 'Custom icons and the app library',
                  onOpen: () => setState(() => _page = 'icons'),
                ),
                SettingsCategory(
                  categoryKey: const Key('console-settings-games'),
                  icon: Icons.sports_esports,
                  title: 'Games',
                  detail: 'Custom tiles and the games library',
                  onOpen: () => setState(() => _page = 'games'),
                ),
                SettingsCategory(
                  categoryKey: const Key('console-settings-language'),
                  icon: Icons.language,
                  title: 'Language',
                  detail: languageByCode(os.language).native,
                  onOpen: () => setState(() => _page = 'language'),
                ),
              ],
            ),
          if (_page == 'look') ...[
            SettingsSection(
              title: 'Interface',
              child: Column(
                children: [
                  for (final shell in const [
                    (
                      'xbox',
                      'Xbox Series',
                      'Green dashboard and a row of game tiles.',
                      [Color(0xFF107C10), Color(0xFF0E1A10)],
                    ),
                    (
                      'ps5',
                      'PlayStation 5',
                      'Wide cards across a dark control strip.',
                      [Color(0xFF003791), Color(0xFF0A1628)],
                    ),
                    (
                      'ps2',
                      'PlayStation 2',
                      'Memory-card browser and a blue menu.',
                      [Color(0xFF1A3A8A), Color(0xFF070B18)],
                    ),
                    (
                      'x360',
                      'Xbox 360',
                      'Blade menu and a row of game tiles.',
                      [Color(0xFF5BA817), Color(0xFF10140C)],
                    ),
                  ]) ...[
                    SettingsTile(
                      tileKey: Key('console-shell-${shell.$1}'),
                      name: shell.$2,
                      desc: shell.$3,
                      preview: shell.$4,
                      active: (os.shell.isEmpty ? 'xbox' : os.shell) == shell.$1,
                      onTap: () => _save((current) => current.copyWith(shell: shell.$1)),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            SettingsSection(
              title: 'Theme',
              child: SettingsThemeGrid(
                prefix: 'console',
                selected: (theme) =>
                    os.backgroundPreset == theme.preset &&
                    os.isLight == theme.light &&
                    os.backgroundType != 'image',
                onSelect: (theme) => _save(
                  (current) => current.copyWith(
                    theme: theme.light ? 'light' : 'dark',
                    backgroundType: 'preset',
                    backgroundPreset: theme.preset,
                    backgroundUrl: '',
                  ),
                ),
              ),
            ),
            SettingsSection(
              title: 'Background',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsTile(
                    tileKey: const Key('console-bg-shell'),
                    name: 'Shell',
                    desc: 'The artwork that ships with this console.',
                    preview: const [Color(0xFF1A1D2E), Color(0xFF000000)],
                    active: !ConsoleLayout.customWall(os),
                    onTap: () => _save(
                      (current) => current.copyWith(
                        theme: 'dark',
                        backgroundType: 'preset',
                        backgroundPreset: 'default',
                        backgroundUrl: '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SettingsPresetGrid(
                    prefix: 'console',
                    selected: os.backgroundType == 'image' || !ConsoleLayout.customWall(os)
                        ? null
                        : os.backgroundPreset,
                    onSelect: (id) => _save(
                      (current) => current.copyWith(
                        backgroundType: 'preset',
                        backgroundPreset: id,
                        backgroundUrl: '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SettingsUploadRow(
                    uploadKey: const Key('console-bg-upload'),
                    uploading: false,
                    showRemove: os.backgroundType == 'image' && os.backgroundUrl.isNotEmpty,
                    onUpload: () async {
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
                    onRemove: () => _save(
                      (current) => current.copyWith(
                        backgroundType: 'preset',
                        backgroundPreset: 'default',
                        backgroundUrl: '',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_page == 'status')
            SettingsSection(
              title: 'Status',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsToggle(
                    key: const Key('console-show-tag'),
                    label: 'Player',
                    value: shown.contains('tag'),
                    onChanged: (value) => _show('tag', value),
                  ),
                  SettingsField(
                    fieldKey: const Key('console-status-tag'),
                    label: 'Player name',
                    value: store.operatorName,
                    onChanged: (value) => store.setOperator(name: value),
                  ),
                  SettingsToggle(
                    key: const Key('console-show-search'),
                    label: 'Search',
                    value: shown.contains('search'),
                    onChanged: (value) => _show('search', value),
                  ),
                  SettingsToggle(
                    key: const Key('console-show-score'),
                    label: 'Gamerscore',
                    value: shown.contains('score'),
                    onChanged: (value) => _show('score', value),
                  ),
                  SettingsToggle(
                    key: const Key('console-show-trophies'),
                    label: 'Trophies',
                    value: shown.contains('trophies'),
                    onChanged: (value) => _show('trophies', value),
                  ),
                  SettingsToggle(
                    key: const Key('console-show-mail'),
                    label: 'Mail',
                    value: shown.contains('mail'),
                    onChanged: (value) => _show('mail', value),
                  ),
                ],
              ),
            ),
          if (_page == 'icons') ...[
            SettingsSection(
              title: 'Custom icons',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SettingsHint(
                    'Same icon maker as the phone. New icons show up in the Game Store.',
                  ),
                  const SizedBox(height: 8),
                  CustomIconMaker(store: store, device: device),
                ],
              ),
            ),
            CollapsibleSection(
              title: 'App Library',
              sectionKey: const Key('console-app-library'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final app in kPropApps) Text(app.label),
                  for (final section in mockCatalog) ...[
                    Text(section.name, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                    for (final app in section.apps)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(app.label),
                      ),
                  ],
                ],
              ),
            ),
          ],
          if (_page == 'games') ...[
            SettingsSection(
              title: 'This computer',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsHint(
                    _localName.isEmpty
                        ? 'Choose a game that is already on this computer. The tile starts it. Nothing is copied in.'
                        : 'Linked on this computer: $_localName',
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const Key('console-local-game'),
                      onPressed: () async {
                        final link = await LocalGameLink.pick();
                        if (!mounted || link == null) return;
                        setState(() => _localName = link.name);
                      },
                      child: const Text('Choose a game on this computer'),
                    ),
                  ),
                ],
              ),
            ),
            SettingsSection(
              title: 'Custom tile',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SettingsHint(
                    'Same maker as the app library. The new tile shows up in the Game Store.',
                  ),
                  const SizedBox(height: 8),
                  CustomIconMaker(store: store, device: device),
                ],
              ),
            ),
            CollapsibleSection(
              title: 'Games library',
              sectionKey: const Key('console-games-library'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final game in mockGames) Text(game.title),
                ],
              ),
            ),
          ],
          if (_page == 'language')
            SettingsSection(
              title: 'Language',
              child: LanguageChoices(
                store: store,
                device: device,
                keyPrefix: 'console-language',
              ),
            ),
        ],
      );
    final close = onClose;
    if (widget.bare || close == null) return page;
    return _Pane(title: 'Settings', onClose: close, child: page);
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
  final _open = <String>{'Featured'};

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
    final shelves = ['Featured', 'Favourites', 'Action', 'Adventure', 'Sports', 'Indie'];
    List<MockGame> gamesFor(String shelf) {
      final source = switch (shelf) {
        'Featured' => mockGames.take(4).toList(),
        'Favourites' => [for (final game in mockGames) if (favs.contains(game.id)) game],
        _ => [for (final game in mockGames) if (game.shelf == shelf) game],
      };
      if (query.isEmpty) return source;
      return [
        for (final game in source)
          if (game.title.toLowerCase().contains(query) || game.studio.toLowerCase().contains(query)) game,
      ];
    }

    return _Pane(
      title: 'Game Store',
      onClose: widget.onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'Game Store',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: const Key('console-store-search'),
              controller: _query,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search games',
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
                for (final shelf in shelves)
                  if (query.isEmpty || gamesFor(shelf).isNotEmpty)
                    _GameShelf(
                      name: shelf,
                      games: gamesFor(shelf),
                      expanded: query.isNotEmpty || _open.contains(shelf),
                      onToggle: () => setState(() {
                        if (_open.contains(shelf)) {
                          _open.remove(shelf);
                        } else {
                          _open.add(shelf);
                        }
                      }),
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

class _GameShelf extends StatelessWidget {
  const _GameShelf({
    required this.name,
    required this.games,
    required this.expanded,
    required this.onToggle,
    required this.favs,
    required this.pins,
    required this.onFav,
    required this.onOpen,
    required this.onPin,
  });

  final String name;
  final List<MockGame> games;
  final bool expanded;
  final VoidCallback onToggle;
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
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text('${games.length}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ),
        if (expanded && games.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 6),
            child: Text('No games here yet.', style: TextStyle(color: Colors.white38, fontSize: 11)),
          ),
        if (expanded)
          for (final game in games)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  IconButton(
                    key: Key('console-store-fav-${game.id}'),
                    onPressed: () => onFav(game.id),
                    icon: Icon(
                      favs.contains(game.id) ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFD60A),
                      size: 16,
                    ),
                  ),
                  GameCover(
                    game: game,
                    width: 54,
                    height: 72,
                    onTap: () => onOpen(game.id),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        Text(game.studio, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  TextButton(
                    key: Key('console-store-open-${game.id}'),
                    onPressed: () => onOpen(game.id),
                    child: const Text('Open'),
                  ),
                  TextButton(
                    key: Key('console-store-home-${game.id}'),
                    onPressed: pins.contains(game.id) ? null : () => onPin(game.id),
                    child: Text(pins.contains(game.id) ? 'Pinned' : 'Home'),
                  ),
                ],
              ),
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

