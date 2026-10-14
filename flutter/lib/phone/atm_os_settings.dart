import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import '../theme.dart';
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
              _cat('status', Icons.schedule, 'Status', 'Clock, date, place, and temperature'),
              _cat('bank', Icons.account_balance, 'Bank', 'Name, balance, currency, and notes'),
              _cat('language', Icons.language, 'Language', languageByCode(os.language).native),
            ],
          ),
        if (_page == 'display') ...[
          SettingsSection(
            title: 'Interface',
            child: Column(
              children: [
                for (final face in const [
                  ('teller', 'Night Teller', 'The original layout. This is the default.'),
                  ('vault', 'Vault Desk', 'Large icons for each transaction.'),
                  ('kiosk', 'Kiosk Grid', 'Square buttons in a grid.'),
                ]) ...[
                  SettingsTile(
                    tileKey: Key('os-atm-face-${face.$1}'),
                    name: face.$2,
                    desc: face.$3,
                    preview: [atmSkinFor(os.shell).major, atmSkinFor(os.shell).washB],
                    active: atmFaceId(os) == face.$1,
                    onTap: () => _save(
                      (current) => current.copyWith(face: face.$1 == 'teller' ? '' : face.$1),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          SettingsSection(
            title: 'Number pad',
            child: Row(
              children: [
                Expanded(
                  child: SettingsChoice(
                    key: const Key('os-atm-keypad-screen'),
                    label: 'On screen',
                    active: os.bankKeypad != 'external',
                    onTap: () => _save((current) => current.copyWith(bankKeypad: 'screen')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SettingsChoice(
                    key: const Key('os-atm-keypad-external'),
                    label: 'External keypad',
                    active: os.bankKeypad == 'external',
                    onTap: () => _save((current) => current.copyWith(bankKeypad: 'external')),
                  ),
                ),
              ],
            ),
          ),
          SettingsSection(
            title: 'Theme',
            child: Column(
              children: [
                for (final item in kAtmSkins) ...[
                  SettingsTile(
                    tileKey: Key('os-atm-skin-${item.id}'),
                    name: item.name,
                    desc: 'Colours for every ATM interface.',
                    preview: [item.major, item.washA],
                    active: os.shell == item.id || (os.shell.isEmpty && item.id == 'night'),
                    onTap: () => _save((current) => current.copyWith(shell: item.id)),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          SettingsSection(
            title: 'Background',
            child: SettingsUploadRow(
              uploading: false,
              showRemove: os.backgroundType == 'image' && os.backgroundUrl.isNotEmpty,
              uploadKey: const Key('os-atm-upload-background'),
              removeKey: const Key('os-atm-remove-background'),
              onUpload: () async {
                final file = await FilePicker.pickFile(type: FileType.image);
                if (file == null) return;
                final path = await persistPickedImage(file);
                if (path == null) return;
                _save((current) => current.copyWith(backgroundType: 'image', backgroundUrl: path));
              },
              onRemove: () => _save(
                (current) => current.copyWith(backgroundType: 'preset', backgroundUrl: ''),
              ),
            ),
          ),
        ],
        if (_page == 'status') ...[
          SettingsSection(title: 'Clock', child: ClockSettings(store: widget.store, device: device)),
          SettingsSection(
            title: 'Date',
            child: SettingsField(
              fieldKey: const Key('os-atm-date'),
              label: 'Date',
              value: formatDateField(os),
              onChanged: (value) {
                final trimmed = value.trim();
                if (trimmed.isEmpty) {
                  _save((current) => current.copyWith(dateYear: 0, dateMonth: 0, dateDay: 0));
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
              },
            ),
          ),
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
          CollapsibleSection(
            sectionKey: const Key('os-atm-currency'),
            title: 'Currency · ${os.bankCurrency}',
            child: SizedBox(
              height: 220,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final currency in atmCurrencyChoices(os.bankCurrency))
                      ListTile(
                        key: Key('os-atm-currency-${currency.code}'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(currency.label, style: const TextStyle(color: Colors.white)),
                        trailing: currency.code == os.bankCurrency
                            ? const Icon(Icons.check, color: kAccent, size: 18)
                            : null,
                        onTap: () => _save((current) => current.copyWith(bankCurrency: currency.code)),
                      ),
                  ],
                ),
              ),
            ),
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

}
