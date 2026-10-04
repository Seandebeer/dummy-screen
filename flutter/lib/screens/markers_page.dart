import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../models.dart';
import '../theme.dart';
import '../vfx/catalog.dart';
import '../vfx/mark_glyph.dart';
import '../widgets/prompt.dart';
import '../widgets/three_finger.dart';

const _cols = 5;
const _rows = 8;

class MarkersPage extends StatefulWidget {
  const MarkersPage({super.key});

  @override
  State<MarkersPage> createState() => _MarkersPageState();
}

class _MarkersPageState extends State<MarkersPage> {
  final Map<String, List<int>> _assignments = {};
  int _barRow = _rows - 1;
  int _barCol = _cols;
  int _vStart = 1;
  List<int> _barNumber = [];
  List<int> _barVNumber = [];
  String? _bgColor;
  String _markStyle = 'none';
  String? _markColor;
  double _markSize = 1.1;
  double _markThick = 0.6;
  bool _glow = true;
  bool _locked = false;
  bool _hint = false;
  Timer? _hintTimer;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final raw = StoreScope.of(context).markerConfig;
    if (raw.isEmpty) return;
    _barRow = (raw['barRow'] as num?)?.toInt() ?? _barRow;
    _barCol = (raw['barCol'] as num?)?.toInt() ?? _barCol;
    _vStart = (raw['barVRow'] as num?)?.toInt() ?? _vStart;
    _bgColor = raw['bgColor'] as String?;
    _markStyle = raw['markStyle'] as String? ?? 'none';
    _markColor = raw['markColor'] as String?;
    _markSize = (raw['markSize'] as num?)?.toDouble() ?? 1.1;
    _markThick = (raw['markThick'] as num?)?.toDouble() ?? 0.6;
    _glow = raw['glow'] as bool? ?? true;
    _barNumber = _ints(raw['barNumber']);
    _barVNumber = _ints(raw['barVNumber']);
    final assigned = raw['assignments'];
    if (assigned is Map) {
      assigned.forEach((key, value) {
        _assignments[key.toString()] = _ints(value);
      });
    }
  }

  List<int> _ints(dynamic value) {
    if (value is List) {
      return [for (final item in value) if (item is num) item.toInt()];
    }
    if (value is num) return [value.toInt()];
    return [];
  }

  void _persist() {
    StoreScope.of(context).setMarkerConfig({
      'assignments': _assignments,
      'barRow': _barRow,
      'barCol': _barCol,
      'barVRow': _vStart,
      'barNumber': _barNumber,
      'barVNumber': _barVNumber,
      'bgColor': _bgColor,
      'markStyle': _markStyle,
      'markColor': _markColor,
      'markSize': _markSize,
      'markThick': _markThick,
      'glow': _glow,
    });
  }

  int _next() {
    final used = [
      for (final list in _assignments.values) ...list,
      ..._barNumber,
      ..._barVNumber,
    ];
    if (used.isEmpty) return 1;
    return used.reduce(math.max) + 1;
  }

  void _renumber() {
    final entries = <(String, int)>[];
    _assignments.forEach((key, list) {
      for (final n in list) {
        entries.add((key, n));
      }
    });
    for (final n in _barNumber) {
      entries.add(('bar', n));
    }
    for (final n in _barVNumber) {
      entries.add(('vbar', n));
    }
    entries.sort((a, b) => a.$2.compareTo(b.$2));
    _assignments.clear();
    _barNumber = [];
    _barVNumber = [];
    for (var i = 0; i < entries.length; i++) {
      final key = entries[i].$1;
      if (key == 'bar') {
        _barNumber.add(i + 1);
      } else if (key == 'vbar') {
        _barVNumber.add(i + 1);
      } else {
        _assignments.putIfAbsent(key, () => []).add(i + 1);
      }
    }
  }

  void _add(String key) {
    setState(() {
      _assignments.putIfAbsent(key, () => []).add(_next());
    });
    _persist();
  }

  void _clear(String key) {
    if ((_assignments[key] ?? const []).isEmpty) return;
    setState(() {
      _assignments.remove(key);
      _renumber();
    });
    _persist();
  }

  void _lock() {
    setState(() {
      _locked = true;
      _hint = true;
    });
    StoreScope.of(context).setFilming(true);
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _hint = false);
    });
  }

  void _unlock() {
    setState(() {
      _locked = false;
      _hint = false;
    });
    StoreScope.of(context).setFilming(false);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgColor == null
        ? const Color(0xFF0B0B0F)
        : parseHex(_bgColor, const Color(0xFF0B0B0F));
    final light = _bgColor != null && lightHex(bg);
    final line = light ? Colors.black26 : Colors.white24;
    final ink = light ? Colors.black87 : Colors.white;
    return ThreeFingerToggle(
      onToggle: () => _locked ? _unlock() : _lock(),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyL): () =>
              _locked ? _unlock() : _lock(),
        },
        child: Focus(
          autofocus: true,
          child: ColoredBox(
            color: bg,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _Grid(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          barRow: _barRow,
                          barCol: _barCol,
                          vStart: _vStart,
                          line: line,
                          ink: ink,
                          locked: _locked,
                          numbers: _assignments,
                          barNumber: _barNumber,
                          barVNumber: _barVNumber,
                          onTap: _locked ? null : _add,
                          onHold: _locked ? null : _clear,
                          onBarTap: _locked
                              ? null
                              : (which) {
                                  setState(() {
                                    if (which == 'h') {
                                      _barNumber.add(_next());
                                    } else {
                                      _barVNumber.add(_next());
                                    }
                                  });
                                  _persist();
                                },
                          onBarHold: _locked
                              ? null
                              : (which) {
                                  setState(() {
                                    if (which == 'h') {
                                      _barNumber = [];
                                    } else {
                                      _barVNumber = [];
                                    }
                                    _renumber();
                                  });
                                  _persist();
                                },
                          onBarMove: _locked
                              ? null
                              : (which, dx, dy, size) {
                                  setState(() {
                                    if (which == 'h') {
                                      final band = size.height / (_rows + 1);
                                      _barRow = (dy / band).floor().clamp(0, _rows);
                                    } else {
                                      final band = size.width / (_cols + 1);
                                      _barCol = (dx / band).floor().clamp(1, _cols);
                                      final track = (dy / size.height) * (_rows + 1);
                                      _vStart = (track - 2.5).round().clamp(1, _rows - 4);
                                    }
                                  });
                                  _persist();
                                },
                        );
                      },
                    ),
                  ),
                ),
                if (_markStyle != 'none')
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Stack(
                        children: [
                          for (final mark in defaultLayoutFor(_markStyle))
                            Align(
                              alignment: Alignment(
                                (mark.x / 50) - 1,
                                (mark.y / 50) - 1,
                              ),
                              child: MarkGlyph(
                                kind: mark.kind,
                                color: _markColor == null
                                    ? (light ? Colors.black : Colors.white)
                                    : parseHex(_markColor, Colors.white),
                                scale: _markSize,
                                thickness: _markThick,
                                x: mark.x,
                                y: mark.y,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (!_locked)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: TextButton.icon(
                      onPressed: () => StoreScope.of(context).openTab(0),
                      icon: Icon(Icons.arrow_back, size: 16, color: light ? Colors.black54 : Colors.white54),
                      label: Text(
                        'Back',
                        style: TextStyle(color: light ? Colors.black54 : Colors.white54),
                      ),
                    ),
                  ),
                if (!_locked)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Tap to add numbers · hold to clear · drag to rearrange',
                        style: TextStyle(
                          color: light ? Colors.black38 : Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                if (!_locked)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: TextButton.icon(
                      onPressed: _lock,
                      icon: const Icon(Icons.lock, size: 12, color: Colors.white70),
                      label: const Text('Lock', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      style: TextButton.styleFrom(backgroundColor: const Color(0xFF1C1C1E)),
                    ),
                  ),
                if (!_locked)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 12,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      children: [
                        _tool(Icons.palette_outlined, () => _pickColor()),
                        _tool(Icons.category_outlined, () => _pickMarks()),
                        _tool(Icons.auto_awesome, () {
                          setState(() => _glow = !_glow);
                          _persist();
                        }, on: _glow),
                        _tool(Icons.save_outlined, _save),
                        _tool(Icons.restart_alt, () {
                          setState(() {
                            _assignments.clear();
                            _barNumber = [];
                            _barVNumber = [];
                          });
                          _persist();
                        }),
                      ],
                    ),
                  ),
                if (_locked && _hint)
                  const Positioned(
                    top: 36,
                    left: 0,
                    right: 0,
                    child: Text(
                      'Three-finger tap or L unlocks',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tool(IconData icon, VoidCallback onTap, {bool on = false}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: on ? kAccent : Colors.white70),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x801C1C1E),
        minimumSize: const Size(36, 32),
      ),
    );
  }

  Future<void> _pickColor() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xE6000000),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          for (final color in kVfxPalette)
            ListTile(
              leading: CircleAvatar(backgroundColor: color.hex, radius: 8),
              title: Text(color.label, style: const TextStyle(color: Colors.white)),
              trailing: _bgColor == hexOf(color.hex)
                  ? const Icon(Icons.check, color: kAccent)
                  : null,
              onTap: () {
                setState(() => _bgColor = hexOf(color.hex));
                _persist();
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _pickMarks() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xE6000000),
      builder: (context) => ListView(
        children: [
          ListTile(
            title: const Text('NONE', style: TextStyle(color: Colors.white, fontSize: 12)),
            onTap: () {
              setState(() => _markStyle = 'none');
              _persist();
              Navigator.pop(context);
            },
          ),
          for (final style in kMarkerKinds)
            ListTile(
              title: Text(style.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
              trailing: _markStyle == style.id ? const Icon(Icons.check, color: kAccent) : null,
              onTap: () {
                setState(() => _markStyle = style.id);
                _persist();
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final store = StoreScope.of(context);
    final name = await promptText(
      context,
      title: 'Save marker layout',
      initial: 'Markers',
      confirm: 'Save',
    );
    if (name == null || name.trim().isEmpty) return;
    store.upsertSaved(
      SavedLayout(
        id: 's-${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        skin: 'modern',
        clockOffsetMinutes: 0,
        notes: '',
        vfxColor: 'green',
        vfxMarks: const [],
        uiMarkers: const [],
        kind: 'markers',
        deviceId: store.boundDeviceId ?? '',
        payload: {
          'assignments': _assignments,
          'barRow': _barRow,
          'barCol': _barCol,
          'barVRow': _vStart,
          'barNumber': _barNumber,
          'barVNumber': _barVNumber,
          'bgColor': _bgColor,
          'markStyle': _markStyle,
          'markColor': _markColor,
          'glow': _glow,
        },
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.width,
    required this.height,
    required this.barRow,
    required this.barCol,
    required this.vStart,
    required this.line,
    required this.ink,
    required this.locked,
    required this.numbers,
    required this.barNumber,
    required this.barVNumber,
    required this.onTap,
    required this.onHold,
    required this.onBarTap,
    required this.onBarHold,
    required this.onBarMove,
  });

  final double width;
  final double height;
  final int barRow;
  final int barCol;
  final int vStart;
  final Color line;
  final Color ink;
  final bool locked;
  final Map<String, List<int>> numbers;
  final List<int> barNumber;
  final List<int> barVNumber;
  final void Function(String key)? onTap;
  final void Function(String key)? onHold;
  final void Function(String which)? onBarTap;
  final void Function(String which)? onBarHold;
  final void Function(String which, double dx, double dy, Size size)? onBarMove;

  @override
  Widget build(BuildContext context) {
    const gap = 4.0;
    final colCount = _cols + 1;
    final rowCount = _rows + 1;
    final cellW = (width - gap * (colCount - 1)) / colCount;
    final cellH = (height - gap * (rowCount - 1)) / rowCount;
    final children = <Widget>[];

    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final col = c + (c >= barCol ? 1 : 0);
        final row = r + (r >= barRow ? 1 : 0);
        final key = '${r * _cols + c}';
        children.add(
          _cell(
            left: col * (cellW + gap),
            top: row * (cellH + gap),
            w: cellW,
            h: cellH,
            label: (numbers[key] ?? const []).join(' '),
            onTap: () => onTap?.call(key),
            onHold: () => onHold?.call(key),
          ),
        );
      }
    }
    for (var t = 1; t <= _rows + 1; t++) {
      if (t >= vStart && t <= vStart + 5) continue;
      if (t == barRow + 1) continue;
      final key = 'vc-$t';
      children.add(
        _cell(
          left: barCol * (cellW + gap),
          top: (t - 1) * (cellH + gap),
          w: cellW,
          h: cellH,
          label: (numbers[key] ?? const []).join(' '),
          onTap: () => onTap?.call(key),
          onHold: () => onHold?.call(key),
        ),
      );
    }
    children.add(
      _bar(
        which: 'h',
        left: 0,
        top: barRow * (cellH + gap),
        w: width,
        h: cellH,
        label: barNumber.join(' '),
      ),
    );
    children.add(
      _bar(
        which: 'v',
        left: barCol * (cellW + gap),
        top: (vStart - 1) * (cellH + gap),
        w: cellW,
        h: cellH * 6 + gap * 5,
        label: barVNumber.join('\n'),
      ),
    );
    return Stack(children: children);
  }

  Widget _cell({
    required double left,
    required double top,
    required double w,
    required double h,
    required String label,
    required VoidCallback onTap,
    required VoidCallback onHold,
  }) {
    final empty = label.isEmpty;
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: GestureDetector(
        onTap: locked ? null : onTap,
        onLongPress: locked ? null : onHold,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: locked && empty ? Colors.transparent : line,
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: ink, fontSize: label.contains(' ') ? 11 : 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar({
    required String which,
    required double left,
    required double top,
    required double w,
    required double h,
    required String label,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: GestureDetector(
        onTap: locked ? null : () => onBarTap?.call(which),
        onLongPress: locked ? null : () => onBarHold?.call(which),
        onPanUpdate: locked
            ? null
            : (details) => onBarMove?.call(
                which,
                details.localPosition.dx + left,
                details.localPosition.dy + top,
                Size(width, height),
              ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: label.isEmpty && locked ? Colors.transparent : line),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: ink, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
