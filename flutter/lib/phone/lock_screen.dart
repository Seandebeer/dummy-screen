import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../os_catalog.dart';
import '../theme.dart';

class LockView extends StatefulWidget {
  const LockView({
    super.key,
    required this.device,
    required this.timeLabel,
    required this.dateLabel,
    required this.onUnlock,
    required this.onSetPasscode,
    required this.onSetPattern,
  });

  final PropDevice device;
  final String timeLabel;
  final String dateLabel;
  final VoidCallback onUnlock;
  final ValueChanged<String> onSetPasscode;
  final ValueChanged<String> onSetPattern;

  @override
  State<LockView> createState() => _LockViewState();
}

class _LockViewState extends State<LockView> {
  String _stage = 'unlock';
  String _entry = '';
  String _first = '';
  String _message = '';
  int _shake = 0;
  Timer? _faceTimer;
  bool _scanning = false;
  bool _reveal = false;
  bool _torch = false;

  String get _method =>
      resolvedLockMethod(widget.device.skin, widget.device.os.lockType);

  bool get _light => widget.device.os.isLight;

  Color get _ink => _light ? const Color(0xD9000000) : Colors.white;

  @override
  void initState() {
    super.initState();
    _stage = _openingStage();
    if (_method == 'face') _startFace();
  }

  @override
  void didUpdateWidget(LockView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = resolvedLockMethod(
      widget.device.skin,
      widget.device.os.lockType,
    );
    final prev = resolvedLockMethod(
      oldWidget.device.skin,
      oldWidget.device.os.lockType,
    );
    if (next != prev) {
      _faceTimer?.cancel();
      _scanning = false;
      _entry = '';
      _first = '';
      _message = '';
      _stage = _openingStage();
      if (next == 'face') _startFace();
    }
  }

  @override
  void dispose() {
    _faceTimer?.cancel();
    super.dispose();
  }

  String _openingStage() {
    final os = widget.device.os;
    final method = resolvedLockMethod(widget.device.skin, os.lockType);
    if (method == 'passcode' && os.passcode.isEmpty) return 'set';
    if (method == 'pattern' && os.pattern.isEmpty) return 'set';
    return 'unlock';
  }

  void _fail(String message) {
    setState(() {
      _message = message;
      _shake += 1;
      _entry = '';
    });
  }

  void _submitPasscode(String code) {
    final saved = widget.device.os.passcode;
    if (_stage == 'unlock') {
      if (code == saved) {
        widget.onUnlock();
      } else {
        _fail('Wrong passcode - try again');
      }
      return;
    }
    if (_stage == 'set') {
      setState(() {
        _first = code;
        _stage = 'confirm';
        _entry = '';
        _message = '';
      });
      return;
    }
    if (_first == code) {
      widget.onSetPasscode(code);
      widget.onUnlock();
    } else {
      setState(() {
        _stage = 'set';
        _first = '';
      });
      _fail("Passcodes didn't match - try again");
    }
  }

  void _pressDigit(String digit) {
    if (_entry.length >= 4) return;
    final next = '$_entry$digit';
    setState(() {
      _message = '';
      _entry = next;
    });
    if (next.length == 4) {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (!mounted || _entry != next) return;
        _submitPasscode(next);
      });
    }
  }

  void _submitPattern(String code) {
    if (code.split(',').where((part) => part.isNotEmpty).length < 4) {
      _fail('Connect at least 4 dots');
      return;
    }
    final saved = widget.device.os.pattern;
    if (_stage == 'unlock') {
      if (code == saved) {
        widget.onUnlock();
      } else {
        _fail('Wrong pattern - try again');
      }
      return;
    }
    if (_stage == 'set') {
      setState(() {
        _first = code;
        _stage = 'confirm';
        _message = '';
      });
      return;
    }
    if (_first == code) {
      widget.onSetPattern(code);
      widget.onUnlock();
    } else {
      setState(() {
        _stage = 'set';
        _first = '';
      });
      _fail("Patterns didn't match - try again");
    }
  }

  void _startFace() {
    _faceTimer?.cancel();
    setState(() => _scanning = true);
    _faceTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) widget.onUnlock();
    });
  }

  String get _heading {
    switch (_method) {
      case 'passcode':
        if (_stage == 'set') return 'Choose a Passcode';
        if (_stage == 'confirm') return 'Confirm Passcode';
        return 'Enter Passcode';
      case 'pattern':
        if (_stage == 'set') return 'Draw a Pattern';
        if (_stage == 'confirm') return 'Confirm Pattern';
        return 'Draw Pattern';
      case 'face':
        return 'Face Scan';
      case 'fingerprint':
        return 'Fingerprint';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final secure = _method == 'passcode' ||
        _method == 'pattern' ||
        _method == 'face' ||
        _method == 'fingerprint';
    final compact = secure && _reveal;
    if (secure && !_reveal) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _reveal = true),
        child: Center(
          child: Text(
            widget.timeLabel,
            style: TextStyle(
              color: _ink,
              fontSize: 86,
              fontWeight: FontWeight.w200,
              letterSpacing: -2,
            ),
          ),
        ),
      );
    }
    return Stack(
      children: [
        Column(
      children: [
        SizedBox(height: compact ? 12 : 28),
        Text(
          widget.timeLabel,
          style: TextStyle(
            color: _ink,
            fontSize: compact ? 48 : 76,
            fontWeight: FontWeight.w200,
            letterSpacing: -1,
          ),
        ),
        Text(
          widget.dateLabel,
          style: TextStyle(
            color: _ink.withValues(alpha: 0.7),
            fontSize: compact ? 14 : 16,
          ),
        ),
        if (_heading.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            _heading,
            style: TextStyle(color: _ink.withValues(alpha: 0.85), fontSize: 13),
          ),
        ],
        if (_method == 'passcode') ...[
          const SizedBox(height: 10),
          _Dots(key: ValueKey(_shake), filled: _entry.length, ink: _ink),
        ],
        if (_message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _message,
              style: const TextStyle(color: kAlert, fontSize: 12),
            ),
          ),
        const Spacer(),
        if (_method == 'slide' || _method == 'swipe')
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 0, 36, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _LockOrb(
                  icon: Icons.flashlight_on,
                  on: _torch,
                  onTap: () => setState(() => _torch = !_torch),
                ),
                _LockOrb(icon: Icons.photo_camera, on: false, onTap: () {}),
              ],
            ),
          ),
        _methodBody(),
        const SizedBox(height: 16),
      ],
        ),
        if (_torch)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _torch = false),
              child: const ColoredBox(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _methodBody() {
    switch (_method) {
      case 'slide':
        return _SlideUnlock(ink: _ink, onUnlock: widget.onUnlock);
      case 'ring':
        return _RingUnlock(ink: _ink, onUnlock: widget.onUnlock);
      case 'passcode':
        return _PasscodePad(onDigit: _pressDigit, onDelete: () {
          if (_entry.isEmpty) return;
          setState(() => _entry = _entry.substring(0, _entry.length - 1));
        });
      case 'pattern':
        return _PatternPad(ink: _ink, onComplete: _submitPattern);
      case 'face':
        return _FaceScan(ink: _ink, scanning: _scanning);
      case 'fingerprint':
        return _Fingerprint(ink: _ink, onUnlock: widget.onUnlock);
      default:
        return _SwipeUnlock(ink: _ink, onUnlock: widget.onUnlock);
    }
  }
}

class _LockOrb extends StatelessWidget {
  const _LockOrb({required this.icon, required this.on, required this.onTap});

  final IconData icon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? Colors.white : Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: on ? Colors.black : Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _SwipeUnlock extends StatelessWidget {
  const _SwipeUnlock({required this.ink, required this.onUnlock});

  final Color ink;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < -200) onUnlock();
      },
      child: Column(
        children: [
          Icon(Icons.keyboard_arrow_up, color: ink.withValues(alpha: 0.7)),
          TextButton(
            key: const Key('lock-unlock'),
            onPressed: onUnlock,
            child: Text('Unlock', style: TextStyle(color: ink)),
          ),
        ],
      ),
    );
  }
}

class _SlideUnlock extends StatefulWidget {
  const _SlideUnlock({required this.ink, required this.onUnlock});

  final Color ink;
  final VoidCallback onUnlock;

  @override
  State<_SlideUnlock> createState() => _SlideUnlockState();
}

class _SlideUnlockState extends State<_SlideUnlock> {
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travel = constraints.maxWidth - 52;
          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _progress = (_progress + details.delta.dx / travel).clamp(
                  0.0,
                  1.0,
                );
              });
            },
            onHorizontalDragEnd: (_) {
              if (_progress > 0.85) {
                widget.onUnlock();
              } else {
                setState(() => _progress = 0);
              }
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: widget.ink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      'slide to unlock',
                      style: TextStyle(
                        color: widget.ink.withValues(alpha: 0.7),
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Positioned(
                    left: travel * _progress,
                    top: 4,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.ink.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: widget.ink.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingUnlock extends StatefulWidget {
  const _RingUnlock({required this.ink, required this.onUnlock});

  final Color ink;
  final VoidCallback onUnlock;

  @override
  State<_RingUnlock> createState() => _RingUnlockState();
}

class _RingUnlockState extends State<_RingUnlock> {
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ring = Offset(constraints.maxWidth / 2, 70);
          final home = Offset(constraints.maxWidth / 2, 180);
          final lock = home + _offset;
          return GestureDetector(
            onPanUpdate: (details) =>
                setState(() => _offset += details.delta),
            onPanEnd: (_) {
              if ((lock - ring).distance < 46) {
                widget.onUnlock();
              } else {
                setState(() => _offset = Offset.zero);
              }
            },
            child: Stack(
              children: [
                Positioned(
                  left: ring.dx - 36,
                  top: ring.dy - 36,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.ink.withValues(alpha: 0.7),
                        width: 3,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: lock.dx - 24,
                  top: lock.dy - 24,
                  child: Icon(Icons.lock, color: widget.ink, size: 48),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PasscodePad extends StatelessWidget {
  const _PasscodePad({required this.onDigit, required this.onDelete});

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        children: [
          for (final key in keys)
            if (key.isEmpty)
              const SizedBox.shrink()
            else if (key == 'del')
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.backspace_outlined),
              )
            else
              InkWell(
                key: Key('passcode-$key'),
                customBorder: const CircleBorder(),
                onTap: () => onDigit(key),
                child: Center(
                  child: Text(key, style: const TextStyle(fontSize: 28)),
                ),
              ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({super.key, required this.filled, required this.ink});

  final int filled;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? ink : Colors.transparent,
              border: Border.all(color: ink),
            ),
          ),
      ],
    );
  }
}

class _PatternPad extends StatefulWidget {
  const _PatternPad({required this.ink, required this.onComplete});

  final Color ink;
  final ValueChanged<String> onComplete;

  @override
  State<_PatternPad> createState() => _PatternPadState();
}

class _PatternPadState extends State<_PatternPad> {
  final List<int> _dots = [];

  void _hit(Offset local, Size size) {
    final cell = size.width / 3;
    for (var i = 0; i < 9; i++) {
      if (_dots.contains(i)) continue;
      final center = Offset(
        cell * (i % 3) + cell / 2,
        cell * (i ~/ 3) + cell / 2,
      );
      if ((local - center).distance < cell * 0.38) {
        setState(() => _dots.add(i));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              onPanStart: (details) => _hit(details.localPosition, size),
              onPanUpdate: (details) => _hit(details.localPosition, size),
              onPanEnd: (_) {
                final code = _dots.join(',');
                setState(() => _dots.clear());
                widget.onComplete(code);
              },
              child: CustomPaint(
                painter: _PatternPainter(dots: _dots, ink: widget.ink),
                child: const SizedBox.expand(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({required this.dots, required this.ink});

  final List<int> dots;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 3;
    Offset center(int i) =>
        Offset(cell * (i % 3) + cell / 2, cell * (i ~/ 3) + cell / 2);
    final line = Paint()
      ..color = ink.withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < dots.length - 1; i++) {
      canvas.drawLine(center(dots[i]), center(dots[i + 1]), line);
    }
    for (var i = 0; i < 9; i++) {
      final active = dots.contains(i);
      canvas.drawCircle(
        center(i),
        active ? 10 : 6,
        Paint()
          ..color = active ? ink : ink.withValues(alpha: 0.45)
          ..style = active ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) => true;
}

class _FaceScan extends StatelessWidget {
  const _FaceScan({required this.ink, required this.scanning});

  final Color ink;
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.face_retouching_natural,
          size: 72,
          color: scanning ? kAccent : ink,
        ),
        const SizedBox(height: 8),
        Text(
          scanning ? 'Scanning…' : 'Hold still',
          style: TextStyle(color: ink.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}

class _Fingerprint extends StatelessWidget {
  const _Fingerprint({required this.ink, required this.onUnlock});

  final Color ink;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onLongPress: onUnlock,
          child: Icon(Icons.fingerprint, size: 72, color: ink),
        ),
        const SizedBox(height: 8),
        Text(
          'Press & hold',
          style: TextStyle(color: ink.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}
