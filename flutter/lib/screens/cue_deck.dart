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
          for (var i = 0; i < section.specs.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _CueRow(
              spec: section.specs[i],
              palette: palette,
              color: section.color,
              active: live?.effect == section.specs[i].id,
              enabled: widget.enabled,
              onPressed: () => _play(section.specs[i].id),
            ),
          ],
          if (showIntensity) ...[
            const SizedBox(height: 14),
            Text(
              section.id == 'power'
                  ? 'Phone dying intensity'
                  : 'Glitch and heat intensity',
              style: TextStyle(color: palette.muted, fontSize: 10),
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
          if (live != null) ...[
            const SizedBox(height: 4),
            Text(
              'Playing · ${cueLabel(live.effect)}',
              style: TextStyle(
                color: section.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _CueRow(
                  key: Key('deck-cue-stop-${section.id}'),
                  spec: const CueSpec(
                    'stop',
                    'Stop',
                    '',
                    Icons.stop_circle_outlined,
                  ),
                  palette: palette,
                  color: kAlert,
                  active: false,
                  enabled: live != null,
                  onPressed: _stopOwned,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CueRow(
                  key: Key('deck-cue-reset-${section.id}'),
                  spec: const CueSpec(
                    'reset',
                    'Reset',
                    '',
                    Icons.settings_backup_restore,
                  ),
                  palette: palette,
                  color: palette.ink,
                  active: false,
                  enabled: live != null,
                  onPressed: () {
                    _stopOwned();
                    setState(() => _intensity = 70);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Stop and Reset restore the screen.',
            style: TextStyle(color: palette.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _CueRow extends StatelessWidget {
  const _CueRow({
    super.key,
    required this.spec,
    required this.palette,
    required this.color,
    required this.active,
    required this.enabled,
    required this.onPressed,
  });

  final CueSpec spec;
  final DeckPalette palette;
  final Color color;
  final bool active;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ink = active ? color : palette.ink;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: active
            ? color.withValues(alpha: 0.16)
            : palette.secondary.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: spec.id == 'stop' || spec.id == 'reset'
              ? null
              : Key('deck-cue-${spec.id}'),
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? color.withValues(alpha: 0.7) : palette.line,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  spec.icon,
                  size: 18,
                  color: active ? color : palette.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    spec.label,
                    style: TextStyle(
                      color: ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (active)
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
