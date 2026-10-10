import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models.dart';
import 'catalog.dart';

/// Current Android home, matched to the ribbon reference: weather and Start,
/// a search bar, one row of four icons, then the dock.
class AndroidHome extends StatelessWidget {
  const AndroidHome({super.key, required this.os, required this.onOpen});

  final OsSettings os;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    final rest = [
      for (final id in (os.homeOrder.isEmpty ? kHomeOrder : os.homeOrder))
        if (propAppById(id) case final app?)
          if (!_pageOne.contains(id) && !_dock.contains(id)) app,
    ];
    final pages = <List<PropApp>>[];
    for (var i = 0; i < rest.length; i += 16) {
      final end = math.min(i + 16, rest.length);
      pages.add(rest.sublist(i, end));
    }
    final count = 1 + pages.length;
    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return PageView(
            key: const Key('android-home'),
            scrollBehavior: const _Scroll(),
            children: [
              SizedBox(width: width, child: _FirstPage(onOpen: onOpen, pages: count)),
              for (var i = 0; i < pages.length; i++)
                SizedBox(
                  width: width,
                  child: _MorePage(apps: pages[i], page: i + 1, pages: count, onOpen: onOpen),
                ),
            ],
          );
        },
      ),
    );
  }
}

const _pageOne = {'appstore', 'photos'};
const _dock = ['phone', 'messages', 'browser', 'camera'];

class _Scroll extends MaterialScrollBehavior {
  const _Scroll();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

class _FirstPage extends StatelessWidget {
  const _FirstPage({required this.onOpen, required this.pages});

  final void Function(String id) onOpen;
  final int pages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          const Spacer(flex: 4),
          Row(
            children: [
              Expanded(
                flex: 11,
                child: _Weather(onTap: () => onOpen('skycast')),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 10,
                child: _Start(onTap: () => onOpen('appstore')),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Search(onTap: () => onOpen('browser')),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Launch(
                label: 'Store',
                onTap: () => onOpen('appstore'),
                mark: const _Bag(),
                buttonKey: const Key('android-store'),
              ),
              _Launch(
                label: 'Gallery',
                onTap: () => onOpen('photos'),
                mark: const _Flower(),
                buttonKey: const Key('android-gallery'),
              ),
              _Launch(
                label: 'Play',
                onTap: () => onOpen('appstore'),
                mark: const _PlayMark(),
                buttonKey: const Key('android-play'),
              ),
              _Launch(
                label: 'Google',
                onTap: () => onOpen('browser'),
                mark: const _DotFolder(),
                buttonKey: const Key('android-google'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Dots(count: pages, index: 0),
          const Spacer(flex: 3),
          const _DockRow(),
        ],
      ),
    );
  }
}

class _MorePage extends StatelessWidget {
  const _MorePage({
    required this.apps,
    required this.page,
    required this.pages,
    required this.onOpen,
  });

  final List<PropApp> apps;
  final int page;
  final int pages;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 12,
            alignment: WrapAlignment.start,
            children: [
              for (final app in apps)
                SizedBox(
                  width: 76,
                  child: _Launch(
                    label: app.label,
                    onTap: () => onOpen(app.id),
                    buttonKey: Key('home-${app.id}'),
                    mark: _PlainIcon(color: app.color, icon: app.icon),
                  ),
                ),
            ],
          ),
          const Spacer(),
          _Dots(count: pages, index: page),
          const SizedBox(height: 10),
          const _DockRow(),
        ],
      ),
    );
  }
}

class _DockRow extends StatelessWidget {
  const _DockRow();

  @override
  Widget build(BuildContext context) {
    final home = context.findAncestorWidgetOfExactType<AndroidHome>();
    final open = home?.onOpen ?? (_) {};
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _DockButton(
            buttonKey: const Key('dock-phone'),
            onTap: () => open('phone'),
            child: const _CircleMark(color: Color(0xFF34C759), icon: Icons.phone),
          ),
          _DockButton(
            buttonKey: const Key('dock-messages'),
            onTap: () => open('messages'),
            child: const _Squircle(
              color: Colors.white,
              child: Icon(Icons.chat_bubble, color: Color(0xFF5B7CFA), size: 26),
            ),
          ),
          _DockButton(
            buttonKey: const Key('dock-browser'),
            onTap: () => open('browser'),
            child: const _BrowserMark(),
          ),
          _DockButton(
            buttonKey: const Key('dock-camera'),
            onTap: () => open('camera'),
            child: const _CameraMark(),
          ),
        ],
      ),
    );
  }
}

class _Weather extends StatelessWidget {
  const _Weather({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('android-weather'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 74,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5EB0FF), Color(0xFF2F86F6)],
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _Sun(),
                SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '14°',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600, height: 1),
                    ),
                    Text('Seoul', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Start extends StatelessWidget {
  const _Start({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        key: const Key('android-start'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: const SizedBox(
          height: 74,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Start',
                style: TextStyle(color: Color(0xFF1C1C1E), fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 8),
              _Swirl(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Search extends StatelessWidget {
  const _Search({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 1,
      child: InkWell(
        key: const Key('android-search'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: const SizedBox(
          height: 46,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Spacer(),
                Icon(Icons.mic_none, color: Color(0xFF5F6368), size: 22),
                SizedBox(width: 12),
                Icon(Icons.photo_camera_outlined, color: Color(0xFF5F6368), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Launch extends StatelessWidget {
  const _Launch({
    required this.label,
    required this.onTap,
    required this.mark,
    required this.buttonKey,
  });

  final String label;
  final VoidCallback onTap;
  final Widget mark;
  final Key buttonKey;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            mark,
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12, shadows: [
                Shadow(color: Color(0x66000000), blurRadius: 4),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({required this.buttonKey, required this.onTap, required this.child});

  final Key buttonKey;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(key: buttonKey, onTap: onTap, customBorder: const CircleBorder(), child: child);
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('android-pages'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: i == index ? 16 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i == index ? Colors.white : Colors.white54,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _Bag extends StatelessWidget {
  const _Bag();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8AA8), Color(0xFFFF4D6D)],
        ),
      ),
      child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 30),
    );
  }
}

class _Flower extends StatelessWidget {
  const _Flower();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF7AD9), Color(0xFF7A5CFF)],
        ),
      ),
      child: const CustomPaint(painter: _FlowerPainter()),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  const _FlowerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final petal = Paint()..color = Colors.white.withValues(alpha: 0.92);
    for (var i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2;
      final at = center + Offset(math.cos(angle) * 8, math.sin(angle) * 8);
      canvas.drawCircle(at, 7, petal);
    }
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFFFFC107));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlayMark extends StatelessWidget {
  const _PlayMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const CustomPaint(painter: _TrianglePainter()),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.38, size.height * 0.28)
      ..lineTo(size.width * 0.72, size.height * 0.5)
      ..lineTo(size.width * 0.38, size.height * 0.72)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3DDC97), Color(0xFF2F6BFF)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotFolder extends StatelessWidget {
  const _DotFolder();

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFFEA4335),
      Color(0xFF4285F4),
      Color(0xFFFBBC05),
      Color(0xFF34A853),
      Color(0xFF7B61FF),
      Color(0xFFFF6D00),
      Color(0xFF00ACC1),
      Color(0xFFAB47BC),
      Color(0xFF5C6BC0),
    ];
    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: [
          for (final color in colors)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            ),
        ],
      ),
    );
  }
}

class _PlainIcon extends StatelessWidget {
  const _PlainIcon({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

class _CircleMark extends StatelessWidget {
  const _CircleMark({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

class _Squircle extends StatelessWidget {
  const _Squircle({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}

class _BrowserMark extends StatelessWidget {
  const _BrowserMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const CustomPaint(painter: _RingPainter()),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.butt;
    const colors = [Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853), Color(0xFF4285F4)];
    for (var i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        (i / 4) * math.pi * 2,
        math.pi / 2 - 0.08,
        false,
        paint,
      );
    }
    canvas.drawCircle(center, 4, Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CameraMark extends StatelessWidget {
  const _CameraMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF1C1C1E), width: 3),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Color(0xFF1C1C1E), shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sun extends StatelessWidget {
  const _Sun();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(color: Color(0xFFFFD60A), shape: BoxShape.circle),
    );
  }
}

class _Swirl extends StatelessWidget {
  const _Swirl();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 36, height: 36, child: CustomPaint(painter: _SwirlPainter()));
  }
}

class _SwirlPainter extends CustomPainter {
  const _SwirlPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const colors = [Color(0xFF3DDC97), Color(0xFF2F6BFF), Color(0xFFFF4D8D), Color(0xFFFFC107)];
    for (var i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 6 + i * 3.2),
        i * 0.8,
        2.2,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Full-bleed wallpaper behind the current Android skin.
class AndroidRibbonPainter extends CustomPainter {
  const AndroidRibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFC8C4C0),
            Color(0xFFE6D5C4),
            Color(0xFF8D7E74),
            Color(0xFF3C3840),
          ],
          stops: [0, 0.38, 0.7, 1],
        ).createShader(rect),
    );
    void ribbon(Color color, double shift, double width) {
      final path = Path()
        ..moveTo(-30, size.height * 0.08 + shift)
        ..cubicTo(
          size.width * 0.35,
          size.height * -0.05 + shift,
          size.width * 0.15,
          size.height * 0.62 + shift,
          size.width * 0.78,
          size.height * 0.46 + shift,
        )
        ..cubicTo(
          size.width * 1.1,
          size.height * 0.36 + shift,
          size.width * 0.7,
          size.height * 0.95 + shift,
          size.width + 20,
          size.height * 0.82 + shift,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    ribbon(const Color(0xFF9C9794), 0, size.shortestSide * 0.34);
    ribbon(const Color(0xFFDCC9B6), size.height * 0.04, size.shortestSide * 0.22);
    ribbon(const Color(0xFF6A635F), -size.height * 0.03, size.shortestSide * 0.16);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
