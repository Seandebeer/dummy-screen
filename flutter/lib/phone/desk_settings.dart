import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import 'extra_settings.dart';
import 'mac_desk.dart';
import 'settings_kit.dart';

/// The computer interfaces a prop machine runs.
const kComputerShells = <(String, String)>[
  ('macos', 'Mac'),
  ('windows', 'Windows'),
  ('linux', 'Linux'),
];

const _shellLook = <String, (String, List<Color>)>{
  'macos': (
    'Menu bar, one moonlit dune, and a shelf dock.',
    [Color(0xFF2B4D7E), Color(0xFF0B1426)],
  ),
  'windows': (
    'Pale desktop, centered taskbar, shortcut stack.',
    [Color(0xFFBCD8F2), Color(0xFF6F9FD4)],
  ),
  'linux': (
    'Slate desktop with a top bar and a bottom dock.',
    [Color(0xFF2F4152), Color(0xFF151D26)],
  ),
};

/// Older saved shells still open as Mac, Windows, or Linux.
String computerShell(String shell) {
  return switch (shell) {
    'windows' ||
    'win95' ||
    'win98' ||
    'winxp' ||
    'vista' ||
    'win7' ||
    'win8' => 'windows',
    'linux' || 'ubuntu' => 'linux',
    _ => 'macos',
  };
}

/// Settings on a computer: the interface, the status details in the menu bar
/// or taskbar, the theme, the wallpaper, the dock and desktop arrangement,
/// app branding, custom icons, and a factory reset. It is the same screen as
/// the phone Settings app, carrying the settings a computer has.
class ComputerSettings extends StatefulWidget {
  const ComputerSettings({
    super.key,
    required this.store,
    required this.device,
    this.onShiftDock,
    this.onToDesktop,
    this.onToDock,
    this.onNudge,
  });

  final StageStore store;
  final PropDevice device;
  final void Function(String id, int delta)? onShiftDock;
  final ValueChanged<String>? onToDesktop;
  final ValueChanged<String>? onToDock;
  final void Function(String id, double dx, double dy)? onNudge;

  @override
  State<ComputerSettings> createState() => _ComputerSettingsState();
}

class _ComputerSettingsState extends State<ComputerSettings> {
  bool _uploading = false;
  bool _langOpen = false;

  PropDevice get device => widget.device;
  OsSettings get os => device.os;

  /// The dock and desktop rows edit the Mac shelf, so they are shown when
  /// that desktop hands over its own arrangement handlers.
  bool get _arranges =>
      computerShell(os.shell) == 'macos' &&
      widget.onShiftDock != null &&
      widget.onToDesktop != null &&
      widget.onToDock != null &&
      widget.onNudge != null;

  void _save(OsSettings Function(OsSettings current) change) {
    widget.store.updateOs(device.id, change);
  }

  void _show(String id, bool value) {
    _save((current) {
      final items = [...MacLayout.status(current)];
      if (value && !items.contains(id)) items.add(id);
      if (!value) items.remove(id);
      return MacLayout.writeStatus(current, items);
    });
  }

  void _style(String token, String value) {
    _save((current) {
      final styles = Map<String, String>.from(current.macStatusStyle);
      styles[token] = value;
      return current.copyWith(macStatusStyle: styles);
    });
  }

  Widget _tune(String token, List<(String, String)> options, String fallback) {
    return SettingsOptions(
      prefix: 'desk-style-$token',
      options: options,
      selected: os.macStatusStyle[token] ?? fallback,
      onSelect: (value) => _style(token, value),
    );
  }

  void _rename(String value) {
    final name = value.trim();
    _save((current) {
      final items = [...MacLayout.status(current)];
      if (name.isNotEmpty && !items.contains('network')) items.add('network');
      if (name.isEmpty) items.remove('network');
      return MacLayout.writeStatus(current.copyWith(networkName: name), items);
    });
  }

  Future<void> _pickWallpaper() async {
    setState(() => _uploading = true);
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      final path = file == null ? null : await persistPickedImage(file);
      if (path != null) {
        _save(
          (current) =>
              current.copyWith(backgroundType: 'image', backgroundUrl: path),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shell = computerShell(os.shell);
    final copy = copyFor(os.language);
    final hasImage = os.backgroundType == 'image' && os.backgroundUrl.isNotEmpty;
    final shown = MacLayout.status(os).toSet();
    final clock = propNow(device.clockOffsetMinutes);
    return SettingsPage(
      listKey: const Key('desk-settings-list'),
      title: copy.settings,
      rtl: languageByCode(os.language).rtl,
      onReset: () => widget.store.factoryResetDevice(device.id),
      children: [
        SettingsSection(
          title: 'Interface',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in kComputerShells) ...[
                SettingsTile(
                  tileKey: Key('desk-shell-${item.$1}'),
                  name: item.$2,
                  desc: _shellLook[item.$1]!.$1,
                  preview: _shellLook[item.$1]!.$2,
                  active: shell == item.$1,
                  onTap: () =>
                      _save((current) => current.copyWith(shell: item.$1)),
                ),
                const SizedBox(height: 8),
              ],
              const SettingsHint(
                'Restyles the desktop, the bar across the top, and the dock of this machine.',
              ),
            ],
          ),
        ),
        SettingsSection(
          title: switch (shell) {
            'windows' => 'Taskbar',
            'linux' => 'Top bar',
            _ => 'Menu bar',
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsToggle(
                key: const Key('desk-status-wifi'),
                label: 'Wi-Fi',
                value: os.wifi,
                onChanged: (value) =>
                    _save((current) => current.copyWith(wifi: value)),
              ),
              SettingsToggle(
                key: const Key('desk-status-bluetooth'),
                label: 'Bluetooth',
                value: os.bluetooth,
                onChanged: (value) => _save((current) {
                  final items = [...MacLayout.status(current)];
                  if (value && !items.contains('bluetooth')) {
                    items.add('bluetooth');
                  }
                  if (!value) items.remove('bluetooth');
                  return MacLayout.writeStatus(
                    current.copyWith(bluetooth: value),
                    items,
                  );
                }),
              ),
              SettingsToggle(
                key: const Key('desk-status-alarm'),
                label: 'Alarm',
                value: os.showAlarm,
                onChanged: (value) => _save((current) {
                  final items = [...MacLayout.status(current)];
                  if (value && !items.contains('alarm')) items.add('alarm');
                  if (!value) items.remove('alarm');
                  return MacLayout.writeStatus(
                    current.copyWith(showAlarm: value),
                    items,
                  );
                }),
              ),
              const SizedBox(height: 4),
              SettingsStepRow(
                name: 'Battery',
                label: '${os.battery}%',
                minusKey: const Key('desk-battery-down'),
                plusKey: const Key('desk-battery-up'),
                onMinus: os.battery <= 0
                    ? null
                    : () => _save(
                        (current) => current.copyWith(
                          battery: (current.battery - 10).clamp(0, 100),
                        ),
                      ),
                onPlus: os.battery >= 100
                    ? null
                    : () => _save(
                        (current) => current.copyWith(
                          battery: (current.battery + 10).clamp(0, 100),
                        ),
                      ),
              ),
              Slider(
                key: const Key('desk-status-battery'),
                value: os.battery.toDouble().clamp(0, 100),
                max: 100,
                onChanged: (value) => _save(
                  (current) =>
                      current.copyWith(battery: value.round().clamp(0, 100)),
                ),
              ),
              SettingsField(
                fieldKey: const Key('desk-status-network'),
                label: 'Network name',
                value: os.networkName,
                onChanged: _rename,
              ),
              const SizedBox(height: 10),
              SettingsStepRow(
                name: 'Clock',
                label: formatClock(clock),
                minusKey: const Key('desk-clock-back'),
                plusKey: const Key('desk-clock-forward'),
                onMinus: () => widget.store.setClockOffset(
                  device.id,
                  device.clockOffsetMinutes - 60,
                ),
                onPlus: () => widget.store.setClockOffset(
                  device.id,
                  device.clockOffsetMinutes + 60,
                ),
              ),
              const SizedBox(height: 8),
              const SettingsHint(
                'Wi-Fi, Bluetooth, the alarm, the battery, the network name, and the clock shown on this machine.',
              ),
            ],
          ),
        ),
        if (shell == 'macos')
          SettingsSection(
            title: 'Menu bar items',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsToggle(
                  key: const Key('desk-show-wifi'),
                  label: 'Show Wi-Fi',
                  value: shown.contains('wifi'),
                  onChanged: (value) => _show('wifi', value),
                ),
                _tune('wifi', const [
                  ('icon', 'Icon'),
                  ('name', 'Name'),
                  ('both', 'Icon and name'),
                ], 'icon'),
                SettingsToggle(
                  key: const Key('desk-show-battery'),
                  label: 'Show battery',
                  value: shown.contains('battery'),
                  onChanged: (value) => _show('battery', value),
                ),
                _tune('battery', const [
                  ('icon', 'Icon'),
                  ('percent', 'Percent'),
                  ('both', 'Icon and percent'),
                ], 'both'),
                SettingsToggle(
                  key: const Key('desk-show-clock'),
                  label: 'Show clock',
                  value: shown.contains('clock'),
                  onChanged: (value) => _show('clock', value),
                ),
                _tune('clock', const [
                  ('time', 'Time'),
                  ('date', 'Date'),
                  ('both', 'Time and date'),
                ], 'time'),
                SettingsToggle(
                  key: const Key('desk-show-search'),
                  label: 'Show search',
                  value: shown.contains('search'),
                  onChanged: (value) => _show('search', value),
                ),
                _tune('search', const [
                  ('icon', 'Icon'),
                  ('label', 'Label'),
                  ('both', 'Icon and label'),
                ], 'icon'),
                SettingsToggle(
                  key: const Key('desk-show-control'),
                  label: 'Show Control Center',
                  value: shown.contains('control'),
                  onChanged: (value) => _show('control', value),
                ),
                _tune('control', const [
                  ('icon', 'Icon'),
                  ('label', 'Label'),
                  ('both', 'Icon and label'),
                ], 'icon'),
                const SizedBox(height: 8),
                const SettingsHint(
                  'Choose which details sit on the right of the menu bar, and how each one is drawn.',
                ),
              ],
            ),
          ),
        SettingsSection(
          title: copy.themes,
          child: SettingsThemeGrid(
            prefix: 'desk',
            selected: (theme) =>
                os.backgroundType != 'image' &&
                os.backgroundPreset == theme.preset &&
                os.isLight == theme.light,
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
          title: copy.background,
          child: Column(
            children: [
              SettingsPresetGrid(
                prefix: 'desk',
                selected: hasImage ? null : os.backgroundPreset,
                onSelect: (id) => _save(
                  (current) => current.copyWith(
                    backgroundType: 'preset',
                    backgroundPreset: id,
                    backgroundUrl: '',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SettingsUploadRow(
                uploadKey: const Key('desk-bg-upload'),
                uploading: _uploading,
                showRemove: hasImage,
                onUpload: _pickWallpaper,
                onRemove: () => _save(
                  (current) => current.copyWith(
                    backgroundType: 'preset',
                    backgroundUrl: '',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_arranges) ...[
          SettingsSection(
            title: 'Dock',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final id in MacLayout.dock(os))
                  _dockRow(id, macGlyph(id, os).label),
                const SizedBox(height: 8),
                const SettingsHint(
                  'Order the shelf, or move an icon out onto the desktop.',
                ),
              ],
            ),
          ),
          SettingsSection(
            title: 'Desktop',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final id in MacLayout.desktop(os))
                  _deskRow(id, macGlyph(id, os).label),
                const SizedBox(height: 8),
                const SettingsHint(
                  'Nudge an icon around the desktop, or send an app back to the dock.',
                ),
              ],
            ),
          ),
        ],
        SettingsSection(
          title: 'App branding',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SettingsChoice(
                      label: 'Generic',
                      active: !os.branded,
                      onTap: () =>
                          _save((current) => current.copyWith(branded: false)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SettingsChoice(
                      label: 'Branded',
                      active: os.branded,
                      onTap: () =>
                          _save((current) => current.copyWith(branded: true)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: SettingsHint(
                  'Generic keeps the fictional names. Branded swaps in the real product names. Icons stay original artwork.',
                ),
              ),
            ],
          ),
        ),
        SettingsSection(
          title: 'Custom icons',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsHint(
                'Same icon maker as the phone. New icons show up in the App Store.',
              ),
              const SizedBox(height: 8),
              CustomIconMaker(store: widget.store, device: device),
            ],
          ),
        ),
        SettingsSection(
          title: copy.language,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                key: const Key('desk-language'),
                onTap: () => setState(() => _langOpen = !_langOpen),
                child: Row(
                  children: [
                    Expanded(child: Text(languageByCode(os.language).native)),
                    Icon(
                      _langOpen ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0x80FFFFFF),
                      size: 18,
                    ),
                  ],
                ),
              ),
              if (_langOpen) ...[
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 3.4,
                  children: [
                    for (final language in osLanguages)
                      SettingsChoice(
                        label: language.native,
                        active: os.language == language.code,
                        onTap: () => _save(
                          (current) =>
                              current.copyWith(language: language.code),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const SettingsHint(
                  'Default contacts follow this language; custom contacts are kept.',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _dockRow(String id, String label) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        IconButton(
          key: Key('desk-dock-left-$id'),
          tooltip: 'Move left',
          onPressed: () => widget.onShiftDock!(id, -1),
          icon: const Icon(Icons.chevron_left, size: 18),
        ),
        IconButton(
          key: Key('desk-dock-right-$id'),
          tooltip: 'Move right',
          onPressed: () => widget.onShiftDock!(id, 1),
          icon: const Icon(Icons.chevron_right, size: 18),
        ),
        TextButton(
          key: Key('desk-dock-desk-$id'),
          onPressed: () => widget.onToDesktop!(id),
          child: const Text('Desktop'),
        ),
      ],
    );
  }

  Widget _deskRow(String id, String label) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        IconButton(
          key: Key('desk-nudge-left-$id'),
          tooltip: 'Nudge left',
          onPressed: () => widget.onNudge!(id, -80, 0),
          icon: const Icon(Icons.west, size: 18),
        ),
        IconButton(
          key: Key('desk-nudge-right-$id'),
          tooltip: 'Nudge right',
          onPressed: () => widget.onNudge!(id, 80, 0),
          icon: const Icon(Icons.east, size: 18),
        ),
        IconButton(
          key: Key('desk-nudge-up-$id'),
          tooltip: 'Nudge up',
          onPressed: () => widget.onNudge!(id, 0, -48),
          icon: const Icon(Icons.north, size: 18),
        ),
        IconButton(
          key: Key('desk-nudge-down-$id'),
          tooltip: 'Nudge down',
          onPressed: () => widget.onNudge!(id, 0, 48),
          icon: const Icon(Icons.south, size: 18),
        ),
        if (!id.startsWith('file:'))
          TextButton(
            key: Key('desk-desk-dock-$id'),
            onPressed: () => widget.onToDock!(id),
            child: const Text('Dock'),
          ),
      ],
    );
  }
}
