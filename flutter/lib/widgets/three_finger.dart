import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Three-finger tap unlocks a filming lock. The L key does the same on a
/// desktop keyboard, matching the stage control on the web app.
class ThreeFingerToggle extends StatefulWidget {
  const ThreeFingerToggle({
    super.key,
    required this.onToggle,
    required this.child,
    this.enableKey = true,
  });

  final VoidCallback onToggle;
  final Widget child;
  final bool enableKey;

  @override
  State<ThreeFingerToggle> createState() => _ThreeFingerToggleState();
}

class _ThreeFingerToggleState extends State<ThreeFingerToggle> {
  final Set<int> _pointers = {};
  bool _fired = false;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.enableKey &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyL) {
      widget.onToggle();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _down(PointerDownEvent event) {
    _pointers.add(event.pointer);
    if (_pointers.length >= 3 && !_fired) {
      _fired = true;
      widget.onToggle();
    }
  }

  void _up(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.isEmpty) _fired = false;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.enableKey,
      onKeyEvent: _onKey,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: widget.child,
      ),
    );
  }
}
