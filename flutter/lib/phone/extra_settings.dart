import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../image_file.dart';
import '../models.dart';
import '../store.dart';
import 'clock_settings.dart';

const kRingtones = [
  'Reflection',
  'Opening',
  'Apex',
  'Ripple',
  'Pulse',
  'Classic',
  'Marimba',
  'Alarm',
];

const kVibrates = ['Off', 'Standard', 'Heartbeat', 'Rapid', 'Long'];

/// Network name, radios, Wi-Fi, and battery for a phone or tablet.
class ExtraSettings extends StatelessWidget {
  const ExtraSettings({
    super.key,
    required this.store,
    required this.device,
    this.cellular = true,
  });

  final StageStore store;
  final PropDevice device;
  final bool cellular;

  OsSettings get os => device.os;

  void _update(OsSettings Function(OsSettings) change) {
    store.updateOs(device.id, change);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: _block(
        'Network name',
        Column(
          children: [
            TextFormField(
              key: const Key('network-name'),
              initialValue: os.networkName,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Network name',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              onFieldSubmitted: (value) =>
                  _update((current) => current.copyWith(networkName: value.trim())),
            ),
            if (cellular) ...[
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Mobile network', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final radio in kCellularRadios)
                    ChoiceChip(
                      key: Key('cellular-$radio'),
                      label: Text(radio),
                      labelStyle: TextStyle(
                        color: os.cellular == radio ? Colors.black : Colors.white,
                      ),
                      selectedColor: Colors.white,
                      backgroundColor: const Color(0xFF2C2C2E),
                      selected: os.cellular == radio,
                      onSelected: (_) =>
                          _update((current) => current.copyWith(cellular: radio)),
                    ),
                ],
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Wi-Fi'),
              value: os.wifi,
              onChanged: (value) => _update((current) => current.copyWith(wifi: value)),
            ),
            _slider('Wi-Fi signal', os.wifiBars.toDouble(), 3, (value) {
              _update((current) => current.copyWith(wifiBars: value.round()));
            }),
            _slider('Mobile signal', os.signal.toDouble(), 4, (value) {
              _update((current) => current.copyWith(signal: value.round()));
            }),
            _slider('Battery', os.battery.toDouble(), 100, (value) {
              _update((current) => current.copyWith(battery: value.round()));
            }),
            ClockSettings(store: store, device: device),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bluetooth'),
              value: os.bluetooth,
              onChanged: (value) => _update((current) => current.copyWith(bluetooth: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Alarm icon'),
              value: os.showAlarm,
              onChanged: (value) => _update((current) => current.copyWith(showAlarm: value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider(String label, double value, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label  ${value.round()}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Slider(value: value.clamp(0, max), max: max, onChanged: onChanged),
      ],
    );
  }

  Widget _block(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 0.8),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Ringtone, notification alerts, and alarm. Each can vibrate and use one upload.
class SoundSettings extends StatelessWidget {
  const SoundSettings({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  OsSettings get os => device.os;

  void _update(OsSettings Function(OsSettings) change) {
    store.updateOs(device.id, change);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mute'),
          value: os.soundsMuted,
          onChanged: (value) => _update((current) => current.copyWith(soundsMuted: value)),
        ),
        _tone(
          'Ringtone',
          tone: os.ringtone,
          vibrate: os.vibrate,
          custom: os.customRingtone,
          onTone: (value) => _update((current) => current.copyWith(ringtone: value)),
          onVibrate: (value) => _update((current) => current.copyWith(vibrate: value)),
          onUpload: (data) => _update(
            (current) => current.copyWith(customRingtone: data, ringtone: 'Custom'),
          ),
        ),
        _tone(
          'Notification alerts',
          tone: os.notifyTone,
          vibrate: os.vibrateNotify,
          custom: os.customNotify,
          onTone: (value) => _update((current) => current.copyWith(notifyTone: value)),
          onVibrate: (value) => _update((current) => current.copyWith(vibrateNotify: value)),
          onUpload: (data) => _update(
            (current) => current.copyWith(customNotify: data, notifyTone: 'Custom'),
          ),
        ),
        _tone(
          'Alarm',
          tone: os.alarmTone,
          vibrate: os.vibrateAlarm,
          custom: os.customAlarm,
          onTone: (value) => _update((current) => current.copyWith(alarmTone: value)),
          onVibrate: (value) => _update((current) => current.copyWith(vibrateAlarm: value)),
          onUpload: (data) => _update(
            (current) => current.copyWith(customAlarm: data, alarmTone: 'Custom'),
          ),
        ),
      ],
    );
  }

  Widget _tone(
    String label, {
    required String tone,
    required String vibrate,
    required String custom,
    required ValueChanged<String> onTone,
    required ValueChanged<String> onVibrate,
    required ValueChanged<String> onUpload,
  }) {
    final toneValue = tone == 'Custom' || kRingtones.contains(tone) ? tone : kRingtones.first;
    final vibrateValue = kVibrates.contains(vibrate) ? vibrate : kVibrates.first;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          DropdownButton<String>(
            value: toneValue,
            dropdownColor: const Color(0xFF1C1C1E),
            style: const TextStyle(color: Colors.white),
            items: [
              for (final name in kRingtones)
                DropdownMenuItem(value: name, child: Text(name)),
              if (custom.isNotEmpty)
                const DropdownMenuItem(value: 'Custom', child: Text('Custom')),
            ],
            onChanged: (value) {
              if (value != null) onTone(value);
            },
          ),
          DropdownButton<String>(
            value: vibrateValue,
            dropdownColor: const Color(0xFF1C1C1E),
            style: const TextStyle(color: Colors.white),
            items: [
              for (final name in kVibrates)
                DropdownMenuItem(value: name, child: Text('Vibrate · $name')),
            ],
            onChanged: (value) {
              if (value != null) onVibrate(value);
            },
          ),
          TextButton(
            onPressed: () async {
              final file = await FilePicker.pickFile(type: FileType.audio);
              if (file == null) return;
              final bytes = await file.readAsBytes();
              if (bytes.length > 180000) return;
              onUpload('data:audio/mpeg;base64,${base64Encode(bytes)}');
            },
            child: Text(custom.isEmpty ? 'Upload custom sound' : 'Replace custom sound'),
          ),
        ],
      ),
    );
  }
}

class CallerDetails extends StatelessWidget {
  const CallerDetails({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  Widget build(BuildContext context) {
    final os = device.os;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How the caller photo appears on an incoming call.',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Round avatar'),
              labelStyle: TextStyle(color: os.callerPhoto != 'full' ? Colors.black : Colors.white),
              selectedColor: Colors.white,
              backgroundColor: const Color(0xFF2C2C2E),
              selected: os.callerPhoto != 'full',
              onSelected: (_) => store.updateOs(
                device.id,
                (current) => current.copyWith(callerPhoto: 'circle'),
              ),
            ),
            ChoiceChip(
              label: const Text('Full screen'),
              labelStyle: TextStyle(color: os.callerPhoto == 'full' ? Colors.black : Colors.white),
              selectedColor: Colors.white,
              backgroundColor: const Color(0xFF2C2C2E),
              selected: os.callerPhoto == 'full',
              onSelected: (_) => store.updateOs(
                device.id,
                (current) => current.copyWith(callerPhoto: 'full'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CustomIconMaker extends StatefulWidget {
  const CustomIconMaker({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<CustomIconMaker> createState() => _CustomIconMakerState();
}

class _CustomIconMakerState extends State<CustomIconMaker> {
  final _name = TextEditingController();
  String _image = '';
  double _scale = 1;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = imageProviderForPath(_image);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _name,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Icon name',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: provider == null
                  ? const Icon(Icons.image, color: Colors.white38)
                  : Transform.scale(
                      scale: _scale,
                      child: Image(image: provider, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () async {
                      final file = await FilePicker.pickFile(type: FileType.image);
                      if (file == null) return;
                      final path = await persistPickedImage(file);
                      if (path != null && mounted) setState(() => _image = path);
                    },
                    child: const Text('Upload picture'),
                  ),
                  Slider(
                    value: _scale,
                    min: 1,
                    max: 2.4,
                    onChanged: (value) => setState(() => _scale = value),
                  ),
                ],
              ),
            ),
          ],
        ),
        FilledButton(
          onPressed: _image.isEmpty || _name.text.trim().isEmpty
              ? null
              : () {
                  final glyph = CustomGlyph(
                    id: 'glyph-${DateTime.now().microsecondsSinceEpoch}',
                    name: _name.text.trim(),
                    image: _image,
                  );
                  widget.store.updateOs(
                    widget.device.id,
                    (current) => current.copyWith(glyphs: [...current.glyphs, glyph]),
                  );
                  _name.clear();
                  setState(() => _image = '');
                },
          child: const Text('Add to library'),
        ),
      ],
    );
  }
}
