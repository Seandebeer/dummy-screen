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

const kDeckPalettes = <String, DeckPalette>{
  'black': DeckPalette(
    background: Color(0xFF06070A),
    surface: Color(0xFF10141A),
    line: Color(0xFF1C2129),
    muted: Color(0xFF9098A6),
    ink: Colors.white,
    secondary: Color(0xFF1C2129),
    light: false,
  ),
  'grey': DeckPalette(
    background: Color(0xFF2E333B),
    surface: Color(0xFF3C424B),
    line: Color(0xFF4E5560),
    muted: Color(0xFFB8BCC2),
    ink: Colors.white,
    secondary: Color(0xFF49505A),
    light: false,
  ),
  'white': DeckPalette(
    background: Color(0xFFF6F1E4),
    surface: Color(0xFFEBE4D4),
    line: Color(0xFFCDC4B4),
    muted: Color(0xFF756C60),
    ink: Color(0xFF261F16),
    secondary: Color(0xFFDDD6C6),
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
        ? const Color(0x07000000)
        : const Color(0x07FFFFFF);
    return ColoredBox(
      color: palette.background,
      child: CustomPaint(
        painter: _GridPainter(line),
        child: child,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter(this.line);

  final Color line;

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
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.line != line;
}

class DeckCard extends StatelessWidget {
  const DeckCard({super.key, required this.palette, required this.child});

  final DeckPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.6),
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
        color: palette.surface.withValues(alpha: 0.6),
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
