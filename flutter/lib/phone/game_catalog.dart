import 'package:flutter/material.dart';

/// A mock game cover. The art is painted, not a flat colour chip.
class MockGame {
  const MockGame({
    required this.id,
    required this.title,
    required this.studio,
    required this.shelf,
    required this.colors,
    required this.mark,
  });

  final String id;
  final String title;
  final String studio;
  final String shelf;
  final List<Color> colors;
  final IconData mark;
}

const mockGames = <MockGame>[
  MockGame(
    id: 'ash-circuit',
    title: 'Ash Circuit',
    studio: 'Northline',
    shelf: 'Action',
    colors: [Color(0xFFFF6A2A), Color(0xFF1A0C08), Color(0xFF3A1208)],
    mark: Icons.local_fire_department,
  ),
  MockGame(
    id: 'harbor-light',
    title: 'Harbor Light',
    studio: 'Keel',
    shelf: 'Adventure',
    colors: [Color(0xFF1EC8C0), Color(0xFF062A32), Color(0xFF0A4A52)],
    mark: Icons.sailing,
  ),
  MockGame(
    id: 'glass-relay',
    title: 'Glass Relay',
    studio: 'Lumen',
    shelf: 'Indie',
    colors: [Color(0xFFB388FF), Color(0xFF14081E), Color(0xFF3A2060)],
    mark: Icons.blur_on,
  ),
  MockGame(
    id: 'north-signal',
    title: 'North Signal',
    studio: 'Field',
    shelf: 'Sports',
    colors: [Color(0xFF4DA3FF), Color(0xFF061426), Color(0xFF123A66)],
    mark: Icons.podcasts,
  ),
  MockGame(
    id: 'red-orchard',
    title: 'Red Orchard',
    studio: 'Keel',
    shelf: 'Adventure',
    colors: [Color(0xFFE23B4A), Color(0xFF2A0A10), Color(0xFF5A1820)],
    mark: Icons.park,
  ),
  MockGame(
    id: 'kilo-drift',
    title: 'Kilo Drift',
    studio: 'Apex Yard',
    shelf: 'Sports',
    colors: [Color(0xFFB6FF3C), Color(0xFF10140A), Color(0xFF2A3810)],
    mark: Icons.speed,
  ),
  MockGame(
    id: 'paper-moon',
    title: 'Paper Moon',
    studio: 'Lumen',
    shelf: 'Indie',
    colors: [Color(0xFFFFE2A8), Color(0xFF1A1430), Color(0xFF3A2A58)],
    mark: Icons.nightlight,
  ),
  MockGame(
    id: 'vault-year',
    title: 'Vault Year',
    studio: 'Northline',
    shelf: 'Action',
    colors: [Color(0xFFE6C36A), Color(0xFF101828), Color(0xFF243044)],
    mark: Icons.lock,
  ),
];

MockGame? gameById(String id) {
  for (final game in mockGames) {
    if (game.id == id) return game;
  }
  return null;
}

/// Cover art for a pinned id that is not one of the mock games.
MockGame coverForLabel({
  required String id,
  required String title,
  required Color color,
  IconData mark = Icons.sports_esports,
}) {
  return MockGame(
    id: id,
    title: title,
    studio: '',
    shelf: 'Pinned',
    colors: [color, Color.lerp(color, const Color(0xFF05060A), 0.72)!, color],
    mark: mark,
  );
}

class GameCover extends StatelessWidget {
  const GameCover({
    super.key,
    required this.game,
    this.width = 112,
    this.height = 148,
    this.onTap,
  });

  final MockGame game;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = (width * 0.08).clamp(6.0, 16.0);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _CoverPainter(game)),
              Positioned(
                left: width * 0.1,
                top: height * 0.14,
                child: Icon(
                  game.mark,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: width * 0.34,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.28),
                      Colors.white.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0, 0.22, 0.55, 1],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  game.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (width * 0.13).clamp(9.0, 16.0),
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 6)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverPainter extends CustomPainter {
  const _CoverPainter(this.game);

  final MockGame game;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: game.colors,
        ).createShader(rect),
    );
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [game.colors.first.withValues(alpha: 0.95), game.colors.first.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.3, size.height * 0.28), radius: size.width * 0.7));
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.28), size.width * 0.7, glow);
    final slash = Path()
      ..moveTo(size.width * 0.55, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.62)
      ..lineTo(size.width * 0.22, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height * 0.72)
      ..close();
    canvas.drawPath(slash, Paint()..color = Colors.black.withValues(alpha: 0.28));
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.2),
      size.width * 0.08,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.1),
      Offset(size.width * 0.42, size.height * 0.1),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _CoverPainter oldDelegate) => oldDelegate.game.id != game.id;
}
