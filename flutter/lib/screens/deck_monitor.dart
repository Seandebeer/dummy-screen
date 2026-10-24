import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../deck/chrome.dart';
import '../format.dart';
import '../models.dart';
import '../phone/cues.dart';
import '../phone/form_factor.dart';
import '../phone/home_view.dart';
import '../phone/lock_screen.dart';
import '../phone/phone_shell.dart';
import '../store.dart';

const _titleHeight = 34.0;
const _minPicture = 150.0;

/// Width divided by height of the framed device picture.
double deckLiveAspect(PropDevice device) {
  final metrics = metricsFor(device.kind);
  final pad = switch (metrics.frame) {
    'phone' => 8.0,
    'tablet' => 10.0,
    'tv' => 8.0,
    'laptop' => 8.0,
    _ => 10.0,
  };
  final chin = switch (metrics.frame) {
    'laptop' => 24.0,
    'monitor' => 22.0,
    _ => 0.0,
  };
  const screenHeight = 844.0;
  final screenWidth = screenHeight * metrics.aspect;
  return (screenWidth + pad * 2) / (screenHeight + pad * 2 + chin);
}

/// Floating monitor. Drag the title to move it. Drag the corner to scale it.
class DeckLiveWindow extends StatefulWidget {
  const DeckLiveWindow({
    super.key,
    required this.store,
    required this.device,
    required this.palette,
    required this.bounds,
    this.initialOffset,
    this.initialHeight = 260,
    this.onFrame,
  });

  final StageStore store;
  final PropDevice device;
  final DeckPalette palette;
  final Size bounds;
  final Offset? initialOffset;
  final double initialHeight;
  final void Function(Offset offset, double pictureHeight)? onFrame;

  @override
  State<DeckLiveWindow> createState() => _DeckLiveWindowState();
}

class _DeckLiveWindowState extends State<DeckLiveWindow> {
  late Offset _offset;
  late double _pictureHeight;

  double get _aspect => deckLiveAspect(widget.device);

  double get _maxPicture {
    final bounds = widget.bounds;
    if (!bounds.width.isFinite || !bounds.height.isFinite) return 480;
    final byHeight = bounds.height - _titleHeight - 16;
    final byWidth = (bounds.width - 16) / _aspect;
    return math.max(_minPicture, math.min(byHeight, byWidth));
  }

  @override
  void initState() {
    super.initState();
    _pictureHeight = widget.initialHeight
        .clamp(_minPicture, _maxPicture)
        .toDouble();
    _offset = widget.initialOffset ?? _home(widget.bounds, _windowSize);
    _offset = _clamp(_offset);
  }

  @override
  void didUpdateWidget(DeckLiveWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pictureHeight = _pictureHeight.clamp(_minPicture, _maxPicture).toDouble();
    _offset = _clamp(_offset);
  }

  Size get _windowSize =>
      Size(_pictureHeight * _aspect, _pictureHeight + _titleHeight);

  Offset _home(Size bounds, Size window) {
    const column = 860.0;
    final rightEdge = bounds.width > column
        ? (bounds.width + column) / 2
        : bounds.width;
    final room = bounds.width - rightEdge - 16;
    if (room >= window.width) return Offset(rightEdge + 8, 20);
    return Offset(math.max(8, bounds.width - window.width - 12), 20);
  }

  Offset _clamp(Offset offset) {
    final bounds = widget.bounds;
    final window = _windowSize;
    if (!bounds.width.isFinite || !bounds.height.isFinite) return offset;
    final dx = offset.dx
        .clamp(0.0, math.max(0.0, bounds.width - window.width))
        .toDouble();
    final dy = offset.dy
        .clamp(0.0, math.max(0.0, bounds.height - window.height))
        .toDouble();
    return Offset(dx, dy);
  }

  void _report() => widget.onFrame?.call(_offset, _pictureHeight);

  void _move(DragUpdateDetails details) {
    setState(() => _offset = _clamp(_offset + details.delta));
    _report();
  }

  void _scale(DragUpdateDetails details) {
    final fromY = details.delta.dy;
    final fromX = details.delta.dx / _aspect;
    final grow = fromY.abs() >= fromX.abs() ? fromY : fromX;
    setState(() {
      _pictureHeight = (_pictureHeight + grow)
          .clamp(_minPicture, _maxPicture)
          .toDouble();
      _offset = _clamp(_offset);
    });
    _report();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final window = _windowSize;
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: SizedBox(
        key: const Key('deck-live-window'),
        width: window.width,
        height: window.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 28,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Column(
                  children: [
                    GestureDetector(
                      key: const Key('deck-live-drag'),
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: _move,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.move,
                        child: SizedBox(
                          height: _titleHeight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.drag_indicator,
                                  size: 16,
                                  color: palette.muted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.device.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: palette.ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: DeckLivePicture(
                        store: widget.store,
                        device: widget.device,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    key: const Key('deck-live-resize'),
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: _scale,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeDownRight,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.open_in_full,
                              size: 14,
                              color: palette.ink.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Scaled picture of one device. Touches stop at the frame.
class DeckLivePicture extends StatelessWidget {
  const DeckLivePicture({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  static const _screenHeight = 844.0;

  @override
  Widget build(BuildContext context) {
    final metrics = metricsFor(device.kind);
    final pad = switch (metrics.frame) {
      'phone' => 8.0,
      'tablet' => 10.0,
      'tv' => 8.0,
      'laptop' => 8.0,
      _ => 10.0,
    };
    final chin = switch (metrics.frame) {
      'laptop' => 24.0,
      'monitor' => 22.0,
      _ => 0.0,
    };
    final screenWidth = _screenHeight * metrics.aspect;
    final outerWidth = screenWidth + pad * 2;
    final outerHeight = _screenHeight + pad * 2 + chin;
    final phone = device.kind == 'phone' || device.kind == 'tablet';
    final wide = device.kind == 'tablet' || metrics.aspect > 1;
    final stage = phone ? _phone(wide) : FormOs(store: store, device: device);

    return ColoredBox(
      key: const Key('deck-live-view'),
      color: const Color(0xFF0A0A0C),
      child: AbsorbPointer(
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: outerWidth,
            height: outerHeight,
            child: DeviceBezel(
              frame: metrics.frame,
              child: PhoneCueLayer(
                cue: store.cueFor(device.id),
                skin: device.skin,
                child: stage,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _phone(bool wide) {
    final now = osNow(device.os);
    final locked = device.locked && device.os.lockType != 'off';
    return PhoneShell(
      framed: false,
      device: device,
      onHome: () {},
      call: store.callFor(device.id),
      onAccept: () {},
      onEnd: () {},
      alarm: store.alarms[device.id] ?? false,
      onDismissAlarm: () {},
      banners: store.bannersFor(device.id),
      onDismissBanner: (_) {},
      onOpenBanner: (_) {},
      body: locked
          ? LockView(
              device: device,
              dateLabel: formatDay(now),
              onUnlock: () {},
              onSetPasscode: (_) {},
              onSetPattern: (_) {},
            )
          : PhoneHome(
              skin: device.skin,
              os: device.os,
              wide: wide,
              light: device.os.isLight,
              onOpen: (_) {},
            ),
    );
  }
}
