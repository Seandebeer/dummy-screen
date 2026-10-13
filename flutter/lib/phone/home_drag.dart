import 'package:flutter/material.dart';

/// Long-press, then drag. A drop outside the device removes the item.
class StageDrag extends StatefulWidget {
  const StageDrag({
    super.key,
    required this.child,
    required this.onTap,
    this.onRemove,
    this.ghost,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final Widget? ghost;

  @override
  State<StageDrag> createState() => _StageDragState();
}

class _StageDragState extends State<StageDrag> {
  bool _off = false;
  OverlayEntry? _ghost;

  @override
  void dispose() {
    _ghost?.remove();
    super.dispose();
  }

  RenderBox? get _phone {
    RenderBox? found;
    context.visitAncestorElements((element) {
      final object = element.renderObject;
      if (object is RenderBox && object.hasSize && object.size.shortestSide > 180) {
        found = object;
        return false;
      }
      return true;
    });
    return found;
  }

  void _move(LongPressMoveUpdateDetails details) {
    final phone = _phone;
    final off = phone != null && droppedOffDevice(phone, details.globalPosition);
    setState(() => _off = off);
    _ghost?.remove();
    final finger = details.globalPosition;
    _ghost = OverlayEntry(
      builder: (context) => Positioned(
        left: finger.dx - 28,
        top: finger.dy - 28,
        child: IgnorePointer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.ghost ?? widget.child,
              if (off)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xE6FF453A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Remove', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
            ],
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_ghost!);
  }

  void _end() {
    if (_off) widget.onRemove?.call();
    _ghost?.remove();
    _ghost = null;
    if (mounted) setState(() => _off = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: widget.onRemove == null ? null : (_) {},
      onLongPressMoveUpdate: widget.onRemove == null ? null : _move,
      onLongPressEnd: widget.onRemove == null ? null : (_) => _end(),
      onLongPressCancel: widget.onRemove == null ? null : _end,
      child: Opacity(opacity: _off ? 0.35 : 1, child: widget.child),
    );
  }
}

/// True when the pointer has left the device and is over the stage around it.
bool droppedOffDevice(RenderBox box, Offset global, {double margin = 48}) {
  if (!box.hasSize) return false;
  final local = box.globalToLocal(global);
  return local.dx < -margin ||
      local.dy < -margin ||
      local.dx > box.size.width + margin ||
      local.dy > box.size.height + margin;
}

/// Cell under [global] inside a top-left grid, or null when the pointer misses it.
int? gridSlot(
  RenderBox grid,
  Offset global, {
  required int columns,
  required int rows,
  required double cellWidth,
  required double cellHeight,
  required double gap,
}) {
  if (!grid.hasSize || columns < 1 || rows < 1) return null;
  final local = grid.globalToLocal(global);
  if (local.dx < 0 || local.dy < 0) return null;
  final col = (local.dx / cellWidth).floor();
  final row = (local.dy / (cellHeight + gap)).floor();
  if (col < 0 || row < 0 || col >= columns || row >= rows) return null;
  return row * columns + col;
}

class SnapGridPainter extends CustomPainter {
  SnapGridPainter({
    required this.columns,
    required this.rows,
    required this.cellWidth,
    required this.cellHeight,
    required this.gap,
    this.slot,
  });

  final int columns;
  final int rows;
  final double cellWidth;
  final double cellHeight;
  final double gap;
  final int? slot;

  @override
  void paint(Canvas canvas, Size size) {
    final stride = cellHeight + gap;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final index = row * columns + col;
        final rect = Rect.fromLTWH(
          col * cellWidth + 4,
          row * stride + 2,
          cellWidth - 8,
          cellHeight - 4,
        );
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = index == slot ? 2 : 1
          ..color = Colors.white.withValues(alpha: index == slot ? 0.9 : 0.35);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(16)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(SnapGridPainter oldDelegate) =>
      oldDelegate.slot != slot ||
      oldDelegate.columns != columns ||
      oldDelegate.rows != rows;
}

List<String> movedOrder(List<String> ids, String id, {required bool remove, int? index}) {
  final next = [...ids];
  if (!next.contains(id)) return next;
  if (remove) {
    next.remove(id);
    return next;
  }
  if (index == null) return next;
  next.remove(id);
  final at = index < 0 ? 0 : (index > next.length ? next.length : index);
  next.insert(at, id);
  return next;
}
