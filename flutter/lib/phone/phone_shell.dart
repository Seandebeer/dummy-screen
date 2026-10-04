import 'package:flutter/material.dart';

import '../format.dart';
import '../image_file.dart';
import '../models.dart';
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
                    onAccept: onAccept,
                    onEnd: onEnd,
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
  });

  final String timeLabel;
  final bool framed;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final top = framed ? 10.0 : MediaQuery.paddingOf(context).top;
    return Padding(
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
          const Spacer(),
          const Icon(Icons.signal_cellular_alt, size: 16),
          const SizedBox(width: 4),
          const Icon(Icons.wifi, size: 16),
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
              widthFactor: 0.7,
              child: Container(
                margin: const EdgeInsets.all(1),
                color: ink,
              ),
            ),
          ),
        ],
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
    this.onAccept,
    this.onEnd,
  });

  final LiveCall call;
  final String answerMode;
  final VoidCallback? onAccept;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    final incoming = call.direction == 'incoming';
    final ringing = call.status == 'ringing';
    final initial = call.contactName.isEmpty
        ? '?'
        : call.contactName.characters.first.toUpperCase();
    return ColoredBox(
      color: const Color(0xFF101014),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 36),
            Text(
              ringing ? (incoming ? 'Incoming call' : 'Calling') : 'Connected',
              style: const TextStyle(color: kMuted, letterSpacing: 0.4),
            ),
            const SizedBox(height: 22),
            CircleAvatar(
              radius: 48,
              backgroundColor: kAccent,
              child: Text(initial, style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 16),
            Text(
              call.contactName,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              call.contactNumber,
              style: const TextStyle(color: kMuted, fontSize: 16),
            ),
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
