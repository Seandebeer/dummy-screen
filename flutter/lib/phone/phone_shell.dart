import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../format.dart';
import '../image_file.dart';
import '../media/call_media.dart';
import '../models.dart';
import 'call_stage.dart';
import 'ios_keyboard.dart';
import '../os_catalog.dart';
import '../theme.dart';
import 'legacy_homes.dart';

class PhoneShell extends StatelessWidget {
  const PhoneShell({
    super.key,
    required this.device,
    required this.timeLabel,
    required this.body,
    required this.onHome,
    this.call,
    this.onAccept,
    this.onEnd,
    this.alarm = false,
    this.onDismissAlarm,
    this.banners = const [],
    this.onDismissBanner,
    this.onOpenBanner,
    this.framed = true,
    this.onStatusTap,
    this.keyboardRoute = '',
  });

  final PropDevice device;
  final String timeLabel;
  final Widget body;
  final VoidCallback onHome;
  final LiveCall? call;
  final VoidCallback? onAccept;
  final VoidCallback? onEnd;
  final bool alarm;
  final VoidCallback? onDismissAlarm;
  final List<BannerNote> banners;
  final void Function(String id)? onDismissBanner;
  final void Function(BannerNote banner)? onOpenBanner;
  final bool framed;

  /// OS edit only. Cycles the cellular radio shown in the status bar.
  final VoidCallback? onStatusTap;

  /// Open app on this device. The keypad closes when it changes.
  final String keyboardRoute;

  @override
  Widget build(BuildContext context) {
    final skin = device.skin;
    final chrome = chromeFor(skin);
    final light = device.os.isLight;
    // Legacy homes paint their own wallpaper, so the status ink follows that
    // paper instead of a light theme sitting underneath it.
    final ink = isLegacySkin(skin) || !light ? Colors.white : const Color(0xD9000000);
    final paper = wallpaperFor(device, locked: device.locked);
    final image = paper.imagePath.isEmpty
        ? null
        : imageProviderForPath(paper.imagePath);
    final feed = call?.kind == 'video'
        ? CallMediaScope.maybeOf(context)?.remoteRenderer
        : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(framed ? 40 : 0),
        boxShadow: framed
            ? const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 40,
                  offset: Offset(0, 18),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(framed ? 40 : 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: paper.gradient,
            image: image == null
                ? null
                : DecorationImage(image: image, fit: BoxFit.cover),
          ),
          child: IconTheme(
            data: IconThemeData(color: ink),
            child: Stack(
            children: [
              Column(
                children: [
                  _StatusBar(
                    timeLabel: timeLabel,
                    framed: framed,
                    ink: ink,
                    os: device.os,
                    skin: skin,
                    onTap: onStatusTap,
                  ),
                  Expanded(
                    child: DeviceKeyboard(
                      route: keyboardRoute,
                      footer: device.locked
                          ? null
                          : _HomeControl(chrome: chrome, skin: skin, onHome: onHome, ink: ink),
                      child: body,
                    ),
                  ),
                ],
              ),
              if (banners.isNotEmpty && call == null && !alarm)
                Positioned(
                  top: framed ? 36 : 28,
                  left: 12,
                  right: 12,
                  child: Column(
                    children: [
                      for (final banner in banners.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Dismissible(
                            key: ValueKey('banner-${banner.id}'),
                            direction: DismissDirection.horizontal,
                            onDismissed: (_) => onDismissBanner?.call(banner.id),
                            child: OsBanner(
                              banner: banner,
                              onTap: () {
                                if (onOpenBanner != null) {
                                  onOpenBanner!(banner);
                                } else {
                                  onDismissBanner?.call(banner.id);
                                }
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (call != null)
                Positioned.fill(
                  child: _CallOverlay(
                    call: call!,
                    answerMode: device.os.callAnswer,
                    callerPhoto: device.os.callerPhoto,
                    onAccept: onAccept,
                    onEnd: onEnd,
                    feed: feed,
                  ),
                ),
              if (!device.locked && call == null)
                Positioned.fill(
                  child: _ControlShade(
                    ink: ink,
                    cellular: device.os.signal > 0,
                    wifi: device.os.wifi,
                    bluetooth: device.os.bluetooth,
                  ),
                ),
              if (alarm)
                Positioned.fill(
                  child: _AlarmOverlay(onDismiss: onDismissAlarm),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.timeLabel,
    required this.framed,
    required this.ink,
    required this.os,
    required this.skin,
    this.onTap,
  });

  final String timeLabel;
  final bool framed;
  final Color ink;
  final OsSettings os;
  final String skin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final top = framed ? 10.0 : MediaQuery.paddingOf(context).top;
    final bars = os.cellular == 'NO SERVICE' ? 0 : os.signal.clamp(0, 4);
    final radio = os.cellular;
    final era = _statusEra(skin);
    if (era != _StatusEra.standard) {
      return _eraStatus(top, bars, era);
    }
    return GestureDetector(
      key: const Key('phone-status'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
      padding: EdgeInsets.fromLTRB(22, top + 8, 18, 6),
      child: Row(
        children: [
          Text(
            timeLabel,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: ink,
            ),
          ),
          if (os.networkName.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              os.networkName,
              style: TextStyle(color: ink.withValues(alpha: 0.85), fontSize: 12),
            ),
          ],
          const Spacer(),
          if (os.showAlarm) ...[
            Icon(Icons.alarm, size: 14, color: ink),
            const SizedBox(width: 4),
          ],
          if (os.bluetooth) ...[
            Icon(Icons.bluetooth, size: 14, color: ink),
            const SizedBox(width: 4),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: 3,
                  height: 4 + i * 2.5,
                  margin: const EdgeInsets.only(right: 1.5),
                  decoration: BoxDecoration(
                    color: i < bars ? ink : ink.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(0.5),
                  ),
                ),
            ],
          ),
          if (radio.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              radio,
              style: TextStyle(
                color: ink,
                fontSize: radio == 'NO SERVICE' ? 10 : 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
          if (os.wifi) ...[
            const SizedBox(width: 4),
            Icon(_wifiIcon(os.wifiBars), size: 16, color: ink),
          ],
          const SizedBox(width: 6),
          Container(
            width: 24,
            height: 11,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: ink.withValues(alpha: 0.7)),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (os.battery.clamp(0, 100)) / 100,
              child: Container(
                margin: const EdgeInsets.all(1),
                color: os.battery < 20 ? kAlert : ink,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _eraStatus(double top, int bars, _StatusEra era) {
    final carrier = os.networkName.isEmpty ? 'Carrier' : os.networkName;
    final signal = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            width: 3,
            height: 4 + i * 2.0,
            margin: const EdgeInsets.only(right: 1),
            color: i < bars ? ink : ink.withValues(alpha: 0.28),
          ),
      ],
    );
    final battery = Text('${os.battery}%', style: TextStyle(color: ink, fontSize: 12));
    Widget sideLeft;
    Widget sideRight;
    final batteryIcon = Icon(Icons.battery_full, size: 18, color: ink);
    switch (era) {
      case _StatusEra.wp:
        sideLeft = const SizedBox.shrink();
        sideRight = Text(timeLabel, style: TextStyle(color: ink, fontSize: 14));
      case _StatusEra.holo:
        sideLeft = Icon(Icons.notifications_none, size: 16, color: ink);
        sideRight = Row(mainAxisSize: MainAxisSize.min, children: [signal, const SizedBox(width: 6), batteryIcon, const SizedBox(width: 6), Text(timeLabel, style: TextStyle(color: ink, fontSize: 13))]);
      case _StatusEra.belle:
        sideLeft = Text(carrier, style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600));
        sideRight = Row(mainAxisSize: MainAxisSize.min, children: [signal, const SizedBox(width: 6), batteryIcon, const SizedBox(width: 8), Text(timeLabel, style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w700))]);
      case _StatusEra.webos:
        sideLeft = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(10)),
          child: const Text('Launcher', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        );
        sideRight = Row(mainAxisSize: MainAxisSize.min, children: [signal, const SizedBox(width: 4), const Icon(Icons.battery_full, size: 16, color: Color(0xFF3DDC5A))]);
      case _StatusEra.ios7:
        sideLeft = Row(mainAxisSize: MainAxisSize.min, children: [
          Text(os.cellular == 'NO SERVICE' ? 'No Service' : carrier, style: TextStyle(color: ink, fontSize: 12)),
          const SizedBox(width: 4),
          signal,
        ]);
        sideRight = Row(mainAxisSize: MainAxisSize.min, children: [if (os.bluetooth) Icon(Icons.bluetooth, size: 14, color: ink), if (os.bluetooth) const SizedBox(width: 4), batteryIcon]);
      case _StatusEra.ios6:
        sideLeft = Text(os.cellular == 'NO SERVICE' ? 'No SIM' : carrier, style: TextStyle(color: ink, fontSize: 12));
        sideRight = Row(mainAxisSize: MainAxisSize.min, children: [signal, const SizedBox(width: 4), battery, const SizedBox(width: 2), batteryIcon]);
      case _StatusEra.ios:
        sideLeft = Text(carrier, style: TextStyle(color: ink, fontSize: 12));
        sideRight = Row(mainAxisSize: MainAxisSize.min, children: [signal, const SizedBox(width: 4), batteryIcon]);
      case _StatusEra.standard:
        sideLeft = const SizedBox.shrink();
        sideRight = const SizedBox.shrink();
    }
    final centered = era == _StatusEra.ios || era == _StatusEra.ios6 || era == _StatusEra.ios7 || era == _StatusEra.webos;
    return GestureDetector(
      key: const Key('phone-status'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, top + 6, 12, 4),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(children: [sideLeft, const Spacer(), sideRight]),
            if (centered) Text(timeLabel, style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

IconData _wifiIcon(int bars) {
  switch (bars.clamp(0, 3)) {
    case 0:
      return Icons.signal_wifi_0_bar;
    case 1:
      return Icons.wifi_1_bar;
    case 2:
      return Icons.wifi_2_bar;
    default:
      return Icons.wifi;
  }
}

class _NavStrip extends StatelessWidget {
  const _NavStrip({required this.onHome, required this.children, this.color = const Color(0xFF000000)});

  final VoidCallback onHome;
  final List<Widget> children;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: SizedBox(
        height: 46,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < children.length; i++)
              IconButton(
                key: i == 0 ? const Key('os-home') : null,
                onPressed: onHome,
                icon: children[i],
              ),
          ],
        ),
      ),
    );
  }
}

class _IosChin extends StatelessWidget {
  const _IosChin({required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0A0A0C),
      child: SizedBox(
        height: 52,
        child: Center(
          child: InkWell(
            key: const Key('os-home'),
            onTap: onHome,
            customBorder: const CircleBorder(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4A4A4E), Color(0xFF1A1A1C)],
                ),
                border: Border.all(color: const Color(0xFF8A8A8E)),
              ),
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white70),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuadMark extends StatelessWidget {
  const _QuadMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [
          _Quad(),
          _Quad(),
          _Quad(),
          _Quad(),
        ],
      ),
    );
  }
}

class _Quad extends StatelessWidget {
  const _Quad();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 7, height: 7, child: ColoredBox(color: Colors.white));
  }
}

class _DotGrid extends StatelessWidget {
  const _DotGrid();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          _NavDot(),
          _NavDot(),
          _NavDot(),
          _NavDot(),
        ],
      ),
    );
  }
}

class _NavDot extends StatelessWidget {
  const _NavDot();

  @override
  Widget build(BuildContext context) {
    return Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle));
  }
}

class _WebOsGesture extends StatelessWidget {
  const _WebOsGesture({required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: InkWell(
        key: const Key('os-home'),
        onTap: onHome,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CardPeek(),
            SizedBox(width: 4),
            _CardPeek(),
            SizedBox(width: 10),
            Icon(Icons.keyboard_arrow_up, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CardPeek extends StatelessWidget {
  const _CardPeek();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3C),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.white24),
      ),
    );
  }
}

class _ControlShade extends StatefulWidget {
  const _ControlShade({
    required this.ink,
    required this.cellular,
    required this.wifi,
    required this.bluetooth,
  });

  final Color ink;
  final bool cellular;
  final bool wifi;
  final bool bluetooth;

  @override
  State<_ControlShade> createState() => _ControlShadeState();
}

class _ControlShadeState extends State<_ControlShade> {
  bool _open = false;
  bool _torch = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 36,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 80) setState(() => _open = true);
            },
          ),
        ),
        if (_torch)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _torch = false),
              child: const ColoredBox(color: Colors.white),
            ),
          ),
        if (_open)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _open = false),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xF01C1C1E), Color(0xCC000000)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _connectivity(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: _mediaCard()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            _round(
                              icon: Icons.flashlight_on,
                              on: _torch,
                              onTap: () => setState(() => _torch = !_torch),
                            ),
                            _round(icon: Icons.timer_outlined, on: false, onTap: () {}),
                            _round(icon: Icons.calculate_outlined, on: false, onTap: () {}),
                            _round(icon: Icons.photo_camera_outlined, on: false, onTap: () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _connectivity() {
    Widget cell(IconData icon, bool on) {
      return Icon(icon, color: on ? const Color(0xFF0A84FF) : Colors.white, size: 22);
    }

    return Container(
      height: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [cell(Icons.airplanemode_inactive, false), cell(Icons.signal_cellular_alt, widget.cellular)],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [cell(Icons.wifi, widget.wifi), cell(Icons.bluetooth, widget.bluetooth)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaCard() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.music_note, color: Colors.white),
          Spacer(),
          Text('Not Playing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          Text('Music', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _round({required IconData icon, required bool on, required VoidCallback onTap}) {
    return Material(
      color: on ? Colors.white : Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: on ? Colors.black : Colors.white),
        ),
      ),
    );
  }
}

enum _StatusEra { standard, ios, ios6, ios7, wp, holo, webos, belle }

_StatusEra _statusEra(String skin) {
  switch (skin) {
    case 'iphoneos':
    case 'aqua':
    case 'classic':
    case 'ios6':
      return _StatusEra.ios6;
    case 'ios7':
      return _StatusEra.ios7;
    case 'winphone':
    case 'tiles':
      return _StatusEra.wp;
    case 'holo':
    case 'material':
      return _StatusEra.holo;
    case 'webos':
      return _StatusEra.webos;
    case 'belle':
    case 'blackberry':
      return _StatusEra.belle;
    default:
      return _StatusEra.standard;
  }
}

class _HomeControl extends StatelessWidget {
  const _HomeControl({
    required this.chrome,
    required this.skin,
    required this.onHome,
    required this.ink,
  });

  final SkinChrome chrome;
  final String skin;
  final VoidCallback onHome;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    switch (skin) {
      case 'winphone':
      case 'tiles':
        return _NavStrip(
          onHome: onHome,
          children: const [
            Icon(Icons.arrow_back, color: Colors.white, size: 22),
            _QuadMark(),
            Icon(Icons.search, color: Colors.white, size: 22),
          ],
        );
      case 'holo':
      case 'material':
        return _NavStrip(
          onHome: onHome,
          color: const Color(0xFF111111),
          children: const [
            Icon(Icons.arrow_back, color: Colors.white, size: 22),
            Icon(Icons.home_outlined, color: Colors.white, size: 22),
            Icon(Icons.crop_square, color: Colors.white, size: 18),
          ],
        );
      case 'belle':
      case 'blackberry':
        return _NavStrip(
          onHome: onHome,
          color: Colors.transparent,
          children: const [
            _DotGrid(),
            Icon(Icons.phone, color: Colors.white, size: 26),
            Icon(Icons.menu, color: Colors.white, size: 26),
          ],
        );
      case 'iphoneos':
      case 'aqua':
      case 'classic':
      case 'ios6':
      case 'ios7':
        return _IosChin(onHome: onHome);
      case 'webos':
        return _WebOsGesture(onHome: onHome);
      default:
        break;
    }
    if (chrome == SkinChrome.tiles) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              key: const Key('os-home'),
              onPressed: onHome,
              icon: const Icon(Icons.arrow_back, size: 18),
            ),
            IconButton(
              onPressed: onHome,
              icon: const Icon(Icons.grid_view, size: 18),
            ),
            IconButton(
              onPressed: onHome,
              icon: const Icon(Icons.search, size: 18),
            ),
          ],
        ),
      );
    }
    if (chrome == SkinChrome.classic) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Center(
          child: InkWell(
            key: const Key('os-home'),
            onTap: onHome,
            customBorder: const CircleBorder(),
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A3A3C), Color(0xFF0A0A0C)],
                ),
              ),
              child: Center(
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white70),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (chrome == SkinChrome.android) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 4),
        child: Center(
          child: InkWell(
            key: const Key('os-home'),
            onTap: onHome,
            customBorder: const CircleBorder(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ink.withValues(alpha: 0.75), width: 2),
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Center(
        child: GestureDetector(
          key: const Key('os-home'),
          onTap: onHome,
          child: Container(
            width: 128,
            height: 5,
            decoration: BoxDecoration(
              color: ink.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

class OsBanner extends StatelessWidget {
  const OsBanner({super.key, required this.banner, required this.onTap});

  final BannerNote banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF22C2C2E),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.notifications, size: 18, color: kAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.appLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      banner.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallOverlay extends StatelessWidget {
  const _CallOverlay({
    required this.call,
    required this.answerMode,
    required this.callerPhoto,
    this.onAccept,
    this.onEnd,
    this.feed,
  });

  final LiveCall call;
  final String answerMode;
  final String callerPhoto;
  final VoidCallback? onAccept;
  final VoidCallback? onEnd;
  final RTCVideoRenderer? feed;

  @override
  Widget build(BuildContext context) {
    final incoming = call.direction == 'incoming';
    final ringing = call.status == 'ringing';
    final initial = call.contactName.isEmpty
        ? '?'
        : call.contactName.characters.first.toUpperCase();
    final stage = !ringing && call.kind == 'video';
    final showing = stage;
    final photo = call.scene['photo'] as String? ?? '';
    final full = (call.scene['caller'] as String? ?? callerPhoto) == 'full' && photo.isNotEmpty;
    final portrait = imageProviderForPath(photo);
    return ColoredBox(
      color: const Color(0xFF101014),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (full && portrait != null)
            Image(image: portrait, fit: BoxFit.cover),
          if (stage) Positioned.fill(child: CallStage(call: call, feed: feed)),
          SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 36),
            Text(
              ringing
                  ? (incoming
                      ? (call.kind == 'video' ? 'Incoming video call' : 'Incoming call')
                      : 'Calling')
                  : 'Connected',
              style: const TextStyle(color: kMuted, letterSpacing: 0.4),
            ),
            const SizedBox(height: 22),
            if (!showing && !full)
              CircleAvatar(
                radius: 48,
                backgroundColor: kAccent,
                backgroundImage: portrait,
                child: portrait == null
                    ? Text(initial, style: const TextStyle(fontSize: 36))
                    : null,
              ),
            if (!showing) const SizedBox(height: 16),
            Text(
              call.contactName,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
            ),
            if (call.contactNumber.isNotEmpty && call.contactNumber != call.contactName) ...[
              const SizedBox(height: 6),
              Text(
                call.contactNumber,
                style: const TextStyle(color: kMuted, fontSize: 16),
              ),
            ],
            const Spacer(),
            if (ringing && incoming && answerMode == 'swipe')
              _SlideToAnswer(onAccept: onAccept, onDecline: onEnd)
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (ringing && incoming)
                    _RoundAction(
                      key: const Key('call-accept'),
                      icon: Icons.call,
                      label: 'Accept',
                      color: kSignal,
                      onTap: onAccept,
                    ),
                  _RoundAction(
                    key: const Key('call-end'),
                    icon: Icons.call_end,
                    label: ringing && incoming ? 'Decline' : 'End',
                    color: kAlert,
                    onTap: onEnd,
                  ),
                ],
              ),
            const SizedBox(height: 36),
          ],
        ),
          ),
        ],
      ),
    );
  }
}

class _SlideToAnswer extends StatefulWidget {
  const _SlideToAnswer({this.onAccept, this.onDecline});

  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  State<_SlideToAnswer> createState() => _SlideToAnswerState();
}

class _SlideToAnswerState extends State<_SlideToAnswer> {
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final travel = constraints.maxWidth - 64;
              return GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _progress = (_progress + details.delta.dx / travel).clamp(
                      0.0,
                      1.0,
                    );
                  });
                },
                onHorizontalDragEnd: (_) {
                  if (_progress > 0.82) {
                    widget.onAccept?.call();
                  } else {
                    setState(() => _progress = 0);
                  }
                },
                child: Container(
                  key: const Key('call-accept'),
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Text(
                          'slide to answer',
                          style: TextStyle(color: kMuted),
                        ),
                      ),
                      Positioned(
                        left: 6 + travel * _progress,
                        top: 6,
                        child: const CircleAvatar(
                          radius: 26,
                          backgroundColor: kSignal,
                          child: Icon(Icons.call, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          _RoundAction(
            key: const Key('call-end'),
            icon: Icons.call_end,
            label: 'Decline',
            color: kAlert,
            onTap: widget.onDecline,
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: 72, height: 72, child: Icon(icon, size: 30)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}

class _AlarmOverlay extends StatelessWidget {
  const _AlarmOverlay({this.onDismiss});

  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1C0A0A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alarm, size: 72, color: kAlert),
            const SizedBox(height: 12),
            const Text(
              'Alarm',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              formatClock(DateTime.now()),
              style: const TextStyle(fontSize: 28, color: kMuted),
            ),
            const SizedBox(height: 28),
            FilledButton(
              key: const Key('alarm-dismiss'),
              style: FilledButton.styleFrom(backgroundColor: kAlert),
              onPressed: onDismiss,
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }
}
