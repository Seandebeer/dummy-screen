import 'package:flutter/material.dart';

import '../os_catalog.dart';

/// Simulated picture cues for the prop. Nothing here writes battery, lock,
/// security, or stored data. Stop and Reset clear the cue and the previous
/// screen is still underneath.
class CueSpec {
  const CueSpec(this.id, this.label, this.category, this.icon);

  final String id;
  final String label;
  final String category;
  final IconData icon;
}

const kPowerCues = [
  CueSpec('boot', 'Power on', 'power', Icons.power_settings_new),
  CueSpec('shutdown', 'Power off', 'power', Icons.power_off),
  CueSpec('dying', 'Phone dying', 'power', Icons.battery_alert),
  CueSpec('restart', 'Restart', 'power', Icons.restart_alt),
  CueSpec('sleep', 'Sleep & wake', 'power', Icons.bedtime_outlined),
  CueSpec('force', 'Force restart', 'power', Icons.flash_on_outlined),
  CueSpec('charged', 'Battery 100%', 'power', Icons.battery_charging_full),
];

const kFaultCues = [
  CueSpec('crash', 'App crash', 'faults', Icons.error_outline),
  CueSpec('fatal', 'System error', 'faults', Icons.report_outlined),
  CueSpec('frozen', 'Touch frozen', 'faults', Icons.do_not_touch_outlined),
  CueSpec('bluescreen', 'Blue screen', 'faults', Icons.monitor_heart_outlined),
  CueSpec('bootloop', 'Boot loop', 'faults', Icons.loop),
  CueSpec('glitch-mild', 'Mild glitch', 'faults', Icons.waves),
  CueSpec('glitch', 'Screen glitch', 'faults', Icons.grain),
  CueSpec('glitch-signal', 'Signal glitch', 'faults', Icons.tv),
  CueSpec('glitch-extreme', 'Extreme glitch', 'faults', Icons.broken_image),
  CueSpec('overheat', 'Overheating', 'faults', Icons.device_thermostat),
  CueSpec('storage', 'Storage full', 'faults', Icons.sd_storage_outlined),
];

const kSecurityCues = [
  CueSpec('seclock', 'Security lock', 'security', Icons.lock_outline),
  CueSpec('passcode', 'Wrong passcode', 'security', Icons.pin_outlined),
  CueSpec('lockout', 'Failed attempts', 'security', Icons.timer_outlined),
  CueSpec('biometric', 'Biometric failed', 'security', Icons.fingerprint),
  CueSpec(
    'remotelock',
    'Remote lock',
    'security',
    Icons.phonelink_lock_outlined,
  ),
  CueSpec('erase', 'Erase warning', 'security', Icons.warning_amber_rounded),
];

const kCueSpecs = [...kPowerCues, ...kFaultCues, ...kSecurityCues];

bool knownCue(String effect) => kCueSpecs.any((spec) => spec.id == effect);

bool cueUsesIntensity(String effect) =>
    effect == 'dying' || effect == 'overheat' || effect.startsWith('glitch');

String cueLabel(String effect) {
  for (final spec in kCueSpecs) {
    if (spec.id == effect) return spec.label;
  }
  return effect;
}

/// Hold cues return null and stay up until Stop or Reset.
Duration? cueAutoStop(String effect) {
  switch (effect) {
    case 'boot':
      return const Duration(milliseconds: 2800);
    case 'restart':
      return const Duration(milliseconds: 4600);
    case 'force':
      return const Duration(milliseconds: 3200);
    case 'charged':
      return const Duration(milliseconds: 2800);
    case 'passcode':
      return const Duration(milliseconds: 2400);
    case 'biometric':
      return const Duration(milliseconds: 2200);
    default:
      return null;
  }
}

class PhoneCue {
  const PhoneCue({
    required this.effect,
    required this.startedAt,
    this.intensity = 70,
    this.generation = 0,
  });

  final String effect;
  final int startedAt;
  final int intensity;
  final int generation;

  PhoneCue copyWith({int? intensity}) => PhoneCue(
    effect: effect,
    startedAt: startedAt,
    intensity: intensity ?? this.intensity,
    generation: generation,
  );

  Map<String, dynamic> toJson() => {
    'effect': effect,
    'startedAt': startedAt,
    'intensity': intensity,
    'generation': generation,
  };

  factory PhoneCue.fromJson(Map<String, dynamic> json) {
    final raw = (json['intensity'] as num?)?.toInt() ?? 70;
    return PhoneCue(
      effect: json['effect'] as String? ?? '',
      startedAt: (json['startedAt'] as num?)?.toInt() ?? 0,
      intensity: raw.clamp(0, 100).toInt(),
      generation: (json['generation'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Paints a cue over the device stage. A live cue also swallows touches so
/// the picture stays put until the cue ends.
class PhoneCueLayer extends StatelessWidget {
  const PhoneCueLayer({
    super.key,
    required this.cue,
    required this.skin,
    required this.child,
  });

  final PhoneCue? cue;
  final String skin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final live = cue;
    final body = live == null ? child : AbsorbPointer(child: child);
    if (live == null) return body;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        body,
        Positioned.fill(
          child: IgnorePointer(
            child: _CueTicker(
              key: ValueKey('${live.effect}-${live.generation}'),
              cue: live,
              skin: skin,
            ),
          ),
        ),
      ],
    );
  }
}

class _CueTicker extends StatefulWidget {
  const _CueTicker({super.key, required this.cue, required this.skin});

  final PhoneCue cue;
  final String skin;

  @override
  State<_CueTicker> createState() => _CueTickerState();
}

class _CueTickerState extends State<_CueTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick;

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tick,
      builder: (context, _) {
        final elapsed =
            DateTime.now().millisecondsSinceEpoch - widget.cue.startedAt;
        return KeyedSubtree(
          key: const Key('phone-cue'),
          child: KeyedSubtree(
            key: Key('phone-cue-${widget.cue.effect}'),
            child: _CueFrame(
              cue: widget.cue,
              skin: widget.skin,
              elapsed: elapsed < 0 ? 0 : elapsed,
            ),
          ),
        );
      },
    );
  }
}

class _CueCopy {
  const _CueCopy({
    required this.chargedTitle,
    required this.chargedBody,
    required this.crashTitle,
    required this.crashBody,
    required this.fatalTitle,
    required this.fatalBody,
    required this.failureTitle,
    required this.failureBody,
    required this.failureBg,
    required this.failureFg,
    required this.heatTitle,
    required this.heatBody,
    required this.storageTitle,
    required this.storageBody,
    required this.lockedTitle,
    required this.lockedBody,
    required this.passcode,
    required this.attempts,
    required this.lockoutTitle,
    required this.lockoutBody,
    required this.bioTitle,
    required this.bioBody,
    required this.remoteTitle,
    required this.remoteBody,
    required this.eraseTitle,
    required this.eraseBody,
    required this.dyingTitle,
    required this.dyingBody,
    required this.shutdownLabel,
    required this.cardBg,
    required this.cardFg,
  });

  final String chargedTitle;
  final String chargedBody;
  final String crashTitle;
  final String crashBody;
  final String fatalTitle;
  final String fatalBody;
  final String failureTitle;
  final String failureBody;
  final Color failureBg;
  final Color failureFg;
  final String heatTitle;
  final String heatBody;
  final String storageTitle;
  final String storageBody;
  final String lockedTitle;
  final String lockedBody;
  final String passcode;
  final String attempts;
  final String lockoutTitle;
  final String lockoutBody;
  final String bioTitle;
  final String bioBody;
  final String remoteTitle;
  final String remoteBody;
  final String eraseTitle;
  final String eraseBody;
  final String dyingTitle;
  final String dyingBody;
  final String shutdownLabel;
  final Color cardBg;
  final Color cardFg;
}

_CueCopy _copyFor(SkinChrome chrome) {
  switch (chrome) {
    case SkinChrome.android:
      return const _CueCopy(
        chargedTitle: 'Charged',
        chargedBody: '100%',
        crashTitle: 'App has stopped',
        crashBody: 'The current app closed unexpectedly.',
        fatalTitle: 'Fatal error',
        fatalBody: 'A system process has failed.',
        failureTitle: 'System failure',
        failureBody: 'The system process stopped.',
        failureBg: Color(0xFF101410),
        failureFg: Color(0xFFB7F5C8),
        heatTitle: 'Device is overheating',
        heatBody: 'Temperature is too high. Let it cool down.',
        storageTitle: 'Storage space running out',
        storageBody: 'Free some space to continue.',
        lockedTitle: 'Device locked',
        lockedBody: 'Locked for security.',
        passcode: 'Wrong PIN',
        attempts: 'Incorrect PIN',
        lockoutTitle: 'Too many attempts',
        lockoutBody: 'Try again in 1 minute.',
        bioTitle: 'Fingerprint not recognised',
        bioBody: 'Try again or use your PIN.',
        remoteTitle: 'Remotely locked',
        remoteBody: 'Device management locked this phone.',
        eraseTitle: 'Erase warning',
        eraseBody: 'This device will be erased.',
        dyingTitle: 'Battery low',
        dyingBody: '1% remaining. Connect a charger.',
        shutdownLabel: 'Shutting down',
        cardBg: Color(0xFFF4F4F5),
        cardFg: Color(0xFF1A1A1A),
      );
    case SkinChrome.classic:
      return const _CueCopy(
        chargedTitle: 'Charged',
        chargedBody: 'Battery is at 100%.',
        crashTitle: 'Application error',
        crashBody: 'The application quit unexpectedly.',
        fatalTitle: 'System error',
        fatalBody: 'A serious problem has occurred.',
        failureTitle: 'System error',
        failureBody: 'The device cannot continue.',
        failureBg: Color(0xFFD8D8DC),
        failureFg: Color(0xFF1C1C1E),
        heatTitle: 'Temperature warning',
        heatBody: 'This device needs to cool down before use.',
        storageTitle: 'Not enough space',
        storageBody: 'Storage is too full to continue.',
        lockedTitle: 'Locked for security',
        lockedBody: 'Enter the passcode to continue.',
        passcode: 'Wrong Passcode',
        attempts: 'Incorrect passcode',
        lockoutTitle: 'Too many failed attempts',
        lockoutBody: 'Try again in 1 minute.',
        bioTitle: 'Face Not Recognised',
        bioBody: 'Try again.',
        remoteTitle: 'Device remotely locked',
        remoteBody: 'A management profile locked this device.',
        eraseTitle: 'Erase warning',
        eraseBody: 'This device is about to be erased.',
        dyingTitle: 'Low Battery',
        dyingBody: 'About 1% remaining.',
        shutdownLabel: 'Shutting down',
        cardBg: Color(0xF2F2F2F7),
        cardFg: Color(0xFF1C1C1E),
      );
    case SkinChrome.tiles:
      return const _CueCopy(
        chargedTitle: 'Fully charged',
        chargedBody: '100%',
        crashTitle: 'App error',
        crashBody: 'This app ran into a problem and closed.',
        fatalTitle: 'Fatal error',
        fatalBody: 'The system hit a problem it cannot recover from.',
        failureTitle: 'Your device ran into a problem',
        failureBody: 'It needs to restart.',
        failureBg: Color(0xFF0078D7),
        failureFg: Color(0xFFFFFFFF),
        heatTitle: 'Overheating',
        heatBody: 'The device is too hot and will slow down.',
        storageTitle: 'Storage is full',
        storageBody: 'Remove some files to free space.',
        lockedTitle: 'Phone locked',
        lockedBody: 'Locked for security.',
        passcode: 'Incorrect PIN',
        attempts: 'Wrong PIN',
        lockoutTitle: 'Too many attempts',
        lockoutBody: 'Temporarily locked. Try again in 1 minute.',
        bioTitle: 'Biometric not recognised',
        bioBody: 'Try again.',
        remoteTitle: 'Remotely locked',
        remoteBody: 'Your organisation locked this device.',
        eraseTitle: 'Erase warning',
        eraseBody: 'This device is about to be erased.',
        dyingTitle: 'Battery low',
        dyingBody: '1% charge remaining.',
        shutdownLabel: 'Shutting down',
        cardBg: Color(0xFF1F1F1F),
        cardFg: Color(0xFFFFFFFF),
      );
    case SkinChrome.modern:
      return const _CueCopy(
        chargedTitle: '100% Charged',
        chargedBody: 'Battery is fully charged.',
        crashTitle: 'App closed',
        crashBody: 'The app quit unexpectedly.',
        fatalTitle: 'System error',
        fatalBody: 'A fatal error has occurred.',
        failureTitle: 'System failure',
        failureBody: 'This device needs to restart.',
        failureBg: Color(0xFF000000),
        failureFg: Color(0xFFFFFFFF),
        heatTitle: 'Temperature warning',
        heatBody: 'This device needs to cool down.',
        storageTitle: 'Storage Almost Full',
        storageBody: 'You can manage storage in Settings.',
        lockedTitle: 'Locked for security',
        lockedBody: 'Enter the passcode to continue.',
        passcode: 'Incorrect Passcode',
        attempts: 'Failed attempt',
        lockoutTitle: 'Too many failed attempts',
        lockoutBody: 'Temporarily locked. Try again in 1 minute.',
        bioTitle: 'Face Not Recognised',
        bioBody: 'Try again.',
        remoteTitle: 'Device remotely locked',
        remoteBody: 'A management profile locked this device.',
        eraseTitle: 'Erase warning',
        eraseBody: 'This device is about to be erased.',
        dyingTitle: 'Low Battery',
        dyingBody: 'About 1% remaining.',
        shutdownLabel: 'Shutting down',
        cardBg: Color(0xF21C1C1E),
        cardFg: Color(0xFFFFFFFF),
      );
  }
}

class _CueFrame extends StatelessWidget {
  const _CueFrame({
    required this.cue,
    required this.skin,
    required this.elapsed,
  });

  final PhoneCue cue;
  final String skin;
  final int elapsed;

  @override
  Widget build(BuildContext context) {
    final chrome = chromeFor(skin);
    final copy = _copyFor(chrome);
    switch (cue.effect) {
      case 'boot':
        return _boot(chrome, elapsed, 2800);
      case 'shutdown':
        return _shutdown(chrome, copy, elapsed);
      case 'dying':
        return _dying(copy, cue, elapsed);
      case 'restart':
        if (elapsed < 1700) return _shutdown(chrome, copy, elapsed);
        return _boot(chrome, elapsed - 1700, 2900);
      case 'sleep':
        final fade = (elapsed / 420).clamp(0.0, 1.0);
        return ColoredBox(color: Colors.black.withValues(alpha: fade));
      case 'force':
        if (elapsed < 220) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.black),
              ColoredBox(
                color: Colors.white.withValues(
                  alpha: elapsed < 80 ? 0.85 : 0.15,
                ),
              ),
              CustomPaint(
                painter: _GlitchPainter(
                  elapsed: elapsed,
                  intensity: 90,
                  style: 'glitch-extreme',
                ),
                child: const SizedBox.expand(),
              ),
            ],
          );
        }
        return _boot(chrome, elapsed - 220, 2980);
      case 'charged':
        return _charged(copy, elapsed);
      case 'crash':
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Colors.black.withValues(alpha: 0.38)),
            if (elapsed < 120) const ColoredBox(color: Color(0x66FFFFFF)),
            _Notice(
              bg: copy.cardBg,
              fg: copy.cardFg,
              icon: Icons.error_outline,
              accent: const Color(0xFFFF453A),
              title: copy.crashTitle,
              body: copy.crashBody,
            ),
          ],
        );
      case 'fatal':
        return _FullMessage(
          bg: const Color(0xFF000000),
          fg: Colors.white,
          accent: const Color(0xFFFF453A),
          title: copy.fatalTitle,
          body: copy.fatalBody,
        );
      case 'frozen':
        return const SizedBox.expand();
      case 'bluescreen':
        return _FullMessage(
          bg: copy.failureBg,
          fg: copy.failureFg,
          title: copy.failureTitle,
          body: copy.failureBody,
        );
      case 'bootloop':
        final phase = elapsed % 2600;
        if (phase > 2100) {
          return const ColoredBox(
            color: Colors.black,
            child: Center(
              child: Text(
                'Restarting',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }
        return _boot(chrome, phase, 2100);
      case 'glitch':
      case 'glitch-mild':
      case 'glitch-signal':
      case 'glitch-extreme':
        return CustomPaint(
          painter: _GlitchPainter(
            elapsed: elapsed,
            intensity: cue.intensity,
            style: cue.effect,
          ),
          child: const SizedBox.expand(),
        );
      case 'overheat':
        return _overheat(copy, cue, elapsed);
      case 'storage':
        return _Notice(
          bg: copy.cardBg,
          fg: copy.cardFg,
          icon: Icons.sd_storage_outlined,
          accent: const Color(0xFFFF9F0A),
          title: copy.storageTitle,
          body: copy.storageBody,
        );
      case 'seclock':
        return _LockScreen(title: copy.lockedTitle, body: copy.lockedBody);
      case 'passcode':
        final wobble = elapsed < 640
            ? ((elapsed ~/ 40) % 2 == 0 ? -8.0 : 8.0)
            : 0.0;
        return Transform.translate(
          offset: Offset(wobble, 0),
          child: _LockScreen(
            title: copy.passcode,
            body: 'Try again.',
            titleColor: const Color(0xFFFF453A),
          ),
        );
      case 'lockout':
        final title = elapsed < 1600 ? copy.attempts : copy.lockoutTitle;
        final body = elapsed < 1600
            ? 'Try again.'
            : elapsed < 3200
            ? 'One more failure will lock this device.'
            : copy.lockoutBody;
        return _LockScreen(
          title: title,
          body: body,
          titleColor: const Color(0xFFFF453A),
        );
      case 'biometric':
        return _biometric(chrome, copy, elapsed > 700);
      case 'remotelock':
        return _LockScreen(
          title: copy.remoteTitle,
          body: copy.remoteBody,
          icon: Icons.phonelink_lock,
        );
      case 'erase':
        final pulse = (elapsed ~/ 500) % 2 == 0 ? 1.0 : 0.45;
        return ColoredBox(
          color: const Color(0xFF2A0000),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: pulse,
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFFF453A),
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    copy.eraseTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFF453A),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    copy.eraseBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All content and settings will be removed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      default:
        return const ColoredBox(color: Colors.black);
    }
  }
}

Widget _boot(SkinChrome chrome, int elapsed, int total) {
  final fadeIn = (elapsed / 500).clamp(0.0, 1.0);
  final fadeOutStart = total - 700;
  final fadeOut = elapsed < fadeOutStart
      ? 1.0
      : (1 - (elapsed - fadeOutStart) / 700).clamp(0.0, 1.0);
  return ColoredBox(
    color: Colors.black.withValues(alpha: elapsed < fadeOutStart ? 1 : fadeOut),
    child: Center(
      child: Opacity(
        opacity: fadeIn * fadeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PropMark(chrome: chrome, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Starting',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _shutdown(SkinChrome chrome, _CueCopy copy, int elapsed) {
  final cover = elapsed < 400 ? 0.7 + 0.3 * (elapsed / 400) : 1.0;
  final mark = elapsed < 1500
      ? 1.0
      : (1 - (elapsed - 1500) / 500).clamp(0.0, 1.0);
  return ColoredBox(
    color: Colors.black.withValues(alpha: cover),
    child: Center(
      child: Opacity(
        opacity: mark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PropMark(chrome: chrome, size: 72),
            const SizedBox(height: 16),
            Text(
              copy.shutdownLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _dying(_CueCopy copy, PhoneCue cue, int elapsed) {
  final amp = cue.intensity.clamp(0, 100) / 100;
  final dieAt = (11000 - amp * 5000).round().clamp(4000, 11000);
  if (elapsed >= dieAt) return const ColoredBox(color: Colors.black);
  final dim = ((elapsed / dieAt) * (0.2 + 0.8 * amp)).clamp(0.0, 0.92);
  final step = (200 - (amp * 120)).round().clamp(60, 200);
  final flicker = amp > 0.15 && (elapsed ~/ step) % 6 == 0;
  return Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(color: Colors.black.withValues(alpha: dim)),
      if (flicker) ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
      Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
          child: _Banner(
            bg: const Color(0xF21C1C1E),
            fg: Colors.white,
            icon: Icons.battery_alert,
            accent: const Color(0xFFFF453A),
            title: copy.dyingTitle,
            body: copy.dyingBody,
          ),
        ),
      ),
    ],
  );
}

Widget _charged(_CueCopy copy, int elapsed) {
  final fade = elapsed < 280
      ? elapsed / 280
      : elapsed > 2300
      ? (1 - (elapsed - 2300) / 500).clamp(0.0, 1.0)
      : 1.0;
  return Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 0),
      child: Opacity(
        opacity: fade,
        child: _Banner(
          bg: copy.cardBg,
          fg: copy.cardFg,
          icon: Icons.battery_charging_full,
          accent: const Color(0xFF30D158),
          title: copy.chargedTitle,
          body: copy.chargedBody,
        ),
      ),
    ),
  );
}

Widget _overheat(_CueCopy copy, PhoneCue cue, int elapsed) {
  final amp = cue.intensity.clamp(0, 100) / 100;
  final shutdown = cue.intensity >= 85 && elapsed > 4000;
  return Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(
        color: Colors.black.withValues(alpha: shutdown ? 0.92 : amp * 0.5),
      ),
      Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 52, 16, 0),
          child: _Banner(
            bg: const Color(0xF23A1A00),
            fg: Colors.white,
            icon: Icons.device_thermostat,
            accent: const Color(0xFFFF9F0A),
            title: shutdown ? copy.shutdownLabel : copy.heatTitle,
            body: copy.heatBody,
          ),
        ),
      ),
    ],
  );
}

Widget _biometric(SkinChrome chrome, _CueCopy copy, bool failed) {
  final ink = failed ? const Color(0xFFFF453A) : Colors.white;
  final icon = chrome == SkinChrome.android ? Icons.fingerprint : Icons.face;
  return ColoredBox(
    color: Colors.black,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ink, width: 3),
              ),
              child: Icon(icon, color: ink, size: 46),
            ),
            const SizedBox(height: 18),
            Text(
              copy.bioTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              copy.bioBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 14),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PropMark extends StatelessWidget {
  const _PropMark({required this.chrome, required this.size});

  final SkinChrome chrome;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (chrome) {
      case SkinChrome.android:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF2FBF71),
              width: size * 0.08,
            ),
          ),
          child: Center(
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2FBF71),
              ),
            ),
          ),
        );
      case SkinChrome.classic:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF7F7FA), Color(0xFF8E8E93)],
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 16),
            ],
          ),
        );
      case SkinChrome.tiles:
        return SizedBox(
          width: size,
          height: size,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Expanded(child: ColoredBox(color: Color(0xFF4FC3F7))),
                    SizedBox(width: 4),
                    Expanded(child: ColoredBox(color: Color(0xFF81C784))),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Row(
                  children: const [
                    Expanded(child: ColoredBox(color: Color(0xFFFFB74D))),
                    SizedBox(width: 4),
                    Expanded(child: ColoredBox(color: Color(0xFFE57373))),
                  ],
                ),
              ),
            ],
          ),
        );
      case SkinChrome.modern:
        return Container(
          width: size * 0.72,
          height: size * 0.72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 0.16),
          ),
        );
    }
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({
    required this.title,
    required this.body,
    this.icon = Icons.lock,
    this.titleColor = Colors.white,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 34),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullMessage extends StatelessWidget {
  const _FullMessage({
    required this.bg,
    required this.fg,
    required this.title,
    required this.body,
    this.accent,
  });

  final Color bg;
  final Color fg;
  final Color? accent;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accent ?? fg,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fg.withValues(alpha: 0.88),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.bg,
    required this.fg,
    required this.title,
    required this.body,
    this.icon,
    this.accent,
  });

  final Color bg;
  final Color fg;
  final String title;
  final String body;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: accent ?? fg, size: 28),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fg,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fg.withValues(alpha: 0.78),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.bg,
    required this.fg,
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
  });

  final Color bg;
  final Color fg;
  final String title;
  final String body;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.75),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlitchPainter extends CustomPainter {
  _GlitchPainter({
    required this.elapsed,
    required this.intensity,
    this.style = 'glitch',
  });

  final int elapsed;
  final int intensity;
  final String style;

  @override
  void paint(Canvas canvas, Size size) {
    final amp = intensity.clamp(0, 100) / 100;
    if (amp <= 0 || size.isEmpty) return;
    switch (style) {
      case 'glitch-mild':
        _mild(canvas, size, amp);
      case 'glitch-signal':
        _signal(canvas, size, amp);
      case 'glitch-extreme':
        _extreme(canvas, size, amp);
      default:
        _digital(canvas, size, amp);
    }
  }

  /// A few hairline tears and a faint colour fringe. The screen stays readable.
  void _mild(Canvas canvas, Size size, double amp) {
    final tick = elapsed ~/ 160;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF7AD7FF).withValues(alpha: 0.04 * amp),
    );
    for (var i = 0; i < 2; i++) {
      final seed = _mix(tick * 9 + i * 5);
      final y = (seed % 1000) / 1000 * size.height;
      final slip = ((seed % 17) - 8) * amp;
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, 1),
        Paint()..color = Colors.white.withValues(alpha: 0.28 * amp),
      );
      canvas.drawRect(
        Rect.fromLTWH(slip, y + 1, size.width * 0.42, 1.5),
        Paint()..color = const Color(0xFFFF4D6A).withValues(alpha: 0.35 * amp),
      );
    }
    final scan = ((elapsed ~/ 18) % 1000) / 1000 * size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, scan, size.width, 1),
      Paint()..color = Colors.white.withValues(alpha: 0.18 * amp),
    );
  }

  /// Chunked colour blocks and a hard scan line.
  void _digital(Canvas canvas, Size size, double amp) {
    final tick = elapsed ~/ 70;
    final wash = [
      const Color(0x55FF2D55),
      const Color(0x5500E5FF),
      const Color(0x66FFE14A),
    ][tick % 3];
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = wash.withValues(alpha: 0.18 * amp),
    );
    const slices = 9;
    for (var i = 0; i < slices; i++) {
      final band = size.height / slices;
      final jitter = ((_mix(tick * 13 + i) % 100) / 100 - 0.5) * 48 * amp;
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, i * band, size.width, band - 1));
      if ((tick + i) % 3 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(jitter, i * band, size.width, band),
          Paint()..color = Colors.white.withValues(alpha: 0.07 * amp),
        );
      }
      canvas.restore();
    }
    final scan = ((tick * 17) % 1000) / 1000 * size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, scan, size.width, 2),
      Paint()..color = Colors.white.withValues(alpha: 0.4 * amp),
    );
    final blocks = (3 + amp * 5).round();
    for (var b = 0; b < blocks; b++) {
      final seed = _mix(tick * 31 + b * 17);
      final x = (seed % 1000) / 1000 * size.width;
      final y = ((seed ~/ 7) % 1000) / 1000 * size.height;
      final w = 6 + (seed % 28) * amp;
      canvas.drawRect(
        Rect.fromLTWH(x, y, w, w * 0.55),
        Paint()..color = const Color(0xAA101014),
      );
    }
  }

  /// Analog hold: scan lines, snow, and a rolling tracking bar.
  void _signal(Canvas canvas, Size size, double amp) {
    final tick = elapsed ~/ 40;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF102018).withValues(alpha: 0.18 * amp),
    );
    final line = Paint()..color = Colors.black.withValues(alpha: 0.22 * amp);
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), line);
    }
    final roll = ((elapsed / 6) % (size.height + 36)) - 18;
    canvas.drawRect(
      Rect.fromLTWH(-8, roll, size.width + 16, 22),
      Paint()..color = const Color(0xFFD5FFE4).withValues(alpha: 0.16 * amp),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, roll + 8, size.width, 2),
      Paint()..color = Colors.white.withValues(alpha: 0.45 * amp),
    );
    final specks = (28 + amp * 40).round();
    for (var i = 0; i < specks; i++) {
      final seed = _mix(tick * 19 + i * 3);
      final x = (seed % 1000) / 1000 * size.width;
      final y = ((seed ~/ 11) % 1000) / 1000 * size.height;
      final ink = i.isEven ? const Color(0xFFB7FFC8) : const Color(0xFF9AA0A6);
      canvas.drawRect(
        Rect.fromLTWH(x, y, 2, 2),
        Paint()..color = ink.withValues(alpha: 0.55 * amp),
      );
    }
  }

  /// Thick torn bands, inverted flashes, and large dead pixels.
  void _extreme(Canvas canvas, Size size, double amp) {
    final tick = elapsed ~/ 40;
    const bands = 5;
    for (var i = 0; i < bands; i++) {
      final seed = _mix(tick * 23 + i * 11);
      final band = size.height / bands;
      final slip = ((seed % 160) - 80) * amp;
      final mode = seed % 5;
      final paint = Paint();
      if (mode == 0) {
        paint.color = const Color(0xFF000000).withValues(alpha: 0.82);
      } else if (mode == 1) {
        paint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.72 * amp);
      } else if (mode == 2) {
        paint.color = const Color(0xFFFF2D55).withValues(alpha: 0.55 * amp);
      } else if (mode == 3) {
        paint.color = const Color(0xFF00F0FF).withValues(alpha: 0.5 * amp);
      } else {
        paint.color = const Color(0xFFFFFF40).withValues(alpha: 0.45 * amp);
      }
      canvas.drawRect(
        Rect.fromLTWH(slip, i * band, size.width, band - 2),
        paint,
      );
    }
    for (var i = 0; i < 8; i++) {
      final seed = _mix(tick * 7 + i * 29);
      if (seed % 3 == 0) continue;
      final col = size.width / 8;
      canvas.drawRect(
        Rect.fromLTWH(i * col, (seed % 40) * amp, col - 2, size.height),
        Paint()
          ..color = (i.isEven ? const Color(0xFFFF4D6A) : const Color(0xFF39F3FF))
              .withValues(alpha: 0.22 * amp),
      );
    }
    final blocks = (6 + amp * 8).round();
    for (var b = 0; b < blocks; b++) {
      final seed = _mix(tick * 41 + b * 13);
      final x = (seed % 1000) / 1000 * size.width;
      final y = ((seed ~/ 9) % 1000) / 1000 * size.height;
      final w = 18 + (seed % 48) * amp;
      canvas.drawRect(
        Rect.fromLTWH(x, y, w, w * 0.72),
        Paint()..color = const Color(0xF0101014),
      );
    }
  }

  @override
  bool shouldRepaint(_GlitchPainter oldDelegate) =>
      oldDelegate.elapsed != elapsed ||
      oldDelegate.intensity != intensity ||
      oldDelegate.style != style;
}

int _mix(int n) {
  var x = n & 0x7fffffff;
  x = (x ^ (x << 13)) & 0x7fffffff;
  x = (x ^ (x >> 17)) & 0x7fffffff;
  x = (x ^ (x << 5)) & 0x7fffffff;
  return x;
}
