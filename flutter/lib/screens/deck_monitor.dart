import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../phone/cues.dart';
import '../phone/form_factor.dart';
import '../phone/home_view.dart';
import '../phone/lock_screen.dart';
import '../phone/phone_shell.dart';
import '../store.dart';

/// Small picture of the deck's selected device. Touches are ignored so the
/// window only monitors the prop.
class DeckLiveView extends StatelessWidget {
  const DeckLiveView({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  static const _screenHeight = 844.0;

  @override
  Widget build(BuildContext context) {
    final metrics = metricsFor(device.kind);
    final pad = switch (metrics.frame) {
      'phone' => 8.0,
      'tablet' => 10.0,
      'tv' => 8.0,
      'laptop' => 8.0,
      _ => 10.0,
    };
    final chin = switch (metrics.frame) {
      'laptop' => 24.0,
      'monitor' => 22.0,
      _ => 0.0,
    };
    final screenWidth = _screenHeight * metrics.aspect;
    final outerWidth = screenWidth + pad * 2;
    final outerHeight = _screenHeight + pad * 2 + chin;
    final aspect = outerWidth / outerHeight;
    var displayHeight = 240.0;
    var displayWidth = displayHeight * aspect;
    if (displayWidth > 340) {
      displayWidth = 340;
      displayHeight = displayWidth / aspect;
    }

    final phone = device.kind == 'phone' || device.kind == 'tablet';
    final wide = device.kind == 'tablet' || metrics.aspect > 1;
    final stage = phone ? _phone(wide) : FormOs(store: store, device: device);

    return Align(
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        key: const Key('deck-live-view'),
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: const Color(0xFF0A0A0C),
          child: SizedBox(
            width: displayWidth,
            height: displayHeight,
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: outerWidth,
                height: outerHeight,
                child: IgnorePointer(
                  child: DeviceBezel(
                    frame: metrics.frame,
                    child: PhoneCueLayer(
                      cue: store.cueFor(device.id),
                      skin: device.skin,
                      child: stage,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _phone(bool wide) {
    final now = osNow(device.os);
    final locked = device.locked && device.os.lockType != 'off';
    return PhoneShell(
      framed: false,
      device: device,
      onHome: () {},
      call: store.callFor(device.id),
      onAccept: () {},
      onEnd: () {},
      alarm: store.alarms[device.id] ?? false,
      onDismissAlarm: () {},
      banners: store.bannersFor(device.id),
      onDismissBanner: (_) {},
      onOpenBanner: (_) {},
      body: locked
          ? LockView(
              device: device,
              dateLabel: formatDay(now),
              onUnlock: () {},
              onSetPasscode: (_) {},
              onSetPattern: (_) {},
            )
          : PhoneHome(
              skin: device.skin,
              os: device.os,
              wide: wide,
              light: device.os.isLight,
              onOpen: (_) {},
            ),
    );
  }
}
