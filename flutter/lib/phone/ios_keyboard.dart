import 'package:flutter/material.dart';

/// The prop's own keyboard, laid out like the iPhone keyboard. Fields stay
/// read-only so the device keyboard never covers the filmed screen.
Future<void> openIosKeyboard(
  BuildContext context,
  TextEditingController controller, {
  bool numeric = false,
  ValueChanged<String>? onChanged,
  VoidCallback? onDone,
}) {
  return showModalBottomSheet<void>(
    context: context,
    barrierColor: Colors.transparent,
    backgroundColor: const Color(0xFFD1D4D9),
    builder: (context) => _Board(
      controller: controller,
      numeric: numeric,
      onChanged: onChanged,
      onDone: onDone,
    ),
  );
}

class _Board extends StatefulWidget {
  const _Board({
    required this.controller,
    required this.numeric,
    this.onChanged,
    this.onDone,
  });

  final TextEditingController controller;
  final bool numeric;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onDone;

  @override
  State<_Board> createState() => _BoardState();
}

class _BoardState extends State<_Board> {
  bool _shift = false;
  bool _symbols = false;

  void _type(String key) {
    final text = widget.controller.text;
    if (key == 'done') {
      widget.onDone?.call();
      Navigator.pop(context);
      return;
    }
    if (key == 'shift') {
      setState(() => _shift = !_shift);
      return;
    }
    if (key == '123') {
      setState(() => _symbols = true);
      return;
    }
    if (key == 'abc') {
      setState(() => _symbols = false);
      return;
    }
    final next = key == '⌫'
        ? (text.isEmpty ? text : text.substring(0, text.length - 1))
        : '$text${key == 'space' ? ' ' : (_shift ? key.toUpperCase() : key)}';
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    widget.onChanged?.call(next);
    if (_shift && key != '⌫') setState(() => _shift = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.numeric) {
      return _pad(const [
        ['1', '2', '3'],
        ['4', '5', '6'],
        ['7', '8', '9'],
        ['⌫', '0', 'done'],
      ]);
    }
    if (_symbols) {
      return _pad(const [
        ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
        ['-', '/', ':', ';', '(', ')', r'$', '&', '@', '"'],
        ['abc', '.', ',', '?', '!', "'", '⌫'],
        ['abc', 'space', 'done'],
      ]);
    }
    return _pad(const [
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
      ['shift', 'z', 'x', 'c', 'v', 'b', 'n', 'm', '⌫'],
      ['123', 'space', 'done'],
    ]);
  }

  Widget _pad(List<List<String>> rows) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(3, 8, 3, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    for (final key in row)
                      Expanded(
                        flex: key == 'space' ? 5 : (key == 'shift' || key == '⌫' || key == '123' || key == 'abc' || key == 'done' ? 2 : 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _Key(
                            label: _label(key),
                            filled: key == 'done',
                            onTap: () => _type(key),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _label(String key) {
    switch (key) {
      case 'space':
        return 'space';
      case 'done':
        return 'return';
      case 'shift':
        return _shift ? '⇧' : '⇧';
      case '123':
        return '123';
      case 'abc':
        return 'ABC';
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
    final special = label == '⇧' || label == '⌫' || label == '123' || label == 'ABC' || label == 'return';
    return Material(
      color: filled
          ? const Color(0xFF0A84FF)
          : (special ? const Color(0xFFADB3BC) : Colors.white),
      borderRadius: BorderRadius.circular(5),
      elevation: 0.5,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: SizedBox(
          height: 42,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : Colors.black,
                fontSize: label.length > 2 ? 13 : 20,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
