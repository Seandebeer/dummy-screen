import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'catalog.dart';

/// A point on the hue / saturation / value spectrum, as `#RRGGBB`.
String colourFromSpectrum({
  required double hue,
  required double saturation,
  required double value,
}) {
  return hexOf(HSVColor.fromAHSV(1, hue, saturation, value).toColor());
}

/// Eyedropper on a continuous spectrum. Hex entry stays behind Hex code.
class SpectrumColourPicker extends StatefulWidget {
  const SpectrumColourPicker({
    super.key,
    required this.label,
    required this.onPick,
    this.selected,
  });

  final String label;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  State<SpectrumColourPicker> createState() => _SpectrumColourPickerState();
}

class _SpectrumColourPickerState extends State<SpectrumColourPicker> {
  bool _open = false;
  bool _hex = false;
  double _hue = 0;
  double _saturation = 1;
  double _value = 1;
  late final TextEditingController _code;

  @override
  void initState() {
    super.initState();
    _read(widget.selected);
    _code = TextEditingController(text: widget.selected ?? '');
  }

  @override
  void didUpdateWidget(SpectrumColourPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected && !_hex) {
      _read(widget.selected);
      _code.text = widget.selected ?? '';
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _read(String? hex) {
    if (hex == null || hex.isEmpty) return;
    final hsv = HSVColor.fromColor(parseHex(hex, Colors.red));
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  void _emit() {
    final hex = colourFromSpectrum(hue: _hue, saturation: _saturation, value: _value);
    _code.text = hex;
    widget.onPick(hex);
  }

  void _field(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    setState(() {
      _saturation = (local.dx / size.width).clamp(0.0, 1.0);
      _value = (1 - local.dy / size.height).clamp(0.0, 1.0);
    });
    _emit();
  }

  void _hueAt(Offset local, double width) {
    if (width <= 0) return;
    setState(() => _hue = (local.dx / width * 360).clamp(0.0, 360.0));
    _emit();
  }

  void _useHex() {
    final raw = _code.text.trim();
    final hex = raw.startsWith('#') ? raw : '#$raw';
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return;
    setState(() => _read(hex));
    widget.onPick(hex.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final fill = selected == null || selected.isEmpty ? null : parseHex(selected, Colors.white);
    final hue = HSVColor.fromAHSV(1, _hue, 1, 1).toColor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.colorize, color: fill ?? Colors.white70),
          title: Text(widget.label, style: const TextStyle(color: Colors.white)),
          trailing: Icon(_open ? Icons.expand_less : Icons.expand_more, color: Colors.white54, size: 18),
          onTap: () => setState(() => _open = !_open),
        ),
        if (_open) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const height = 120.0;
              return Column(
                children: [
                  GestureDetector(
                    key: const Key('colour-spectrum'),
                    onPanDown: (details) => _field(details.localPosition, Size(width, height)),
                    onPanUpdate: (details) => _field(details.localPosition, Size(width, height)),
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(child: ColoredBox(color: Colors.white)),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.white, hue]),
                              ),
                            ),
                          ),
                          const Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: (_saturation * width - 9).clamp(0.0, width - 18),
                            top: ((1 - _value) * height - 9).clamp(0.0, height - 18),
                            child: const IgnorePointer(
                              child: Icon(
                                Icons.colorize,
                                key: Key('colour-eyedropper'),
                                size: 18,
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    key: const Key('colour-hue'),
                    onPanDown: (details) => _hueAt(details.localPosition, width),
                    onPanUpdate: (details) => _hueAt(details.localPosition, width),
                    child: SizedBox(
                      width: width,
                      height: 16,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [
                              for (var step = 0; step <= 12; step++)
                                HSVColor.fromAHSV(1, step * 30.0, 1, 1).toColor(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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
