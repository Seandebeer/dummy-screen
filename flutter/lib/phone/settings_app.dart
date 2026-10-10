import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import '../theme.dart';
import 'extra_settings.dart';
import 'ios_keyboard.dart';
import 'settings_kit.dart';

/// OS Settings for a phone or a tablet, laid out like the Base44 Settings
/// app: interface, themes, wallpaper, lock screen, dial codes, language,
/// answer mode, ring duration, auto-rotate, and factory reset. A computer
/// runs the desk build of this screen, which carries its own settings.
class SettingsApp extends StatefulWidget {
  const SettingsApp({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> {
  int? _editingCode;
  String _draft = '';
  final _codeController = TextEditingController();
  bool _langOpen = false;
  bool _legacy = false;
  bool _uploading = false;
  bool _lockUploading = false;
  bool _uploadError = false;
  bool _lockUploadError = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  PropDevice get device => widget.device;
  OsSettings get os => device.os;

  Future<void> _pickImage({required bool lock}) async {
    setState(() {
      if (lock) {
        _lockUploading = true;
        _lockUploadError = false;
      } else {
        _uploading = true;
        _uploadError = false;
      }
    });
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      final path = file == null ? null : await persistPickedImage(file);
      if (!mounted) return;
      if (path == null) {
        setState(() {
          if (lock) {
            _lockUploadError = true;
          } else {
            _uploadError = true;
          }
        });
        return;
      }
      widget.store.updateOs(device.id, (current) {
        if (lock) {
          return current.copyWith(
            lockBackgroundType: 'image',
            lockBackgroundUrl: path,
          );
        }
        return current.copyWith(backgroundType: 'image', backgroundUrl: path);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          if (lock) {
            _lockUploadError = true;
          } else {
            _uploadError = true;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _lockUploading = false;
        });
      }
    }
  }

  void _commitCode(String value) {
    final index = _editingCode;
    setState(() => _editingCode = null);
    if (index == null) return;
    final code = value.trim();
    final codes = os.dialCodes;
    if (!validDialCode(code) || codes.contains(code) || code == codes[index]) {
      return;
    }
    final next = [...codes];
    next[index] = code;
    widget.store.updateOs(
      device.id,
      (current) => current.copyWith(dialCodes: next),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = copyFor(os.language);
    final light = os.isLight;
    final hasImage = os.backgroundType == 'image' && os.backgroundUrl.isNotEmpty;
    final lockImage =
        os.lockBackgroundType == 'image' && os.lockBackgroundUrl.isNotEmpty;
    final skinMethod = skinLockMethod(device.skin);
    final defaultLabel = lockMethodLabel(
      skinMethod == 'none' ? 'swipe' : skinMethod,
    );
    final needsSetup =
        (os.lockType == 'passcode' && os.passcode.isEmpty) ||
        (os.lockType == 'pattern' && os.pattern.isEmpty);
    final delay = os.ringDelaySeconds;
    final phone = device.kind == 'phone';
    final tablet = device.kind == 'tablet';

    return SettingsPage(
      listKey: const Key('os-settings-list'),
      title: copy.settings,
      rtl: languageByCode(os.language).rtl,
      onReset: () => widget.store.factoryResetDevice(device.id),
      children: [
        if (tablet)
          SettingsSection(
            title: 'Interface',
            child: SettingsTile(
              tileKey: const Key('skin-tablet'),
              name: 'Tablet',
              desc: 'One tablet layout for this device.',
              preview: skinById('modern')!.preview,
              active: true,
              onTap: () {},
            ),
          ),
        if (phone)
          SettingsSection(
          title: 'Interface',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _skinButton(skinById('modern')!),
              const SizedBox(height: 8),
              _skinButton(skinById('android')!),
              const SizedBox(height: 8),
              Material(
                color: light
                    ? const Color(0x14000000)
                    : const Color(0x18FFFFFF),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      key: const Key('legacy-skins'),
                      onTap: () => setState(() => _legacy = !_legacy),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _legacy ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                              color: light ? Colors.black54 : Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LEGACY',
                              style: TextStyle(
                                color: light ? Colors.black87 : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Interfaces',
                              style: TextStyle(
                                color: light ? Colors.black45 : Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_legacy)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: Column(
                          children: [
                            for (final skin in osSkins)
                              if (skin.era == 'legacy') ...[
                                _skinButton(skin),
                                const SizedBox(height: 8),
                              ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SettingsHint(
                'Restyles the status bar, dock, icons and home button of this device.',
              ),
            ],
          ),
        ),
        ExtraSettings(store: widget.store, device: device, cellular: phone),
        SettingsSection(
          title: copy.themes,
          child: SettingsThemeGrid(
            prefix: 'os',
            selected: (theme) =>
                os.backgroundPreset == theme.preset && light == theme.light,
            onSelect: (theme) => widget.store.updateOs(
              device.id,
              (current) => current.copyWith(
                theme: theme.light ? 'light' : 'dark',
                backgroundType: 'preset',
                backgroundPreset: theme.preset,
                backgroundUrl: '',
              ),
            ),
          ),
        ),
        CollapsibleSection(
          title: copy.background,
          child: Column(
            children: [
              SettingsPresetGrid(
                prefix: 'home',
                selected: hasImage ? null : os.backgroundPreset,
                onSelect: (id) => widget.store.updateOs(
                  device.id,
                  (current) => current.copyWith(
                    backgroundType: 'preset',
                    backgroundPreset: id,
                    backgroundUrl: '',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SettingsUploadRow(
                uploading: _uploading,
                showRemove: hasImage,
                onUpload: () => _pickImage(lock: false),
                onRemove: () => widget.store.updateOs(
                  device.id,
                  (current) => current.copyWith(
                    backgroundType: 'preset',
                    backgroundUrl: '',
                  ),
                ),
              ),
              if (_uploadError)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'image upload failed - try again',
                    style: TextStyle(color: kAlert, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
        CollapsibleSection(
          title: 'Lock Screen',
          child: Column(
            children: [
              SettingsPresetGrid(
                prefix: 'lock',
                selected: lockImage ? null : os.lockBackgroundPreset,
                onSelect: (id) => widget.store.updateOs(
                  device.id,
                  (current) => current.copyWith(
                    lockBackgroundType: 'preset',
                    lockBackgroundPreset: id,
                    lockBackgroundUrl: '',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SettingsUploadRow(
                uploading: _lockUploading,
                showRemove: lockImage,
                onUpload: () => _pickImage(lock: true),
                onRemove: () => widget.store.updateOs(
                  device.id,
                  (current) => current.copyWith(
                    lockBackgroundType: 'preset',
                    lockBackgroundUrl: '',
                  ),
                ),
              ),
              if (_lockUploadError)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'image upload failed - try again',
                    style: TextStyle(color: kAlert, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
        CollapsibleSection(
          title: 'Lock Screen Method',
          sectionKey: const Key('lock-methods'),
          child: Column(
            children: [
              for (final method in lockMethods)
                InkWell(
                  onTap: () => widget.store.updateOs(
                    device.id,
                    (current) => current.copyWith(lockType: method.id),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          method.icon,
                          size: 18,
                          color: os.lockType == method.id
                              ? const Color(0xFF0A84FF)
                              : const Color(0x80FFFFFF),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(method.label),
                              Text(
                                method.id == 'none'
                                    ? '$defaultLabel by default'
                                    : method.hint,
                                style: const TextStyle(
                                  color: Color(0x59FFFFFF),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (os.lockType == method.id)
                          const Icon(
                            Icons.check,
                            size: 16,
                            color: Color(0xFF0A84FF),
                          ),
                      ],
                    ),
                  ),
                ),
              const Divider(height: 16, color: Color(0x1AFFFFFF)),
              Row(
                children: [
                  if (os.lockType == 'passcode')
                    TextButton(
                      onPressed: () {
                        widget.store.updateOs(
                          device.id,
                          (current) => current.copyWith(passcode: ''),
                        );
                        widget.store.setLocked(device.id, true);
                      },
                      child: const Text(
                        'Reset Passcode',
                        style: TextStyle(color: kAlert, fontSize: 12),
                      ),
                    )
                  else if (os.lockType == 'pattern')
                    TextButton(
                      onPressed: () {
                        widget.store.updateOs(
                          device.id,
                          (current) => current.copyWith(pattern: ''),
                        );
                        widget.store.setLocked(device.id, true);
                      },
                      child: const Text(
                        'Reset Pattern',
                        style: TextStyle(color: kAlert, fontSize: 12),
                      ),
                    ),
                  const Spacer(),
                  if (needsSetup)
                    const Text(
                      'SET ON NEXT LOCK',
                      style: TextStyle(
                        color: Color(0xFFFF9F0A),
                        fontSize: 10,
                        letterSpacing: 0.6,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (phone)
        SettingsSection(
          title: copy.dialCodes,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (var i = 0; i < os.dialCodes.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _editingCode == i
                          ? TextField(
                              key: Key('dial-edit-$i'),
                              readOnly: true,
                              showCursor: true,
                              onTap: () => openIosKeyboard(
                                context,
                                _codeController,
                                numeric: true,
                              ),
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: kAccent),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onChanged: (value) {
                                final digits = value.replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                );
                                final clipped = digits.length > 3
                                    ? digits.substring(0, 3)
                                    : digits;
                                if (clipped != value) {
                                  _codeController.value = TextEditingValue(
                                    text: clipped,
                                    selection: TextSelection.collapsed(
                                      offset: clipped.length,
                                    ),
                                  );
                                }
                                _draft = clipped;
                                if (clipped.length == 3) {
                                  _commitCode(clipped);
                                }
                              },
                              onSubmitted: _commitCode,
                              onTapOutside: (_) => _commitCode(_draft),
                            )
                          : OutlinedButton(
                              key: Key('dial-code-$i'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kAccent,
                                side: BorderSide(
                                  color: kAccent.withValues(alpha: 0.4),
                                ),
                                backgroundColor: kAccent.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                              onPressed: () => setState(() {
                                _editingCode = i;
                                _draft = os.dialCodes[i];
                                _codeController.text = _draft;
                              }),
                              child: Text(os.dialCodes[i]),
                            ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              const SettingsHint('Tap to edit'),
            ],
          ),
        ),
        if (phone)
        SettingsSection(
          title: copy.answerCalls,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SettingsChoice(
                      label: copy.answerTap,
                      active: os.callAnswer != 'swipe',
                      onTap: () => widget.store.updateOs(
                        device.id,
                        (current) => current.copyWith(callAnswer: 'tap'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SettingsChoice(
                      label: copy.answerSwipe,
                      active: os.callAnswer == 'swipe',
                      onTap: () => widget.store.updateOs(
                        device.id,
                        (current) => current.copyWith(callAnswer: 'swipe'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: SettingsHint(
                  'How incoming calls are answered on this device.',
                ),
              ),
            ],
          ),
        ),
        if (phone)
        SettingsSection(
          title: 'Ring Duration',
          child: Column(
            children: [
              SettingsStepRow(
                label: '${delay}s',
                minusKey: const Key('os-ring-minus'),
                plusKey: const Key('os-ring-plus'),
                onMinus: delay <= 1
                    ? null
                    : () => widget.store.updateOs(
                        device.id,
                        (current) => current.copyWith(ringDelay: delay - 1),
                      ),
                onPlus: delay >= 60
                    ? null
                    : () => widget.store.updateOs(
                        device.id,
                        (current) => current.copyWith(ringDelay: delay + 1),
                      ),
              ),
              const SizedBox(height: 8),
              const SettingsHint(
                'How long the other side rings before picking up (1–60s).',
              ),
            ],
          ),
        ),
        SettingsSection(
          title: 'Auto rotate',
          plain: true,
          child: SettingsToggle(
            key: const Key('os-auto-rotate'),
            label: 'Turn screen with device',
            hint: 'OS switches to landscape when the device is tilted on its side.',
            value: os.autoRotate,
            onChanged: (value) => widget.store.updateOs(
              device.id,
              (current) => current.copyWith(autoRotate: value),
            ),
          ),
        ),
        _language(copy),
        CollapsibleSection(
          title: 'Sounds',
          sectionKey: const Key('sound-settings'),
          child: SoundSettings(store: widget.store, device: device),
        ),
        if (phone)
          SettingsSection(
            title: 'Caller details',
            child: CallerDetails(store: widget.store, device: device),
          ),
        SettingsSection(
          title: 'App branding',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generic keeps the fictional names and icons. Branded uses the real product names and artwork.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Generic'),
                    labelStyle: TextStyle(color: !os.branded ? Colors.black : Colors.white),
                    selectedColor: Colors.white,
                    backgroundColor: const Color(0xFF2C2C2E),
                    selected: !os.branded,
                    onSelected: (_) => widget.store.updateOs(
                      device.id,
                      (current) => current.copyWith(branded: false),
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('Branded'),
                    labelStyle: TextStyle(color: os.branded ? Colors.black : Colors.white),
                    selectedColor: Colors.white,
                    backgroundColor: const Color(0xFF2C2C2E),
                    selected: os.branded,
                    onSelected: (_) => widget.store.updateOs(
                      device.id,
                      (current) => current.copyWith(branded: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SettingsSection(
          title: 'Custom apps',
          child: CustomIconMaker(store: widget.store, device: device),
        ),
      ],
    );
  }

  Widget _language(OsCopy copy) {
    return SettingsSection(
      title: copy.language,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _langOpen = !_langOpen),
            child: Row(
              children: [
                Expanded(child: Text(languageByCode(os.language).native)),
                Icon(
                  _langOpen ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xB3FFFFFF),
                  size: 18,
                ),
              ],
            ),
          ),
          if (_langOpen) ...[
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.4,
              children: [
                for (final language in osLanguages)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: os.language == language.code
                          ? kAccent
                          : const Color(0xD9FFFFFF),
                      backgroundColor: os.language == language.code
                          ? kAccent.withValues(alpha: 0.1)
                          : Colors.transparent,
                      side: BorderSide(
                        color: os.language == language.code
                            ? kAccent
                            : const Color(0x33FFFFFF),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => widget.store.updateOs(
                      device.id,
                      (current) => current.copyWith(language: language.code),
                    ),
                    child: Text(
                      language.native,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const SettingsHint(
              'Default contacts follow this language; custom contacts are kept.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _skinButton(OsSkin skin) {
    return SettingsTile(
      tileKey: Key('skin-${skin.id}'),
      name: skin.name,
      desc: skin.desc,
      preview: skin.preview,
      active: device.skin == skin.id,
      onTap: () => widget.store.setSkin(device.id, skin.id),
    );
  }
}
