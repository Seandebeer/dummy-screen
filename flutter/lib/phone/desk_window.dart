import 'package:flutter/material.dart';

/// A desktop window that opens large and can be resized from its corner.
class DeskSizer extends StatefulWidget {
  const DeskSizer({super.key, required this.child});

  final Widget child;

  @override
  State<DeskSizer> createState() => _DeskSizerState();
}

class _DeskSizerState extends State<DeskSizer> {
  double? _width;
  double? _height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 1200.0;
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 800.0;
        final width = (_width ?? maxWidth * 0.9).clamp(360.0, maxWidth);
        final height = (_height ?? maxHeight * 0.86).clamp(280.0, maxHeight);
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: widget.child),
              Positioned(
                right: 0,
                bottom: 0,
                child: Tooltip(
                  message: 'Resize',
                  child: GestureDetector(
                    key: const Key('desk-window-resize'),
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) => setState(() {
                      _width = (width + details.delta.dx).clamp(360.0, maxWidth);
                      _height = (height + details.delta.dy).clamp(
                        280.0,
                        maxHeight,
                      );
                    }),
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(painter: _ResizeGrip()),
                    ),
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

class _ResizeGrip extends CustomPainter {
  const _ResizeGrip();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8E8E93)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final start in [6.0, 11.0, 16.0]) {
      canvas.drawLine(
        Offset(start, size.height - 4),
        Offset(size.width - 4, start),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ResizeGrip oldDelegate) => false;
}

/// The name under a desktop icon. A click on the name edits it in place.
class DeskIconName extends StatelessWidget {
  const DeskIconName({
    super.key,
    required this.label,
    required this.labelKey,
    required this.editing,
    required this.controller,
    required this.onStart,
    required this.onCommit,
    this.color = Colors.white,
    this.fontSize = 11,
    this.maxLines = 2,
  });

  final String label;
  final Key labelKey;
  final bool editing;
  final TextEditingController controller;
  final VoidCallback onStart;
  final VoidCallback onCommit;
  final Color color;
  final double fontSize;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (editing) {
      return TextField(
        key: const Key('desk-rename-field'),
        controller: controller,
        autofocus: true,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: fontSize, height: 1.2),
        cursorColor: color,
        decoration: const InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Color(0xCC000000),
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          border: InputBorder.none,
        ),
        onSubmitted: (_) => onCommit(),
        onTapOutside: (_) => onCommit(),
      );
    }
    return Semantics(
      container: true,
      button: true,
      label: 'Rename $label',
      child: GestureDetector(
        key: labelKey,
        behavior: HitTestBehavior.opaque,
        onTap: onStart,
        child: Text(
          label,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
            height: 1.05,
            shadows: const [Shadow(color: Color(0xE6000000), blurRadius: 3)],
          ),
        ),
      ),
    );
  }
}
