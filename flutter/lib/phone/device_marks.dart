import 'package:flutter/material.dart';

import '../vfx/catalog.dart';
import '../vfx/mark_glyph.dart';

/// Tracking marks drawn on a device. In OS edit they drag, snap, rotate, and
/// can be added or deleted. Filming leaves them as a still overlay.
class DeviceMarks extends StatefulWidget {
  const DeviceMarks({
    super.key,
    required this.marks,
    required this.editing,
    required this.scale,
    required this.thickness,
    required this.opacity,
    required this.color,
    required this.addKind,
    required this.onChange,
  });

  final List<StageMark> marks;
  final bool editing;
  final double scale;
  final double thickness;
  final double opacity;
  final Color color;
  final String addKind;
  final ValueChanged<List<StageMark>> onChange;

  @override
  State<DeviceMarks> createState() => _DeviceMarksState();
}

class _DeviceMarksState extends State<DeviceMarks> {
  final _stage = GlobalKey();
  List<StageMark> _marks = const [];
  String? _dragId;
  bool _moved = false;

  @override
  void initState() {
    super.initState();
    _marks = widget.marks;
  }

  @override
  void didUpdateWidget(covariant DeviceMarks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragId == null) _marks = widget.marks;
  }

  void _commit(List<StageMark> next) {
    setState(() => _marks = next);
    widget.onChange(next);
  }

  void _rotate(String id) {
    _commit([
      for (final mark in _marks)
        if (mark.id == id) mark.copyWith(rot: (mark.rot + 45) % 360) else mark,
    ]);
  }

  void _delete(String id) {
    _commit([for (final mark in _marks) if (mark.id != id) mark]);
  }

  void _add(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final lines = markerSnapLines(size.width, size.height);
    final mark = StageMark(
      id: 'm-${DateTime.now().microsecondsSinceEpoch}',
      kind: widget.addKind.isEmpty ? 'cross' : widget.addKind,
      x: snapMarkerPercent(local.dx, size.width, lines.xs),
      y: snapMarkerPercent(local.dy, size.height, lines.ys),
    );
    _commit([..._marks, mark]);
  }

  void _move(String id, Offset global) {
    final box = _stage.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || box.size.width <= 0 || box.size.height <= 0) return;
    final local = box.globalToLocal(global);
    final lines = markerSnapLines(box.size.width, box.size.height);
    setState(() {
      _moved = true;
      _marks = [
        for (final mark in _marks)
          if (mark.id == id)
            mark.copyWith(
              x: snapMarkerPercent(local.dx, box.size.width, lines.xs),
              y: snapMarkerPercent(local.dy, box.size.height, lines.ys),
            )
          else
            mark,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final paint = IgnorePointer(
      ignoring: !widget.editing,
      child: Stack(
        key: _stage,
        children: [
          const SizedBox.expand(),
          for (final mark in _marks)
            _placed(
              mark,
              child: widget.editing
                  ? _MarkHit(
                      mark: mark,
                      onTap: () {
                        if (_moved) {
                          _moved = false;
                          return;
                        }
                        _rotate(mark.id);
                      },
                      onDouble: () => _delete(mark.id),
                      onDrag: (global) {
                        _dragId = mark.id;
                        _move(mark.id, global);
                      },
                      onDrop: () {
                        _dragId = null;
                        if (_moved) widget.onChange(_marks);
                        _moved = false;
                      },
                      child: _glyph(mark),
                    )
                  : _glyph(mark),
            ),
        ],
      ),
    );
    if (!widget.editing) return paint;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: (details) {
        final box = _stage.currentContext?.findRenderObject() as RenderBox?;
        if (box == null || box.size.width <= 0) return;
        final local = box.globalToLocal(details.globalPosition);
        for (final mark in _marks) {
          final dx = box.size.width * mark.x / 100 - local.dx;
          final dy = box.size.height * mark.y / 100 - local.dy;
          if (dx * dx + dy * dy < 784) return;
        }
        _add(local, box.size);
      },
      child: paint,
    );
  }

  Widget _glyph(StageMark mark) {
    return Opacity(
      opacity: widget.opacity.clamp(0.15, 1),
      child: MarkGlyph(
        kind: mark.kind,
        color: widget.color,
        scale: 1.1 * widget.scale,
        thickness: 0.6 * widget.thickness,
        rotation: mark.rot,
        x: mark.x,
        y: mark.y,
      ),
    );
  }

  Widget _placed(StageMark mark, {required Widget child}) {
    return Align(
      alignment: Alignment(mark.x / 50 - 1, mark.y / 50 - 1),
      child: child,
    );
  }
}

class _MarkHit extends StatelessWidget {
  const _MarkHit({
    required this.mark,
    required this.onTap,
    required this.onDouble,
    required this.onDrag,
    required this.onDrop,
    required this.child,
  });

  final StageMark mark;
  final VoidCallback onTap;
  final VoidCallback onDouble;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onDrop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onDoubleTap: onDouble,
      onPanStart: (details) => onDrag(details.globalPosition),
      onPanUpdate: (details) => onDrag(details.globalPosition),
      onPanEnd: (_) => onDrop(),
      onPanCancel: onDrop,
      child: SizedBox(width: 44, height: 44, child: Center(child: child)),
    );
  }
}
