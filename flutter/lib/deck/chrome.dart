import 'package:flutter/material.dart';

import '../theme.dart';

class DeckPalette {
  const DeckPalette({
    required this.background,
    required this.surface,
    required this.line,
    required this.muted,
    required this.ink,
    required this.secondary,
    required this.light,
  });

  final Color background;
  final Color surface;
  final Color line;
  final Color muted;
  final Color ink;
  final Color secondary;
  final bool light;
}

/// Base44 app themes. Ids stay stable so a saved choice still applies.
/// Dark is `black`, Cream is `white`.
const kDeckPalettes = <String, DeckPalette>{
  'black': DeckPalette(
    background: Color(0xFF06060A),
    surface: Color(0xFF101219),
    line: Color(0xFF1D212B),
    muted: Color(0xFF9198AC),
    ink: Colors.white,
    secondary: Color(0xFF1D212B),
    light: false,
  ),
  'grey': DeckPalette(
    background: Color(0xFF2E3038),
    surface: Color(0xFF3C3F49),
    line: Color(0xFF4E525F),
    muted: Color(0xFFBABDC4),
    ink: Colors.white,
    secondary: Color(0xFF494E5A),
    light: false,
  ),
  'white': DeckPalette(
    background: Color(0xFFF7F2E9),
    surface: Color(0xFFECE7DA),
    line: Color(0xFFD0C8B9),
    muted: Color(0xFF756957),
    ink: Color(0xFF262017),
    secondary: Color(0xFFDDD7CA),
    light: true,
  ),
};

DeckPalette paletteFor(String id) => kDeckPalettes[id] ?? kDeckPalettes['black']!;

class AppLanguage {
  const AppLanguage(this.code, this.native, {this.rtl = false});

  final String code;
  final String native;
  final bool rtl;
}

const kAppLanguages = <AppLanguage>[
  AppLanguage('en', 'English'),
  AppLanguage('af', 'Afrikaans'),
  AppLanguage('es', 'Español'),
  AppLanguage('fr', 'Français'),
  AppLanguage('de', 'Deutsch'),
  AppLanguage('pt', 'Português'),
  AppLanguage('zh', '中文（简体）'),
  AppLanguage('ar', 'العربية', rtl: true),
];

class GridFill extends StatelessWidget {
  const GridFill({super.key, required this.palette, required this.child});

  final DeckPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final line = palette.light
        ? const Color(0x1A000000)
        : const Color(0x1AFFFFFF);
    final vignette = palette.light
        ? const Color(0x18000000)
        : const Color(0x50000000);
    return ColoredBox(
      color: palette.background,
      child: CustomPaint(
        painter: _GridPainter(line, vignette),
        child: child,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter(this.line, this.vignette);

  final Color line;
  final Color vignette;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    if (size.width <= 0 || size.height <= 0) return;
    final reach = (size.shortestSide * 0.34).clamp(72.0, 220.0);
    final soft = vignette.withValues(alpha: vignette.a * 0.28);
    for (final corner in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      final rect = Rect.fromCircle(center: corner, radius: reach);
      final shade = Paint()
        ..shader = RadialGradient(
          colors: [vignette, soft, const Color(0x00000000)],
          stops: const [0.0, 0.38, 1],
        ).createShader(rect);
      canvas.drawCircle(corner, reach, shade);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.line != line || oldDelegate.vignette != vignette;
}

class DeckCard extends StatelessWidget {
  const DeckCard({super.key, required this.palette, required this.child});

  final DeckPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.line.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x48000000),
            blurRadius: 32,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class CollapsibleCard extends StatefulWidget {
  const CollapsibleCard({
    super.key,
    required this.palette,
    required this.icon,
    required this.title,
    required this.child,
    this.iconColor = kSignal,
    this.badge,
    this.initiallyOpen = false,
  });

  final DeckPalette palette;
  final IconData icon;
  final String title;
  final Widget child;
  final Color iconColor;
  final Widget? badge;
  final bool initiallyOpen;

  @override
  State<CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<CollapsibleCard> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.line.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(widget.icon, size: 16, color: widget.iconColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (widget.badge != null) widget.badge!,
                  const SizedBox(width: 8),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: palette.muted,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

InputDecoration deckField(DeckPalette palette, String hint) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: palette.secondary.withValues(alpha: 0.4),
    hintStyle: TextStyle(color: palette.muted, fontSize: 13),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: palette.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: palette.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kAccent),
    ),
  );
}
