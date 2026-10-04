import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/three_finger.dart';

class VfxPage extends StatefulWidget {
  const VfxPage({super.key});

  @override
  State<VfxPage> createState() => _VfxPageState();
}

class _VfxPageState extends State<VfxPage> {
  List<MarkPoint>? _drag;

  void _toggle() {
    final store = StoreScope.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    store.setFilming(!store.filming);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final marks = _drag ?? store.vfxMarks;
    final color = kVfxColors[store.vfxColor] ?? kVfxColors['green']!;
    final ink = store.vfxColor == 'white' || store.vfxColor == 'grey'
        ? Colors.black
        : Colors.white;
    return ThreeFingerToggle(
      onToggle: _toggle,
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: color)),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    for (final mark in marks)
                      Positioned(
                        left: mark.x * constraints.maxWidth - 18,
                        top: mark.y * constraints.maxHeight - 18,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            final current = _drag ?? store.vfxMarks;
                            setState(() {
                              _drag = [
                                for (final item in current)
                                  if (item.id == mark.id)
                                    MarkPoint(
                                      id: item.id,
                                      x:
                                          ((item.x * constraints.maxWidth +
                                                      details.delta.dx) /
                                                  constraints.maxWidth)
                                              .clamp(0.04, 0.96)
                                              .toDouble(),
                                      y:
                                          ((item.y * constraints.maxHeight +
                                                      details.delta.dy) /
                                                  constraints.maxHeight)
                                              .clamp(0.04, 0.96)
                                              .toDouble(),
                                    )
                                  else
                                    item,
                              ];
                            });
                          },
                          onPanEnd: (_) {
                            final next = _drag;
                            if (next != null) store.setVfxMarks(next);
                            setState(() => _drag = null);
                          },
                          child: CustomPaint(
                            size: const Size(36, 36),
                            painter: _CrossPainter(ink),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (!store.filming)
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Screens',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  for (final entry in kVfxColors.entries)
                    ChoiceChip(
                      label: Text(entry.key),
                      selected: store.vfxColor == entry.key,
                      onSelected: (_) => store.setVfxColor(entry.key),
                    ),
                  IconButton(
                    tooltip: 'Add mark',
                    onPressed: () {
                      final next = [
                        ...store.vfxMarks,
                        MarkPoint(
                          id: 'mk-${DateTime.now().microsecondsSinceEpoch}',
                          x: 0.5,
                          y: 0.5,
                        ),
                      ];
                      store.setVfxMarks(next);
                    },
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    tooltip: 'Clear marks',
                    onPressed: () => store.setVfxMarks(const []),
                    icon: const Icon(Icons.clear_all),
                  ),
                  IconButton(
                    tooltip: 'Hide chrome',
                    onPressed: _toggle,
                    icon: const Icon(Icons.fullscreen),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(Offset(2, c.dy), Offset(size.width - 2, c.dy), paint);
    canvas.drawLine(Offset(c.dx, 2), Offset(c.dx, size.height - 2), paint);
    canvas.drawCircle(c, 6, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _CrossPainter oldDelegate) =>
      oldDelegate.color != color;
}
