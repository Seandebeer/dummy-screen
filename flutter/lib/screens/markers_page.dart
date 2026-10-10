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
const _phoneCell = 62.0;

/// Phone-sized squares. Wider stages add squares instead of stretching them.
(int, int, double) markerExtent(double width, double height) {
  const gap = 4.0;
  var cols = ((width + gap) / (_phoneCell + gap)).floor() - 1;
  var rows = ((height + gap) / (_phoneCell + gap)).floor() - 1;
  if (cols < _cols) cols = _cols;
  if (rows < _rows) rows = _rows;
  final fitW = (width - gap * cols) / (cols + 1);
  final fitH = (height - gap * rows) / (rows + 1);
  final cell = fitW < _phoneCell || fitH < _phoneCell
      ? (fitW < fitH ? fitW : fitH)
      : _phoneCell;
  return (cols, rows, cell);
}

class MarkersPage extends StatefulWidget {
  const MarkersPage({super.key, this.onExit});

  /// Closes this stage when it is open on top of another screen.
  final VoidCallback? onExit;

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
  final Map<String, List<StageMark>> _markLayouts = {};
  String? _dragId;
  String? _pending;
  Timer? _hold;
  String? _lastTap;
  int _lastTapAt = 0;
  String? _snapping;

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
    final layouts = raw['markLayouts'];
    if (layouts is Map) {
      layouts.forEach((key, value) {
        if (value is! List) return;
        _markLayouts[key.toString()] = [
          for (final item in value)
            if (item is Map) StageMark.fromJson(Map<String, dynamic>.from(item)),
        ];
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
      'markLayouts': {
        for (final entry in _markLayouts.entries)
          entry.key: [for (final mark in entry.value) mark.toJson()],
      },
    });
  }

  List<StageMark> _layoutFor(String style) =>
      _markLayouts[style] ?? defaultLayoutFor(style);

  void _setLayout(List<StageMark> next) {
    setState(() => _markLayouts[_markStyle] = next);
    _persist();
  }

  void _snapStyle(String style, Size size) {
    if (!mounted || _locked || style != _markStyle) return;
    if (_markLayouts.containsKey(style) || !isPointStyle(style)) return;
    if (size.width <= 0 || size.height <= 0) return;
    final lines = markerSnapLines(size.width, size.height);
    setState(() {
      _markLayouts[style] = [
        for (final mark in defaultLayoutFor(style))
          mark.copyWith(
            x: snapMarkerPercent(mark.x / 100 * size.width, size.width, lines.xs),
            y: snapMarkerPercent(mark.y / 100 * size.height, size.height, lines.ys),
          ),
      ];
    });
    _persist();
  }

  void _beginMark(String id) {
    _pending = id;
    _hold?.cancel();
    _hold = Timer(const Duration(milliseconds: 250), () {
      _pending = null;
      if (mounted) setState(() => _dragId = id);
    });
  }

  void _moveMark(String id, Offset local, Size size) {
    final lines = markerSnapLines(size.width, size.height);
    _setLayout([
      for (final mark in _layoutFor(_markStyle))
        if (mark.id == id)
          mark.copyWith(
            x: snapMarkerPercent(local.dx, size.width, lines.xs),
            y: snapMarkerPercent(local.dy, size.height, lines.ys),
          )
        else
          mark,
    ]);
  }

  void _releaseMark() {
    _hold?.cancel();
    if (_dragId != null) {
      setState(() => _dragId = null);
      return;
    }
    final tapped = _pending;
    _pending = null;
    if (tapped == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastTap == tapped && now - _lastTapAt < 350) {
      _lastTap = null;
      _setLayout([
        for (final mark in _layoutFor(_markStyle))
          if (mark.id != tapped) mark,
      ]);
    } else {
      _lastTap = tapped;
      _lastTapAt = now;
      _setLayout([
        for (final mark in _layoutFor(_markStyle))
          if (mark.id == tapped) mark.copyWith(rot: (mark.rot + 45) % 360) else mark,
      ]);
    }
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

  void _swapCells(String from, String to) {
    if (from == to) return;
    setState(() {
      final a = _assignments[from];
      final b = _assignments[to];
      if (b == null) {
        _assignments.remove(from);
      } else {
        _assignments[from] = List<int>.of(b);
      }
      if (a == null) {
        _assignments.remove(to);
      } else {
        _assignments[to] = List<int>.of(a);
      }
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
    _hold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgColor == null
        ? const Color(0xFF0B0B0F)
        : parseHex(_bgColor, const Color(0xFF0B0B0F));
    final light = _bgColor != null && lightHex(bg);
    final line = light ? Colors.black87 : Colors.white70;
    final ink = light ? Colors.black87 : Colors.white;
    final chrome = light ? const Color(0xF21A1A1E) : const Color(0xF2F4F4F8);
    final chromeInk = light ? Colors.white : const Color(0xFF1C1C1E);
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
                        final grid = markerExtent(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        return _Grid(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          cols: grid.$1,
                          rows: grid.$2,
                          cell: grid.$3,
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
                          onCellSwap: _locked ? null : _swapCells,
                          onBarMove: _locked
                              ? null
                              : (which, dx, dy, size) {
                                  setState(() {
                                    final extent = markerExtent(size.width, size.height);
                                    if (which == 'h') {
                                      final band = size.height / (extent.$2 + 1);
                                      _barRow = (dy / band).floor().clamp(0, extent.$2);
                                    } else {
                                      final band = size.width / (extent.$1 + 1);
                                      _barCol = (dx / band).floor().clamp(1, extent.$1);
                                      final track = (dy / size.height) * (extent.$2 + 1);
                                      _vStart = (track - 2.5).round().clamp(1, extent.$2 - 4);
                                    }
                                  });
                                  _persist();
                                },
                        );
                      },
                    ),
                  ),
                ),
                if (_markStyle != 'none' && isPointStyle(_markStyle))
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);
                        if (!_markLayouts.containsKey(_markStyle) && _snapping != _markStyle) {
                          _snapping = _markStyle;
                          final style = _markStyle;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _snapping = null;
                            _snapStyle(style, size);
                          });
                        }
                        final layout = _layoutFor(_markStyle);
                        final inkMark = _markColor == null
                            ? (light ? Colors.black : Colors.white)
                            : parseHex(_markColor, Colors.white);
                        return Listener(
                          onPointerMove: (event) {
                            final id = _dragId;
                            if (id == null) return;
                            final box = context.findRenderObject() as RenderBox?;
                            if (box == null || !box.hasSize) return;
                            _moveMark(id, box.globalToLocal(event.position), size);
                          },
                          onPointerUp: (_) => _releaseMark(),
                          onPointerCancel: (_) => _releaseMark(),
                          child: Stack(
                            children: [
                              for (final mark in layout)
                                Positioned(
                                  left: mark.x / 100 * size.width - 22,
                                  top: mark.y / 100 * size.height - 22,
                                  child: Listener(
                                    behavior: HitTestBehavior.opaque,
                                    onPointerDown: _locked ? null : (_) => _beginMark(mark.id),
                                    child: SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: Center(
                                        child: MarkGlyph(
                                          kind: mark.kind,
                                          color: inkMark,
                                          scale: _markSize,
                                          thickness: _markThick,
                                          rotation: mark.rot,
                                          x: mark.x,
                                          y: mark.y,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                if (_dragId != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _MarkerSnapPainter(
                          color: _markColor == null
                              ? (light ? Colors.black : Colors.white)
                              : parseHex(_markColor, Colors.white),
                        ),
                      ),
                    ),
                  ),
                if (!_locked)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: TextButton.icon(
                      onPressed: () {
                        final exit = widget.onExit;
                        if (exit != null) {
                          exit();
                        } else {
                          StoreScope.of(context).openTab(0);
                        }
                      },
                      icon: Icon(Icons.arrow_back, size: 16, color: chromeInk),
                      label: Text('Back', style: TextStyle(color: chromeInk, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(backgroundColor: chrome),
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
                          color: light ? Colors.black87 : Colors.white70,
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
                      icon: Icon(Icons.fullscreen, size: 18, color: chromeInk),
                      label: Text('Fullscreen', style: TextStyle(color: chromeInk, fontSize: 10, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(backgroundColor: chrome),
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
                        _tool(Icons.palette_outlined, () => _pickColor(), fill: chrome, ink: chromeInk),
                        _tool(Icons.category_outlined, () => _pickMarks(), fill: chrome, ink: chromeInk),
                        _tool(Icons.my_location, () => _pickMarks(kinds: true), fill: chrome, ink: chromeInk),
                        _tool(Icons.auto_awesome, () {
                          setState(() => _glow = !_glow);
                          _persist();
                        }, on: _glow, fill: chrome, ink: chromeInk),
                        _tool(Icons.save_outlined, _save, fill: chrome, ink: chromeInk),
                        _markedTool('×', () {
                          setState(() {
                            _markLayouts[_markStyle] = defaultLayoutFor(_markStyle);
                            _markSize = 1.1;
                            _markThick = 0.6;
                          });
                          _persist();
                        }, fill: chrome, ink: chromeInk),
                        _markedTool('1', () {
                          setState(() {
                            _assignments.clear();
                            _barNumber = [];
                            _barVNumber = [];
                          });
                          _persist();
                        }, fill: chrome, ink: chromeInk),
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

  Widget _markedTool(String mark, VoidCallback onTap, {required Color fill, required Color ink}) {
    final wide = MediaQuery.sizeOf(context).width >= 768;
    return IconButton(
      tooltip: mark == '1' ? 'Reset numbers' : 'Reset tracking marks',
      onPressed: onTap,
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.restart_alt, size: wide ? 28 : 16, color: ink),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Text(
              mark,
              style: TextStyle(
                color: Colors.white,
                fontSize: wide ? 11 : 9,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
      style: IconButton.styleFrom(
        backgroundColor: fill,
        fixedSize: Size(wide ? 76 : 40, wide ? 64 : 36),
      ),
    );
  }

  Widget _tool(IconData icon, VoidCallback onTap, {bool on = false, required Color fill, required Color ink}) {
    final wide = MediaQuery.sizeOf(context).width >= 768;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: wide ? 28 : 16, color: on ? kAccent : ink),
      style: IconButton.styleFrom(
        backgroundColor: fill,
        fixedSize: Size(wide ? 76 : 40, wide ? 64 : 36),
        iconSize: wide ? 32 : 18,
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

  Future<void> _pickMarks({bool kinds = false}) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          if (!kinds)
            ListTile(
              title: const Text('NONE', style: TextStyle(color: Colors.white, fontSize: 12)),
              onTap: () {
                setState(() => _markStyle = 'none');
                _persist();
                Navigator.pop(context);
              },
            ),
          for (final style in (kinds ? kMarkerKinds : kTrackingStyles))
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
          'markSize': _markSize,
          'markThick': _markThick,
          'glow': _glow,
          'markLayouts': {
            for (final entry in _markLayouts.entries)
              entry.key: [for (final mark in entry.value) mark.toJson()],
          },
        },
      ),
    );
  }
}

class _MarkerSnapPainter extends CustomPainter {
  const _MarkerSnapPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final lines = markerSnapLines(size.width, size.height);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (final x in lines.xs) {
      _dashed(canvas, Offset(x, 0), Offset(x, size.height), paint);
    }
    for (final y in lines.ys) {
      _dashed(canvas, Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.drawCircle(size.center(Offset.zero), 3, Paint()..color = color.withValues(alpha: 0.9));
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0;
    final delta = b - a;
    final length = delta.distance;
    if (length == 0) return;
    final step = delta / length;
    var drawn = 0.0;
    while (drawn < length) {
      final start = a + step * drawn;
      final end = a + step * (drawn + dash).clamp(0, length);
      canvas.drawLine(start, end, paint);
      drawn += dash * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _MarkerSnapPainter oldDelegate) => oldDelegate.color != color;
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.width,
    required this.height,
    required this.cols,
    required this.rows,
    required this.cell,
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
    required this.onCellSwap,
  });

  final double width;
  final double height;
  final int cols;
  final int rows;
  final double cell;
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
  final void Function(String from, String to)? onCellSwap;

  @override
  Widget build(BuildContext context) {
    const gap = 4.0;
    final cellW = cell;
    final cellH = cell;
    final children = <Widget>[];

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final col = c + (c >= barCol ? 1 : 0);
        final row = r + (r >= barRow ? 1 : 0);
        final key = '${r * cols + c}';
        children.add(
          _cell(
            left: col * (cellW + gap),
            top: row * (cellH + gap),
            w: cellW,
            h: cellH,
            label: (numbers[key] ?? const []).join(' '),
            onTap: () => onTap?.call(key),
            onHold: () => onHold?.call(key),
            onRearrange: onCellSwap == null
                ? null
                : (delta) => _dropCell(key, left: col * (cellW + gap), top: row * (cellH + gap), delta: delta),
          ),
        );
      }
    }
    for (var t = 1; t <= rows + 1; t++) {
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
          onRearrange: onCellSwap == null
              ? null
              : (delta) => _dropCell(
                  key,
                  left: barCol * (cellW + gap),
                  top: (t - 1) * (cellH + gap),
                  delta: delta,
                ),
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

  void _dropCell(
    String from, {
    required double left,
    required double top,
    required Offset delta,
  }) {
    final target = _keyAt(left + cell / 2 + delta.dx, top + cell / 2 + delta.dy);
    if (target == null || target == from) return;
    onCellSwap?.call(from, target);
  }

  String? _keyAt(double x, double y) {
    const gap = 4.0;
    final pitch = cell + gap;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final col = c + (c >= barCol ? 1 : 0);
        final row = r + (r >= barRow ? 1 : 0);
        final left = col * pitch;
        final top = row * pitch;
        if (x >= left && x < left + cell && y >= top && y < top + cell) {
          return '${r * cols + c}';
        }
      }
    }
    for (var t = 1; t <= rows + 1; t++) {
      if (t >= vStart && t <= vStart + 5) continue;
      if (t == barRow + 1) continue;
      final left = barCol * pitch;
      final top = (t - 1) * pitch;
      if (x >= left && x < left + cell && y >= top && y < top + cell) {
        return 'vc-$t';
      }
    }
    return null;
  }

  Widget _cell({
    required double left,
    required double top,
    required double w,
    required double h,
    required String label,
    required VoidCallback onTap,
    required VoidCallback onHold,
    required void Function(Offset delta)? onRearrange,
  }) {
    final empty = label.isEmpty;
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: _MarkerButton(
        locked: locked,
        empty: empty,
        line: line,
        ink: ink,
        label: label,
        onTap: onTap,
        onHold: onHold,
        onRearrange: onRearrange,
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
      child: _SwipeButton(
        which: which,
        locked: locked,
        line: line,
        ink: ink,
        label: label,
        horizontal: which == 'h',
        onTap: () => onBarTap?.call(which),
        onHold: () => onBarHold?.call(which),
        onMove: locked
            ? null
            : (dx, dy) => onBarMove?.call(
                which,
                dx + left,
                dy + top,
                Size(width, height),
              ),
      ),
    );
  }
}

class _MarkerButton extends StatefulWidget {
  const _MarkerButton({
    required this.locked,
    required this.empty,
    required this.line,
    required this.ink,
    required this.label,
    required this.onTap,
    required this.onHold,
    required this.onRearrange,
  });

  final bool locked;
  final bool empty;
  final Color line;
  final Color ink;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onHold;
  final void Function(Offset delta)? onRearrange;

  @override
  State<_MarkerButton> createState() => _MarkerButtonState();
}

class _MarkerButtonState extends State<_MarkerButton> {
  bool _glow = false;
  Offset _pan = Offset.zero;
  bool _moved = false;

  @override
  Widget build(BuildContext context) {
    final box = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.locked && widget.empty ? Colors.transparent : widget.line,
          width: 1.6,
        ),
        boxShadow: _glow
            ? const [
                BoxShadow(color: Color(0x99FFFFFF), blurRadius: 16, spreadRadius: 1),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.ink,
            fontSize: widget.label.contains(' ') ? 16 : 22,
          ),
        ),
      ),
    );
    if (widget.locked) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _glow = true),
        onTapUp: (_) => setState(() => _glow = false),
        onTapCancel: () => setState(() => _glow = false),
        child: box,
      );
    }
    return GestureDetector(
      onTap: () {
        if (_moved) {
          _moved = false;
          return;
        }
        widget.onTap();
      },
      onLongPress: widget.onHold,
      onPanStart: widget.onRearrange == null
          ? null
          : (_) {
              setState(() {
                _pan = Offset.zero;
                _moved = false;
              });
            },
      onPanUpdate: widget.onRearrange == null
          ? null
          : (details) {
              setState(() {
                _pan += details.delta;
                if (_pan.distance > 10) _moved = true;
              });
            },
      onPanEnd: widget.onRearrange == null
          ? null
          : (_) {
              if (_moved) widget.onRearrange!(_pan);
              setState(() {
                _pan = Offset.zero;
                _moved = false;
              });
            },
      child: Transform.translate(offset: _moved ? _pan : Offset.zero, child: box),
    );
  }
}

class _SwipeButton extends StatefulWidget {
  const _SwipeButton({
    required this.which,
    required this.locked,
    required this.line,
    required this.ink,
    required this.label,
    required this.horizontal,
    required this.onTap,
    required this.onHold,
    required this.onMove,
  });

  final String which;
  final bool locked;
  final Color line;
  final Color ink;
  final String label;
  final bool horizontal;
  final VoidCallback onTap;
  final VoidCallback onHold;
  final void Function(double dx, double dy)? onMove;

  @override
  State<_SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<_SwipeButton> {
  double? _along;
  bool _fromStart = true;

  @override
  Widget build(BuildContext context) {
    final along = _along;
    return GestureDetector(
      onTap: widget.locked ? null : widget.onTap,
      onLongPress: widget.locked ? null : widget.onHold,
      onPanStart: widget.locked
          ? (details) {
              final box = context.size ?? Size.zero;
              final local = details.localPosition;
              final fromStart = widget.horizontal
                  ? local.dx < box.width / 2
                  : local.dy < box.height / 2;
              setState(() {
                _fromStart = fromStart;
                _along = fromStart ? 0 : 1;
              });
            }
          : null,
      onPanUpdate: (details) {
        if (widget.locked) {
          final box = context.size ?? const Size(1, 1);
          final local = details.localPosition;
          final span = widget.horizontal ? box.width : box.height;
          final raw = widget.horizontal ? local.dx : local.dy;
          setState(() => _along = (raw / (span == 0 ? 1 : span)).clamp(0.0, 1.0));
          return;
        }
        widget.onMove?.call(details.localPosition.dx, details.localPosition.dy);
      },
      onPanEnd: widget.locked ? (_) => setState(() => _along = null) : null,
      onPanCancel: widget.locked ? () => setState(() => _along = null) : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.label.isEmpty && widget.locked ? Colors.transparent : widget.line,
          ),
          gradient: along == null
              ? null
              : LinearGradient(
                  begin: widget.horizontal
                      ? (_fromStart ? Alignment.centerLeft : Alignment.centerRight)
                      : (_fromStart ? Alignment.topCenter : Alignment.bottomCenter),
                  end: widget.horizontal
                      ? (_fromStart ? Alignment.centerRight : Alignment.centerLeft)
                      : (_fromStart ? Alignment.bottomCenter : Alignment.topCenter),
                  colors: const [
                    Color(0xAAFFFFFF),
                    Color(0x22FFFFFF),
                    Color(0x00FFFFFF),
                  ],
                  stops: [
                    0,
                    along,
                    (along + 0.12).clamp(0.0, 1.0),
                  ],
                ),
        ),
        child: Center(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(color: widget.ink, fontSize: 22),
          ),
        ),
      ),
    );
  }
}
