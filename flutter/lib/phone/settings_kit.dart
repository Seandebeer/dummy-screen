import 'package:flutter/material.dart';

import '../os_catalog.dart';
import '../theme.dart';

/// The pieces the Settings app is built from. A phone, a tablet, and a
/// computer each list the settings that belong to that device, and all of
/// them are drawn with these cards, pills, and grids.
const kSettingsPage = Color(0xFF0B0B0F);
const kSettingsCard = Color(0x0DFFFFFF);
const kSettingsEdge = Color(0x1AFFFFFF);
const kSettingsHint = Color(0xB3FFFFFF);
const kSettingsLabel = Color(0xD9FFFFFF);

/// Settings itself: a title, a scroll of titled cards, a factory reset, and
/// the prop build line. [listKey] names the scroll so a test can reach it.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.listKey,
    required this.title,
    required this.children,
    required this.onReset,
    this.rtl = false,
  });

  final Key listKey;
  final String title;
  final List<Widget> children;
  final VoidCallback onReset;
  final bool rtl;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _armed = false;
  bool _confirm = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.rtl ? TextDirection.rtl : TextDirection.ltr,
      child: ColoredBox(
        color: kSettingsPage,
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, fontSize: 14),
          child: Stack(
            children: [
              ListView(
                key: widget.listKey,
                padding: const EdgeInsets.only(bottom: 28),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...widget.children,
                  SettingsSection(title: 'Reset', child: _reset()),
                  const Padding(
                    padding: EdgeInsets.only(top: 22),
                    child: Text(
                      'DUMMY SCREEN · PROP BUILD 1.0',
                      key: Key('os-build-footer'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0x40FFFFFF),
                        fontSize: 10,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (_confirm) _sheet(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reset() {
    if (!_armed) {
      return InkWell(
        key: const Key('factory-reset'),
        onTap: () => setState(() => _armed = true),
        child: const Row(
          children: [
            Icon(Icons.restart_alt, size: 16, color: kAlert),
            SizedBox(width: 8),
            Text('Factory Reset', style: TextStyle(color: kAlert)),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Erase all changes on this device - pages, apps, settings and configurations. Pages saved to this character's device are removed from it; items saved to General stay in Saved.",
          style: TextStyle(color: kSettingsLabel, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _armed = false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                key: const Key('erase-device'),
                style: FilledButton.styleFrom(backgroundColor: kAlert),
                onPressed: () => setState(() => _confirm = true),
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('Erase Device'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sheet() {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xB3000000),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Material(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Erase all content?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This removes every change on this device - pages, apps, settings and configurations. General saved items are kept. This cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0x8CFFFFFF),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('erase-confirm'),
                        style: FilledButton.styleFrom(backgroundColor: kAlert),
                        onPressed: widget.onReset,
                        icon: const Icon(Icons.restart_alt, size: 16),
                        label: const Text('Erase'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => setState(() {
                          _confirm = false;
                          _armed = false;
                        }),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One titled card in the settings scroll.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.child,
    this.plain = false,
  });

  final String title;
  final Widget child;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              plain ? title : title.toUpperCase(),
              style: const TextStyle(
                color: kSettingsHint,
                fontSize: 11,
                letterSpacing: 1.1,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: kSettingsCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kSettingsEdge),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// A settings card that starts closed and opens on the heading.
class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyOpen = false,
    this.sectionKey,
  });

  final String title;
  final Widget child;
  final bool initiallyOpen;
  final Key? sectionKey;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kSettingsCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kSettingsEdge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: widget.sectionKey,
              onTap: () => setState(() => _open = !_open),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title.toUpperCase(),
                        style: const TextStyle(
                          color: kSettingsHint,
                          fontSize: 11,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    Icon(
                      _open ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: kSettingsHint,
                    ),
                  ],
                ),
              ),
            ),
            if (_open)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: widget.child,
              ),
          ],
        ),
      ),
    );
  }
}

/// The small grey line under a control.
class SettingsHint extends StatelessWidget {
  const SettingsHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: kSettingsHint, fontSize: 11),
    );
  }
}

/// A row with a title, an optional hint, and a switch pill on the end.
class SettingsToggle extends StatelessWidget {
  const SettingsToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint = '',
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  if (hint.isNotEmpty) SettingsHint(hint),
                ],
              ),
            ),
            SettingsPill(on: value),
          ],
        ),
      ),
    );
  }
}

/// A value with minus and plus buttons. [name] titles the row so the reading
/// on the middle says what it belongs to.
class SettingsStepRow extends StatelessWidget {
  const SettingsStepRow({
    super.key,
    required this.label,
    required this.minusKey,
    required this.plusKey,
    required this.onMinus,
    required this.onPlus,
    this.name = '',
  });

  final String label;
  final String name;
  final Key minusKey;
  final Key plusKey;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        SettingsStepButton(key: minusKey, icon: Icons.remove, onTap: onMinus),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        SettingsStepButton(key: plusKey, icon: Icons.add, onTap: onPlus),
      ],
    );
    if (name.isEmpty) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(name)),
        row,
      ],
    );
  }
}

/// A short list of looks for one setting, drawn as pills under it.
class SettingsOptions extends StatelessWidget {
  const SettingsOptions({
    super.key,
    required this.prefix,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  /// Each option is an id and the words shown on its pill.
  final String prefix;
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final option in options)
            _OptionPill(
              pillKey: Key('$prefix-${option.$1}'),
              label: option.$2,
              active: selected == option.$1,
              onTap: () => onSelect(option.$1),
            ),
        ],
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  const _OptionPill({
    required this.pillKey,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final Key pillKey;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? kAccent.withValues(alpha: 0.14) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(99),
        side: BorderSide(color: active ? kAccent : kSettingsEdge),
      ),
      child: InkWell(
        key: pillKey,
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: active ? kAccent : const Color(0x99FFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}

/// The four-across theme swatches.
class SettingsThemeGrid extends StatelessWidget {
  const SettingsThemeGrid({
    super.key,
    required this.prefix,
    required this.selected,
    required this.onSelect,
  });

  final String prefix;
  final bool Function(OsThemeChoice theme) selected;
  final ValueChanged<OsThemeChoice> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.78,
      children: [
        for (final theme in osThemes)
          _ThemeButton(
            tileKey: Key('$prefix-theme-${theme.id}'),
            theme: theme,
            active: selected(theme),
            onTap: () => onSelect(theme),
          ),
      ],
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.tileKey,
    required this.theme,
    required this.active,
    required this.onTap,
  });

  final Key tileKey;
  final OsThemeChoice theme;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preset = bgPresetById(theme.preset);
    final colors = theme.light ? preset.light : preset.dark;
    return InkWell(
      key: tileKey,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? kAccent : kSettingsEdge,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors.length < 2
                        ? [colors.first, colors.first]
                        : colors,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              theme.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: active ? kAccent : const Color(0x99FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The four-across wallpaper swatches.
class SettingsPresetGrid extends StatelessWidget {
  const SettingsPresetGrid({
    super.key,
    required this.prefix,
    required this.selected,
    required this.onSelect,
  });

  final String prefix;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.15,
      children: [
        for (final preset in bgPresets)
          Tooltip(
            message: preset.name,
            child: InkWell(
              key: Key('$prefix-preset-${preset.id}'),
              onTap: () => onSelect(preset.id),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected == preset.id ? kAccent : kSettingsEdge,
                    width: 2,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: preset.dark.length < 2
                          ? [preset.dark.first, preset.dark.first]
                          : preset.dark,
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

/// Upload a picture for the wallpaper, with Remove once one is set.
class SettingsUploadRow extends StatelessWidget {
  const SettingsUploadRow({
    super.key,
    required this.uploading,
    required this.showRemove,
    required this.onUpload,
    required this.onRemove,
    this.uploadKey,
  });

  final bool uploading;
  final bool showRemove;
  final VoidCallback onUpload;
  final VoidCallback onRemove;
  final Key? uploadKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            key: uploadKey,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0A84FF),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onPressed: uploading ? null : onUpload,
            icon: uploading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload, size: 14),
            label: const Text('Upload Image', style: TextStyle(fontSize: 12)),
          ),
        ),
        if (showRemove) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, size: 14),
            label: const Text('Remove'),
          ),
        ],
      ],
    );
  }
}

/// One of a pair of outlined choices.
class SettingsChoice extends StatelessWidget {
  const SettingsChoice({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? kAccent : const Color(0x99FFFFFF),
        backgroundColor: active
            ? kAccent.withValues(alpha: 0.1)
            : Colors.transparent,
        side: BorderSide(color: active ? kAccent : kSettingsEdge),
      ),
      onPressed: onTap,
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class SettingsStepButton extends StatelessWidget {
  const SettingsStepButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: kSettingsEdge),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 16)),
      ),
    );
  }
}

class SettingsPill extends StatelessWidget {
  const SettingsPill({super.key, required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 40,
      height: 24,
      decoration: BoxDecoration(
        color: on ? kSignal : const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 160),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.all(2),
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// A dark text field for a name typed into settings.
class SettingsField extends StatelessWidget {
  const SettingsField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      initialValue: value,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: kAccent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kSettingsLabel, fontSize: 12),
        isDense: true,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: kSettingsEdge),
        ),
      ),
      onChanged: onChanged,
      onFieldSubmitted: onChanged,
    );
  }
}

/// The picker every settings screen uses for a one-off list, such as the
/// interface a device runs.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.tileKey,
    required this.name,
    required this.desc,
    required this.preview,
    required this.active,
    required this.onTap,
  });

  final Key tileKey;
  final String name;
  final String desc;
  final List<Color> preview;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? kAccent.withValues(alpha: 0.1) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: active ? kAccent : kSettingsEdge),
      ),
      child: InkWell(
        key: tileKey,
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: preview.length < 2
                        ? [preview.first, preview.first]
                        : preview,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      desc,
                      style: const TextStyle(
                        color: Color(0x80FFFFFF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (active) const Icon(Icons.check, size: 16, color: kAccent),
            ],
          ),
        ),
      ),
    );
  }
}
