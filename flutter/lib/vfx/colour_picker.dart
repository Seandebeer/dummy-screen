import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'catalog.dart';

/// Hue rows plus a grey ramp. Custom colours are chosen from these swatches.
List<String> paletteColourHexes() {
  final colors = <String>[];
  for (final light in [0.9, 0.7, 0.5, 0.32]) {
    for (var step = 0; step < 12; step++) {
      colors.add(hexOf(HSLColor.fromAHSL(1, step * 30.0, 0.78, light).toColor()));
    }
  }
  for (var step = 0; step < 12; step++) {
    final value = (255 * (11 - step) / 11).round();
    colors.add(hexOf(Color.fromARGB(255, value, value, value)));
  }
  return colors;
}

/// Palette first. Hex entry stays behind the Hex code control.
class PaletteColourPicker extends StatefulWidget {
  const PaletteColourPicker({
    super.key,
    required this.label,
    required this.onPick,
    this.selected,
  });

  final String label;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  State<PaletteColourPicker> createState() => _PaletteColourPickerState();
}

class _PaletteColourPickerState extends State<PaletteColourPicker> {
  bool _open = false;
  bool _hex = false;
  late final TextEditingController _code;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.selected ?? '');
  }

  @override
  void didUpdateWidget(PaletteColourPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected && !_hex) {
      _code.text = widget.selected ?? '';
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _useHex() {
    final raw = _code.text.trim();
    final hex = raw.startsWith('#') ? raw : '#$raw';
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return;
    widget.onPick(hex.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected?.toUpperCase();
    final fill = selected == null ? null : parseHex(selected, Colors.transparent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              gradient: fill == null
                  ? const SweepGradient(
                      colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red],
                    )
                  : null,
              border: Border.all(color: Colors.white24),
            ),
          ),
          title: Text(widget.label, style: const TextStyle(color: Colors.white)),
          trailing: Icon(_open ? Icons.expand_less : Icons.expand_more, color: Colors.white54, size: 18),
          onTap: () => setState(() => _open = !_open),
        ),
        if (_open) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final hex in paletteColourHexes())
                GestureDetector(
                  key: Key('swatch-$hex'),
                  onTap: () => widget.onPick(hex),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: parseHex(hex, Colors.black),
                      border: Border.all(
                        color: selected == hex ? kAccent : Colors.white24,
                        width: selected == hex ? 2 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          TextButton(
            key: const Key('colour-hex-option'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white54,
              padding: const EdgeInsets.symmetric(horizontal: 0),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => setState(() => _hex = !_hex),
            child: Text(_hex ? 'Hide hex code' : 'Hex code'),
          ),
          if (_hex)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('colour-hex-field'),
                    controller: _code,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    inputFormatters: [LengthLimitingTextInputFormatter(7)],
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '#00B140',
                    ),
                    onSubmitted: (_) => _useHex(),
                  ),
                ),
                TextButton(
                  key: const Key('colour-hex-use'),
                  onPressed: _useHex,
                  child: const Text('Use'),
                ),
              ],
            ),
        ],
      ],
    );
  }
}
