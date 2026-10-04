import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import '../theme.dart';

/// OS Settings, laid out like the Base44 Settings app: interface, themes,
/// wallpaper, lock screen, dial codes, language, answer mode, ring duration,
/// auto-rotate, and factory reset.
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
  bool _resetArmed = false;
  bool _confirmReset = false;
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

    return Directionality(
      textDirection: languageByCode(os.language).rtl
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFF0B0B0F),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, fontSize: 14),
          child: Stack(
            children: [
              ListView(
                key: const Key('os-settings-list'),
                padding: const EdgeInsets.only(bottom: 28),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                    child: Text(
                      copy.settings,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _Section(
                    title: 'Interface',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _skinButton(skinById('modern')!),
                        const SizedBox(height: 8),
                        _skinButton(skinById('android')!),
                        const Padding(
                          padding: EdgeInsets.only(top: 12, bottom: 8),
                          child: Text(
                            'LEGACY',
                            style: TextStyle(
                              color: Color(0x59FFFFFF),
                              fontSize: 10,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        for (final skin in osSkins)
                          if (skin.era != 'modern') ...[
                            _skinButton(skin),
                            const SizedBox(height: 8),
                          ],
                        const Text(
                          'Restyles the status bar, dock, icons and home button of this device.',
                          style: TextStyle(color: Color(0x66FFFFFF), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    title: copy.themes,
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.78,
                      children: [
                        for (final theme in osThemes)
                          _ThemeButton(
                            theme: theme,
                            active:
                                os.backgroundPreset == theme.preset &&
                                light == theme.light,
                            onTap: () => widget.store.updateOs(
                              device.id,
                              (current) => current.copyWith(
                                theme: theme.light ? 'light' : 'dark',
                                backgroundType: 'preset',
                                backgroundPreset: theme.preset,
                                backgroundUrl: '',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _Section(
                    title: copy.background,
                    child: Column(
                      children: [
                        _PresetGrid(
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
                        _UploadRow(
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
                  _Section(
                    title: 'Lock Screen',
                    child: Column(
                      children: [
                        _PresetGrid(
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
                        _UploadRow(
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
                  _Section(
                    title: 'Lock Screen Method',
                    child: Column(
                      children: [
                        for (final method in lockMethods)
                          InkWell(
                            onTap: () => widget.store.updateOs(
                              device.id,
                              (current) =>
                                  current.copyWith(lockType: method.id),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                  _Section(
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
                                        autofocus: true,
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
                                            _codeController.value =
                                                TextEditingValue(
                                                  text: clipped,
                                                  selection:
                                                      TextSelection.collapsed(
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
                                        onTapOutside: (_) =>
                                            _commitCode(_draft),
                                      )
                                    : OutlinedButton(
                                        key: Key('dial-code-$i'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: kAccent,
                                          side: BorderSide(
                                            color: kAccent.withValues(
                                              alpha: 0.4,
                                            ),
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
                        const Text(
                          'Tap to edit',
                          style: TextStyle(color: Color(0x66FFFFFF), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    title: copy.language,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          onTap: () => setState(() => _langOpen = !_langOpen),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  languageByCode(os.language).native,
                                ),
                              ),
                              Icon(
                                _langOpen
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: const Color(0x80FFFFFF),
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
                                    foregroundColor:
                                        os.language == language.code
                                        ? kAccent
                                        : const Color(0xB3FFFFFF),
                                    backgroundColor:
                                        os.language == language.code
                                        ? kAccent.withValues(alpha: 0.1)
                                        : Colors.transparent,
                                    side: BorderSide(
                                      color: os.language == language.code
                                          ? kAccent
                                          : const Color(0x1AFFFFFF),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onPressed: () => widget.store.updateOs(
                                    device.id,
                                    (current) => current.copyWith(
                                      language: language.code,
                                    ),
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
                          const Text(
                            'Default contacts follow this language; custom contacts are kept.',
                            style: TextStyle(
                              color: Color(0x66FFFFFF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _Section(
                    title: copy.answerCalls,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _Choice(
                                label: copy.answerTap,
                                active: os.callAnswer != 'swipe',
                                onTap: () => widget.store.updateOs(
                                  device.id,
                                  (current) =>
                                      current.copyWith(callAnswer: 'tap'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _Choice(
                                label: copy.answerSwipe,
                                active: os.callAnswer == 'swipe',
                                onTap: () => widget.store.updateOs(
                                  device.id,
                                  (current) =>
                                      current.copyWith(callAnswer: 'swipe'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'How incoming calls are answered on this device.',
                            style: TextStyle(
                              color: Color(0x66FFFFFF),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    title: 'Ring Duration',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _StepButton(
                              key: const Key('os-ring-minus'),
                              icon: Icons.remove,
                              onTap: delay <= 1
                                  ? null
                                  : () => widget.store.updateOs(
                                      device.id,
                                      (current) => current.copyWith(
                                        ringDelay: delay - 1,
                                      ),
                                    ),
                            ),
                            Expanded(
                              child: Text(
                                '${delay}s',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _StepButton(
                              key: const Key('os-ring-plus'),
                              icon: Icons.add,
                              onTap: delay >= 60
                                  ? null
                                  : () => widget.store.updateOs(
                                      device.id,
                                      (current) => current.copyWith(
                                        ringDelay: delay + 1,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'How long the other side rings before picking up (1–60s).',
                          style: TextStyle(color: Color(0x66FFFFFF), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    title: 'Auto rotate',
                    plain: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          key: const Key('os-auto-rotate'),
                          onTap: () => widget.store.updateOs(
                            device.id,
                            (current) => current.copyWith(
                              autoRotate: !current.autoRotate,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text('Turn screen with device'),
                              ),
                              _Pill(on: os.autoRotate),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'OS switches to landscape when the device is tilted on its side.',
                          style: TextStyle(color: Color(0x66FFFFFF), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    title: 'Reset',
                    child: _resetArmed
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Erase all changes on this device - pages, apps, settings and configurations. Pages saved to this character's device are removed from it; items saved to General stay in Saved.",
                                style: TextStyle(
                                  color: Color(0x99FFFFFF),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          setState(() => _resetArmed = false),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      key: const Key('erase-device'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: kAlert,
                                      ),
                                      onPressed: () =>
                                          setState(() => _confirmReset = true),
                                      icon: const Icon(Icons.restart_alt, size: 16),
                                      label: const Text('Erase Device'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : InkWell(
                            key: const Key('factory-reset'),
                            onTap: () => setState(() => _resetArmed = true),
                            child: const Row(
                              children: [
                                Icon(Icons.restart_alt, size: 16, color: kAlert),
                                SizedBox(width: 8),
                                Text(
                                  'Factory Reset',
                                  style: TextStyle(color: kAlert),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 22),
                    child: Text(
                      'TAKEOVER OS · PROP BUILD 1.0',
                      key: Key('os-build-footer'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0x40FFFFFF),
                        fontSize: 10,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (_confirmReset)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0xB3000000),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: Material(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Erase all content?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'This removes every change on this device - pages, apps, settings and configurations. General saved items are kept. This cannot be undone.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0x8CFFFFFF),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    key: const Key('erase-confirm'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: kAlert,
                                    ),
                                    onPressed: () => widget.store
                                        .factoryResetDevice(device.id),
                                    icon: const Icon(Icons.restart_alt, size: 16),
                                    label: const Text('Erase'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: () => setState(() {
                                      _confirmReset = false;
                                      _resetArmed = false;
                                    }),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skinButton(OsSkin skin) {
    final active = device.skin == skin.id;
    return Material(
      color: active ? kAccent.withValues(alpha: 0.1) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: active ? kAccent : const Color(0x1AFFFFFF),
        ),
      ),
      child: InkWell(
        key: Key('skin-${skin.id}'),
        borderRadius: BorderRadius.circular(10),
        onTap: () => widget.store.setSkin(device.id, skin.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: skin.preview.length < 2
                        ? [skin.preview.first, skin.preview.first]
                        : skin.preview,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skin.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      skin.desc,
                      style: const TextStyle(
                        color: Color(0x80FFFFFF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (active)
                const Icon(Icons.check, size: 16, color: kAccent),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.plain = false,
  });

  final String title;
  final Widget child;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              plain ? title : title.toUpperCase(),
              style: const TextStyle(
                color: Color(0x66FFFFFF),
                fontSize: 11,
                letterSpacing: 1.1,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.theme,
    required this.active,
    required this.onTap,
  });

  final OsThemeChoice theme;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preset = bgPresetById(theme.preset);
    final colors = theme.light ? preset.light : preset.dark;
    return InkWell(
      key: Key('theme-${theme.id}'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? kAccent : const Color(0x1AFFFFFF),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors.length < 2
                        ? [colors.first, colors.first]
                        : colors,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              theme.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: active ? kAccent : const Color(0x99FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetGrid extends StatelessWidget {
  const _PresetGrid({
    required this.prefix,
    required this.selected,
    required this.onSelect,
  });

  final String prefix;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.15,
      children: [
        for (final preset in bgPresets)
          Tooltip(
            message: preset.name,
            child: InkWell(
              key: Key('$prefix-preset-${preset.id}'),
              onTap: () => onSelect(preset.id),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected == preset.id
                        ? kAccent
                        : const Color(0x1AFFFFFF),
                    width: 2,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: preset.dark.length < 2
                          ? [preset.dark.first, preset.dark.first]
                          : preset.dark,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UploadRow extends StatelessWidget {
  const _UploadRow({
    required this.uploading,
    required this.showRemove,
    required this.onUpload,
    required this.onRemove,
  });

  final bool uploading;
  final bool showRemove;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0A84FF),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onPressed: uploading ? null : onUpload,
            icon: uploading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload, size: 14),
            label: const Text('Upload Image', style: TextStyle(fontSize: 12)),
          ),
        ),
        if (showRemove) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, size: 14),
            label: const Text('Remove'),
          ),
        ],
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? kAccent : const Color(0x99FFFFFF),
        backgroundColor: active
            ? kAccent.withValues(alpha: 0.1)
            : Colors.transparent,
        side: BorderSide(
          color: active ? kAccent : const Color(0x1AFFFFFF),
        ),
      ),
      onPressed: onTap,
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0x1AFFFFFF)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 16)),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 40,
      height: 24,
      decoration: BoxDecoration(
        color: on ? kSignal : const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 160),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.all(2),
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
