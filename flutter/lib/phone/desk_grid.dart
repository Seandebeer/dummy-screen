import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'home_drag.dart';

/// Columns and rows that fill a computer desktop, one icon per cell.
class DeskGrid {
  const DeskGrid({
    required this.columns,
    required this.rows,
    required this.cellWidth,
    required this.cellHeight,
    required this.gap,
  });

  final int columns;
  final int rows;
  final double cellWidth;
  final double cellHeight;
  final double gap;

  int get capacity => columns * rows;

  static DeskGrid of(Size area) {
    const minWidth = 96.0;
    const minHeight = 84.0;
    const gap = 8.0;
    final width = area.width.isFinite && area.width > 8 ? area.width : 960.0;
    final height = area.height.isFinite && area.height > 8 ? area.height : 540.0;
    final columns = math.max(1, (width / minWidth).floor());
    final rows = math.max(1, ((height + gap) / (minHeight + gap)).floor());
    final cellWidth = width / columns;
    final rawHeight = (height - gap * (rows - 1)) / rows;
    return DeskGrid(
      columns: columns,
      rows: rows,
      cellWidth: cellWidth,
      cellHeight: rawHeight < 8 ? 8.0 : rawHeight,
      gap: gap,
    );
  }

  Offset origin(int index) {
    final slot = index.clamp(0, capacity - 1);
    final col = slot % columns;
    final row = slot ~/ columns;
    return Offset(col * cellWidth, row * (cellHeight + gap));
  }

  int? indexAt(Offset local) {
    if (columns < 1 || rows < 1) return null;
    final width = columns * cellWidth;
    final height = rows * (cellHeight + gap);
    if (local.dx < -8 || local.dy < -8 || local.dx > width + 8 || local.dy > height + 8) {
      return null;
    }
    final col = (local.dx / cellWidth).floor().clamp(0, columns - 1);
    final stride = cellHeight + gap;
    final row = (local.dy / stride).floor().clamp(0, rows - 1);
    return row * columns + col;
  }
}

Offset snapSpot(DeskGrid grid, Offset spot) {
  var best = 0;
  var bestDist = double.infinity;
  for (var i = 0; i < grid.capacity; i++) {
    final dist = (grid.origin(i) - spot).distance;
    if (dist < bestDist) {
      bestDist = dist;
      best = i;
    }
  }
  return grid.origin(best);
}

bool _folder(String id) => id.startsWith('folder:') || id.startsWith('file:');

/// Snaps [id] onto the cell under [drop]. An occupied cell swaps. A dock icon
/// landing on an app reports that app as [SnapMove.displaced] so it can take
/// the dock slot. Folders stay on the desktop.
class SnapMove {
  const SnapMove(this.spots, this.displaced);

  final Map<String, Offset> spots;
  final String? displaced;
}

SnapMove snapMove({
  required DeskGrid grid,
  required Map<String, Offset> spots,
  required String id,
  required Offset drop,
}) {
  final target = snapSpot(grid, drop);
  final next = Map<String, Offset>.from(spots);
  String? occupant;
  for (final entry in next.entries) {
    if (entry.key == id) continue;
    if ((snapSpot(grid, entry.value) - target).distance < 1) {
      occupant = entry.key;
      break;
    }
  }
  if (occupant == null) {
    next[id] = target;
    return SnapMove(next, null);
  }
  if (next.containsKey(id)) {
    next[occupant] = snapSpot(grid, next[id]!);
    next[id] = target;
    return SnapMove(next, null);
  }
  if (_folder(occupant)) {
    next[occupant] = _freeCell(grid, next, except: occupant, taken: target);
    next[id] = target;
    return SnapMove(next, null);
  }
  next.remove(occupant);
  next[id] = target;
  return SnapMove(next, occupant);
}

Offset _freeCell(
  DeskGrid grid,
  Map<String, Offset> spots, {
  required String except,
  required Offset taken,
}) {
  final used = <String>{_cellKey(taken)};
  for (final entry in spots.entries) {
    if (entry.key == except) continue;
    used.add(_cellKey(snapSpot(grid, entry.value)));
  }
  for (var i = 0; i < grid.capacity; i++) {
    final origin = grid.origin(i);
    if (!used.contains(_cellKey(origin))) return origin;
  }
  return grid.origin(0);
}

String _cellKey(Offset spot) => '${spot.dx.round()},${spot.dy.round()}';

/// Slot inside a dock or taskbar. Null when the pointer misses the bar.
int? dockSlot(
  RenderBox box,
  Offset global, {
  required int count,
  Axis axis = Axis.horizontal,
}) {
  if (!box.hasSize || count < 1) return null;
  final local = box.globalToLocal(global);
  final along = axis == Axis.horizontal ? local.dx : local.dy;
  final cross = axis == Axis.horizontal ? local.dy : local.dx;
  final extent = axis == Axis.horizontal ? box.size.width : box.size.height;
  final crossExtent = axis == Axis.horizontal ? box.size.height : box.size.width;
  if (along < -16 || along > extent + 16 || cross < -24 || cross > crossExtent + 24) {
    return null;
  }
  final stride = extent / count;
  if (stride <= 0) return null;
  return (along / stride).floor().clamp(0, count - 1);
}

/// Packed desktop grid with the phone's drag rules: snap, swap, and a dock.
class SnapField extends StatefulWidget {
  const SnapField({
    super.key,
    required this.ids,
    required this.buildIcon,
    required this.onDrop,
    this.dockKey,
    this.dockCount = 0,
    this.dockAxis = Axis.horizontal,
    this.onSecondary,
  });

  final List<String> ids;
  final Widget Function(
    String id, {
    required bool dimmed,
    required bool ghost,
    void Function(Offset global)? onDragStart,
    void Function(Offset global)? onDragMove,
    VoidCallback? onDragEnd,
  }) buildIcon;
  final void Function(String id, {required bool remove, int? homeIndex, int? dockIndex}) onDrop;
  final GlobalKey? dockKey;
  final int dockCount;
  final Axis dockAxis;
  final VoidCallback? onSecondary;

  @override
  State<SnapField> createState() => SnapFieldState();
}

class SnapFieldState extends State<SnapField> {
  final _gridKey = GlobalKey();
  String? _dragId;
  Offset? _finger;
  int? _slot;
  bool _off = false;
  OverlayEntry? _ghost;
  int _columns = 1;
  int _rows = 1;

  @override
  void dispose() {
    _ghost?.remove();
    super.dispose();
  }

  DeskGrid get _grid {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    final size = box != null && box.hasSize ? box.size : const Size(960, 540);
    return DeskGrid.of(size);
  }

  void track(String id, Offset global) {
    final frame = enclosingDevice(context);
    final off = frame != null && droppedOffDevice(frame, global);
    final grid = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    int? slot;
    if (!off && grid != null) {
      final local = gridSlot(
        grid,
        global,
        columns: _columns,
        rows: _rows,
        cellWidth: _grid.cellWidth,
        cellHeight: _grid.cellHeight,
        gap: _grid.gap,
      );
      if (local != null) {
        slot = local > widget.ids.length ? widget.ids.length : local;
      }
    }
    final dock = _dockIndex(global);
    setState(() {
      _dragId = id;
      _finger = global;
      _off = off;
      _slot = dock != null ? null : slot;
    });
    _syncGhost();
  }

  void finish() {
    final id = _dragId;
    final finger = _finger;
    if (id != null && finger != null) {
      final off = _off;
      final dockIndex = off ? null : _dockIndex(finger);
      final homeIndex = off || dockIndex != null ? null : _slot;
      widget.onDrop(id, remove: off, homeIndex: homeIndex, dockIndex: dockIndex);
    }
    _ghost?.remove();
    _ghost = null;
    if (mounted) {
      setState(() {
        _dragId = null;
        _finger = null;
        _slot = null;
        _off = false;
      });
    }
  }

  int? _dockIndex(Offset global) {
    final box = widget.dockKey?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return dockSlot(box, global, count: widget.dockCount, axis: widget.dockAxis);
  }

  void _syncGhost() {
    final id = _dragId;
    final finger = _finger;
    if (id == null || finger == null) return;
    _ghost?.remove();
    final off = _off;
    _ghost = OverlayEntry(
      builder: (context) => Positioned(
        left: finger.dx - 36,
        top: finger.dy - 28,
        child: IgnorePointer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.buildIcon(id, dimmed: false, ghost: true),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final grid = DeskGrid.of(constraints.biggest);
        _columns = grid.columns;
        _rows = grid.rows;
        final highlight = _slot;
        return GestureDetector(
          key: _gridKey,
          behavior: HitTestBehavior.opaque,
          onSecondaryTap: widget.onSecondary,
          child: Stack(
            children: [
              if (_dragId != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: SnapGridPainter(
                        columns: grid.columns,
                        rows: grid.rows,
                        cellWidth: grid.cellWidth,
                        cellHeight: grid.cellHeight,
                        gap: grid.gap,
                        slot: highlight != null && highlight < grid.capacity ? highlight : null,
                      ),
                    ),
                  ),
                ),
              for (var i = 0; i < widget.ids.length && i < grid.capacity; i++)
                Positioned(
                  left: grid.origin(i).dx,
                  top: grid.origin(i).dy,
                  width: grid.cellWidth,
                  height: grid.cellHeight,
                  child: Center(
                    child: widget.buildIcon(
                      widget.ids[i],
                      dimmed: _dragId == widget.ids[i],
                      ghost: false,
                      onDragStart: (global) => track(widget.ids[i], global),
                      onDragMove: (global) => track(widget.ids[i], global),
                      onDragEnd: finish,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Tap opens. A short move starts a drag and keeps the pointer.
class HoldDrag extends StatefulWidget {
  const HoldDrag({
    super.key,
    required this.child,
    required this.onTap,
    this.onStart,
    this.onMove,
    this.onEnd,
  });

  final Widget child;
  final VoidCallback onTap;
  final void Function(Offset global)? onStart;
  final void Function(Offset global)? onMove;
  final VoidCallback? onEnd;

  @override
  State<HoldDrag> createState() => _HoldDragState();
}

class _HoldDragState extends State<HoldDrag> {
  Offset? _origin;
  bool _dragged = false;

  void _down(PointerDownEvent event) {
    _origin = event.position;
    _dragged = false;
  }

  void _move(PointerMoveEvent event) {
    final origin = _origin;
    if (origin == null || widget.onStart == null) return;
    if (!_dragged && (event.position - origin).distance > 12) {
      _dragged = true;
      widget.onStart!(event.position);
    }
    if (_dragged) widget.onMove?.call(event.position);
  }

  void _up(PointerUpEvent event) {
    if (_dragged) {
      widget.onEnd?.call();
    } else {
      widget.onTap();
    }
    _origin = null;
    _dragged = false;
  }

  void _cancel(PointerCancelEvent event) {
    if (_dragged) widget.onEnd?.call();
    _origin = null;
    _dragged = false;
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        _DeskClaim: GestureRecognizerFactoryWithHandlers<_DeskClaim>(
          () => _DeskClaim(),
          (_) {},
        ),
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _cancel,
        child: widget.child,
      ),
    );
  }
}

class _DeskClaim extends OneSequenceGestureRecognizer {
  @override
  String get debugDescription => 'desk-claim';

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {}

  @override
  void didStopTrackingLastPointer(int pointer) {}
}
