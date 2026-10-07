import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../image_file.dart';
import '../models.dart';
import '../store.dart';

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

/// Status bar, sounds, caller photo, branding, and custom icons.
class ExtraSettings extends StatelessWidget {
  const ExtraSettings({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  OsSettings get os => device.os;

  void _update(OsSettings Function(OsSettings) change) {
    store.updateOs(device.id, change);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Column(
      children: [
        _block(
          'Status bar',
          Column(
            children: [
              TextFormField(
                initialValue: os.networkName,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Network name',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
                onFieldSubmitted: (value) =>
                    _update((current) => current.copyWith(networkName: value.trim())),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Wi-Fi'),
                value: os.wifi,
                onChanged: (value) => _update((current) => current.copyWith(wifi: value)),
              ),
              _slider('Signal', os.signal.toDouble(), 4, (value) {
                _update((current) => current.copyWith(signal: value.round()));
              }),
              _slider('Battery', os.battery.toDouble(), 100, (value) {
                _update((current) => current.copyWith(battery: value.round()));
              }),
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
        _block(
          'Sounds',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButton<String>(
                value: kRingtones.contains(os.ringtone) ? os.ringtone : kRingtones.first,
                dropdownColor: const Color(0xFF1C1C1E),
                items: [
                  for (final name in kRingtones)
                    DropdownMenuItem(value: name, child: Text(name)),
                ],
                onChanged: (value) {
                  if (value != null) _update((current) => current.copyWith(ringtone: value));
                },
              ),
              DropdownButton<String>(
                value: kVibrates.contains(os.vibrate) ? os.vibrate : kVibrates[1],
                dropdownColor: const Color(0xFF1C1C1E),
                items: [
                  for (final name in kVibrates)
                    DropdownMenuItem(value: name, child: Text(name)),
                ],
                onChanged: (value) {
                  if (value != null) _update((current) => current.copyWith(vibrate: value));
                },
              ),
              const SizedBox(height: 8),
              Text(
                os.customRingtone.isEmpty
                    ? 'One custom ringtone can be saved on this device.'
                    : 'Custom ringtone saved · ${os.ringtoneIn.toStringAsFixed(1)}s–${os.ringtoneOut.toStringAsFixed(1)}s',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              TextButton(
                onPressed: () async {
                  final file = await FilePicker.pickFile(type: FileType.audio);
                  if (file == null) return;
                  final bytes = await file.readAsBytes();
                  if (bytes.length > 180000) return;
                  final data = 'data:audio/mpeg;base64,${base64Encode(bytes)}';
                  _update((current) => current.copyWith(customRingtone: data, ringtone: 'Custom'));
                },
                child: const Text('Upload ringtone'),
              ),
              if (os.customRingtone.isNotEmpty) ...[
                _slider('Trim start', os.ringtoneIn, 30, (value) {
                  _update((current) => current.copyWith(ringtoneIn: value));
                }),
                _slider('Trim end', os.ringtoneOut, 30, (value) {
                  _update((current) => current.copyWith(ringtoneOut: value));
                }),
              ],
            ],
          ),
        ),
        _block(
          'Caller details',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How the caller photo appears on an incoming call.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Round avatar'),
                    selected: os.callerPhoto != 'full',
                    onSelected: (_) => _update((current) => current.copyWith(callerPhoto: 'circle')),
                  ),
                  ChoiceChip(
                    label: const Text('Full screen'),
                    selected: os.callerPhoto == 'full',
                    onSelected: (_) => _update((current) => current.copyWith(callerPhoto: 'full')),
                  ),
                ],
              ),
            ],
          ),
        ),
        _block(
          'App branding',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generic keeps the fictional names. Branded swaps in the real product names. Icons stay original artwork.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Generic'),
                    selected: !os.branded,
                    onSelected: (_) => _update((current) => current.copyWith(branded: false)),
                  ),
                  ChoiceChip(
                    label: const Text('Branded'),
                    selected: os.branded,
                    onSelected: (_) => _update((current) => current.copyWith(branded: true)),
                  ),
                ],
              ),
            ],
          ),
        ),
        _block('Custom icons', CustomIconMaker(store: store, device: device)),
      ],
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
