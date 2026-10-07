import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../format.dart';
import '../image_file.dart';
import '../media/call_media.dart';
import '../models.dart';
import 'call_stage.dart';
import '../os_catalog.dart';
import '../theme.dart';

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
    this.framed = true,
    this.onStatusTap,
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
  final bool framed;

  /// OS edit only. Cycles the cellular radio shown in the status bar.
  final VoidCallback? onStatusTap;

  @override
  Widget build(BuildContext context) {
    final skin = device.skin;
    final chrome = chromeFor(skin);
    final light = device.os.isLight;
    final ink = light ? const Color(0xD9000000) : Colors.white;
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
                    onTap: onStatusTap,
                  ),
                  Expanded(child: body),
                  if (!device.locked)
                    _HomeControl(chrome: chrome, onHome: onHome, ink: ink),
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
                          child: _Banner(
                            banner: banner,
                            onDismiss: () => onDismissBanner?.call(banner.id),
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
    this.onTap,
  });

  final String timeLabel;
  final bool framed;
  final Color ink;
  final OsSettings os;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final top = framed ? 10.0 : MediaQuery.paddingOf(context).top;
    final bars = os.cellular == 'NO SERVICE' ? 0 : os.signal.clamp(0, 4);
    final radio = os.cellular == 'NO SERVICE' ? '' : os.cellular;
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
          if (os.wifi) ...[
            const SizedBox(width: 4),
            Icon(Icons.wifi, size: 16, color: ink),
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

class _HomeControl extends StatelessWidget {
  const _HomeControl({
    required this.chrome,
    required this.onHome,
    required this.ink,
  });

  final SkinChrome chrome;
  final VoidCallback onHome;
  final Color ink;

  @override
  Widget build(BuildContext context) {
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

class _Banner extends StatelessWidget {
  const _Banner({required this.banner, required this.onDismiss});

  final BannerNote banner;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF22C2C2E),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onDismiss,
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
