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
  bool _editing = false;
  bool _alive = true;
  late final TextEditingController _time;
  late final FocusNode _focus;

  OsSettings get os => widget.device.os;

  String get _shown => formatOsClock(osNow(os), hour24: os.clockFormat == '24');

  @override
  void initState() {
    super.initState();
    _time = TextEditingController(text: _shown);
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_alive || !mounted || _focus.hasFocus || !_editing) return;
      _commit(_time.text);
    });
  }

  @override
  void didUpdateWidget(ClockSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncField();
  }

  @override
  void dispose() {
    _alive = false;
    _focus.dispose();
    _time.dispose();
    super.dispose();
  }

  void _syncField() {
    if (_editing) return;
    final next = _shown;
    if (_time.text == next) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _editing || _time.text == _shown) return;
      _time.text = _shown;
    });
  }

  void _save(OsSettings Function(OsSettings) change) {
    widget.store.updateOs(widget.device.id, change);
  }

  void _commit(String raw) {
    _editing = false;
    final parsed = parseClockText(raw);
    if (parsed == null) {
      _time.text = _shown;
      return;
    }
    _save((current) => pinClock(current, parsed.$1, parsed.$2));
    _syncField();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
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
            'Type the exact time. A stopped clock stays there and does not run.',
            style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 11),
          ),
          const SizedBox(height: 8),
          const Text('Screen clock', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const Text(
            'Analog replaces the clock on the screen. The header stays digital.',
            style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 11),
          ),
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
          const SizedBox(height: 10),
          const Text('Clock format', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip('AM/PM', '12', os.clockFormat, 'clock-format-12', (value) {
                _save((current) => current.copyWith(clockFormat: value));
              }),
              _chip('24-hour', '24', os.clockFormat, 'clock-format-24', (value) {
                _save((current) => current.copyWith(clockFormat: value));
              }),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Exact time', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            key: const Key('clock-time-field'),
            focusNode: _focus,
            controller: _time,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            cursorColor: Colors.white,
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              hintText: os.clockFormat == '24' ? '21:15' : '9:41 AM',
              hintStyle: const TextStyle(color: Colors.white38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              if (value != _shown) _editing = true;
            },
            onSubmitted: _commit,
          ),
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
