import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../format.dart';
import '../image_file.dart';
import '../media/live_lens.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import '../theme.dart';
import 'ios_keyboard.dart';

class ClockApp extends StatelessWidget {
  const ClockApp({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  Widget build(BuildContext context) {
    final now = propNow(device.clockOffsetMinutes);
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          const Spacer(),
          Text(
            formatClock(now),
            style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w200, letterSpacing: -1),
          ),
          Text(formatDay(now), style: const TextStyle(color: kMuted, fontSize: 16)),
          const SizedBox(height: 28),
          Wrap(
            spacing: 8,
            children: [
              _shift(context, '-1h', -60),
              _shift(context, '-1m', -1),
              _shift(context, '+1m', 1),
              _shift(context, '+1h', 60),
            ],
          ),
          TextButton(
            onPressed: () => store.setClockOffset(device.id, 0),
            child: const Text('Use the real time'),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _shift(BuildContext context, String label, int delta) {
    return OutlinedButton(
      onPressed: () =>
          store.setClockOffset(device.id, device.clockOffsetMinutes + delta),
      child: Text(label),
    );
  }
}

class NotesApp extends StatefulWidget {
  const NotesApp({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  late final TextEditingController _controller;
  final _focus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.device.notes);
  }

  @override
  void didUpdateWidget(NotesApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && widget.device.notes != _controller.text) {
      _controller.text = widget.device.notes;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFBE6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Text(
              'Notes',
              style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                readOnly: true,
                showCursor: true,
                style: const TextStyle(color: Colors.black, fontSize: 17, height: 1.4),
                cursorColor: const Color(0xFFFFC800),
                onTap: () => openIosKeyboard(
                  context,
                  _controller,
                  onChanged: (value) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 350), () {
                      widget.store.setNotes(widget.device.id, value);
                    });
                  },
                ),
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Start writing',
                  hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (value) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 350), () {
                    widget.store.setNotes(widget.device.id, value);
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key, this.chrome = SkinChrome.modern});

  final SkinChrome chrome;

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  String _display = '0';
  double? _acc;
  String? _op;
  bool _fresh = true;

  double get _value => double.tryParse(_display) ?? 0;

  void _digit(String digit) {
    setState(() {
      if (_display == 'Error' || _fresh) {
        _display = digit == '.' ? '0.' : digit;
        _fresh = false;
        return;
      }
      if (digit == '.' && _display.contains('.')) return;
      if (_display == '0' && digit != '.') {
        _display = digit;
      } else {
        _display += digit;
      }
    });
  }

  void _operate(String op) {
    setState(() {
      _reduce();
      _acc = _value;
      _op = op;
      _fresh = true;
    });
  }

  void _reduce() {
    if (_acc == null || _op == null || _fresh) return;
    final left = _acc!;
    final right = _value;
    double result;
    switch (_op) {
      case '+':
        result = left + right;
      case '−':
        result = left - right;
      case '×':
        result = left * right;
      case '÷':
        result = right == 0 ? double.nan : left / right;
      default:
        result = right;
    }
    _display = result.isNaN ? 'Error' : _trim(result);
    _acc = null;
    _op = null;
  }

  String _trim(double value) {
    if (value == value.roundToDouble() && value.abs() < 1000000000) {
      return value.round().toString();
    }
    var text = value.toStringAsFixed(4);
    text = text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return text;
  }

  void _sign() {
    setState(() {
      if (_display == 'Error' || _display == '0') return;
      _display = _display.startsWith('-') ? _display.substring(1) : '-$_display';
    });
  }

  void _percent() {
    setState(() {
      final current = _value;
      final result = _acc == null ? current / 100 : _acc! * current / 100;
      _display = _trim(result);
      _fresh = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['fn', '±', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 12.0;
          final key = ((constraints.maxWidth - 24 - gap * 3) / 4).clamp(44.0, 84.0);
          return Column(
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _display,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w300,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: gap),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < row.length; i++) ...[
                        if (i > 0) const SizedBox(width: gap),
                        _calcKey(row[i], row[i] == '0' ? key * 2 + gap : key, key),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _calcKey(String label, double width, double height) {
    final clear = label == 'fn';
    final shown = clear ? (_fresh ? 'AC' : 'C') : label;
    final operator = '÷×−+='.contains(label);
    final active = operator && label != '=' && _op == label && _fresh;
    final function = clear || label == '±' || label == '%';
    final accent = switch (widget.chrome) {
      SkinChrome.android => const Color(0xFF8AB4F8),
      SkinChrome.tiles => const Color(0xFF1BA1E2),
      _ => const Color(0xFFFF9F0A),
    };
    final radius = widget.chrome == SkinChrome.tiles ? 4.0 : height / 2;
    final color = active
        ? Colors.white
        : operator
            ? accent
            : function
                ? const Color(0xFFA5A5A5)
                : const Color(0xFF333333);
    final ink = active
        ? accent
        : function
            ? Colors.black
            : Colors.white;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: () {
          if (clear) {
            if (_fresh) {
              setState(() {
                _display = '0';
                _acc = null;
                _op = null;
              });
            } else {
              setState(() {
                _display = '0';
                _fresh = true;
              });
            }
          } else if (label == '±') {
            _sign();
          } else if (label == '%') {
            _percent();
          } else if (label == '=') {
            setState(() {
              _reduce();
              _fresh = true;
            });
          } else if (operator) {
            _operate(label);
          } else {
            _digit(label);
          }
        },
        child: SizedBox(
          width: width,
          height: height,
          child: Center(
            child: Text(
              shown,
              style: TextStyle(color: ink, fontSize: shown == 'AC' ? 24 : 32, fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ),
    );
  }
}

class CameraApp extends StatefulWidget {
  const CameraApp({super.key, required this.photos, required this.onShutter});

  final List<PropPhoto> photos;
  final void Function(Uint8List? bytes) onShutter;

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  final LiveLens _lensDevice = LiveLens();
  String _mode = 'camera';
  String _lens = 'photo';
  bool _flash = false;
  bool _front = false;

  @override
  void initState() {
    super.initState();
    _openLens();
  }

  @override
  void dispose() {
    _lensDevice.close();
    super.dispose();
  }

  Future<void> _openLens() async {
    await _lensDevice.open(video: true, audio: false, front: _front);
    if (mounted) setState(() {});
  }

  Future<void> _capture() async {
    final bytes = await _lensDevice.capture();
    if (!mounted) return;
    widget.onShutter(bytes);
    setState(() => _flash = true);
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (mounted) setState(() => _flash = false);
    });
  }

  void _show(String mode) {
    setState(() => _mode = mode);
    if (mode == 'camera') {
      _openLens();
    } else {
      _lensDevice.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == 'roll') {
      return PhotosApp(
        photos: widget.photos,
        onBack: () => _show('camera'),
      );
    }
    if (_mode == 'clips') {
      return _ClipsGallery(onBack: () => _show('camera'));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        LensView(lens: _lensDevice, mirror: _front),
        if (_lensDevice.denied)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera, size: 28, color: Colors.white30),
                  SizedBox(height: 8),
                  Text(
                    'Camera unavailable',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Allow camera access in the browser to use the lens',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
            ),
          ),
        if (_flash)
          const ColoredBox(color: Color(0xCCFFFFFF)),
        Positioned(
          top: 8,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CamButton(
                icon: Icons.photo_library_outlined,
                badge: widget.photos.length,
                badgeColor: kAccent,
                badgeInk: Colors.black,
                onTap: () => _show('roll'),
              ),
              _CamButton(
                icon: Icons.movie_outlined,
                badge: 0,
                badgeColor: kAlert,
                badgeInk: Colors.white,
                onTap: () => _show('clips'),
              ),
              _CamButton(
                icon: Icons.flip_camera_ios_outlined,
                badge: 0,
                badgeColor: kAccent,
                badgeInk: Colors.black,
                iconColor: _front ? kAccent : Colors.white,
                onTap: () {
                  setState(() => _front = !_front);
                  _openLens();
                },
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 96,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _lensButton('Photo', 'photo', kAccent),
              const SizedBox(width: 28),
              _lensButton('Video', 'video', kAlert),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Center(child: _shutter()),
        ),
      ],
    );
  }

  Widget _lensButton(String label, String id, Color active) {
    final selected = _lens == id;
    return GestureDetector(
      onTap: () => setState(() => _lens = id),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: selected ? active : Colors.white54,
        ),
      ),
    );
  }

  Widget _shutter() {
    final video = _lens == 'video';
    return GestureDetector(
      onTap: video ? null : _capture,
      child: Opacity(
        opacity: video ? 0.4 : 1,
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: video ? const Color(0xB3FF453A) : Colors.white,
              width: 4,
            ),
            color: video ? const Color(0x26FF453A) : Colors.white24,
          ),
          child: video
              ? const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFF453A),
                  ),
                  child: SizedBox(width: 36, height: 36),
                )
              : const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: SizedBox(width: 48, height: 48),
                ),
        ),
      ),
    );
  }
}

class _CamButton extends StatelessWidget {
  const _CamButton({
    required this.icon,
    required this.badge,
    required this.badgeColor,
    required this.badgeInk,
    this.iconColor = Colors.white,
    required this.onTap,
  });

  final IconData icon;
  final int badge;
  final Color badgeColor;
  final Color badgeInk;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0x73000000),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ),
            if (badge > 0)
              Positioned(
                top: -4,
                right: -4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '$badge',
                      style: TextStyle(
                        color: badgeInk,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClipsGallery extends StatelessWidget {
  const _ClipsGallery({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.chevron_left, color: kAccent),
                  label: const Text('Camera', style: TextStyle(color: kAccent)),
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Text(
                    '0 clips',
                    style: TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_outlined, size: 24, color: Colors.white30),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'No clips yet - record one from the camera',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PhotosApp extends StatelessWidget {
  const PhotosApp({super.key, required this.photos, this.onBack});

  final List<PropPhoto> photos;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final grid = photos.isEmpty
        ? const Center(
            child: Text(
              'The camera roll is empty.',
              style: TextStyle(color: kMuted),
            ),
          )
        : GridView.count(
            padding: const EdgeInsets.all(8),
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (final photo in photos.reversed) _PhotoTile(photo: photo),
            ],
          );
    if (onBack == null) return grid;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left, color: kAccent),
            label: const Text('Camera', style: TextStyle(color: kAccent)),
          ),
        ),
        Expanded(child: grid),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo});

  final PropPhoto photo;

  @override
  Widget build(BuildContext context) {
    final provider = imageProviderForPath(photo.image);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color(photo.color),
        image: provider == null
            ? null
            : DecorationImage(image: provider, fit: BoxFit.cover),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            formatStamp(photo.createdAt),
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
