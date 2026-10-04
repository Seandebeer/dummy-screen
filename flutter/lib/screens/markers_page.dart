import 'package:flutter/material.dart';

import '../app.dart';
import '../theme.dart';
import '../widgets/three_finger.dart';

class MarkersPage extends StatelessWidget {
  const MarkersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    void toggle() {
      FocusManager.instance.primaryFocus?.unfocus();
      store.setFilming(!store.filming);
    }

    return ThreeFingerToggle(
      onToggle: toggle,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFF05070A))),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: store.filming ? 0 : 52),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final aspect =
                      (constraints.maxWidth / 5) / (constraints.maxHeight / 8);
                  return GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 5,
                    childAspectRatio: aspect,
                    children: [
                      for (var row = 0; row < 8; row++)
                        for (var col = 0; col < 5; col++)
                          _Cell(
                            on: store.uiMarkers.contains('$col:$row'),
                            onTap: () => store.toggleMarker(col, row),
                          ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (!store.filming)
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'UI markers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: store.clearMarkers,
                    child: const Text('Clear'),
                  ),
                  IconButton(
                    tooltip: 'Hide chrome',
                    onPressed: toggle,
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

class _Cell extends StatelessWidget {
  const _Cell({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: on ? kAccent : Colors.white24),
          color: on ? kAccent.withValues(alpha: 0.28) : Colors.transparent,
        ),
        child: on
            ? const Icon(Icons.add, color: Colors.white)
            : const SizedBox.expand(),
      ),
    );
  }
}
