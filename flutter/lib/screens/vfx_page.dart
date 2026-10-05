import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../image_file.dart';
import '../models.dart';
import '../theme.dart';
import '../vfx/catalog.dart';
import '../vfx/mark_glyph.dart';
import '../widgets/prompt.dart';
import '../widgets/three_finger.dart';

class VfxPage extends StatefulWidget {
  const VfxPage({super.key});

  @override
  State<VfxPage> createState() => _VfxPageState();
}

class _VfxPageState extends State<VfxPage> {
  String _colorId = 'green';
  String _marksId = 'cross';
  double _scale = 1;
  double _thickness = 1;
  double _opacity = 1;
  String? _markColor;
  String? _bgColor;
  String? _bgImage;
  Map<String, dynamic> _overlay = {
    'opacity': 50,
    'hidden': false,
    'scale': 1.0,
    'rot': 0,
    'x': 0.0,
    'y': 0.0,
    'flip': false,
    'flop': false,
  };
  String _addKind = 'cross';
  bool _locked = false;
  bool _hint = false;
  String? _dragId;
  Timer? _hold;
  String? _pending;
  String? _lastTap;
  int _lastTapAt = 0;
  final Map<String, List<StageMark>> _layouts = {};
  Timer? _hintTimer;

  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final config = StoreScope.of(context).screenConfig;
    _colorId = config['colorId'] as String? ?? StoreScope.of(context).vfxColor;
    _marksId = config['marksId'] as String? ?? 'cross';
    _scale = (config['scale'] as num?)?.toDouble() ?? 1;
    _thickness = (config['thickness'] as num?)?.toDouble() ?? 1;
    _opacity = (config['opacity'] as num?)?.toDouble() ?? 1;
    _markColor = config['markColor'] as String?;
    _bgColor = config['bgColor'] as String?;
    _bgImage = config['bgImage'] as String?;
    final overlay = config['overlay'];
    if (overlay is Map) _overlay = {..._overlay, ...jsonMap(overlay)};
    final raw = config['layouts'];
    if (raw is Map) {
      raw.forEach((key, value) {
        _layouts[key.toString()] = [
          for (final item in jsonList(value))
            if (item is Map) StageMark.fromJson(jsonMap(item)),
        ];
      });
    }
  }

  @override
  void dispose() {
    _hold?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  List<StageMark> get _layout =>
      _layouts[_marksId] ?? defaultLayoutFor(_marksId);

  void _persist() {
    StoreScope.of(context).setScreenConfig({
      'colorId': _colorId,
      'marksId': _marksId,
      'scale': _scale,
      'thickness': _thickness,
      'opacity': _opacity,
      'markColor': _markColor,
      'bgColor': _bgColor,
      'bgImage': _bgImage,
      'overlay': _overlay,
      'layouts': {
        for (final entry in _layouts.entries)
          entry.key: entry.value.map((mark) => mark.toJson()).toList(),
      },
    });
  }

  void _setLayout(List<StageMark> next) {
    setState(() => _layouts[_marksId] = next);
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
    _hintTimer?.cancel();
    setState(() {
      _locked = false;
      _hint = false;
    });
    StoreScope.of(context).setFilming(false);
  }

  bool get _light {
    if (_bgImage != null && _bgImage!.isNotEmpty) return false;
    if (_bgColor != null) return lightHex(parseHex(_bgColor, Colors.black));
    return _colorId == 'white' || _colorId == 'green' || _colorId == 'grey';
  }

  Color get _stage {
    if (_bgColor != null) return parseHex(_bgColor, vfxColorById(_colorId).hex);
    return vfxColorById(_colorId).hex;
  }

  Color get _ink {
    if (_markColor != null) return parseHex(_markColor, Colors.white);
    return _light ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final point = isPointStyle(_marksId);
    final image = imageProviderForPath(_bgImage ?? '');
    // The shell gives this page loose constraints. Expand so the stage
    // fills the screen even when every stack child is positioned.
    return SizedBox.expand(
      child: ThreeFingerToggle(
      onToggle: () => _locked ? _unlock() : _lock(),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyL): () =>
              _locked ? _unlock() : _lock(),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: _stage,
                  child: image == null
                      ? null
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            image: DecorationImage(image: image, fit: BoxFit.cover),
                          ),
                        ),
                ),
              ),
              _overlayLayer(),
              if (_marksId == 'checkerboard' || _marksId == 'dots')
                Positioned.fill(
                  child: PatternFill(
                    type: _marksId,
                    color: _ink,
                    scale: _scale,
                    thickness: _thickness,
                  ),
                ),
              if (point)
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTapUp: _locked
                                  ? null
                                  : (details) {
                                      final box = context.findRenderObject() as RenderBox?;
                                      if (box == null || !box.hasSize) return;
                                      final local = box.globalToLocal(details.globalPosition);
                                      final x = snapX(local.dx / box.size.width * 100);
                                      final y = snapY(local.dy / box.size.height * 100);
                                      _setLayout([
                                        ..._layout,
                                        StageMark(
                                          id: 'm-${DateTime.now().microsecondsSinceEpoch}',
                                          kind: _addKind,
                                          x: x,
                                          y: y,
                                        ),
                                      ]);
                                    },
                            ),
                          ),
                          for (final mark in _layout)
                            Positioned(
                              left: mark.x / 100 * constraints.maxWidth - 22,
                              top: mark.y / 100 * constraints.maxHeight - 22,
                              child: GestureDetector(
                                onTapDown: _locked
                                    ? null
                                    : (_) {
                                        _pending = mark.id;
                                        _hold?.cancel();
                                        _hold = Timer(
                                          const Duration(milliseconds: 250),
                                          () {
                                            _pending = null;
                                            setState(() => _dragId = mark.id);
                                          },
                                        );
                                      },
                                onTapUp: _locked
                                    ? null
                                    : (_) {
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
                                            for (final item in _layout)
                                              if (item.id != tapped) item,
                                          ]);
                                        } else {
                                          _lastTap = tapped;
                                          _lastTapAt = now;
                                          _setLayout([
                                            for (final item in _layout)
                                              if (item.id == tapped)
                                                item.copyWith(rot: (item.rot + 45) % 360)
                                              else
                                                item,
                                          ]);
                                        }
                                      },
                                onPanUpdate: _dragId == mark.id
                                    ? (details) {
                                        final box = context.findRenderObject() as RenderBox?;
                                        if (box == null || !box.hasSize) return;
                                        final local = box.globalToLocal(details.globalPosition);
                                        final parent = constraints;
                                        _setLayout([
                                          for (final item in _layout)
                                            if (item.id == mark.id)
                                              item.copyWith(
                                                x: snapX(local.dx / parent.maxWidth * 100),
                                                y: snapCells(local.dy / parent.maxHeight * 100, 8),
                                              )
                                            else
                                              item,
                                        ]);
                                      }
                                    : null,
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Center(
                                    child: Opacity(
                                      opacity: _opacity.clamp(0.05, 1),
                                      child: MarkGlyph(
                                        kind: mark.kind,
                                        color: _ink,
                                        scale: _scale,
                                        thickness: _thickness,
                                        rotation: mark.rot,
                                        x: mark.x,
                                        y: mark.y,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              if (_dragId != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SnapGridPainter(light: _light),
                    ),
                  ),
                ),
              if (!_locked)
                Positioned(
                  top: 8,
                  right: 8,
                  child: TextButton.icon(
                    onPressed: _lock,
                    icon: Icon(Icons.lock, size: 12, color: _light ? Colors.black54 : Colors.white54),
                    label: Text(
                      'Lock',
                      style: TextStyle(fontSize: 10, color: _light ? Colors.black54 : Colors.white54),
                    ),
                  ),
                ),
              if (_locked && _hint)
                const Positioned(
                  top: 28,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Three-finger tap or L unlocks',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              if (!_locked && point)
                const Positioned(
                  bottom: 144,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0x8C000000),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        border: Border.fromBorderSide(BorderSide(color: Color(0x26FFFFFF))),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Text(
                          'Tap empty space to add · Hold & drag to move · tap to rotate · double-tap to delete',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ),
              if (!_locked) _toolbar(point),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _toolbar(bool point) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 24,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x8C000000),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x26FFFFFF)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                children: [
                  IconButton(
                    tooltip: 'Exit stage',
                    onPressed: () => StoreScope.of(context).openTab(0),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Colour',
                    onPressed: _colourSheet,
                    icon: const Icon(Icons.palette_outlined, color: Colors.white, size: 18),
                  ),
                  _menu(
                    icon: Icons.category_outlined,
                    title: 'Tracking marks',
                    onSelected: (index) {
                      final style = kTrackingStyles[index];
                      setState(() {
                        _marksId = style.id;
                        if (style.point) _addKind = style.id;
                        _persist();
                      });
                    },
                    children: [
                      for (final style in kTrackingStyles)
                        _menuItem(style.name, selected: _marksId == style.id),
                    ],
                  ),
                  if (_marksId != 'none')
                    IconButton(
                      tooltip: 'Size & thickness',
                      onPressed: _sizeSheet,
                      icon: const Icon(Icons.tune, color: Colors.white, size: 18),
                    ),
                  IconButton(
                    tooltip: 'Image overlay',
                    onPressed: _overlaySheet,
                    icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 18),
                  ),
                  if ((_overlay['url'] as String?)?.isNotEmpty == true)
                    IconButton(
                      tooltip: _overlay['hidden'] == true ? 'Show image' : 'Hide image',
                      onPressed: () {
                        setState(() => _overlay['hidden'] = _overlay['hidden'] != true);
                        _persist();
                      },
                      icon: Icon(
                        _overlay['hidden'] == true ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  if (point) ...[
                    _menu(
                      icon: Icons.my_location,
                      title: 'Marker type',
                      onSelected: (index) => setState(() => _addKind = kMarkerKinds[index].id),
                      children: [
                        for (final kind in kMarkerKinds)
                          _menuItem(kind.name, selected: _addKind == kind.id),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Rotate all markers 45°',
                      onPressed: () => _setLayout([
                        for (final mark in _layout)
                          mark.copyWith(rot: (mark.rot + 45) % 360),
                      ]),
                      icon: const Icon(Icons.rotate_right, color: Colors.white, size: 18),
                    ),
                  ],
                  IconButton(
                    tooltip: 'Save screen',
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                  ),
                  if (_marksId != 'none')
                    IconButton(
                      tooltip: 'Reset',
                      onPressed: () {
                        setState(() {
                          _scale = 1;
                          _thickness = 1;
                          _layouts[_marksId] = defaultLayoutFor(_marksId);
                        });
                        _persist();
                      },
                      icon: const Icon(Icons.restart_alt, color: Colors.white, size: 18),
                    ),
                ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sizeSheet() async {
    var scale = _scale;
    var thick = _thickness;
    var fade = _opacity;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xCC000000),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('SIZE  ${scale.toStringAsFixed(2)}×', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  Slider(
                    value: scale,
                    min: 0.5,
                    max: 3,
                    divisions: 10,
                    onChanged: (value) => setSheet(() => scale = value),
                  ),
                  Text('THICKNESS  ${thick.toStringAsFixed(2)}×', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  Slider(
                    value: thick,
                    min: 0.5,
                    max: 3,
                    divisions: 10,
                    onChanged: (value) => setSheet(() => thick = value),
                  ),
                  Text('OPACITY  ${(fade * 100).round()}%', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  Slider(
                    value: fade,
                    min: 0.15,
                    max: 1,
                    onChanged: (value) => setSheet(() => fade = value),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    setState(() {
      _scale = scale;
      _thickness = thick;
      _opacity = fade;
    });
    _persist();
  }

  Future<void> _save() async {
    final store = StoreScope.of(context);
    final name = await promptText(
      context,
      title: 'Save screen',
      initial: '$_marksId · $_colorId',
      confirm: 'Save',
    );
    if (name == null || name.trim().isEmpty) return;
    final device = store.deviceById(store.boundDeviceId);
    store.upsertSaved(
      SavedLayout(
        id: 's-${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        skin: device?.skin ?? 'modern',
        clockOffsetMinutes: 0,
        notes: '',
        vfxColor: _colorId,
        vfxMarks: const [],
        uiMarkers: const [],
        kind: 'screen',
        deviceId: store.boundDeviceId ?? '',
        payload: {
          'colorId': _colorId,
          'marksId': _marksId,
          'scale': _scale,
          'thickness': _thickness,
          'markColor': _markColor,
          'bgColor': _bgColor,
          'bgImage': _bgImage,
          'overlay': _overlay,
          'layouts': {
            for (final entry in _layouts.entries)
              entry.key: entry.value.map((mark) => mark.toJson()).toList(),
          },
        },
      ),
    );
  }

  Widget _menu({
    required IconData icon,
    required String title,
    required List<Widget> children,
    required ValueChanged<int> onSelected,
  }) {
    return PopupMenuButton<int>(
      tooltip: title,
      color: const Color(0xCC000000),
      icon: Icon(icon, color: Colors.white, size: 18),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (var i = 0; i < children.length; i++)
          PopupMenuItem(value: i, child: children[i]),
      ],
    );
  }

  Widget _menuItem(
    String label, {
    required bool selected,
    Widget? leading,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 8)],
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 0.6),
            ),
          ),
          if (selected) const Icon(Icons.check, color: kAccent, size: 14),
        ],
      ),
    );
  }

  Widget _swatch(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
    );
  }

  Widget _overlayLayer() {
    final url = _overlay['url'] as String?;
    if (url == null || url.isEmpty || _overlay['hidden'] == true) {
      return const Positioned.fill(child: SizedBox.shrink());
    }
    final image = imageProviderForPath(url);
    if (image == null) return const SizedBox.shrink();
    final opacity = ((_overlay['opacity'] as num?)?.toDouble() ?? 50) / 100;
    final scale = (_overlay['scale'] as num?)?.toDouble() ?? 1;
    final rot = (_overlay['rot'] as num?)?.toDouble() ?? 0;
    final x = (_overlay['x'] as num?)?.toDouble() ?? 0;
    final y = (_overlay['y'] as num?)?.toDouble() ?? 0;
    final flip = _overlay['flip'] == true;
    final flop = _overlay['flop'] == true;
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0, 1),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translateByDouble(constraints.maxWidth * x / 100, constraints.maxHeight * y / 100, 0, 1)
                  ..rotateZ(rot * math.pi / 180)
                  ..scaleByDouble(scale * (flip ? -1 : 1), scale * (flop ? -1 : 1), 1, 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(image: image, fit: BoxFit.contain),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _colourSheet() async {
    const markColors = <(String, Color)>[
      ('white', Colors.white),
      ('black', Colors.black),
      ('red', Color(0xFFFF3B30)),
      ('green', Color(0xFF34C759)),
      ('magenta', Color(0xFFFF2D92)),
      ('cyan', Color(0xFF32ADE6)),
      ('yellow', Color(0xFFFFD60A)),
    ];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xCC000000),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('BACKGROUND', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.2)),
                  if (_marksId == 'checkerboard')
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Black & white only', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    )
                  else ...[
                    for (final color in kVfxPalette)
                      ListTile(
                        leading: _swatch(color.hex),
                        title: Text(color.label, style: const TextStyle(color: Colors.white)),
                        trailing: _colorId == color.id && _bgColor == null ? const Icon(Icons.check, color: kAccent) : null,
                        onTap: () {
                          setState(() {
                            _colorId = color.id;
                            _bgColor = null;
                          });
                          _persist();
                          setSheet(() {});
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.colorize, color: Colors.white70),
                      title: const Text('Custom colour', style: TextStyle(color: Colors.white)),
                      subtitle: Text(_bgColor ?? '', style: const TextStyle(color: Colors.white38)),
                      onTap: () async {
                        final hex = await _askHex('Background colour', _bgColor ?? '#00B140');
                        if (hex == null) return;
                        setState(() => _bgColor = hex);
                        _persist();
                        setSheet(() {});
                      },
                    ),
                    if (_bgColor != null)
                      ListTile(
                        leading: const Icon(Icons.close, color: Colors.white70),
                        title: const Text('Clear custom colour', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          setState(() => _bgColor = null);
                          _persist();
                          setSheet(() {});
                        },
                      ),
                  ],
                  if (_marksId != 'checkerboard' && _marksId != 'none') ...[
                    const SizedBox(height: 8),
                    const Text('MARKS', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _markDot(null, setSheet),
                        for (final color in markColors) _markDot(hexOf(color.$2), setSheet, fill: color.$2),
                      ],
                    ),
                    ListTile(
                      leading: const Icon(Icons.colorize, color: Colors.white70),
                      title: const Text('Custom mark colour', style: TextStyle(color: Colors.white)),
                      onTap: () async {
                        final hex = await _askHex('Mark colour', _markColor ?? '#FFFFFF');
                        if (hex == null) return;
                        setState(() => _markColor = hex);
                        _persist();
                        setSheet(() {});
                      },
                    ),
                  ],
                  if (_marksId != 'checkerboard') ...[
                    const Text('PHOTO', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.2)),
                    ListTile(
                      leading: const Icon(Icons.upload, color: Colors.white70),
                      title: Text(_bgImage == null ? 'Upload photo' : 'Replace photo', style: const TextStyle(color: Colors.white)),
                      onTap: () async {
                        final file = await FilePicker.pickFile(type: FileType.image);
                        if (file == null) return;
                        final path = await persistPickedImage(file);
                        if (path == null || !mounted) return;
                        setState(() => _bgImage = path);
                        _persist();
                      },
                    ),
                    if (_bgImage != null)
                      ListTile(
                        leading: const Icon(Icons.close, color: Colors.white70),
                        title: const Text('Remove photo', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          setState(() => _bgImage = null);
                          _persist();
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _markDot(String? hex, StateSetter setSheet, {Color? fill}) {
    final selected = _markColor == hex;
    return GestureDetector(
      onTap: () {
        setState(() => _markColor = hex);
        _persist();
        setSheet(() {});
      },
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          gradient: fill == null
              ? const SweepGradient(colors: [Colors.white, Colors.black, Colors.white])
              : null,
          border: Border.all(color: selected ? kAccent : Colors.white24, width: selected ? 2 : 1),
        ),
      ),
    );
  }

  Future<String?> _askHex(String title, String initial) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: '#00B140'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final raw = controller.text.trim();
                final hex = raw.startsWith('#') ? raw : '#$raw';
                if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return;
                Navigator.pop(context, hex.toUpperCase());
              },
              child: const Text('Use'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _overlaySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xCC000000),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            double numOf(String key, double fallback) => (_overlay[key] as num?)?.toDouble() ?? fallback;
            void setNum(String key, double value) {
              setState(() => _overlay[key] = value);
              setSheet(() {});
              _persist();
            }
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload, color: Colors.white70),
                      title: Text(
                        (_overlay['url'] as String?)?.isNotEmpty == true ? 'Replace image' : 'Upload image',
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () async {
                        final file = await FilePicker.pickFile(type: FileType.image);
                        if (file == null) return;
                        final path = await persistPickedImage(file);
                        if (path == null || !mounted) return;
                        setState(() {
                          _overlay['url'] = path;
                          _overlay['hidden'] = false;
                        });
                        _persist();
                        setSheet(() {});
                      },
                    ),
                    if ((_overlay['url'] as String?)?.isNotEmpty == true) ...[
                      _slider('Opacity', numOf('opacity', 50), 0, 100, (value) => setNum('opacity', value)),
                      _slider('Size', numOf('scale', 1), 0.25, 4, (value) => setNum('scale', value)),
                      _slider('Position X', numOf('x', 0), -100, 100, (value) => setNum('x', value)),
                      _slider('Position Y', numOf('y', 0), -100, 100, (value) => setNum('y', value)),
                      _slider('Rotation', numOf('rot', 0), 0, 360, (value) => setNum('rot', value)),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _overlay['flip'] = _overlay['flip'] != true);
                                _persist();
                                setSheet(() {});
                              },
                              child: const Text('Flip'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _overlay['flop'] = _overlay['flop'] != true);
                                _persist();
                                setSheet(() {});
                              },
                              child: const Text('Flop'),
                            ),
                          ),
                        ],
                      ),
                      ListTile(
                        title: const Text('Remove image', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          setState(() => _overlay = {
                            'opacity': 50,
                            'hidden': false,
                            'scale': 1.0,
                            'rot': 0,
                            'x': 0.0,
                            'y': 0.0,
                            'flip': false,
                            'flop': false,
                          });
                          _persist();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          children: [
            Text(label.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
            const Spacer(),
            Text(value.toStringAsFixed(label == 'Size' ? 2 : 0), style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
        Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}

class _SnapGridPainter extends CustomPainter {
  const _SnapGridPainter({required this.light});

  final bool light;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (light ? Colors.black : Colors.white).withValues(alpha: 0.3)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var i = 1; i < 8; i++) {
      final y = size.height * i / 8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final axis = Paint()
      ..color = (light ? Colors.black : Colors.white).withValues(alpha: 0.45)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), axis);
    canvas.drawCircle(size.center(Offset.zero), 3, Paint()..color = light ? Colors.black : Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SnapGridPainter oldDelegate) => oldDelegate.light != light;
}
