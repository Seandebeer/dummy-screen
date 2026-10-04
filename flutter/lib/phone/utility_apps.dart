import 'dart:async';

import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          device.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text('Interface skin', style: TextStyle(color: kMuted)),
        const SizedBox(height: 10),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'modern', label: Text('Current')),
            ButtonSegment(value: 'classic', label: Text('Classic')),
            ButtonSegment(value: 'tiles', label: Text('Tiles')),
          ],
          selected: {device.skin},
          onSelectionChanged: (value) => store.setSkin(device.id, value.first),
        ),
        const SizedBox(height: 18),
        const Text(
          'Three-finger tap, or the L key on a keyboard, hides the app chrome so the screen can sit on camera.',
          style: TextStyle(color: kMuted, height: 1.4),
        ),
      ],
    );
  }
}

class ClockApp extends StatelessWidget {
  const ClockApp({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  Widget build(BuildContext context) {
    final now = propNow(device.clockOffsetMinutes);
    return Column(
      children: [
        const Spacer(),
        Text(
          formatClock(now),
          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w200),
        ),
        Text(formatDay(now), style: const TextStyle(color: kMuted)),
        const SizedBox(height: 20),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          hintText: 'Notes for this prop…',
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
    );
  }
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

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

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['C', '÷', '×', '⌫'],
      ['7', '8', '9', '−'],
      ['4', '5', '6', '+'],
      ['1', '2', '3', '='],
      ['0', '.', '='],
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              _display,
              style: const TextStyle(fontSize: 42),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              for (final row in rows)
                Expanded(
                  child: Row(
                    children: [
                      for (final label in row)
                        Expanded(
                          flex: label == '0' ? 2 : 1,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: '÷×−+=⌫'.contains(label)
                                    ? kAccent
                                    : kLine,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                if (label == 'C') {
                                  setState(() {
                                    _display = '0';
                                    _acc = null;
                                    _op = null;
                                    _fresh = true;
                                  });
                                } else if (label == '⌫') {
                                  setState(() {
                                    _display = _display.length <= 1
                                        ? '0'
                                        : _display.substring(
                                            0,
                                            _display.length - 1,
                                          );
                                    _fresh = false;
                                  });
                                } else if (label == '=') {
                                  setState(() {
                                    _reduce();
                                    _fresh = true;
                                  });
                                } else if ('÷×−+'.contains(label)) {
                                  _operate(label);
                                } else {
                                  _digit(label);
                                }
                              },
                              child: FittedBox(
                                child: Text(
                                  label,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class CameraApp extends StatelessWidget {
  const CameraApp({super.key, required this.onShutter});

  final VoidCallback onShutter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF243044), Color(0xFF10151C), Color(0xFF05070A)],
            ),
          ),
        ),
        CustomPaint(painter: _GridPainter()),
        const Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 10, color: kAlert),
                SizedBox(width: 6),
                Text('PROP', style: TextStyle(letterSpacing: 2, fontSize: 12)),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: onShutter,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: const Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: SizedBox(width: 48, height: 48),
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PhotosApp extends StatelessWidget {
  const PhotosApp({super.key, required this.photos});

  final List<PropPhoto> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const Center(
        child: Text(
          'The camera roll is empty.',
          style: TextStyle(color: kMuted),
        ),
      );
    }
    return GridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        for (final photo in photos.reversed)
          ColoredBox(
            color: Color(photo.color),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  formatStamp(photo.createdAt),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
