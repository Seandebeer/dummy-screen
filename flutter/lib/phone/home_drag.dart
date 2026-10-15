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

  void _move(Offset global) {
    final phone = enclosingDevice(context) ?? context.findRenderObject() as RenderBox?;
    final off = phone != null && droppedOffDevice(phone, global);
    setState(() => _off = off);
    _ghost?.remove();
    final finger = global;
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
      onPanStart: widget.onRemove == null ? null : (details) => _move(details.globalPosition),
      onPanUpdate: widget.onRemove == null ? null : (details) => _move(details.globalPosition),
      onPanEnd: widget.onRemove == null ? null : (_) => _end(),
      onPanCancel: widget.onRemove == null ? null : _end,
      child: Opacity(opacity: _off ? 0.35 : 1, child: widget.child),
    );
  }
}

/// The device frame: the largest box that still sits inside the stage.
RenderBox? enclosingDevice(BuildContext context) {
  final screen = MediaQuery.sizeOf(context);
  RenderBox? best;
  var bestArea = 0.0;
  context.visitAncestorElements((element) {
    final object = element.renderObject;
    if (object is RenderBox && object.hasSize) {
      final size = object.size;
      final inside = size.width <= screen.width - 4 && size.height <= screen.height - 4;
      final area = size.width * size.height;
      if (inside && size.shortestSide > 160 && area > bestArea) {
        best = object;
        bestArea = area;
      }
    }
    return true;
  });
  return best;
}

/// True when the pointer has left the device and is over the stage around it.
bool droppedOffDevice(RenderBox box, Offset global, {double margin = 28}) {
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
  if (local.dx < 0 ||
      local.dy < 0 ||
      local.dx > grid.size.width + 4 ||
      local.dy > grid.size.height + 4) {
    return null;
  }
  final colStride = cellWidth > 0 ? cellWidth : grid.size.width / columns;
  final rowStride = cellHeight + gap;
  final col = (local.dx / colStride).floor();
  final row = (local.dy / (rowStride <= 0 ? 1 : rowStride)).floor();
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

/// Moves [id] between the home grid and the dock. An occupied slot swaps.
/// [remove] takes the app off both.
({List<String> home, List<String> dock}) placeApp({
  required List<String> home,
  required List<String> dock,
  required String id,
  required bool remove,
  int? homeIndex,
  int? dockIndex,
}) {
  final originHome = home.indexOf(id);
  final originDock = dock.indexOf(id);
  if (originHome < 0 && originDock < 0) {
    return (home: [...home], dock: [...dock]);
  }
  if (remove) {
    return (
      home: [for (final item in home) if (item != id) item],
      dock: [for (final item in dock) if (item != id) item],
    );
  }
  if (dockIndex != null && originDock >= 0 && homeIndex == null) {
    return (home: [...home], dock: movedOrder(dock, id, remove: false, index: dockIndex));
  }
  if (homeIndex != null && originHome >= 0 && dockIndex == null) {
    return (home: movedOrder(home, id, remove: false, index: homeIndex), dock: [...dock]);
  }
  if (dockIndex != null && originHome >= 0) {
    final nextHome = [...home]..removeAt(originHome);
    final nextDock = [...dock];
    if (dockIndex >= nextDock.length) {
      nextDock.add(id);
    } else {
      final displaced = nextDock[dockIndex];
      nextDock[dockIndex] = id;
      nextHome.insert(originHome.clamp(0, nextHome.length), displaced);
    }
    return (home: nextHome, dock: nextDock);
  }
  if (homeIndex != null && originDock >= 0) {
    final nextDock = [...dock]..removeAt(originDock);
    final nextHome = [...home];
    if (homeIndex >= nextHome.length) {
      nextHome.add(id);
    } else {
      final displaced = nextHome[homeIndex];
      nextHome[homeIndex] = id;
      nextDock.insert(originDock.clamp(0, nextDock.length), displaced);
    }
    return (home: nextHome, dock: nextDock);
  }
  return (home: [...home], dock: [...dock]);
}

/// Drop [id] on [index]. An occupied cell swaps the two apps. A cell past the
/// last app moves it to the end. [remove] takes it off the home screen.
List<String> movedOrder(List<String> ids, String id, {required bool remove, int? index}) {
  final next = [...ids];
  final from = next.indexOf(id);
  if (from < 0) return next;
  if (remove) {
    next.removeAt(from);
    return next;
  }
  if (index == null || index == from || index < 0) return next;
  if (index >= next.length) {
    next.removeAt(from);
    next.add(id);
    return next;
  }
  final displaced = next[index];
  next[index] = id;
  next[from] = displaced;
  return next;
}
