import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import 'settings_kit.dart';

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
  bool _editingDate = false;
  bool _alive = true;
  late final TextEditingController _time;
  late final TextEditingController _date;
  late final FocusNode _focus;
  late final FocusNode _dateFocus;

  OsSettings get os => widget.device.os;

  String get _shown => formatOsClock(osNow(os), hour24: os.clockFormat == '24');

  @override
  void initState() {
    super.initState();
    _time = TextEditingController(text: _shown);
    _date = TextEditingController(text: formatDateField(os));
    _focus = FocusNode();
    _dateFocus = FocusNode();
    _focus.addListener(() {
      if (!_alive || !mounted || _focus.hasFocus || !_editing) return;
      _commit(_time.text);
    });
    _dateFocus.addListener(() {
      if (!_alive || !mounted || _dateFocus.hasFocus || !_editingDate) return;
      _commitDate(_date.text);
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
    _dateFocus.dispose();
    _time.dispose();
    _date.dispose();
    super.dispose();
  }

  void _syncField() {
    if (!_editing) {
      final next = _shown;
      if (_time.text != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _editing || _time.text == _shown) return;
          _time.text = _shown;
        });
      }
    }
    if (_editingDate) return;
    final date = formatDateField(os);
    if (_date.text == date) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _editingDate || _date.text == formatDateField(os)) return;
      _date.text = formatDateField(os);
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

  void _liveTime(String raw) {
    _editing = true;
    final parsed = parseClockText(raw);
    if (parsed == null) return;
    _save((current) => pinClock(current, parsed.$1, parsed.$2));
  }

  void _liveDate(String raw) {
    _editingDate = true;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      _save(
        (current) => current.copyWith(dateYear: 0, dateMonth: 0, dateDay: 0),
      );
      return;
    }
    final parsed = parseDateText(trimmed);
    if (parsed == null) return;
    _save(
      (current) => current.copyWith(
        dateYear: parsed.$1,
        dateMonth: parsed.$2,
        dateDay: parsed.$3,
      ),
    );
  }

  void _commitDate(String raw) {
    _editingDate = false;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      _save(
        (current) => current.copyWith(dateYear: 0, dateMonth: 0, dateDay: 0),
      );
      _date.text = '';
      return;
    }
    final parsed = parseDateText(trimmed);
    if (parsed == null) {
      _date.text = formatDateField(os);
      return;
    }
    _save(
      (current) => current.copyWith(
        dateYear: parsed.$1,
        dateMonth: parsed.$2,
        dateDay: parsed.$3,
      ),
    );
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
                    'Time',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(shown, style: const TextStyle(color: kSettingsHint, fontSize: 15)),
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
            'Type 9:41 or 21:15. A stopped clock stays there and does not run.',
            style: TextStyle(color: kSettingsHint, fontSize: 13),
          ),
          const SizedBox(height: 12),
          const Text('Time source', style: TextStyle(fontSize: 15)),
          const SizedBox(height: 8),
          SettingsOptions(
            prefix: 'clock-source',
            options: const [
              ('local', 'Local time'),
              ('zone', 'Timezone'),
              ('set', 'Set time'),
            ],
            selected: os.clockSource,
            onSelect: (value) => _save((current) => chooseClockSource(current, value)),
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
          const SizedBox(height: 12),
          const Text('Clock format', style: TextStyle(fontSize: 15)),
          const SizedBox(height: 8),
          SettingsOptions(
            prefix: 'clock-format',
            options: const [
              ('12', '12-hour'),
              ('24', '24-hour'),
            ],
            selected: os.clockFormat,
            onSelect: (value) => _save((current) => current.copyWith(clockFormat: value)),
          ),
          const SizedBox(height: 12),
          const Text('Exact time', style: TextStyle(fontSize: 15)),
          const SizedBox(height: 4),
          TextField(
            key: const Key('clock-time-field'),
            focusNode: _focus,
            controller: _time,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: Colors.white,
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              hintText: os.clockFormat == '24' ? '21:15' : '9:41',
              hintStyle: const TextStyle(color: Colors.white38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _liveTime,
            onSubmitted: _commit,
          ),
          const SizedBox(height: 12),
          const Text('Device date', style: TextStyle(fontSize: 15)),
          const SizedBox(height: 4),
          const Text(
            'Type a date as 2026-10-13. Leave it empty to follow today.',
            style: TextStyle(color: kSettingsHint, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('device-date-field'),
            focusNode: _dateFocus,
            controller: _date,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: Colors.white,
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              hintText: '2026-10-13',
              hintStyle: const TextStyle(color: Colors.white38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _liveDate,
            onSubmitted: _commitDate,
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
                  Text(hint, style: const TextStyle(color: kSettingsHint, fontSize: 13)),
                ],
              ),
            ),
            Switch(key: key, value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

}
