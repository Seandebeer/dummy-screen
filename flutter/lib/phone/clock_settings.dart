import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';

/// Collapsed time controls. Starts closed, and sits under a battery slider.
class ClockSettings extends StatefulWidget {
  const ClockSettings({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<ClockSettings> createState() => _ClockSettingsState();
}

class _ClockSettingsState extends State<ClockSettings> {
  bool _open = false;

  OsSettings get os => widget.device.os;

  void _save(OsSettings Function(OsSettings) change) {
    widget.store.updateOs(widget.device.id, change);
  }

  @override
  Widget build(BuildContext context) {
    final shown = formatClock(osNow(os));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: const Key('clock-section'),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'TIME',
                    style: TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 11,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Text(shown, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(width: 6),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: const Color(0xB3FFFFFF),
                ),
              ],
            ),
          ),
        ),
        if (_open) ...[
          const Text(
            'A stopped clock shows the set time and does not run.',
            style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 11),
          ),
          const SizedBox(height: 8),
          const Text('Clock style', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip('Digital', 'digital', os.clockStyle, 'clock-style-digital', (value) {
                _save((current) => current.copyWith(clockStyle: value));
              }),
              _chip('Analog', 'analog', os.clockStyle, 'clock-style-analog', (value) {
                _save((current) => current.copyWith(clockStyle: value));
              }),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Time source', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip('Local time', 'local', os.clockSource, 'clock-source-local', (value) {
                _save((current) => chooseClockSource(current, value));
              }),
              _chip('Timezone', 'zone', os.clockSource, 'clock-source-zone', (value) {
                _save((current) => chooseClockSource(current, value));
              }),
              _chip('Set time', 'set', os.clockSource, 'clock-source-set', (value) {
                _save((current) => chooseClockSource(current, value));
              }),
            ],
          ),
          if (os.clockSource == 'zone') ...[
            const SizedBox(height: 8),
            DropdownButton<String>(
              key: const Key('clock-zone'),
              value: kClockZones.any((zone) => zone.id == os.clockZone) ? os.clockZone : 'utc',
              isExpanded: true,
              dropdownColor: const Color(0xFF2C2C2E),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: [
                for (final zone in kClockZones)
                  DropdownMenuItem(value: zone.id, child: Text(zone.label)),
              ],
              onChanged: (value) {
                if (value == null) return;
                _save((current) => chooseClockSource(current, 'zone', zone: value));
              },
            ),
          ],
          if (os.clockSource == 'set' || !os.clockRunning) ...[
            const SizedBox(height: 8),
            _step(
              'Hour',
              '${os.clockHour}',
              const Key('clock-hour-down'),
              const Key('clock-hour-up'),
              -60,
              60,
            ),
            _step(
              'Minute',
              os.clockMinute.toString().padLeft(2, '0'),
              const Key('clock-minute-down'),
              const Key('clock-minute-up'),
              -1,
              1,
            ),
          ],
          _toggle(
            'Run clock',
            'A stopped clock keeps the set time on screen.',
            os.clockRunning,
            const Key('clock-running'),
            (value) => _save((current) => value ? startClock(current) : stopClock(current)),
          ),
          _toggle(
            'Show time',
            'Turn this off to remove the time from the device.',
            os.showClock,
            const Key('clock-show'),
            (value) => _save((current) => current.copyWith(showClock: value)),
          ),
        ],
      ],
    );
  }

  Widget _toggle(
    String label,
    String hint,
    bool value,
    Key key,
    ValueChanged<bool> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  Text(hint, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            Switch(key: key, value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Widget _step(String label, String value, Key down, Key up, int minus, int plus) {
    return Row(
      children: [
        SizedBox(width: 64, child: Text(label, style: const TextStyle(color: Colors.white))),
        IconButton(
          key: down,
          onPressed: () => _save((current) => shiftClock(current, minus)),
          icon: const Icon(Icons.remove, color: Colors.white),
        ),
        SizedBox(
          width: 28,
          child: Text(value, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
        ),
        IconButton(
          key: up,
          onPressed: () => _save((current) => shiftClock(current, plus)),
          icon: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  Widget _chip(
    String label,
    String value,
    String selected,
    String keyName,
    ValueChanged<String> onSelected,
  ) {
    final on = selected == value;
    return ChoiceChip(
      key: Key(keyName),
      label: Text(label),
      labelStyle: TextStyle(color: on ? Colors.black : Colors.white),
      selectedColor: Colors.white,
      backgroundColor: const Color(0xFF2C2C2E),
      surfaceTintColor: Colors.transparent,
      selected: on,
      onSelected: (_) => onSelected(value),
    );
  }
}
