import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import 'atm_chrome.dart';
import 'clock_settings.dart';
import 'language_settings.dart';
import 'place_settings.dart';
import 'settings_kit.dart';

/// The same ATM controls as the machine's own settings panel.
class AtmOsSettings extends StatefulWidget {
  const AtmOsSettings({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<AtmOsSettings> createState() => _AtmOsSettingsState();
}

class _AtmOsSettingsState extends State<AtmOsSettings> {
  String? _page;

  PropDevice get device => widget.store.deviceById(widget.device.id) ?? widget.device;
  OsSettings get os => device.os;

  void _save(OsSettings Function(OsSettings current) change) {
    widget.store.updateOs(device.id, change);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      listKey: const Key('device-settings-atm'),
      title: switch (_page) {
        'display' => 'Display',
        'status' => 'Status',
        'bank' => 'Bank',
        'language' => 'Language',
        _ => 'Settings',
      },
      onBack: _page == null ? null : () => setState(() => _page = null),
      onReset: () => widget.store.factoryResetDevice(device.id),
      children: [
        if (_page == null)
          SettingsGroup(
            children: [
              _cat('display', Icons.account_balance_wallet, 'Display', 'Interface, keypad, and theme'),
              _cat('status', Icons.schedule, 'Status', 'Clock, place, and temperature'),
              _cat('bank', Icons.account_balance, 'Bank', 'Name, balance, currency, and notes'),
              _cat('language', Icons.language, 'Language', languageByCode(os.language).native),
            ],
          ),
        if (_page == 'display') ...[
          const _Label('Interface'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final face in const [
                ('teller', 'Night Teller'),
                ('vault', 'Vault Desk'),
                ('kiosk', 'Kiosk Grid'),
              ])
                ChoiceChip(
                  key: Key('os-atm-face-${face.$1}'),
                  label: Text(face.$2),
                  selected: atmFaceId(os) == face.$1,
                  onSelected: (_) => _save((current) => current.copyWith(face: face.$1)),
                ),
            ],
          ),
          const _Label('Number pad'),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                key: const Key('os-atm-keypad-screen'),
                label: const Text('On screen'),
                selected: os.bankKeypad != 'external',
                onSelected: (_) => _save((current) => current.copyWith(bankKeypad: 'screen')),
              ),
              ChoiceChip(
                key: const Key('os-atm-keypad-external'),
                label: const Text('External keypad'),
                selected: os.bankKeypad == 'external',
                onSelected: (_) => _save((current) => current.copyWith(bankKeypad: 'external')),
              ),
            ],
          ),
          const _Label('Theme'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in kAtmSkins)
                ChoiceChip(
                  key: Key('os-atm-skin-${item.id}'),
                  label: Text(item.name),
                  selected: os.shell == item.id || (os.shell.isEmpty && item.id == 'night'),
                  onSelected: (_) => _save((current) => current.copyWith(shell: item.id)),
                ),
            ],
          ),
          const _Label('Background'),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: [
                TextButton(
                  key: const Key('os-atm-upload-background'),
                  onPressed: () async {
                    final file = await FilePicker.pickFile(type: FileType.image);
                    if (file == null) return;
                    final path = await persistPickedImage(file);
                    if (path == null) return;
                    _save((current) => current.copyWith(backgroundType: 'image', backgroundUrl: path));
                  },
                  child: const Text('Upload background'),
                ),
                if (os.backgroundType == 'image' && os.backgroundUrl.isNotEmpty)
                  TextButton(
                    key: const Key('os-atm-remove-background'),
                    onPressed: () => _save(
                      (current) => current.copyWith(backgroundType: 'preset', backgroundUrl: ''),
                    ),
                    child: const Text('Remove background'),
                  ),
              ],
            ),
          ),
          const _Label('Panels'),
          for (final id in atmPanels(os))
            ListTile(
              title: Text(id, style: const TextStyle(color: Colors.white)),
              trailing: IconButton(
                key: Key('os-atm-panel-down-$id'),
                onPressed: () => _move(id, 1),
                icon: const Icon(Icons.arrow_downward, color: Colors.white),
              ),
            ),
        ],
        if (_page == 'status') ...[
          SettingsSection(title: 'Clock', child: ClockSettings(store: widget.store, device: device)),
          PlaceSettings(store: widget.store, device: device),
          SettingsField(
            fieldKey: const Key('os-atm-temperature'),
            label: 'Temperature °C',
            value: '${os.temperature}',
            onChanged: (value) {
              final parsed = int.tryParse(value.trim());
              if (parsed == null) return;
              _save((current) => current.copyWith(temperature: parsed.clamp(-99, 99)));
            },
          ),
        ],
        if (_page == 'bank') ...[
          SettingsField(
            fieldKey: const Key('os-atm-bank-name'),
            label: 'Bank name',
            value: os.bankName,
            onChanged: (value) => _save((current) => current.copyWith(bankName: value.trim())),
          ),
          SettingsField(
            fieldKey: const Key('os-atm-user-name'),
            label: 'Account holder',
            value: os.bankHolder,
            onChanged: (value) => _save((current) => current.copyWith(bankHolder: value.trim())),
          ),
          SettingsField(
            fieldKey: const Key('os-atm-balance'),
            label: 'Balance',
            value: '${os.bankBalance}',
            onChanged: (value) {
              final parsed = int.tryParse(value.trim());
              if (parsed == null) return;
              _save((current) => current.copyWith(bankBalance: parsed));
            },
          ),
          const _Label('Currency'),
          Wrap(
            spacing: 8,
            children: [
              for (final currency in atmCurrencyChoices(os.bankCurrency))
                ChoiceChip(
                  label: Text(currency.code),
                  selected: os.bankCurrency == currency.code,
                  onSelected: (_) => _save((current) => current.copyWith(bankCurrency: currency.code)),
                ),
            ],
          ),
          SettingsField(
            fieldKey: const Key('os-atm-notes'),
            label: 'Notes',
            value: os.bankNotes.join(' '),
            onChanged: (value) {
              final notes = [
                for (final part in value.split(RegExp(r'[^0-9]+')))
                  if (int.tryParse(part) != null) int.parse(part),
              ];
              if (notes.isEmpty) return;
              _save((current) => current.copyWith(bankNotes: notes));
            },
          ),
        ],
        if (_page == 'language')
          LanguageChoices(store: widget.store, device: device, keyPrefix: 'os-atm-language'),
      ],
    );
  }

  SettingsCategory _cat(String id, IconData icon, String title, String detail) {
    return SettingsCategory(
      categoryKey: Key('device-cat-atm-$id'),
      icon: icon,
      title: title,
      detail: detail,
      onOpen: () => setState(() => _page = id),
    );
  }

  void _move(String id, int delta) {
    final order = [...atmPanels(os)];
    final index = order.indexOf(id);
    final next = index + delta;
    if (index < 0 || next < 0 || next >= order.length) return;
    final held = order[index];
    order[index] = order[next];
    order[next] = held;
    _save((current) => current.copyWith(homeOrder: order));
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
    );
  }
}
