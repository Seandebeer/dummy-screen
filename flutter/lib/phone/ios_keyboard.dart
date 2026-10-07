import 'package:flutter/material.dart';

/// The prop's own keyboard, laid out like the iPhone keyboard and pinned to
/// the device that opened it. Fields stay read-only so a system keyboard
/// never covers the filmed screen.
Future<void> openIosKeyboard(
  BuildContext context,
  TextEditingController controller, {
  bool numeric = false,
  ValueChanged<String>? onChanged,
  VoidCallback? onDone,
}) {
  final host = DeviceKeyboardScope.maybeOf(context);
  if (host != null) {
    host.show(
      controller: controller,
      numeric: numeric,
      onChanged: onChanged,
      onDone: onDone,
    );
    return Future.value();
  }
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: false,
    barrierColor: Colors.transparent,
    backgroundColor: const Color(0xFFD1D4D9),
    builder: (context) => _Board(
      controller: controller,
      numeric: numeric,
      onChanged: onChanged,
      onDone: () {
        onDone?.call();
        Navigator.pop(context);
      },
      onHide: () => Navigator.pop(context),
    ),
  );
}

/// Drops the keypad. Safe while a field is closing; it does not subscribe.
void hideIosKeyboard(BuildContext context) {
  context.getInheritedWidgetOfExactType<DeviceKeyboardScope>()?.hide();
}

/// Keeps the keypad inside the mock device, under the app, instead of a
/// sheet that spills over the device edge. [route] is the open app. When it
/// changes, the keypad closes with that app.
class DeviceKeyboard extends StatefulWidget {
  const DeviceKeyboard({
    super.key,
    required this.child,
    this.footer,
    this.route = '',
  });

  final Widget child;
  final Widget? footer;
  final String route;

  @override
  State<DeviceKeyboard> createState() => _DeviceKeyboardState();
}

class DeviceKeyboardScope extends InheritedWidget {
  const DeviceKeyboardScope({
    super.key,
    required this.show,
    required this.hide,
    required super.child,
  });

  final void Function({
    required TextEditingController controller,
    required bool numeric,
    ValueChanged<String>? onChanged,
    VoidCallback? onDone,
  }) show;
  final VoidCallback hide;

  static DeviceKeyboardScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DeviceKeyboardScope>();
  }

  @override
  bool updateShouldNotify(DeviceKeyboardScope oldWidget) => false;
}

class _DeviceKeyboardState extends State<DeviceKeyboard> {
  TextEditingController? _controller;
  bool _numeric = false;
  ValueChanged<String>? _onChanged;
  VoidCallback? _onDone;

  void _show({
    required TextEditingController controller,
    required bool numeric,
    ValueChanged<String>? onChanged,
    VoidCallback? onDone,
  }) {
    setState(() {
      _controller = controller;
      _numeric = numeric;
      _onChanged = onChanged;
      _onDone = onDone;
    });
  }

  void _hide() {
    if (!mounted || _controller == null) return;
    setState(() {
      _controller = null;
      _onChanged = null;
      _onDone = null;
    });
  }

  @override
  void didUpdateWidget(DeviceKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.route != oldWidget.route) {
      _controller = null;
      _onChanged = null;
      _onDone = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return DeviceKeyboardScope(
      show: _show,
      hide: _hide,
      child: Column(
        children: [
          Expanded(child: widget.child),
          if (controller != null)
            _Board(
              controller: controller,
              numeric: _numeric,
              onChanged: _onChanged,
              onDone: () {
                final done = _onDone;
                _hide();
                done?.call();
              },
              onHide: _hide,
            )
          else if (widget.footer != null)
            widget.footer!,
        ],
      ),
    );
  }
}

const _emojis = [
  '😀', '😂', '🥰', '😍', '😘', '😊', '😉', '😎',
  '🤔', '😢', '😭', '😡', '👍', '👎', '👏', '🙏',
  '❤️', '🔥', '✨', '🎉', '💯', '✅', '⭐', '💬',
  '🎂', '🌹', '👀', '🙌', '🤝', '😴', '🤗', '😇',
  '🤩', '😜', '🥺', '😏', '😳', '🤯', '🥳', '👋',
  '👌', '✌️', '💪', '💔', '💙', '💜', '☀️', '🌙',
  '🎵', '📷', '🎁', '🍕', '☕', '🐶', '🐱', '🏠',
];

class _Board extends StatefulWidget {
  const _Board({
    required this.controller,
    required this.numeric,
    required this.onDone,
    required this.onHide,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool numeric;
  final ValueChanged<String>? onChanged;
  final VoidCallback onDone;
  final VoidCallback onHide;

  @override
  State<_Board> createState() => _BoardState();
}

class _BoardState extends State<_Board> {
  bool _shift = false;
  bool _symbols = false;
  bool _emoji = false;

  void _insert(String value) {
    final text = widget.controller.text;
    final next = '$text$value';
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    widget.onChanged?.call(next);
  }

  void _type(String key) {
    final text = widget.controller.text;
    if (key == 'done') {
      widget.onDone();
      return;
    }
    if (key == 'hide') {
      widget.onHide();
      return;
    }
    if (key == 'shift') {
      setState(() => _shift = !_shift);
      return;
    }
    if (key == '123') {
      setState(() {
        _symbols = true;
        _emoji = false;
      });
      return;
    }
    if (key == 'abc') {
      setState(() {
        _symbols = false;
        _emoji = false;
      });
      return;
    }
    if (key == 'emoji') {
      setState(() => _emoji = !_emoji);
      return;
    }
    if (key == '⌫') {
      final next = text.isEmpty ? text : text.characters.skipLast(1).string;
      widget.controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
      widget.onChanged?.call(next);
      return;
    }
    _insert(key == 'space' ? ' ' : (_shift ? key.toUpperCase() : key));
    if (_shift) setState(() => _shift = false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFD1D4D9),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 6, 3, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.numeric && !_emoji) _suggestions(),
              if (_emoji)
                _emojiGrid()
              else
                _pad(_rows()),
            ],
          ),
        ),
      ),
    );
  }

  List<List<String>> _rows() {
    if (widget.numeric) {
      return const [
        ['1', '2', '3'],
        ['4', '5', '6'],
        ['7', '8', '9'],
        ['⌫', '0', 'done'],
      ];
    }
    if (_symbols) {
      return const [
        ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
        ['-', '/', ':', ';', '(', ')', r'$', '&', '@', '"'],
        ['abc', '.', ',', '?', '!', "'", '⌫'],
        ['emoji', 'abc', 'space', 'done'],
      ];
    }
    return const [
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
      ['shift', 'z', 'x', 'c', 'v', 'b', 'n', 'm', '⌫'],
      ['123', 'emoji', 'space', 'done'],
    ];
  }

  Widget _suggestions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          for (final word in const ['I', 'The', "I'm"])
            Expanded(
              child: InkWell(
                onTap: () => _insert('$word '),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    word,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black, fontSize: 15),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Hide keyboard',
            onPressed: widget.onHide,
            icon: const Icon(Icons.keyboard_hide, color: Colors.black54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _emojiGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 168,
          child: GridView.count(
            crossAxisCount: 8,
            children: [
              for (final emoji in _emojis)
                InkWell(
                  onTap: () => _insert(emoji),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                ),
            ],
          ),
        ),
        _pad(const [
          ['abc', 'space', '⌫'],
        ]),
      ],
    );
  }

  Widget _pad(List<List<String>> rows) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    flex: key == 'space'
                        ? 5
                        : (key == 'shift' || key == '⌫' || key == '123' || key == 'abc' || key == 'done' || key == 'emoji' ? 2 : 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _Key(
                        label: _label(key),
                        filled: key == 'done' && widget.controller.text.isNotEmpty,
                        onTap: () => _type(key),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _label(String key) {
    switch (key) {
      case 'space':
        return 'space';
      case 'done':
        return 'return';
      case 'shift':
        return '⇧';
      case '123':
        return '123';
      case 'abc':
        return 'ABC';
      case 'emoji':
        return '😊';
      case '⌫':
        return '⌫';
      default:
        return _shift ? key.toUpperCase() : key;
    }
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap, this.filled = false});

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final special = label == '⇧' || label == '⌫' || label == '123' || label == 'ABC' || label == 'return' || label == '😊';
    return Material(
      color: filled
          ? const Color(0xFF0A84FF)
          : (special ? const Color(0xFFADB3BC) : Colors.white),
      borderRadius: BorderRadius.circular(6),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 42,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : Colors.black,
                fontSize: label.length > 2 ? 13 : 22,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
