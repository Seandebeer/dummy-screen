import 'package:flutter/material.dart';

import '../deck/chrome.dart';
import '../phone/cues.dart';
import '../store.dart';
import '../theme.dart';

/// Three cue strips on the existing Remote Control Deck.
class CueDeck extends StatelessWidget {
  const CueDeck({
    super.key,
    required this.palette,
    required this.store,
    required this.targets,
    required this.enabled,
    required this.open,
    required this.stripHeight,
    required this.onOpenChanged,
  });

  final DeckPalette palette;
  final StageStore store;
  final List<String> targets;
  final bool enabled;
  final String? open;
  final double stripHeight;
  final ValueChanged<String?> onOpenChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final section in _sections)
          if (open == null || open == section.id) ...[
            SizedBox(height: open == section.id ? 12 : 20),
            SizedBox(
              height: open == section.id ? stripHeight : null,
              child: _CueCategoryCard(
                palette: palette,
                store: store,
                targets: targets,
                enabled: enabled,
                section: section,
                open: open == section.id,
                fill: open == section.id,
                onOpenChanged: (next) =>
                    onOpenChanged(next ? section.id : null),
              ),
            ),
          ],
      ],
    );
  }
}

class _Section {
  const _Section(this.id, this.title, this.icon, this.color, this.specs);

  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<CueSpec> specs;
}

const _sections = [
  _Section(
    'power',
    'Power, system & battery',
    Icons.power_settings_new,
    kSignal,
    kPowerCues,
  ),
  _Section(
    'faults',
    'System errors & malfunctions',
    Icons.report_gmailerrorred,
    kAlert,
    kFaultCues,
  ),
  _Section(
    'security',
    'Security & privacy',
    Icons.lock_outline,
    kAccent,
    kSecurityCues,
  ),
];

class _CueCategoryCard extends StatefulWidget {
  const _CueCategoryCard({
    required this.palette,
    required this.store,
    required this.targets,
    required this.enabled,
    required this.section,
    required this.open,
    required this.fill,
    required this.onOpenChanged,
  });

  final DeckPalette palette;
  final StageStore store;
  final List<String> targets;
  final bool enabled;
  final _Section section;
  final bool open;
  final bool fill;
  final ValueChanged<bool> onOpenChanged;

  @override
  State<_CueCategoryCard> createState() => _CueCategoryCardState();
}

class _CueCategoryCardState extends State<_CueCategoryCard> {
  double _intensity = 70;

  PhoneCue? get _live {
    final id = widget.store.targetDeviceId;
    if (id == null) return null;
    final cue = widget.store.cueFor(id);
    if (cue == null) return null;
    if (!widget.section.specs.any((spec) => spec.id == cue.effect)) return null;
    return cue;
  }

  void _play(String effect) {
    final level = _intensity.round();
    for (final id in widget.targets) {
      widget.store.playCue(id, effect, intensity: level);
    }
  }

  void _stopOwned() {
    final ids = widget.section.specs.map((spec) => spec.id).toSet();
    for (final id in widget.targets) {
      final cue = widget.store.cueFor(id);
      if (cue != null && ids.contains(cue.effect)) {
        widget.store.stopCue(id);
      }
    }
  }

  void _onIntensity(double value) {
    setState(() => _intensity = value);
    final ids = widget.section.specs.map((spec) => spec.id).toSet();
    for (final id in widget.targets) {
      final cue = widget.store.cueFor(id);
      if (cue != null &&
          ids.contains(cue.effect) &&
          cueUsesIntensity(cue.effect)) {
        widget.store.setCueIntensity(id, value.round());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final live = _live;
    final section = widget.section;
    final showIntensity = section.id == 'power' || section.id == 'faults';
    return CollapsibleCard(
      palette: palette,
      icon: section.icon,
      iconColor: section.color,
      title: section.title,
      open: widget.open,
      fill: widget.fill,
      onOpenChanged: widget.onOpenChanged,
      badge: live == null
          ? null
          : Text(
              'LIVE',
              style: TextStyle(
                color: section.color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plays on the connected device. Stop and Reset restore the screen.',
            style: TextStyle(color: palette.muted, fontSize: 11, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final spec in section.specs)
                _CueButton(
                  effect: spec.id,
                  label: spec.label,
                  active: live?.effect == spec.id,
                  enabled: widget.enabled,
                  onPressed: () => _play(spec.id),
                ),
            ],
          ),
          if (showIntensity) ...[
            const SizedBox(height: 14),
            Text(
              section.id == 'power'
                  ? 'Phone dying intensity'
                  : 'Glitch and heat intensity',
              style: TextStyle(color: palette.muted, fontSize: 11),
            ),
            Slider(
              key: Key('deck-cue-intensity-${section.id}'),
              value: _intensity,
              min: 0,
              max: 100,
              label: '${_intensity.round()}',
              onChanged: widget.enabled ? _onIntensity : null,
            ),
          ],
          const SizedBox(height: 8),
          if (live != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Playing · ${cueLabel(live.effect)}',
                style: const TextStyle(
                  color: kSignal,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Row(
            children: [
              OutlinedButton(
                key: Key('deck-cue-stop-${section.id}'),
                onPressed: live == null ? null : _stopOwned,
                child: const Text('Stop'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: Key('deck-cue-reset-${section.id}'),
                onPressed: live == null
                    ? null
                    : () {
                        _stopOwned();
                        setState(() => _intensity = 70);
                      },
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CueButton extends StatelessWidget {
  const _CueButton({
    required this.effect,
    required this.label,
    required this.active,
    required this.enabled,
    required this.onPressed,
  });

  final String effect;
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
    final child = Text(label);
    if (active) {
      return FilledButton(
        key: Key('deck-cue-$effect'),
        style: style,
        onPressed: enabled ? onPressed : null,
        child: child,
      );
    }
    return OutlinedButton(
      key: Key('deck-cue-$effect'),
      style: style,
      onPressed: enabled ? onPressed : null,
      child: child,
    );
  }
}
