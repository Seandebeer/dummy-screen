import 'package:dummy_phone/app.dart';
import 'package:dummy_phone/phone/cues.dart';
import 'package:dummy_phone/screens/control_page.dart';
import 'package:dummy_phone/store.dart';
import 'package:dummy_phone/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorder implements StageSync {
  _Recorder(this.role);

  @override
  LinkRole role;

  @override
  String status = '';

  @override
  String? address;

  final patches = <Map<String, dynamic>>[];

  @override
  Future<String?> host({int? port}) async => null;

  @override
  Future<void> join(String input) async {}

  @override
  Future<void> disconnect() async {}

  @override
  void broadcastState() {}

  @override
  void sendPatch(Map<String, dynamic> patch) => patches.add(patch);
}

void main() {
  test('cues stay on the picture and leave the phone alone', () {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final before = store.deviceById('d-hero')!;
    store.sendMessage(
      deviceId: 'd-hero',
      sender: 'phone',
      text: 'Keep me',
      senderName: 'Hero',
      thread: 'A',
    );
    store.playCue('d-hero', 'not-a-cue');
    expect(store.cueFor('d-hero'), isNull);

    store.playCue('d-hero', 'sleep');
    expect(store.cueFor('d-hero')!.effect, 'sleep');
    store.playCue('d-hero', 'sleep');
    expect(store.cueFor('d-hero'), isNull);

    store.playCue('d-hero', 'glitch', intensity: 10);
    store.setCueIntensity('d-hero', 95);
    expect(store.cueFor('d-hero')!.intensity, 95);
    store.playCue('d-hero', 'charged');
    store.playCue('d-hero', 'erase');
    store.playCue('d-hero', 'seclock');
    final exported = store.exportState();
    store.stopCue('d-hero');
    expect(store.cueFor('d-hero'), isNull);

    final other = StageStore.demo();
    addTearDown(other.dispose);
    other.importState(exported);
    expect(other.cueFor('d-hero')!.effect, 'seclock');
    other.factoryResetDevice('d-hero');
    expect(other.cueFor('d-hero'), isNull);

    final after = store.deviceById('d-hero')!;
    expect(after.os.battery, before.os.battery);
    expect(after.locked, before.locked);
    expect(store.messages.single.text, 'Keep me');
    expect(store.photos['d-hero'] ?? const [], isEmpty);
  });

  test('a deck cue reaches the phone through the host', () {
    final host = StageStore.demo();
    final client = StageStore.demo();
    addTearDown(host.dispose);
    addTearDown(client.dispose);
    host.attach(_Recorder(LinkRole.host));
    final link = _Recorder(LinkRole.client);
    client.attach(link);

    client.playCue('d-hero', 'fatal', intensity: 40);
    expect(link.patches, hasLength(1));
    host.applyPatch(link.patches.single);
    expect(host.cueFor('d-hero')!.effect, 'fatal');
    expect(host.cueFor('d-hero')!.intensity, 40);
    expect(host.deviceById('d-hero')!.locked, isTrue);
    expect(host.deviceById('d-hero')!.os.battery, 80);

    client.stopCue('d-hero');
    host.applyPatch(link.patches.last);
    expect(host.cueFor('d-hero'), isNull);
  });

  testWidgets('a short cue restores the screen by itself', (tester) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    store.playCue('d-hero', 'passcode');
    await tester.pump(const Duration(milliseconds: 400));
    store.playCue('d-hero', 'shutdown');
    await tester.pump(const Duration(milliseconds: 2200));
    expect(store.cueFor('d-hero')!.effect, 'shutdown');

    store.playCue('d-hero', 'passcode');
    await tester.pump(const Duration(milliseconds: 2500));
    expect(store.cueFor('d-hero'), isNull);
    expect(store.deviceById('d-hero')!.os.battery, 80);
    expect(store.deviceById('d-hero')!.locked, isTrue);
  });

  testWidgets('every cue paints on the device', (tester) async {
    Future<void> show(String effect, String skin, {int elapsed = 0}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 390,
              height: 844,
              child: PhoneCueLayer(
                cue: PhoneCue(
                  effect: effect,
                  startedAt: DateTime.now().millisecondsSinceEpoch - elapsed,
                  intensity: 90,
                  generation: 1,
                ),
                skin: skin,
                child: GestureDetector(
                  key: const Key('under'),
                  onTap: () {},
                  child: const ColoredBox(color: Color(0xFF2244AA)),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    for (final spec in kCueSpecs) {
      await show(spec.id, 'modern');
      expect(tester.takeException(), isNull, reason: spec.id);
      expect(find.byKey(Key('phone-cue-${spec.id}')), findsOneWidget);
    }

    await show('shutdown', 'modern');
    expect(find.text('Shutting down'), findsOneWidget);

    await show('charged', 'android');
    expect(find.text('Charged'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await show('crash', 'android');
    expect(find.text('App has stopped'), findsOneWidget);

    await show('bluescreen', 'tiles');
    expect(find.text('Your device ran into a problem'), findsOneWidget);

    await show('bluescreen', 'modern');
    expect(find.text('System failure'), findsOneWidget);

    await show('biometric', 'android');
    expect(find.text('Fingerprint not recognised'), findsOneWidget);

    await show('biometric', 'iphoneos');
    expect(find.text('Face Not Recognised'), findsOneWidget);

    await show('overheat', 'modern', elapsed: 5000);
    expect(find.text('Shutting down'), findsOneWidget);

    await show('erase', 'modern');
    expect(find.text('This device is about to be erased.'), findsOneWidget);

    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 400,
            child: PhoneCueLayer(
              cue: PhoneCue(
                effect: 'frozen',
                startedAt: DateTime.now().millisecondsSinceEpoch,
                generation: 2,
              ),
              skin: 'modern',
              child: GestureDetector(
                onTap: () => taps += 1,
                child: const ColoredBox(
                  key: Key('under'),
                  color: Color(0xFF2244AA),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('phone-cue-frozen'))),
    );
    await tester.pump();
    expect(taps, 0);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 400,
            child: PhoneCueLayer(
              cue: null,
              skin: 'modern',
              child: GestureDetector(
                onTap: () => taps += 1,
                child: const ColoredBox(
                  key: Key('under'),
                  color: Color(0xFF2244AA),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('under')));
    await tester.pump();
    expect(taps, 1);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the os stage shows a shutdown cue from the store', (
    tester,
  ) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    store.playCue('d-hero', 'shutdown');

    await tester.pumpWidget(DummyPhoneApp(store: store));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nav-os')));
    await tester.pump();

    expect(find.byKey(const Key('phone-cue-shutdown')), findsOneWidget);
    expect(find.text('Shutting down'), findsOneWidget);
    expect(store.deviceById('d-hero')!.os.battery, 80);

    store.stopCue('d-hero');
    await tester.pump();
    expect(find.byKey(const Key('phone-cue-shutdown')), findsNothing);
    expect(find.text('Shutting down'), findsNothing);
  });

  testWidgets('the control deck triggers and stops a cue', (tester) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 2200));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: StoreScope(store: store, child: const ControlPage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Power, system & battery'), findsOneWidget);
    expect(find.text('System errors & malfunctions'), findsOneWidget);
    expect(find.text('Security & privacy'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Alarm'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);

    await tester.ensureVisible(find.text('Power, system & battery'));
    await tester.tap(find.text('Power, system & battery'));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('deck-cue-boot')));
    await tester.tap(find.byKey(const Key('deck-cue-boot')));
    await tester.pump();
    expect(store.cueFor('d-hero')!.effect, 'boot');
    expect(find.text('Playing · Power on'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('deck-cue-stop-power')));
    await tester.tap(find.byKey(const Key('deck-cue-stop-power')));
    await tester.pump();
    expect(store.cueFor('d-hero'), isNull);

    await tester.ensureVisible(find.byKey(const Key('deck-cue-sleep')));
    await tester.tap(find.byKey(const Key('deck-cue-sleep')));
    await tester.pump();
    expect(store.cueFor('d-hero')!.effect, 'sleep');
    await tester.tap(find.byKey(const Key('deck-cue-sleep')));
    await tester.pump();
    expect(store.cueFor('d-hero'), isNull);
    expect(store.deviceById('d-hero')!.locked, isTrue);
    expect(store.deviceById('d-hero')!.os.battery, 80);
  });

  testWidgets('the deck monitors the selected device and the glitch looks', (
    tester,
  ) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 2400));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: StoreScope(store: store, child: const ControlPage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('deck-live-view')), findsOneWidget);
    expect(find.text('Mild glitch'), findsNothing);

    await tester.ensureVisible(find.text('System errors & malfunctions'));
    await tester.tap(find.text('System errors & malfunctions'));
    await tester.pump();

    expect(find.text('Mild glitch'), findsOneWidget);
    expect(find.text('Screen glitch'), findsOneWidget);
    expect(find.text('Signal glitch'), findsOneWidget);
    expect(find.text('Extreme glitch'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('deck-cue-glitch-mild')));
    await tester.tap(find.byKey(const Key('deck-cue-glitch-mild')));
    await tester.pump();
    expect(store.cueFor('d-hero')!.effect, 'glitch-mild');
    expect(find.byKey(const Key('phone-cue-glitch-mild')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('deck-cue-glitch-extreme')),
    );
    await tester.tap(find.byKey(const Key('deck-cue-glitch-extreme')));
    await tester.pump();
    expect(store.cueFor('d-hero')!.effect, 'glitch-extreme');
    expect(find.byKey(const Key('phone-cue-glitch-extreme')), findsOneWidget);
    expect(find.byKey(const Key('phone-cue-glitch-mild')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('deck-live-toggle')));
    await tester.tap(find.byKey(const Key('deck-live-toggle')));
    await tester.pump();
    expect(find.byKey(const Key('deck-live-view')), findsNothing);
    expect(store.cueFor('d-hero')!.effect, 'glitch-extreme');

    await tester.tap(find.byKey(const Key('deck-live-toggle')));
    await tester.pump();
    expect(find.byKey(const Key('deck-live-view')), findsOneWidget);
    expect(find.byKey(const Key('phone-cue-glitch-extreme')), findsOneWidget);

    store.stopCue('d-hero');
    await tester.pump();
    expect(find.byKey(const Key('phone-cue-glitch-extreme')), findsNothing);
    expect(find.byKey(const Key('deck-live-view')), findsOneWidget);
    expect(store.deviceById('d-hero')!.locked, isTrue);
    expect(store.deviceById('d-hero')!.os.battery, 80);
  });
}
