import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import 'settings_kit.dart';

/// Place name and weather temperature. The number is what the weather
/// widget prints, in Fahrenheit unless Celsius is chosen.
class PlaceSettings extends StatelessWidget {
  const PlaceSettings({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  OsSettings get os => device.os;

  void _save(OsSettings Function(OsSettings current) change) {
    store.updateOs(device.id, change);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(
          title: 'Location',
          child: SettingsField(
            fieldKey: const Key('os-place'),
            label: 'Place',
            value: os.place,
            onChanged: (value) => _save((current) => current.copyWith(place: value)),
          ),
        ),
        SettingsSection(
          title: 'Temperature',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsField(
                fieldKey: const Key('os-weather-degrees'),
                label: 'Degrees',
                value: '${os.weatherDegrees}',
                onChanged: (value) {
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null) return;
                  _save(
                    (current) => current.copyWith(
                      weatherDegrees: parsed.clamp(-80, 140),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SettingsChoice(
                      key: const Key('os-unit-f'),
                      label: 'Fahrenheit',
                      active: os.weatherUnit != 'c',
                      onTap: () => _save((current) => current.copyWith(weatherUnit: 'f')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SettingsChoice(
                      key: const Key('os-unit-c'),
                      label: 'Celsius',
                      active: os.weatherUnit == 'c',
                      onTap: () => _save((current) => current.copyWith(weatherUnit: 'c')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
